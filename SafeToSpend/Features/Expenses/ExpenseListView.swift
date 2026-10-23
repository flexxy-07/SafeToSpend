import SwiftUI

struct ExpenseListView: View {
    @EnvironmentObject var appState: AppState
    @State private var expenses: [ExpenseResponse] = []
    @State private var isLoading = true
    @State private var groupedExpenses: [(String, [ExpenseResponse])] = []
    @State private var selectedCategory: String = "All"
    
    private let categories = [
        "All", "Food", "Shopping", "Transport", "Bills", "Groceries",
        "Entertainment", "Health", "Utilities", "Travel", "Subscription", "General"
    ]
    
    private var filteredExpenses: [ExpenseResponse] {
        if selectedCategory == "All" {
            return expenses
        }
        return expenses.filter { $0.category.localizedCaseInsensitiveContains(selectedCategory) }
    }
    
    var body: some View {
        ZStack {
            AppBackground()
            
            VStack(spacing: 0) {
                // Header
                headerView
                
                // Horizontally scrollable category filter bar
                categoryFilterBar
                
                if isLoading {
                    loadingList
                } else if filteredExpenses.isEmpty {
                    emptyScrollView
                } else {
                    expensesList
                }
            }
        }
        .task {
            await loadExpenses()
        }
        .onAppear {
            Task {
                await loadExpenses()
            }
        }
        .onReceive(NotificationCenter.default.publisher(for: .dataDidUpdate)) { _ in
            Task {
                await loadExpenses()
            }
        }
        .refreshable {
            await loadExpenses()
        }
    }
    
    // MARK: - Header
    private var headerView: some View {
        HStack {
            Text("Expenses")
                .font(.stsLargeTitle)
                .foregroundStyle(.stsPrimary)
            
            Spacer()
            
            Text("\(expenses.count) total")
                .font(.stsCaption)
                .foregroundStyle(.stsSecondary)
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(Color.stsCardBackground)
                .clipShape(Capsule())
        }
        .padding(.horizontal, 16)
        .padding(.top, 16)
    }
    
    // MARK: - Category Filter Bar (Horizontally scrollable)
    private var categoryFilterBar: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                ForEach(categories, id: \.self) { cat in
                    Button {
                        Haptics.selection()
                        withAnimation(.easeInOut(duration: 0.2)) {
                            selectedCategory = cat
                            groupExpenses()
                        }
                    } label: {
                        Text(cat)
                            .font(.stsSmall)
                            .foregroundStyle(selectedCategory == cat ? .white : .stsSecondary)
                            .padding(.horizontal, 14)
                            .padding(.vertical, 7)
                            .background(selectedCategory == cat ? Color.stsAccent : Color.stsCardBackground)
                            .clipShape(Capsule())
                    }
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 10)
        }
        .scrollBounceBehavior(.always, axes: .horizontal)
    }
    
    // MARK: - Expenses List (Vertically scrollable)
    private var expensesList: some View {
        ScrollView(.vertical, showsIndicators: true) {
            LazyVStack(spacing: 8, pinnedViews: [.sectionHeaders]) {
                ForEach(groupedExpenses, id: \.0) { date, dayExpenses in
                    Section {
                        ForEach(dayExpenses) { expense in
                            expenseRow(expense)
                        }
                    } header: {
                        sectionHeader(date, total: dayExpenses.reduce(0) { $0 + $1.amountPaise })
                    }
                }
                
                Color.clear.frame(height: 100)
            }
            .padding(.horizontal, 16)
        }
        .scrollBounceBehavior(.always, axes: .vertical)
        .refreshable {
            await loadExpenses()
        }
    }
    
    private func sectionHeader(_ date: String, total: Int) -> some View {
        HStack {
            Text(formatDateHeader(date))
                .font(.stsCaption)
                .foregroundStyle(.stsSecondary)
            
            Spacer()
            
            Text(total.toRupees)
                .font(.stsCaption)
                .foregroundStyle(.stsWarning)
        }
        .padding(.vertical, 8)
        .padding(.horizontal, 4)
        .background(Color.stsBackground.opacity(0.95))
    }
    
    private func expenseRow(_ expense: ExpenseResponse) -> some View {
        HStack(spacing: 12) {
            // Category icon
            Text(expense.categoryIcon)
                .font(.title2)
                .frame(width: 44, height: 44)
                .background(Color.stsElevated)
                .clipShape(RoundedRectangle(cornerRadius: 12))
            
            VStack(alignment: .leading, spacing: 4) {
                Text(expense.displayTitle)
                    .font(.stsHeadline)
                    .foregroundStyle(expense.status == "voided" ? .stsTertiary : .stsPrimary)
                    .strikethrough(expense.status == "voided")
                
                HStack(spacing: 6) {
                    Text(expense.category.capitalized)
                        .font(.stsSmall)
                        .foregroundStyle(.stsAccent)
                    
                    if let merchant = expense.merchant {
                        Text("• \(merchant)")
                            .font(.stsSmall)
                            .foregroundStyle(.stsTertiary)
                    }
                }
            }
            
            Spacer()
            
            Text(expense.amountPaise.toRupees)
                .font(.stsHeadline)
                .foregroundStyle(expense.status == "voided" ? .stsTertiary : .stsPrimary)
                .strikethrough(expense.status == "voided")
        }
        .padding(12)
        .background(Color.stsCardBackground)
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .contextMenu {
            if expense.status != "voided" {
                Button(role: .destructive) {
                    Task { await voidExpense(expense.id) }
                } label: {
                    Label("Void Expense", systemImage: "trash")
                }
            }
        }
    }
    
    // MARK: - States
    
    private var loadingList: some View {
        VStack(spacing: 8) {
            ForEach(0..<5, id: \.self) { _ in
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color.stsCardBackground)
                    .frame(height: 68)
                    .shimmer()
            }
        }
        .padding(16)
    }
    
    // MARK: - Scrollable Empty View with Pull-To-Refresh
    private var emptyScrollView: some View {
        ScrollView(.vertical, showsIndicators: false) {
            VStack(spacing: 16) {
                Spacer(minLength: 60)
                
                Image(systemName: selectedCategory == "All" ? "tray" : "line.3.horizontal.decrease.circle")
                    .font(.system(size: 48))
                    .foregroundStyle(.stsTertiary)
                
                Text(selectedCategory == "All" ? "No expenses yet" : "No \(selectedCategory) expenses")
                    .font(.stsTitle)
                    .foregroundStyle(.stsPrimary)
                
                Text(selectedCategory == "All" ? "Tap the + button to log your first expense" : "Expenses matching this category will show up here")
                    .font(.stsBody)
                    .foregroundStyle(.stsSecondary)
                    .multilineTextAlignment(.center)
                
                if selectedCategory != "All" {
                    Button("Show All Expenses") {
                        selectedCategory = "All"
                        groupExpenses()
                    }
                    .font(.stsCaption)
                    .foregroundStyle(.stsAccent)
                    .padding(.top, 4)
                }
                
                Spacer(minLength: 80)
            }
            .frame(maxWidth: .infinity)
            .padding(32)
        }
        .scrollBounceBehavior(.always, axes: .vertical)
        .refreshable {
            await loadExpenses()
        }
    }
    
    // MARK: - Helpers
    
    private func formatDateHeader(_ dateStr: String) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        guard let date = formatter.date(from: dateStr) else { return dateStr }
        
        if Calendar.current.isDateInToday(date) { return "Today" }
        if Calendar.current.isDateInYesterday(date) { return "Yesterday" }
        
        formatter.dateFormat = "EEEE, d MMM"
        return formatter.string(from: date)
    }
    
    private func loadExpenses() async {
        isLoading = true
        do {
            expenses = try await APIClient.shared.listExpenses()
            groupExpenses()
        } catch {
            print("Error loading expenses: \(error)")
        }
        isLoading = false
    }
    
    private func groupExpenses() {
        let grouped = Dictionary(grouping: filteredExpenses) { $0.occurredOn }
        groupedExpenses = grouped.sorted { $0.key > $1.key }
    }
    
    private func voidExpense(_ id: String) async {
        do {
            try await APIClient.shared.voidExpense(id)
            Haptics.notification(.success)
            await loadExpenses()
            await appState.refreshToday()
        } catch {
            Haptics.notification(.error)
        }
    }
}

#Preview {
    ExpenseListView()
}
