import SwiftUI
import Foundation

/// Service for exporting financial data to CSV and JSON
@MainActor
final class ExportService {
    static let shared = ExportService()
    
    private init() {}
    
    // MARK: - CSV Generation
    
    func generateExpensesCSV(expenses: [ExpenseResponse], bills: [BillResponse]) -> URL? {
        var csvString = "Type,Date,Description,Category,Amount (INR),Status\n"
        
        // Add Expenses
        for expense in expenses {
            let type = "Expense"
            let date = expense.occurredOn
            let desc = sanitizeCSV(expense.merchant ?? "Expense")
            let category = sanitizeCSV(expense.category.capitalized)
            let amount = String(format: "%.2f", Double(expense.amountPaise) / 100.0)
            let status = expense.status
            
            csvString += "\(type),\"\(date)\",\"\(desc)\",\"\(category)\",\(amount),\(status)\n"
        }
        
        // Add Bills
        for bill in bills {
            let type = "Recurring Bill"
            let date = bill.dueDate
            let desc = sanitizeCSV(bill.name)
            let category = "Subscription / Bill"
            let amount = String(format: "%.2f", Double(bill.amountPaise) / 100.0)
            let status = bill.status
            
            csvString += "\(type),\"\(date)\",\"\(desc)\",\"\(category)\",\(amount),\(status)\n"
        }
        
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd"
        let dateTag = dateFormatter.string(from: Date())
        let filename = "SafeToSpend_Export_\(dateTag).csv"
        
        return writeStringToTempFile(content: csvString, filename: filename)
    }
    
    // MARK: - JSON Generation
    
    func generateJSONBackup(rawJSON: [String: AnyCodable]?) -> URL? {
        guard let raw = rawJSON else { return nil }
        
        do {
            let encoder = JSONEncoder()
            encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
            let data = try encoder.encode(raw)
            
            let dateFormatter = DateFormatter()
            dateFormatter.dateFormat = "yyyy-MM-dd"
            let dateTag = dateFormatter.string(from: Date())
            let filename = "SafeToSpend_Backup_\(dateTag).json"
            
            let tempURL = FileManager.default.temporaryDirectory.appendingPathComponent(filename)
            try data.write(to: tempURL, options: .atomic)
            return tempURL
        } catch {
            print("Error encoding backup JSON: \(error)")
            return nil
        }
    }
    
    // MARK: - Helpers
    
    private func sanitizeCSV(_ string: String) -> String {
        string.replacingOccurrences(of: "\"", with: "\"\"")
            .replacingOccurrences(of: "\n", with: " ")
    }
    
    private func writeStringToTempFile(content: String, filename: String) -> URL? {
        let tempURL = FileManager.default.temporaryDirectory.appendingPathComponent(filename)
        do {
            try content.write(to: tempURL, atomically: true, encoding: .utf8)
            return tempURL
        } catch {
            print("Error writing temp CSV file: \(error)")
            return nil
        }
    }
}

// MARK: - UIActivityViewController Sheet
struct ActivityShareSheet: UIViewControllerRepresentable {
    let activityItems: [Any]
    let applicationActivities: [UIActivity]? = nil
    
    func makeUIViewController(context: Context) -> UIActivityViewController {
        let controller = UIActivityViewController(
            activityItems: activityItems,
            applicationActivities: applicationActivities
        )
        return controller
    }
    
    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
}
