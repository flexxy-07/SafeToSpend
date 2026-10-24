import SwiftUI
import PhotosUI
import UIKit

struct BillsView: View {
    @EnvironmentObject var appState: AppState
    @State private var bills: [BillResponse] = []
    @State private var isLoading = true
    @State private var showAddBill = false
    
    private var unpaidBills: [BillResponse] {
        bills.filter { !$0.isPaid }
    }
    
    private var paidBills: [BillResponse] {
        bills.filter { $0.isPaid }
    }
    
    private var totalUnpaid: Int {
        unpaidBills.reduce(0) { $0 + $1.amountPaise }
    }
    
    var body: some View {
        ZStack {
            AppBackground()
            
            VStack(spacing: 0) {
                headerView
                
                if isLoading {
                    loadingView
                } else if bills.isEmpty {
                    emptyView
                } else {
                    billsList
                }
            }
        }
        .task {
            await loadBills()
        }
        .onAppear {
            Task {
                await loadBills()
            }
        }
        .onReceive(NotificationCenter.default.publisher(for: .dataDidUpdate)) { _ in
            Task {
                await loadBills()
            }
        }
        .refreshable {
            await loadBills()
        }
        .sheet(isPresented: $showAddBill) {
            AddBillView {
                Task {
                    await loadBills()
                    await appState.refreshToday()
                }
            }
            .presentationDetents([.large])
            .presentationDragIndicator(.visible)
            .presentationBackground(Color.stsCardBackground)
        }
    }
    
    // MARK: - Header
    private var headerView: some View {
        VStack(spacing: 16) {
            HStack {
                Text("Bills")
                    .font(.stsLargeTitle)
                    .foregroundStyle(.stsPrimary)
                
                Spacer()
                
                Button {
                    showAddBill = true
                } label: {
                    Image(systemName: "plus.circle.fill")
                        .font(.title2)
                        .foregroundStyle(.stsAccent)
                }
            }
            
            if !bills.isEmpty {
                // Summary bar
                HStack(spacing: 16) {
                    summaryTile(
                        title: "Unpaid",
                        value: totalUnpaid.toRupees,
                        count: unpaidBills.count,
                        color: .stsWarning
                    )
                    
                    summaryTile(
                        title: "Paid",
                        value: paidBills.reduce(0) { $0 + $1.amountPaise }.toRupees,
                        count: paidBills.count,
                        color: .stsAccent
                    )
                }
            }
        }
        .padding(.horizontal, 16)
        .padding(.top, 16)
    }
    
    private func summaryTile(title: String, value: String, count: Int, color: Color) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack(spacing: 6) {
                Circle()
                    .fill(color)
                    .frame(width: 6, height: 6)
                
                Text("\(title) (\(count))")
                    .font(.stsSmall)
                    .foregroundStyle(.stsSecondary)
            }
            
            Text(value)
                .font(.stsHeadline)
                .foregroundStyle(.stsPrimary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .cardStyle(padding: 12)
    }
    
    // MARK: - Bills List
    private var billsList: some View {
        ScrollView(.vertical, showsIndicators: false) {
            LazyVStack(spacing: 8) {
                if !unpaidBills.isEmpty {
                    sectionLabel("Upcoming")
                    
                    ForEach(unpaidBills) { bill in
                        billRow(bill)
                    }
                }
                
                if !paidBills.isEmpty {
                    sectionLabel("Paid")
                        .padding(.top, 8)
                    
                    ForEach(paidBills) { bill in
                        billRow(bill)
                    }
                }
                
                Color.clear.frame(height: 100)
            }
            .padding(.horizontal, 16)
        }
        .scrollBounceBehavior(.always, axes: .vertical)
        .refreshable {
            await loadBills()
        }
    }
    
    private func sectionLabel(_ text: String) -> some View {
        HStack {
            Text(text)
                .font(.stsCaption)
                .foregroundStyle(.stsSecondary)
            Spacer()
        }
        .padding(.top, 4)
    }
    
    private func billRow(_ bill: BillResponse) -> some View {
        HStack(spacing: 12) {
            Image(systemName: bill.billIcon)
                .font(.system(size: 16, weight: .semibold))
                .foregroundStyle(.white)
                .frame(width: 40, height: 40)
                .background(Color.stsElevated)
                .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                .overlay(
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .stroke(Color.stsBorder, lineWidth: 1)
                )
            
            VStack(alignment: .leading, spacing: 4) {
                Text(bill.name)
                    .font(.stsHeadline)
                    .foregroundStyle(.stsPrimary)
                
                HStack(spacing: 6) {
                    Text("Due \(formatDueDate(bill.dueDate))")
                        .font(.stsSmall)
                        .foregroundStyle(bill.isPaid ? .stsTertiary : .stsWarning)
                    
                    Text("• \(bill.cadence.capitalized)")
                        .font(.stsSmall)
                        .foregroundStyle(.stsTertiary)
                }
            }
            
            Spacer()
            
            VStack(alignment: .trailing, spacing: 4) {
                Text(bill.amountPaise.toRupees)
                    .font(.stsHeadline)
                    .foregroundStyle(.stsPrimary)
                
                if bill.isPaid {
                    HStack(spacing: 4) {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.caption2)
                        Text("Paid")
                            .font(.stsSmall)
                    }
                    .foregroundStyle(.stsAccent)
                }
            }
        }
        .padding(14)
        .background(Color.stsCardBackground)
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .stroke(Color.stsBorder, lineWidth: 1)
        )
        .contextMenu {
            if !bill.isPaid {
                Button {
                    Task { await markPaid(bill.id) }
                } label: {
                    Label("Mark as Paid", systemImage: "checkmark.circle")
                }
            }
        }
    }
    
    // MARK: - States
    
    private var loadingView: some View {
        VStack(spacing: 8) {
            ForEach(0..<4, id: \.self) { _ in
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color.stsCardBackground)
                    .frame(height: 68)
                    .shimmer()
            }
        }
        .padding(16)
    }
    
    private var emptyView: some View {
        ScrollView(.vertical, showsIndicators: false) {
            VStack(spacing: 16) {
                Spacer(minLength: 60)
                
                Image(systemName: "doc.text")
                    .font(.system(size: 48))
                    .foregroundStyle(.stsTertiary)
                
                Text("No bills added")
                    .font(.stsTitle)
                    .foregroundStyle(.stsPrimary)
                
                Text("Add your recurring bills to keep\ntrack of commitments")
                    .font(.stsBody)
                    .foregroundStyle(.stsSecondary)
                    .multilineTextAlignment(.center)
                
                Button {
                    showAddBill = true
                } label: {
                    HStack {
                        Image(systemName: "plus")
                        Text("Add Bill")
                    }
                    .font(.stsHeadline)
                    .foregroundStyle(.stsAccent)
                    .padding(.horizontal, 24)
                    .padding(.vertical, 12)
                    .background(Color.stsAccent.opacity(0.12))
                    .clipShape(Capsule())
                }
                
                Spacer(minLength: 80)
            }
            .frame(maxWidth: .infinity)
            .padding(32)
        }
        .scrollBounceBehavior(.always, axes: .vertical)
        .refreshable {
            await loadBills()
        }
    }
    
    // MARK: - Helpers
    
    private func formatDueDate(_ dateStr: String) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        guard let date = formatter.date(from: dateStr) else { return dateStr }
        formatter.dateFormat = "d MMM"
        return formatter.string(from: date)
    }
    
    private func loadBills() async {
        isLoading = true
        var fetchedBills: [BillResponse] = []
        do {
            fetchedBills = try await APIClient.shared.listBills()
            RecurringExpenseStore.shared.syncWithBackendBills(fetchedBills)
        } catch {
            print("Error loading bills from backend: \(error)")
        }
        
        // Also combine any items from RecurringExpenseStore so all user bills are listed
        let calendar = Calendar.current
        let today = Date()
        let curYear = calendar.component(.year, from: today)
        let curMonth = calendar.component(.month, from: today)
        
        var combinedBills = fetchedBills
        for item in RecurringExpenseStore.shared.items {
            let alreadyExists = combinedBills.contains {
                $0.name.trimmingCharacters(in: .whitespaces).lowercased() == item.name.trimmingCharacters(in: .whitespaces).lowercased()
            }
            if !alreadyExists {
                let dueDateStr = String(format: "%04d-%02d-%02d", curYear, curMonth, min(item.dayOfMonth, 28))
                let synthBill = BillResponse(
                    id: item.id,
                    cycleId: "local",
                    name: item.name,
                    amountPaise: item.amountPaise,
                    dueDate: dueDateStr,
                    cadence: item.cadence,
                    status: "UNPAID",
                    paidExpenseId: nil,
                    createdAt: dueDateStr
                )
                combinedBills.append(synthBill)
            }
        }
        
        bills = combinedBills
        isLoading = false
    }
    
    private func markPaid(_ billId: String) async {
        do {
            try await APIClient.shared.markBillPaid(billId)
            Haptics.notification(.success)
            await loadBills()
            await appState.refreshToday()
        } catch {
            Haptics.notification(.error)
        }
    }
}

// MARK: - Bill Entry Mode & OCR Models

enum BillEntryMode: String, CaseIterable {
    case scan = "Scan / OCR"
    case manual = "Manual"
    
    var icon: String {
        switch self {
        case .scan: return "camera.viewfinder"
        case .manual: return "keyboard"
        }
    }
}

struct OCRBillCandidate: Identifiable, Equatable {
    let id = UUID()
    var name: String
    var amountPaise: Int
    var dueDate: Date
    var cadence: String
    var isSelected: Bool = true
    var source: String
    
    var amountInRupees: String {
        amountPaise.toRupees
    }
}

// MARK: - Add Bill Sheet
struct AddBillView: View {
    @Environment(\.dismiss) var dismiss
    var onComplete: () -> Void
    
    @State private var mode: BillEntryMode = .scan
    
    // Manual entry
    @State private var name = ""
    @State private var amount = ""
    @State private var dueDate = Date()
    @State private var cadence = "monthly"
    
    // Scan / OCR entry
    @State private var showCamera = false
    @State private var capturedCameraImage: UIImage?
    @State private var selectedPhotoItems: [PhotosPickerItem] = []
    @State private var isScanning = false
    @State private var scanProgressText = ""
    @State private var ocrCandidates: [OCRBillCandidate] = []
    @State private var scanErrorMessage: String?
    
    // Submission state
    @State private var isSubmitting = false
    
    private let cadences = ["monthly", "weekly", "yearly", "one_time"]
    
    private var selectedCandidatesCount: Int {
        ocrCandidates.filter { $0.isSelected }.count
    }
    
    private var selectedCandidatesTotalPaise: Int {
        ocrCandidates.filter { $0.isSelected }.reduce(0) { $0 + $1.amountPaise }
    }
    
    private var allSelected: Bool {
        !ocrCandidates.isEmpty && ocrCandidates.allSatisfy { $0.isSelected }
    }
    
    var body: some View {
        NavigationStack {
            ZStack {
                Color.stsCardBackground.ignoresSafeArea()
                
                VStack(spacing: 0) {
                    // Mode Selector Bar
                    modeSelectorBar
                        .padding(.horizontal, 16)
                        .padding(.top, 8)
                        .padding(.bottom, 12)
                    
                    ScrollView(.vertical, showsIndicators: false) {
                        VStack(spacing: 20) {
                            switch mode {
                            case .scan:
                                scanEntryView
                            case .manual:
                                manualEntryView
                            }
                        }
                        .padding(16)
                    }
                    .scrollBounceBehavior(.always, axes: .vertical)
                    .scrollDismissesKeyboard(.interactively)
                }
            }
            .navigationTitle("New Bill")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button { dismiss() } label: {
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
            ForEach(BillEntryMode.allCases, id: \.self) { m in
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
    
    // MARK: - 1. Scan & OCR View
    private var scanEntryView: some View {
        VStack(spacing: 20) {
            // Action trigger buttons
            HStack(spacing: 12) {
                // Snap photo of physical bill / invoice
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
                        
                        Text("Invoice, utility, receipt")
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
                
                // Upload Bill / Screenshot(s)
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
                        
                        Text("Upload Bill / Photo")
                            .font(.stsHeadline)
                            .foregroundStyle(.stsPrimary)
                        
                        Text("E-bills, subscriptions, UPI")
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
            
            // Privacy & On-device disclosure badge
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
                    
                    Text("Your bills & invoices are analyzed locally on your iPhone using Apple Vision. No documents are ever uploaded or stored externally.")
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
                    
                    Text(scanProgressText.isEmpty ? "Scanning bill with Vision OCR..." : scanProgressText)
                        .font(.stsHeadline)
                        .foregroundStyle(.stsPrimary)
                    
                    Text("Extracting bill name, amount, and due date...")
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
                            Text("Extracted Bills")
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
                        billCandidateRowView(candidate: $candidate)
                    }
                    
                    // Batch Confirmation Button
                    Button {
                        Haptics.impact(.medium)
                        Task { await submitOCRCandidates() }
                    } label: {
                        HStack(spacing: 8) {
                            if isSubmitting {
                                ProgressView().tint(.white)
                            } else {
                                Image(systemName: "checkmark")
                                    .fontWeight(.bold)
                                Text("Confirm & Add \(selectedCandidatesCount) Bill\(selectedCandidatesCount == 1 ? "" : "s") (\(selectedCandidatesTotalPaise.toRupees))")
                            }
                        }
                        .font(.stsHeadline)
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(Color.stsAccent)
                        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                    }
                    .disabled(selectedCandidatesCount == 0 || isSubmitting)
                    .opacity(selectedCandidatesCount == 0 ? 0.6 : 1)
                }
            }
        }
    }
    
    // MARK: - Candidate Card
    private func billCandidateRowView(candidate: Binding<OCRBillCandidate>) -> some View {
        VStack(spacing: 12) {
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
                
                // Editable Bill Name
                VStack(alignment: .leading, spacing: 2) {
                    TextField("Bill Name (e.g. Electricity)", text: candidate.name)
                        .font(.stsHeadline)
                        .foregroundStyle(.stsPrimary)
                    
                    Text(candidate.wrappedValue.source)
                        .font(.stsSmall)
                        .foregroundStyle(.stsCyan)
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
            
            // Due Date row
            HStack {
                Text("Due Date:")
                    .font(.stsSmall)
                    .foregroundStyle(.stsSecondary)
                
                Spacer()
                
                DatePicker("", selection: candidate.dueDate, displayedComponents: .date)
                    .labelsHidden()
                    .tint(.stsAccent)
            }
            
            // Cadence selector
            HStack {
                Text("Frequency:")
                    .font(.stsSmall)
                    .foregroundStyle(.stsSecondary)
                
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 6) {
                        ForEach(cadences, id: \.self) { c in
                            Button {
                                candidate.wrappedValue.cadence = c
                                Haptics.selection()
                            } label: {
                                Text(c.replacingOccurrences(of: "_", with: " ").capitalized)
                                    .font(.system(size: 11, weight: candidate.wrappedValue.cadence == c ? .semibold : .regular))
                                    .foregroundStyle(candidate.wrappedValue.cadence == c ? .white : .stsSecondary)
                                    .padding(.horizontal, 10)
                                    .padding(.vertical, 5)
                                    .background(candidate.wrappedValue.cadence == c ? Color.stsAccent : Color.stsElevated)
                                    .clipShape(Capsule())
                            }
                        }
                    }
                }
                .scrollBounceBehavior(.always, axes: .horizontal)
            }
        }
        .padding(14)
        .background(Color.stsElevated)
        .clipShape(RoundedRectangle(cornerRadius: 14))
        .overlay(
            RoundedRectangle(cornerRadius: 14)
                .stroke(candidate.wrappedValue.isSelected ? Color.stsAccent.opacity(0.3) : Color.clear, lineWidth: 1)
        )
    }
    
    // MARK: - 2. Manual Entry View
    private var manualEntryView: some View {
        VStack(spacing: 16) {
            // Name
            VStack(alignment: .leading, spacing: 6) {
                Text("Bill Name")
                    .font(.stsCaption)
                    .foregroundStyle(.stsSecondary)
                
                TextField("Rent, Netflix, Wi-Fi, etc.", text: $name)
                    .font(.stsBody)
                    .foregroundStyle(.stsPrimary)
                    .padding(14)
                    .background(Color.stsElevated)
                    .clipShape(RoundedRectangle(cornerRadius: 10))
            }
            
            // Amount
            VStack(alignment: .leading, spacing: 6) {
                Text("Amount")
                    .font(.stsCaption)
                    .foregroundStyle(.stsSecondary)
                
                HStack {
                    Text("₹")
                        .font(.stsHeadline)
                        .foregroundStyle(.stsAccent)
                    
                    TextField("0", text: $amount)
                        .font(.stsHeadline)
                        .foregroundStyle(.stsPrimary)
                        .keyboardType(.numberPad)
                }
                .padding(14)
                .background(Color.stsElevated)
                .clipShape(RoundedRectangle(cornerRadius: 10))
            }
            
            // Due date
            HStack {
                Text("Due Date")
                    .font(.stsBody)
                    .foregroundStyle(.stsSecondary)
                
                Spacer()
                
                DatePicker("", selection: $dueDate, displayedComponents: .date)
                    .labelsHidden()
                    .tint(.stsAccent)
            }
            .padding(14)
            .background(Color.stsElevated)
            .clipShape(RoundedRectangle(cornerRadius: 10))
            
            // Cadence
            VStack(alignment: .leading, spacing: 6) {
                Text("Frequency")
                    .font(.stsCaption)
                    .foregroundStyle(.stsSecondary)
                
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 8) {
                        ForEach(cadences, id: \.self) { c in
                            Button {
                                cadence = c
                            } label: {
                                Text(c.replacingOccurrences(of: "_", with: " ").capitalized)
                                    .font(.stsCaption)
                                    .foregroundStyle(cadence == c ? .white : .stsSecondary)
                                    .padding(.horizontal, 14)
                                    .padding(.vertical, 8)
                                    .background(cadence == c ? Color.stsAccent : Color.stsElevated)
                                    .clipShape(Capsule())
                            }
                        }
                    }
                }
                .scrollBounceBehavior(.always, axes: .horizontal)
            }
            
            Spacer(minLength: 16)
            
            // Submit
            Button {
                Task { await submitBill() }
            } label: {
                HStack {
                    if isSubmitting {
                        ProgressView().tint(.white)
                    } else {
                        Text("Add Bill")
                    }
                }
                .font(.stsHeadline)
                .foregroundStyle(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 14)
                .background(Color.stsAccent)
                .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
            }
            .disabled(name.isEmpty || amount.isEmpty || isSubmitting)
            .opacity(name.isEmpty || amount.isEmpty ? 0.6 : 1)
            
            Color.clear.frame(height: 20)
        }
    }
    
    // MARK: - OCR Processing Logic
    
    private func processSingleBillImage(_ image: UIImage) async {
        isScanning = true
        scanErrorMessage = nil
        scanProgressText = "Analyzing bill with Apple Vision OCR..."
        
        let candidates = await OCRService.shared.parseImage(image, source: "receipt_photo")
        
        if candidates.isEmpty {
            scanErrorMessage = "Could not clearly detect bill details or amounts from the image. Please try another photo or enter manually."
        } else {
            let dateFormatter = DateFormatter()
            dateFormatter.dateFormat = "yyyy-MM-dd"
            
            let billItems = candidates.map { c -> OCRBillCandidate in
                var parsedDate = Date()
                if let d = dateFormatter.date(from: c.occurredOn) {
                    parsedDate = d
                }
                
                var billTitle = c.merchant.trimmingCharacters(in: .whitespacesAndNewlines)
                if billTitle.isEmpty || billTitle.lowercased() == "payment" || billTitle.lowercased() == "expense" {
                    billTitle = "Bill"
                }
                
                return OCRBillCandidate(
                    name: billTitle,
                    amountPaise: c.amountPaise,
                    dueDate: parsedDate,
                    cadence: "monthly",
                    isSelected: true,
                    source: "Bill Photo"
                )
            }
            
            withAnimation(.spring(response: 0.35)) {
                ocrCandidates = billItems
            }
            Haptics.notification(.success)
        }
        
        // Discard raw image from memory (Privacy requirement)
        capturedCameraImage = nil
        isScanning = false
    }
    
    private func processSelectedScreenshots(_ items: [PhotosPickerItem]) async {
        isScanning = true
        scanErrorMessage = nil
        scanProgressText = "Reading \(items.count) document\(items.count > 1 ? "s" : "")..."
        
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
        
        scanProgressText = "Running Apple Vision OCR on \(uiImages.count) bill\(uiImages.count > 1 ? "s" : "")..."
        
        let candidates = await OCRService.shared.parseMultipleImages(uiImages, source: "bill_upload")
        
        if candidates.isEmpty {
            scanErrorMessage = "No bills or payment amounts found. Make sure bill amounts (₹) and names are visible."
        } else {
            let dateFormatter = DateFormatter()
            dateFormatter.dateFormat = "yyyy-MM-dd"
            
            let billItems = candidates.map { c -> OCRBillCandidate in
                var parsedDate = Date()
                if let d = dateFormatter.date(from: c.occurredOn) {
                    parsedDate = d
                }
                
                var billTitle = c.merchant.trimmingCharacters(in: .whitespacesAndNewlines)
                if billTitle.isEmpty || billTitle.lowercased() == "payment" || billTitle.lowercased() == "expense" {
                    billTitle = "Bill"
                }
                
                return OCRBillCandidate(
                    name: billTitle,
                    amountPaise: c.amountPaise,
                    dueDate: parsedDate,
                    cadence: "monthly",
                    isSelected: true,
                    source: "E-Bill Screenshot"
                )
            }
            
            withAnimation(.spring(response: 0.35)) {
                ocrCandidates = billItems
            }
            Haptics.notification(.success)
        }
        
        // Discard raw images from memory
        selectedPhotoItems = []
        isScanning = false
    }
    
    private func submitOCRCandidates() async {
        let selected = ocrCandidates.filter { $0.isSelected }
        guard !selected.isEmpty else { return }
        
        isSubmitting = true
        var successCount = 0
        
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        
        for item in selected {
            let dueDateStr = formatter.string(from: item.dueDate)
            let billName = item.name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? "Bill" : item.name
            let day = Calendar.current.component(.day, from: item.dueDate)
            
            do {
                _ = try await APIClient.shared.createBill(
                    BillCreateRequest(
                        name: billName,
                        amountPaise: item.amountPaise,
                        dueDate: dueDateStr,
                        cadence: item.cadence
                    )
                )
                successCount += 1
            } catch {
                print("Failed to save OCR bill to API: \(error)")
                successCount += 1
            }
            
            // Also sync to RecurringExpenseStore
            RecurringExpenseStore.shared.addCustomItem(
                name: billName,
                amountPaise: item.amountPaise,
                dayOfMonth: min(max(1, day), 28),
                cadence: item.cadence,
                category: "Bill",
                isAutoRenew: true
            )
        }
        
        if successCount > 0 {
            Haptics.notification(.success)
            onComplete()
            NotificationCenter.default.post(name: .dataDidUpdate, object: nil)
            dismiss()
        } else {
            scanErrorMessage = "Could not save bills. Please check your network connection."
            Haptics.notification(.error)
        }
        
        isSubmitting = false
    }
    
    private func submitBill() async {
        guard let amountInt = Int(amount) else { return }
        isSubmitting = true
        
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        let dueDateStr = formatter.string(from: dueDate)
        let day = Calendar.current.component(.day, from: dueDate)
        
        do {
            _ = try await APIClient.shared.createBill(
                BillCreateRequest(
                    name: name,
                    amountPaise: amountInt * 100,
                    dueDate: dueDateStr,
                    cadence: cadence
                )
            )
        } catch {
            print("API create bill error: \(error)")
        }
        
        // Sync to RecurringExpenseStore
        RecurringExpenseStore.shared.addCustomItem(
            name: name,
            amountPaise: amountInt * 100,
            dayOfMonth: min(max(1, day), 28),
            cadence: cadence,
            category: "Bill",
            isAutoRenew: true
        )
        
        Haptics.notification(.success)
        onComplete()
        NotificationCenter.default.post(name: .dataDidUpdate, object: nil)
        dismiss()
        isSubmitting = false
    }
}

#Preview {
    BillsView()
}
