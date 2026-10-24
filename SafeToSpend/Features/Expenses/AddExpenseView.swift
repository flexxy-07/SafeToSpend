import SwiftUI
import PhotosUI
import UIKit

enum ExpenseEntryMode: String, CaseIterable {
    case smart = "Smart"
    case scan = "Scan / OCR"
    case manual = "Manual"
    
    var icon: String {
        switch self {
        case .smart: return "sparkles"
        case .scan: return "camera.viewfinder"
        case .manual: return "keyboard"
        }
    }
}

struct AddExpenseView: View {
    @Environment(\.dismiss) var dismiss
    @EnvironmentObject var appState: AppState
    @State private var mode: ExpenseEntryMode = .smart
    
    // Smart entry
    @State private var rawInput = ""
    @State private var preview: ExpensePreviewResponse?
    @State private var isPreviewLoading = false
    @State private var debounceTask: Task<Void, Never>?
    
    // Manual entry
    @State private var manualAmount = ""
    @State private var manualDescription = ""
    @State private var manualCategory = "general"
    
    // Scan / OCR entry
    @State private var showCamera = false
    @State private var capturedCameraImage: UIImage?
    @State private var selectedPhotoItems: [PhotosPickerItem] = []
    @State private var isScanning = false
    @State private var scanProgressText = ""
    @State private var ocrCandidates: [ParsedExpenseCandidate] = []
    @State private var scanErrorMessage: String?
    
    // Submission state
    @State private var isSubmitting = false
    @State private var submitted = false
    @State private var loggedCount = 1
    
    private let categories = [
        "food", "transport", "shopping", "entertainment",
        "health", "utilities", "groceries", "education",
        "travel", "subscription", "general"
    ]
    
    var body: some View {
        NavigationStack {
            ZStack {
                Color.stsCardBackground.ignoresSafeArea()
                
                VStack(spacing: 0) {
                    // Mode Selector Bar
                    if !submitted {
                        modeSelectorBar
                            .padding(.horizontal, 16)
                            .padding(.top, 8)
                            .padding(.bottom, 12)
                    }
                    
                    ScrollView(.vertical, showsIndicators: false) {
                        VStack(spacing: 20) {
                            if submitted {
                                successView
                            } else {
                                switch mode {
                                case .smart:
                                    smartEntryView
                                case .scan:
                                    scanEntryView
                                case .manual:
                                    manualEntryView
                                }
                            }
                        }
                        .padding(16)
                    }
                    .scrollBounceBehavior(.always, axes: .vertical)
                    .scrollDismissesKeyboard(.interactively)
                }
            }
            .navigationTitle("Add Expense")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button {
                        dismiss()
                    } label: {
                        Image(systemName: "xmark")
                            .foregroundStyle(.stsSecondary)
                    }
                }
            }
            .sheet(isPresented: $showCamera) {
                CameraPickerView(selectedImage: $capturedCameraImage)
                    .ignoresSafeArea()
            }
            .onChange(of: capturedCameraImage) { _, newImage in
                if let image = newImage {
                    Task {
                        await processSingleBillImage(image)
                    }
                }
            }
            .onChange(of: selectedPhotoItems) { _, items in
                if !items.isEmpty {
                    Task {
                        await processSelectedScreenshots(items)
                    }
                }
            }
        }
    }
    
    // MARK: - Mode Selector Bar
    private var modeSelectorBar: some View {
        HStack(spacing: 6) {
            ForEach(ExpenseEntryMode.allCases, id: \.self) { m in
                Button {
                    Haptics.selection()
                    withAnimation(.spring(response: 0.25, dampingFraction: 0.75)) {
                        mode = m
                    }
                } label: {
                    HStack(spacing: 6) {
                        Image(systemName: m.icon)
                            .font(.system(size: 13))
                        Text(m.rawValue)
                            .font(.stsCaption)
                            .fontWeight(mode == m ? .semibold : .regular)
                    }
                    .foregroundStyle(mode == m ? .white : .stsSecondary)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 10)
                    .background(mode == m ? Color.stsAccent : Color.stsElevated)
                    .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
                }
            }
        }
        .padding(4)
        .background(Color.stsElevated.opacity(0.6))
        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
    }
    
    // MARK: - 1. Smart Entry
    private var smartEntryView: some View {
        VStack(spacing: 20) {
            VStack(alignment: .leading, spacing: 8) {
                Text("Type naturally")
                    .font(.stsCaption)
                    .foregroundStyle(.stsSecondary)
                
                HStack(spacing: 12) {
                    Image(systemName: "sparkles")
                        .foregroundStyle(.stsAccent)
                    
                    TextField("chai 25 or swiggy lunch 350", text: $rawInput)
                        .font(.stsHeadline)
                        .foregroundStyle(.stsPrimary)
                        .onChange(of: rawInput) { _, newValue in
                            debouncePreview(newValue)
                        }
                }
                .padding(16)
                .background(Color.stsElevated)
                .clipShape(RoundedRectangle(cornerRadius: 12))
            }
            
            if isPreviewLoading {
                HStack(spacing: 12) {
                    ProgressView()
                        .tint(.stsAccent)
                    Text("Parsing...")
                        .font(.stsBody)
                        .foregroundStyle(.stsSecondary)
                }
                .frame(maxWidth: .infinity)
                .cardStyle()
            } else if let preview = preview {
                previewCard(preview)
            }
            
            if preview != nil {
                confirmButton(title: "Confirm Expense", isBusy: isSubmitting) {
                    await submitFromPreview()
                }
            }
        }
    }
    
    // MARK: - 2. Scan & OCR Entry (Photo Bill & UPI Screenshots)
    private var scanEntryView: some View {
        VStack(spacing: 20) {
            // Action trigger buttons
            HStack(spacing: 12) {
                // Snap photo of bill (Camera)
                Button {
                    Haptics.impact(.light)
                    showCamera = true
                } label: {
                    VStack(spacing: 8) {
                        Image(systemName: "camera.fill")
                            .font(.title2)
                            .foregroundStyle(.stsAccent)
                        
                        Text("Snap Bill Photo")
                            .font(.stsHeadline)
                            .foregroundStyle(.stsPrimary)
                        
                        Text("At time of expense")
                            .font(.stsSmall)
                            .foregroundStyle(.stsSecondary)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 18)
                    .padding(.horizontal, 8)
                    .background(Color.stsElevated)
                    .clipShape(RoundedRectangle(cornerRadius: 14))
                    .overlay(
                        RoundedRectangle(cornerRadius: 14)
                            .stroke(Color.stsAccent.opacity(0.2), lineWidth: 1)
                    )
                }
                
                // Upload UPI Screenshots (PhotosPicker with multi-selection)
                PhotosPicker(
                    selection: $selectedPhotoItems,
                    maxSelectionCount: 10,
                    matching: .images,
                    photoLibrary: .shared()
                ) {
                    VStack(spacing: 8) {
                        Image(systemName: "photo.stack.fill")
                            .font(.title2)
                            .foregroundStyle(.stsCyan)
                        
                        Text("UPI Screenshot(s)")
                            .font(.stsHeadline)
                            .foregroundStyle(.stsPrimary)
                        
                        Text("Single or History batch")
                            .font(.stsSmall)
                            .foregroundStyle(.stsSecondary)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 18)
                    .padding(.horizontal, 8)
                    .background(Color.stsElevated)
                    .clipShape(RoundedRectangle(cornerRadius: 14))
                    .overlay(
                        RoundedRectangle(cornerRadius: 14)
                            .stroke(Color.stsCyan.opacity(0.2), lineWidth: 1)
                    )
                }
            }
            
            // Privacy & On-device disclosure badge (SRS FR-DAT-04 / FR-QAD-04)
            HStack(alignment: .top, spacing: 10) {
                Image(systemName: "lock.shield.fill")
                    .foregroundStyle(.stsAccent)
                    .font(.subheadline)
                    .padding(.top, 2)
                
                VStack(alignment: .leading, spacing: 2) {
                    Text("100% On-Device Neural Vision OCR")
                        .font(.stsSmall)
                        .fontWeight(.semibold)
                        .foregroundStyle(.stsPrimary)
                    
                    Text("Your screenshots & receipts are processed locally on your iPhone and discarded immediately. No financial images are ever saved or uploaded.")
                        .font(.stsSmall)
                        .foregroundStyle(.stsSecondary)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
            .padding(12)
            .background(Color.stsAccent.opacity(0.08))
            .clipShape(RoundedRectangle(cornerRadius: 12))
            
            // Loading state while OCR runs
            if isScanning {
                VStack(spacing: 12) {
                    ProgressView()
                        .tint(.stsAccent)
                        .scaleEffect(1.2)
                    
                    Text(scanProgressText.isEmpty ? "Scanning image with Vision OCR..." : scanProgressText)
                        .font(.stsHeadline)
                        .foregroundStyle(.stsPrimary)
                    
                    Text("Extracting amounts, merchants, and dates...")
                        .font(.stsCaption)
                        .foregroundStyle(.stsSecondary)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 32)
                .cardStyle()
            }
            
            // Error message if any
            if let err = scanErrorMessage {
                HStack(spacing: 8) {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .foregroundStyle(.stsWarning)
                    Text(err)
                        .font(.stsCaption)
                        .foregroundStyle(.stsWarning)
                }
                .padding(12)
                .background(Color.stsWarning.opacity(0.12))
                .clipShape(RoundedRectangle(cornerRadius: 10))
            }
            
            // Extracted OCR candidates list
            if !ocrCandidates.isEmpty && !isScanning {
                VStack(alignment: .leading, spacing: 14) {
                    // Header summary
                    HStack {
                        VStack(alignment: .leading, spacing: 2) {
                            Text("Extracted Transactions")
                                .font(.stsHeadline)
                                .foregroundStyle(.stsPrimary)
                            
                            Text("\(selectedCandidatesCount) of \(ocrCandidates.count) selected • Total: \(selectedCandidatesTotalPaise.toRupees)")
                                .font(.stsCaption)
                                .foregroundStyle(.stsAccent)
                        }
                        
                        Spacer()
                        
                        Button(allSelected ? "Deselect All" : "Select All") {
                            withAnimation {
                                let newState = !allSelected
                                for i in ocrCandidates.indices {
                                    ocrCandidates[i].isSelected = newState
                                }
                            }
                        }
                        .font(.stsSmall)
                        .foregroundStyle(.stsSecondary)
                    }
                    
                    // List of Candidate Cards
                    ForEach($ocrCandidates) { $candidate in
                        candidateRowView(candidate: $candidate)
                    }
                    
                    // Batch Confirmation Button
                    confirmButton(
                        title: "Confirm & Log \(selectedCandidatesCount) Expense\(selectedCandidatesCount == 1 ? "" : "s") (\(selectedCandidatesTotalPaise.toRupees))",
                        isBusy: isSubmitting
                    ) {
                        await submitOCRCandidates()
                    }
                    .disabled(selectedCandidatesCount == 0 || isSubmitting)
                }
            }
        }
    }
    
    private func candidateRowView(candidate: Binding<ParsedExpenseCandidate>) -> some View {
        VStack(spacing: 10) {
            HStack(spacing: 12) {
                // Checkbox
                Button {
                    candidate.wrappedValue.isSelected.toggle()
                    Haptics.selection()
                } label: {
                    Image(systemName: candidate.wrappedValue.isSelected ? "checkmark.circle.fill" : "circle")
                        .font(.title3)
                        .foregroundStyle(candidate.wrappedValue.isSelected ? .stsAccent : .stsTertiary)
                }
                
                // Merchant / Payee
                VStack(alignment: .leading, spacing: 2) {
                    TextField("Merchant", text: candidate.merchant)
                        .font(.stsHeadline)
                        .foregroundStyle(.stsPrimary)
                    
                    HStack(spacing: 6) {
                        Text(candidate.wrappedValue.occurredOn)
                            .font(.stsSmall)
                            .foregroundStyle(.stsTertiary)
                        
                        Text("•")
                            .font(.stsSmall)
                            .foregroundStyle(.stsTertiary)
                        
                        Text(candidate.wrappedValue.source == "receipt_photo" ? "Receipt" : "UPI Screenshot")
                            .font(.stsSmall)
                            .foregroundStyle(.stsCyan)
                    }
                }
                
                Spacer()
                
                // Editable Rupee Amount
                HStack(spacing: 2) {
                    Text("₹")
                        .font(.stsHeadline)
                        .foregroundStyle(.stsAccent)
                    
                    let amountBinding = Binding<String>(
                        get: { String(candidate.wrappedValue.amountPaise / 100) },
                        set: { newStr in
                            if let val = Int(newStr) {
                                candidate.wrappedValue.amountPaise = val * 100
                            }
                        }
                    )
                    
                    TextField("0", text: amountBinding)
                        .font(.stsHeadline)
                        .foregroundStyle(.stsPrimary)
                        .keyboardType(.numberPad)
                        .multilineTextAlignment(.trailing)
                        .frame(width: 80)
                }
            }
            
            Divider()
                .background(Color.white.opacity(0.08))
            
            // Category selector for this candidate
            HStack {
                Text("Category:")
                    .font(.stsSmall)
                    .foregroundStyle(.stsSecondary)
                
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 6) {
                        ForEach(categories, id: \.self) { cat in
                            Button {
                                candidate.wrappedValue.category = cat
                                Haptics.selection()
                            } label: {
                                Text(cat.capitalized)
                                    .font(.system(size: 11))
                                    .foregroundStyle(candidate.wrappedValue.category == cat ? .white : .stsSecondary)
                                    .padding(.horizontal, 10)
                                    .padding(.vertical, 4)
                                    .background(candidate.wrappedValue.category == cat ? Color.stsAccent : Color.stsElevated)
                                    .clipShape(Capsule())
                            }
                        }
                    }
                }
            }
            
            // Type toggle: Expense vs Bill
            HStack(spacing: 8) {
                Text("Log as:")
                    .font(.stsSmall)
                    .foregroundStyle(.stsSecondary)
                
                Button {
                    candidate.wrappedValue.isBill = false
                    Haptics.selection()
                } label: {
                    HStack(spacing: 4) {
                        Image(systemName: "creditcard.fill")
                        Text("Expense")
                    }
                    .font(.system(size: 11, weight: .medium))
                    .foregroundStyle(!candidate.wrappedValue.isBill ? .white : .stsSecondary)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 4)
                    .background(!candidate.wrappedValue.isBill ? Color.stsAccent : Color.stsElevated)
                    .clipShape(Capsule())
                }
                
                Button {
                    candidate.wrappedValue.isBill = true
                    Haptics.selection()
                } label: {
                    HStack(spacing: 4) {
                        Image(systemName: "doc.text.fill")
                        Text("Bill / Commitment")
                    }
                    .font(.system(size: 11, weight: .medium))
                    .foregroundStyle(candidate.wrappedValue.isBill ? .white : .stsSecondary)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 4)
                    .background(candidate.wrappedValue.isBill ? Color.stsWarning : Color.stsElevated)
                    .clipShape(Capsule())
                }
                
                Spacer()
            }
        }
        .padding(14)
        .background(Color.stsCardBackground)
        .clipShape(RoundedRectangle(cornerRadius: 14))
        .overlay(
            RoundedRectangle(cornerRadius: 14)
                .stroke(candidate.wrappedValue.isSelected ? Color.stsAccent.opacity(0.3) : Color.clear, lineWidth: 1)
        )
    }
    
    // MARK: - 3. Manual Entry
    private var manualEntryView: some View {
        VStack(spacing: 16) {
            // Amount
            VStack(alignment: .leading, spacing: 8) {
                Text("Amount")
                    .font(.stsCaption)
                    .foregroundStyle(.stsSecondary)
                
                HStack {
                    Text("₹")
                        .font(.stsLargeTitle)
                        .foregroundStyle(.stsAccent)
                    
                    TextField("0", text: $manualAmount)
                        .font(.stsLargeTitle)
                        .foregroundStyle(.stsPrimary)
                        .keyboardType(.numberPad)
                }
                .padding(16)
                .background(Color.stsElevated)
                .clipShape(RoundedRectangle(cornerRadius: 12))
            }
            
            // Description
            VStack(alignment: .leading, spacing: 8) {
                Text("What was it for?")
                    .font(.stsCaption)
                    .foregroundStyle(.stsSecondary)
                
                TextField("Coffee, groceries, etc.", text: $manualDescription)
                    .font(.stsBody)
                    .foregroundStyle(.stsPrimary)
                    .padding(16)
                    .background(Color.stsElevated)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
            }
            
            // Category picker
            VStack(alignment: .leading, spacing: 8) {
                Text("Category")
                    .font(.stsCaption)
                    .foregroundStyle(.stsSecondary)
                
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 8) {
                        ForEach(categories, id: \.self) { cat in
                            categoryChip(cat)
                        }
                    }
                }
            }
            
            confirmButton(title: "Confirm Expense", isBusy: isSubmitting) {
                await submitManual()
            }
        }
    }
    
    // MARK: - Preview Card (Smart Entry)
    private func previewCard(_ preview: ExpensePreviewResponse) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Parsed Expense")
                    .font(.stsCaption)
                    .foregroundStyle(.stsSecondary)
                
                Spacer()
                
                HStack(spacing: 4) {
                    Circle()
                        .fill(preview.confidence > 0.7 ? Color.stsAccent : Color.stsWarning)
                        .frame(width: 6, height: 6)
                    
                    Text("\(Int(preview.confidence * 100))% sure")
                        .font(.stsSmall)
                        .foregroundStyle(preview.confidence > 0.7 ? .stsAccent : .stsWarning)
                }
            }
            
            HStack {
                Text(preview.candidateAmountPaise.toRupees)
                    .font(.stsLargeTitle)
                    .foregroundStyle(.stsPrimary)
                
                Spacer()
                
                if let desc = preview.candidateDescription {
                    Text(desc)
                        .font(.stsBody)
                        .foregroundStyle(.stsSecondary)
                }
            }
            
            if let category = preview.candidateCategory {
                HStack(spacing: 6) {
                    Image(systemName: categoryIcon(category))
                        .font(.system(size: 12, weight: .semibold))
                    Text(category.capitalized)
                        .font(.stsCaption)
                        .foregroundStyle(.stsAccent)
                }
                .padding(.horizontal, 10)
                .padding(.vertical, 6)
                .background(Color.stsAccent.opacity(0.12))
                .clipShape(Capsule())
            }
        }
        .cardStyle()
        .transition(.scale.combined(with: .opacity))
    }
    
    // MARK: - Common UI Components
    
    private func categoryChip(_ category: String) -> some View {
        Button {
            Haptics.selection()
            manualCategory = category
        } label: {
            Text(category.capitalized)
                .font(.stsCaption)
                .foregroundStyle(manualCategory == category ? .white : .stsSecondary)
                .padding(.horizontal, 14)
                .padding(.vertical, 8)
                .background(manualCategory == category ? Color.stsAccent : Color.stsElevated)
                .clipShape(Capsule())
        }
    }
    
    private func confirmButton(title: String, isBusy: Bool, action: @escaping () async -> Void) -> some View {
        Button {
            Haptics.impact(.medium)
            Task { await action() }
        } label: {
            HStack(spacing: 8) {
                if isBusy {
                    ProgressView()
                        .tint(.white)
                } else {
                    Image(systemName: "checkmark")
                    Text(title)
                }
            }
            .font(.stsHeadline)
            .foregroundStyle(.white)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
            .background(Color.stsAccent)
            .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
        }
        .disabled(isBusy)
    }
    
    private var successView: some View {
        VStack(spacing: 20) {
            Spacer(minLength: 40)
            
            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 64))
                .foregroundStyle(.stsAccent)
                .symbolEffect(.bounce, value: submitted)
            
            Text(loggedCount > 1 ? "\(loggedCount) Expenses Logged!" : "Expense Logged!")
                .font(.stsTitle)
                .foregroundStyle(.stsPrimary)
            
            Text("Your safe-to-spend has been recalculated.")
                .font(.stsBody)
                .foregroundStyle(.stsSecondary)
            
            Spacer(minLength: 40)
            
            Button {
                Task {
                    await appState.refreshToday()
                    dismiss()
                }
            } label: {
                Text("Done")
                    .font(.stsHeadline)
                    .foregroundStyle(.stsAccent)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                    .background(Color.stsAccent.opacity(0.12))
                    .clipShape(RoundedRectangle(cornerRadius: 14))
            }
        }
    }
    
    // MARK: - OCR Processing Logic
    
    private func processSingleBillImage(_ image: UIImage) async {
        isScanning = true
        scanErrorMessage = nil
        scanProgressText = "Analyzing receipt with Vision OCR..."
        
        let candidates = await OCRService.shared.parseImage(image, source: "receipt_photo")
        
        if candidates.isEmpty {
            scanErrorMessage = "Could not clearly detect an expense amount from the image. Please try another photo or use Smart/Manual mode."
        } else {
            withAnimation(.spring(response: 0.35)) {
                ocrCandidates = candidates
            }
            Haptics.notification(.success)
        }
        
        // Discard raw image from memory (Privacy requirement FR-DAT-04)
        capturedCameraImage = nil
        isScanning = false
    }
    
    private func processSelectedScreenshots(_ items: [PhotosPickerItem]) async {
        isScanning = true
        scanErrorMessage = nil
        scanProgressText = "Reading \(items.count) screenshot\(items.count > 1 ? "s" : "")..."
        
        var uiImages: [UIImage] = []
        for item in items {
            if let data = try? await item.loadTransferable(type: Data.self),
               let img = UIImage(data: data) {
                uiImages.append(img)
            }
        }
        
        guard !uiImages.isEmpty else {
            isScanning = false
            scanErrorMessage = "Failed to load selected photos. Please try again."
            return
        }
        
        scanProgressText = "Running Apple Vision OCR on \(uiImages.count) screenshot\(uiImages.count > 1 ? "s" : "")..."
        
        let candidates = await OCRService.shared.parseMultipleImages(uiImages)
        
        if candidates.isEmpty {
            scanErrorMessage = "No UPI payments or expenses found in the selected screenshot(s). Make sure amounts (₹) and merchant names are visible."
        } else {
            withAnimation(.spring(response: 0.35)) {
                ocrCandidates = candidates
            }
            Haptics.notification(.success)
        }
        
        // Reset picker selection & discard raw images from memory (FR-DAT-04)
        selectedPhotoItems = []
        isScanning = false
    }
    
    private func submitOCRCandidates() async {
        let selected = ocrCandidates.filter { $0.isSelected }
        guard !selected.isEmpty else { return }
        
        isSubmitting = true
        var successCount = 0
        
        for item in selected {
            do {
                if item.isBill {
                    _ = try await APIClient.shared.createBill(
                        BillCreateRequest(
                            name: item.merchant,
                            amountPaise: item.amountPaise,
                            dueDate: item.occurredOn,
                            cadence: "monthly"
                        )
                    )
                } else {
                    _ = try await APIClient.shared.createExpense(
                        ExpenseCreateRequest(
                            amountPaise: item.amountPaise,
                            occurredOn: item.occurredOn,
                            description: item.merchant,
                            merchant: item.merchant,
                            category: item.category,
                            source: item.source
                        ),
                        idempotencyKey: UUID().uuidString
                    )
                }
                successCount += 1
            } catch {
                print("Failed to save OCR entry: \(error)")
            }
        }
        
        if successCount > 0 {
            loggedCount = successCount
            Haptics.notification(.success)
            
            // Instantly refresh today's Safe to Spend budget & post notification across all tabs
            await appState.refreshToday()
            
            withAnimation(.spring(response: 0.4)) {
                submitted = true
            }
        } else {
            scanErrorMessage = "Could not save entries. Please check your network connection."
            Haptics.notification(.error)
        }
        
        isSubmitting = false
    }
    
    // MARK: - Smart & Manual Submissions
    
    private func debouncePreview(_ input: String) {
        debounceTask?.cancel()
        guard !input.isEmpty else {
            preview = nil
            return
        }
        
        debounceTask = Task {
            try? await Task.sleep(nanoseconds: 600_000_000)
            guard !Task.isCancelled else { return }
            
            isPreviewLoading = true
            do {
                let result = try await APIClient.shared.previewExpense(
                    ExpensePreviewRequest(rawInput: input)
                )
                withAnimation(.spring(response: 0.3)) {
                    preview = result
                }
            } catch {
                print("Preview error: \(error)")
            }
            isPreviewLoading = false
        }
    }
    
    private func submitFromPreview() async {
        guard let preview = preview else { return }
        isSubmitting = true
        
        do {
            _ = try await APIClient.shared.createExpense(
                ExpenseCreateRequest(
                    amountPaise: preview.candidateAmountPaise,
                    description: preview.candidateDescription,
                    category: preview.candidateCategory,
                    source: "smart_text"
                ),
                idempotencyKey: UUID().uuidString
            )
            
            loggedCount = 1
            Haptics.notification(.success)
            await appState.refreshToday()
            
            withAnimation(.spring(response: 0.4)) {
                submitted = true
            }
        } catch {
            Haptics.notification(.error)
        }
        
        isSubmitting = false
    }
    
    private func submitManual() async {
        guard let amount = Int(manualAmount), amount > 0 else { return }
        isSubmitting = true
        
        do {
            _ = try await APIClient.shared.createExpense(
                ExpenseCreateRequest(
                    amountPaise: amount * 100,
                    description: manualDescription.isEmpty ? nil : manualDescription,
                    category: manualCategory,
                    source: "manual"
                ),
                idempotencyKey: UUID().uuidString
            )
            
            loggedCount = 1
            Haptics.notification(.success)
            await appState.refreshToday()
            
            withAnimation(.spring(response: 0.4)) {
                submitted = true
            }
        } catch {
            Haptics.notification(.error)
        }
        
        isSubmitting = false
    }
    
    // MARK: - Computed Properties & Helpers
    
    private var selectedCandidatesCount: Int {
        ocrCandidates.filter { $0.isSelected }.count
    }
    
    private var selectedCandidatesTotalPaise: Int {
        ocrCandidates.filter { $0.isSelected }.reduce(0) { $0 + $1.amountPaise }
    }
    
    private var allSelected: Bool {
        !ocrCandidates.isEmpty && ocrCandidates.allSatisfy { $0.isSelected }
    }
    
    private func categoryIcon(_ category: String) -> String {
        switch category.lowercased() {
        case "food", "dining": return "fork.knife"
        case "transport": return "car.fill"
        case "shopping": return "bag.fill"
        case "entertainment": return "film.fill"
        case "health": return "cross.fill"
        case "utilities": return "bolt.fill"
        case "groceries": return "cart.fill"
        default: return "creditcard.fill"
        }
    }
}

#Preview {
    AddExpenseView()
}
