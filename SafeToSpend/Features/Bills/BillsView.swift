import SwiftUI

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
            .presentationDetents([.medium, .large])
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
            Text(bill.billIcon)
                .font(.title2)
                .frame(width: 44, height: 44)
                .background(Color.stsElevated)
                .clipShape(RoundedRectangle(cornerRadius: 12))
            
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
        .padding(12)
        .background(Color.stsCardBackground)
        .clipShape(RoundedRectangle(cornerRadius: 12))
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
        do {
            bills = try await APIClient.shared.listBills()
        } catch {
            print("Error loading bills: \(error)")
        }
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

// MARK: - Add Bill Sheet
struct AddBillView: View {
    @Environment(\.dismiss) var dismiss
    var onComplete: () -> Void
    
    @State private var name = ""
    @State private var amount = ""
    @State private var dueDate = Date()
    @State private var cadence = "monthly"
    @State private var isSubmitting = false
    
    private let cadences = ["one_time", "weekly", "monthly", "yearly"]
    
    var body: some View {
        NavigationStack {
            ZStack {
                Color.stsCardBackground.ignoresSafeArea()
                
                ScrollView(.vertical, showsIndicators: false) {
                    VStack(spacing: 16) {
                        // Name
                        VStack(alignment: .leading, spacing: 6) {
                            Text("Bill Name")
                                .font(.stsCaption)
                                .foregroundStyle(.stsSecondary)
                            
                            TextField("Rent, Netflix, etc.", text: $name)
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
                            .background(
                                LinearGradient(colors: [.stsAccent, .stsCyan], startPoint: .leading, endPoint: .trailing)
                            )
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                        }
                        .disabled(name.isEmpty || amount.isEmpty || isSubmitting)
                        .opacity(name.isEmpty || amount.isEmpty ? 0.6 : 1)
                        
                        Color.clear.frame(height: 20)
                    }
                    .padding(20)
                }
                .scrollBounceBehavior(.always, axes: .vertical)
                .scrollDismissesKeyboard(.interactively)
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
        }
    }
    
    private func submitBill() async {
        guard let amountInt = Int(amount) else { return }
        isSubmitting = true
        
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        
        do {
            _ = try await APIClient.shared.createBill(
                BillCreateRequest(
                    name: name,
                    amountPaise: amountInt * 100,
                    dueDate: formatter.string(from: dueDate),
                    cadence: cadence
                )
            )
            Haptics.notification(.success)
            onComplete()
            dismiss()
        } catch {
            Haptics.notification(.error)
        }
        
        isSubmitting = false
    }
}

#Preview {
    BillsView()
}
