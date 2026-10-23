import Foundation
import UIKit
import Vision
import os

private let ocrLog = Logger(subsystem: "com.safetospend.app", category: "OCR")

// MARK: - Parsed Expense Candidate

struct ParsedExpenseCandidate: Identifiable, Equatable {
    let id = UUID()
    var amountPaise: Int
    var merchant: String
    var category: String
    var occurredOn: String // YYYY-MM-DD
    var confidence: Double
    var isSelected: Bool = true
    var isBill: Bool = false
    var source: String // "upi_screenshot" or "receipt_photo"
    var rawTextSnippet: String = ""
    
    var amountInRupees: String {
        amountPaise.toRupees
    }
}

// MARK: - OCR Service

actor OCRService {
    static let shared = OCRService()
    
    private init() {}
    
    /// Parse a single image for expense candidates
    func parseImage(_ image: UIImage, source: String = "upi_screenshot") async -> [ParsedExpenseCandidate] {
        // Try multiple ways to get a CGImage (handles HEIC, rotated, etc.)
        var cgImage = image.cgImage
        if cgImage == nil {
            // Force render via UIGraphicsImageRenderer
            let renderer = UIGraphicsImageRenderer(size: image.size)
            let rendered = renderer.image { ctx in
                image.draw(at: .zero)
            }
            cgImage = rendered.cgImage
        }
        
        guard let finalCGImage = cgImage else {
            ocrLog.error("Failed to get CGImage from UIImage (size: \(image.size.width)x\(image.size.height))")
            return []
        }
        
        ocrLog.info("Starting OCR on image \(finalCGImage.width)x\(finalCGImage.height)")
        
        return await withCheckedContinuation { continuation in
            let request = VNRecognizeTextRequest { request, error in
                if let error = error {
                    ocrLog.error("Vision error: \(error.localizedDescription)")
                    continuation.resume(returning: [])
                    return
                }
                
                guard let observations = request.results as? [VNRecognizedTextObservation] else {
                    ocrLog.error("No observations returned")
                    continuation.resume(returning: [])
                    return
                }
                
                let lines = observations.compactMap { obs -> String? in
                    guard let topCandidate = obs.topCandidates(1).first else { return nil }
                    let str = topCandidate.string.trimmingCharacters(in: .whitespacesAndNewlines)
                    return str.isEmpty ? nil : str
                }
                
                ocrLog.info("Extracted \(lines.count) text lines")
                for (i, line) in lines.enumerated() {
                    ocrLog.info("  [\(i)] \(line)")
                }
                
                let candidates = self.extractExpenses(from: lines, source: source)
                ocrLog.info("Found \(candidates.count) expense candidates")
                for c in candidates {
                    ocrLog.info("  → \(c.merchant) | \(c.amountPaise) paise | \(c.occurredOn)")
                }
                continuation.resume(returning: candidates)
            }
            
            request.recognitionLevel = .accurate
            request.usesLanguageCorrection = true
            request.recognitionLanguages = ["en-IN", "en-US"]
            
            let handler = VNImageRequestHandler(cgImage: finalCGImage, options: [:])
            do {
                try handler.perform([request])
            } catch {
                ocrLog.error("Vision handler error: \(error)")
                continuation.resume(returning: [])
            }
        }
    }
    
    /// Parse multiple screenshots (e.g. UPI history screenshots at end of day)
    func parseMultipleImages(_ images: [UIImage]) async -> [ParsedExpenseCandidate] {
        var allCandidates: [ParsedExpenseCandidate] = []
        for img in images {
            let candidates = await parseImage(img, source: "upi_screenshot")
            allCandidates.append(contentsOf: candidates)
        }
        
        // Deduplicate exact matches (same amount, merchant, and date)
        var seen = Set<String>()
        var uniqueCandidates: [ParsedExpenseCandidate] = []
        for c in allCandidates {
            let key = "\(c.amountPaise)_\(c.merchant.lowercased())_\(c.occurredOn)"
            if !seen.contains(key) {
                seen.insert(key)
                uniqueCandidates.append(c)
            }
        }
        
        return uniqueCandidates
    }
    
    // MARK: - Main Extraction Logic
    
    private nonisolated func extractExpenses(from lines: [String], source: String) -> [ParsedExpenseCandidate] {
        let todayDateStr = formatDate(Date())
        
        // Strategy 1: Look for structured transaction blocks (Samsung Pay, GPay history, PhonePe, etc.)
        let blockCandidates = extractTransactionBlocks(from: lines, source: source, defaultDate: todayDateStr)
        if !blockCandidates.isEmpty {
            return blockCandidates
        }
        
        // Strategy 2: Find all amount lines and pair with nearest merchant/date
        let scanCandidates = extractByAmountScan(from: lines, source: source, defaultDate: todayDateStr)
        if !scanCandidates.isEmpty {
            return scanCandidates
        }
        
        // Strategy 3: Single receipt / payment confirmation screen
        if let singleCandidate = extractSingleReceipt(from: lines, source: source, defaultDate: todayDateStr) {
            return [singleCandidate]
        }
        
        return []
    }
    
    // MARK: - Strategy 1: Transaction Block Detection
    // Detects structured UPI history (Samsung Pay, GPay, PhonePe, Paytm)
    // These apps show: Merchant Name → UPI ID → Date → Amount → Status per transaction
    
    private nonisolated func extractTransactionBlocks(from lines: [String], source: String, defaultDate: String) -> [ParsedExpenseCandidate] {
        var results: [ParsedExpenseCandidate] = []
        
        // Find ALL lines that contain rupee amounts
        var amountLines: [(index: Int, amountPaise: Int, text: String)] = []
        
        for (i, line) in lines.enumerated() {
            if let amount = extractRupeeAmount(from: line) {
                amountLines.append((index: i, amountPaise: amount, text: line))
            }
        }
        
        ocrLog.info("Found \(amountLines.count) lines with ₹ amounts")
        
        guard !amountLines.isEmpty else { return [] }
        
        // For each amount line, scan surrounding lines for merchant, date, and status
        for amountInfo in amountLines {
            let idx = amountInfo.index
            
            // --- Detect if this is a "Received" / credit transaction → skip it ---
            // In UPI history apps, status ("Sent" / "Received") is immediately adjacent to the amount
            let statusWindowStart = max(0, idx - 2)
            let statusWindowEnd = min(lines.count - 1, idx + 2)
            let statusWindow = Array(lines[statusWindowStart...statusWindowEnd])
            let isCredit = statusWindow.contains(where: { line in
                let l = line.trimmingCharacters(in: .whitespaces).lowercased()
                return l == "received" || l == "credited" || l == "credit"
                    || l.hasPrefix("received") || l.contains("money received")
                    || l.contains("credited to")
            })
            
            if isCredit {
                ocrLog.info("Skipping received/credit transaction at line \(idx)")
                continue
            }
            
            // --- Skip if this amount is clearly a balance line ---
            let amountLineLower = amountInfo.text.lowercased()
            if amountLineLower.contains("balance") || amountLineLower.contains("available") {
                continue
            }
            
            // --- Extract merchant name ---
            var merchantName = "Payment"
            
            // Look at lines BEFORE the amount for merchant name
            // In Samsung Pay: merchant is 1-4 lines above the amount
            for lookback in 1...5 {
                let prevIdx = idx - lookback
                guard prevIdx >= 0 else { break }
                let candidateLine = lines[prevIdx]
                
                if isMerchantName(candidateLine) {
                    merchantName = candidateLine.trimmingCharacters(in: .whitespacesAndNewlines)
                    ocrLog.info("Found merchant '\(merchantName)' at line \(prevIdx) for amount at \(idx)")
                    break
                }
            }
            
            // --- Extract date ---
            var itemDate = defaultDate
            
            for scanOffset in -4...3 {
                let scanIdx = idx + scanOffset
                guard scanIdx >= 0 && scanIdx < lines.count else { continue }
                if let d = extractDateFromLine(lines[scanIdx]) {
                    itemDate = d
                    break
                }
            }
            
            let category = guessCategory(for: merchantName)
            let candidate = ParsedExpenseCandidate(
                amountPaise: amountInfo.amountPaise,
                merchant: merchantName,
                category: category,
                occurredOn: itemDate,
                confidence: 0.90,
                isSelected: true,
                source: source,
                rawTextSnippet: amountInfo.text
            )
            results.append(candidate)
        }
        
        return results
    }
    
    // MARK: - Strategy 2: Amount-scan based extraction
    // Falls back to scanning for any ₹ amounts and pairing with nearby text
    
    private nonisolated func extractByAmountScan(from lines: [String], source: String, defaultDate: String) -> [ParsedExpenseCandidate] {
        var results: [ParsedExpenseCandidate] = []
        
        for (i, line) in lines.enumerated() {
            guard let amount = extractRupeeAmount(from: line) else { continue }
            
            let lower = line.lowercased()
            // Skip balance/header lines
            if lower.contains("balance") || lower.contains("available") || lower.contains("total balance") {
                continue
            }
            
            // Check nearby for "received" → skip credits
            let nearbyText = gatherNearbyText(lines: lines, around: i, range: 2).lowercased()
            if nearbyText.contains("received") || nearbyText.contains("credited") {
                continue
            }
            
            // Find merchant
            var merchant = "Payment"
            for lookback in 1...4 {
                let prevIdx = i - lookback
                guard prevIdx >= 0 else { break }
                if isMerchantName(lines[prevIdx]) {
                    merchant = lines[prevIdx].trimmingCharacters(in: .whitespacesAndNewlines)
                    break
                }
            }
            
            // Find date
            var date = defaultDate
            for offset in -3...3 {
                let scanIdx = i + offset
                guard scanIdx >= 0 && scanIdx < lines.count else { continue }
                if let d = extractDateFromLine(lines[scanIdx]) {
                    date = d
                    break
                }
            }
            
            results.append(ParsedExpenseCandidate(
                amountPaise: amount,
                merchant: merchant,
                category: guessCategory(for: merchant),
                occurredOn: date,
                confidence: 0.80,
                isSelected: true,
                source: source,
                rawTextSnippet: line
            ))
        }
        
        return results
    }
    
    // MARK: - Strategy 3: Single Receipt
    
    private nonisolated func extractSingleReceipt(from lines: [String], source: String, defaultDate: String) -> ParsedExpenseCandidate? {
        guard !lines.isEmpty else { return nil }
        
        var bestAmountPaise: Int?
        var bestMerchant = "Expense"
        var bestDate = defaultDate
        var confidence = 0.70
        
        // Find the primary amount — prefer lines with "Total", "Paid", "Amount"
        for line in lines {
            let lower = line.lowercased()
            if lower.contains("balance") || lower.contains("available") {
                continue
            }
            
            let isTotalLine = lower.contains("total") || lower.contains("paid") || lower.contains("amount")
            
            if let amount = extractRupeeAmount(from: line) {
                if isTotalLine || bestAmountPaise == nil {
                    bestAmountPaise = amount
                    confidence = isTotalLine ? 0.95 : 0.80
                }
            }
            
            if let parsedD = extractDateFromLine(line) {
                bestDate = parsedD
            }
        }
        
        // Fallback: look for "Total: 350" without ₹ symbol
        if bestAmountPaise == nil {
            let rawTotalPattern = #"(?:total|grand total|amount|paid)\s*[:=\-]?\s*([0-9]+(?:\.[0-9]{1,2})?)"#
            if let totalRegex = try? NSRegularExpression(pattern: rawTotalPattern, options: .caseInsensitive) {
                for line in lines {
                    let range = NSRange(line.startIndex..<line.endIndex, in: line)
                    if let match = totalRegex.firstMatch(in: line, options: [], range: range),
                       let numRange = Range(match.range(at: 1), in: line) {
                        if let val = Double(line[numRange]), val > 0 {
                            bestAmountPaise = Int(round(val * 100))
                            confidence = 0.85
                            break
                        }
                    }
                }
            }
        }
        
        guard let amountPaise = bestAmountPaise else { return nil }
        
        // Find merchant/payee from "Paid to" or first meaningful line
        for line in lines {
            let lower = line.lowercased()
            if lower.contains("paid to") || lower.contains("to:") {
                var clean = line
                if let range = lower.range(of: "paid to") {
                    clean = String(line[range.upperBound...])
                } else if let range = lower.range(of: "to:") {
                    clean = String(line[range.upperBound...])
                }
                clean = clean.trimmingCharacters(in: .whitespacesAndNewlines)
                if !clean.isEmpty && clean.count > 1 {
                    bestMerchant = clean
                    break
                }
            }
        }
        
        if bestMerchant == "Expense" {
            for line in lines.prefix(6) {
                if isMerchantName(line) {
                    bestMerchant = line.trimmingCharacters(in: .whitespacesAndNewlines)
                    break
                }
            }
        }
        
        return ParsedExpenseCandidate(
            amountPaise: amountPaise,
            merchant: bestMerchant,
            category: guessCategory(for: bestMerchant),
            occurredOn: bestDate,
            confidence: confidence,
            isSelected: true,
            source: source,
            rawTextSnippet: lines.joined(separator: "\n")
        )
    }
    
    // MARK: - Amount Extraction
    
    /// Extracts ₹ amount in paise from a line. Returns nil if no amount found.
    private nonisolated func extractRupeeAmount(from line: String) -> Int? {
        // 1. Matches rupee symbol or corrupted OCR representations:
        // ₹255.00, ₴255.00, ·36.00, •140.00, Rs. 500, INR 255, -₹250
        let prefixPattern = #"(?:[₹₴·•*~]|Rs\.?|INR|[-–—])\s*([0-9]{1,3}(?:[,][0-9]{2,3})*(?:\.[0-9]{1,2})?)"#
        if let regex = try? NSRegularExpression(pattern: prefixPattern, options: .caseInsensitive) {
            let range = NSRange(line.startIndex..<line.endIndex, in: line)
            if let match = regex.firstMatch(in: line, options: [], range: range),
               let amountRange = Range(match.range(at: 1), in: line) {
                let amountStr = String(line[amountRange]).replacingOccurrences(of: ",", with: "")
                if let val = Double(amountStr), val > 0 && val < 1_000_000 {
                    return Int(round(val * 100))
                }
            }
        }
        
        // 2. Standalone number with 2 decimal places (e.g. "255.00" or "36.00")
        // Only if line is short (<= 15 chars) to prevent matching phone numbers or timestamps
        let trimmed = line.trimmingCharacters(in: .whitespacesAndNewlines)
        if trimmed.count <= 15 {
            let decimalPattern = #"^[^\d]*([0-9]{1,3}(?:[,][0-9]{2,3})*\.[0-9]{2})[^\d]*$"#
            if let regex = try? NSRegularExpression(pattern: decimalPattern, options: []) {
                let range = NSRange(trimmed.startIndex..<trimmed.endIndex, in: trimmed)
                if let match = regex.firstMatch(in: trimmed, options: [], range: range),
                   let amountRange = Range(match.range(at: 1), in: trimmed) {
                    let amountStr = String(trimmed[amountRange]).replacingOccurrences(of: ",", with: "")
                    if let val = Double(amountStr), val > 0 && val < 1_000_000 {
                        return Int(round(val * 100))
                    }
                }
            }
        }
        
        return nil
    }
    
    // MARK: - Date Extraction
    
    /// Attempts to extract a date (YYYY-MM-DD) from a line of OCR text
    private nonisolated func extractDateFromLine(_ text: String) -> String? {
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        let lower = trimmed.lowercased()
        let calendar = Calendar.current
        let now = Date()
        
        // Handle relative dates
        if lower == "today" || lower.hasPrefix("today,") || lower.contains("today") {
            if lower.count < 30 {
                return formatDate(now)
            }
        }
        if lower == "yesterday" || lower.hasPrefix("yesterday,") || lower.contains("yesterday") {
            if lower.count < 30 {
                if let yesterday = calendar.date(byAdding: .day, value: -1, to: now) {
                    return formatDate(yesterday)
                }
            }
        }
        
        // Match dates like "23 OCT 2026, 14:43:39" or "22 OCT 2026"
        let dateTimePatterns: [String] = [
            #"(\d{1,2}\s+[A-Za-z]{3,9}\s+\d{4})"#,
            #"(\d{4}-\d{2}-\d{2})"#,
            #"(\d{1,2}/\d{1,2}/\d{4})"#,
            #"(\d{1,2}-\d{1,2}-\d{4})"#
        ]
        
        for pattern in dateTimePatterns {
            guard let regex = try? NSRegularExpression(pattern: pattern, options: .caseInsensitive) else { continue }
            let range = NSRange(trimmed.startIndex..<trimmed.endIndex, in: trimmed)
            if let match = regex.firstMatch(in: trimmed, options: [], range: range),
               let dateRange = Range(match.range(at: 1), in: trimmed) {
                let dateStr = String(trimmed[dateRange]).trimmingCharacters(in: .whitespaces)
                
                let formats = [
                    "dd MMM yyyy", "d MMM yyyy",
                    "dd MMMM yyyy", "d MMMM yyyy",
                    "yyyy-MM-dd",
                    "dd/MM/yyyy", "d/M/yyyy",
                    "dd-MM-yyyy", "d-M-yyyy"
                ]
                
                let formatter = DateFormatter()
                formatter.locale = Locale(identifier: "en_US_POSIX")
                
                for fmt in formats {
                    formatter.dateFormat = fmt
                    if let d = formatter.date(from: dateStr.capitalized) {
                        return formatDate(d)
                    }
                }
            }
        }
        
        return nil
    }
    
    // MARK: - Merchant Detection
    
    /// Checks if a line looks like a merchant/payee name (not a UPI ID, status, date, or amount)
    private nonisolated func isMerchantName(_ line: String) -> Bool {
        let trimmed = line.trimmingCharacters(in: .whitespacesAndNewlines)
        let lower = trimmed.lowercased()
        
        // Too short or too long
        if trimmed.count < 2 || trimmed.count > 60 { return false }
        
        // Skip if line contains an amount
        if extractRupeeAmount(from: trimmed) != nil { return false }
        
        // Skip UPI IDs (contain @)
        if trimmed.contains("@") { return false }
        
        // Skip date-like lines
        if extractDateFromLine(trimmed) != nil { return false }
        
        // Skip pure status words and UI controls
        let statusWords: Set<String> = [
            "sent", "received", "credited", "debited", "failed", "pending",
            "completed", "success", "successful", "refunded", "cancelled",
            "upi lite", "savings account", "current account", "credit",
            "filter", "filter e", "all transactions", "powered by", "axis bank",
            "name/upi id/amount", "search", "<", "q", "upi", "lip/lite"
        ]
        if statusWords.contains(lower) { return false }
        
        // Skip lines that are purely status/metadata
        let skipPrefixes = [
            "powered by", "upi transaction", "transaction id",
            "ref no", "reference", "rrn:", "the following",
            "samsung pay", "google pay", "phonepe", "paytm",
            "bank account", "savings account", "current account"
        ]
        for prefix in skipPrefixes {
            if lower.hasPrefix(prefix) || lower == prefix { return false }
        }
        
        // Must contain at least two letters
        let alphaCount = trimmed.filter { $0.isLetter }.count
        if alphaCount < 2 { return false }
        
        return true
    }
    
    // MARK: - Helpers
    
    private nonisolated func gatherNearbyText(lines: [String], around index: Int, range: Int) -> String {
        let start = max(0, index - range)
        let end = min(lines.count - 1, index + range)
        guard start <= end else { return "" }
        return lines[start...end].joined(separator: " ")
    }
    
    // MARK: - Category Guessing
    
    private nonisolated func guessCategory(for merchant: String) -> String {
        let m = merchant.lowercased()
        
        if m.contains("swiggy") || m.contains("zomato") || m.contains("mcdonald") ||
           m.contains("starbucks") || m.contains("chai") || m.contains("cafe") ||
           m.contains("restaurant") || m.contains("kitchen") || m.contains("dining") ||
           m.contains("pizza") || m.contains("burger") || m.contains("bakery") ||
           m.contains("bistro") || m.contains("food") || m.contains("chilli") ||
           m.contains("biryani") || m.contains("dhaba") || m.contains("hotel") ||
           m.contains("canteen") || m.contains("mess") || m.contains("diner") ||
           m.contains("juice") || m.contains("tea") || m.contains("coffee") {
            return "food"
        }
        
        if m.contains("blinkit") || m.contains("zepto") || m.contains("instamart") ||
           m.contains("bigbasket") || m.contains("dmart") || m.contains("grocery") ||
           m.contains("mart") || m.contains("vegetable") || m.contains("fruits") ||
           m.contains("kirana") || m.contains("supermarket") || m.contains("reliance") {
            return "groceries"
        }
        
        if m.contains("uber") || m.contains("ola") || m.contains("rapido") ||
           m.contains("metro") || m.contains("petrol") || m.contains("fuel") ||
           m.contains("shell") || m.contains("irctc") || m.contains("toll") ||
           m.contains("transport") || m.contains("auto") || m.contains("parking") {
            return "transport"
        }
        
        if m.contains("amazon") || m.contains("flipkart") || m.contains("myntra") ||
           m.contains("zara") || m.contains("retail") || m.contains("shopping") ||
           m.contains("store") || m.contains("meesho") || m.contains("ajio") {
            return "shopping"
        }
        
        if m.contains("bescom") || m.contains("electricity") || m.contains("broadband") ||
           m.contains("wifi") || m.contains("airtel") || m.contains("jio") ||
           m.contains("recharge") || m.contains("bill") || m.contains("gas") ||
           m.contains("water") || m.contains("bsnl") || m.contains("vi ") {
            return "utilities"
        }
        
        if m.contains("apollo") || m.contains("pharmacy") || m.contains("medplus") ||
           m.contains("1mg") || m.contains("hospital") || m.contains("clinic") ||
           m.contains("doctor") || m.contains("medical") || m.contains("pharma") ||
           m.contains("netmeds") || m.contains("practo") {
            return "health"
        }
        
        if m.contains("bookmyshow") || m.contains("pvr") || m.contains("inox") ||
           m.contains("netflix") || m.contains("spotify") || m.contains("cinema") ||
           m.contains("hotstar") || m.contains("prime") || m.contains("youtube") {
            return "entertainment"
        }
        
        return "general"
    }
    
    private nonisolated func formatDate(_ date: Date) -> String {
        let f = DateFormatter()
        f.dateFormat = "yyyy-MM-dd"
        return f.string(from: date)
    }
}
