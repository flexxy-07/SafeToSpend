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
            VStack(alignment: .leading, spacing: 2) {
                Text("Expenses")
                    .font(.zenHeading(28, weight: .bold))
                    .foregroundStyle(Color.zenInk)
                Text("Tracked outflow")
                    .font(.zenBody(12))
                    .foregroundStyle(Color.zenPlumGrey)
            }
            
            Spacer()
            
            HStack(spacing: 5) {
                Image(systemName: "list.bullet.rectangle.portrait.fill")
                    .font(.system(size: 11))
                Text("\(expenses.count) logged")
                    .font(.zenHeading(12, weight: .bold))
            }
            .foregroundStyle(Color.zenCrimson)
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
            .background(Color.white.opacity(0.85))
            .clipShape(Capsule())
            .overlay(
                Capsule().stroke(Color.zenCrimson.opacity(0.25), lineWidth: 1)
            )
            .shadow(color: Color.zenInk.opacity(0.04), radius: 4, y: 2)
        }
        .padding(.horizontal, 16)
        .padding(.top, 16)
    }
    
    // MARK: - Category Filter Bar (Horizontally scrollable with Themed Icons)
    private func categoryIcon(for category: String) -> String {
        switch category.lowercased() {
        case "all": return "sparkles"
        case "food", "dining": return "fork.knife"
        case "shopping": return "bag.fill"
        case "transport", "transportation": return "car.fill"
        case "bills": return "doc.text.fill"
        case "groceries": return "cart.fill"
        case "entertainment": return "play.tv.fill"
        case "health", "medical": return "heart.fill"
        case "utilities": return "bolt.fill"
        case "travel": return "airplane"
        case "subscription": return "arrow.triangle.2.circlepath"
        default: return "tag.fill"
        }
    }
    
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
                        HStack(spacing: 6) {
                            Image(systemName: categoryIcon(for: cat))
                                .font(.system(size: 11, weight: .bold))
                            Text(cat)
                                .font(.zenBody(12, weight: selectedCategory == cat ? .bold : .medium))
                        }
                        .foregroundStyle(selectedCategory == cat ? Color.white : Color.zenInk)
                        .padding(.horizontal, 14)
                        .padding(.vertical, 8)
                        .background(
                            selectedCategory == cat ?
                            LinearGradient(colors: [Color.zenCrimson, Color.zenCrimsonDark], startPoint: .topLeading, endPoint: .bottomTrailing) :
                            LinearGradient(colors: [Color.white.opacity(0.85), Color.white.opacity(0.70)], startPoint: .top, endPoint: .bottom)
                        )
                        .clipShape(Capsule())
                        .overlay(
                            Capsule()
                                .stroke(selectedCategory == cat ? Color.zenGold.opacity(0.4) : Color.zenPlumBorder, lineWidth: 1)
                        )
                        .shadow(color: selectedCategory == cat ? Color.zenCrimson.opacity(0.25) : Color.zenInk.opacity(0.04), radius: 4, y: 2)
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
                .font(.zenHeading(12, weight: .bold))
                .foregroundStyle(Color.zenPlumGrey)
            
            Spacer()
            
            Text(total.toRupees)
                .font(.zenNumber(12, weight: .bold))
                .foregroundStyle(Color.zenCrimson)
        }
        .padding(.vertical, 8)
        .padding(.horizontal, 4)
        .background(Color.white.opacity(0.92))
    }
    
    private func categoryColor(for category: String) -> Color {
        switch category.lowercased() {
        case "food", "dining": return .zenCrimson
        case "shopping": return .zenBlossomDeep
        case "transport", "transportation": return .zenSkyTop
        case "bills": return .zenGoldDeep
        case "groceries": return .zenJade
        case "entertainment": return .zenGold
        case "health", "medical": return .zenCrimson
        case "utilities": return .zenGoldDeep
        case "travel": return .zenSkyDeep
        case "subscription": return .zenPlumGrey
        default: return .zenInk
        }
    }
    
    private func expenseRow(_ expense: ExpenseResponse) -> some View {
        let catColor = categoryColor(for: expense.category)
        
        return HStack(spacing: 12) {
            // Category icon with themed zen badge
            Image(systemName: expense.categoryIcon)
                .font(.system(size: 16, weight: .semibold))
                .foregroundStyle(catColor)
                .frame(width: 42, height: 42)
                .background(catColor.opacity(0.12))
                .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                .overlay(
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .stroke(catColor.opacity(0.28), lineWidth: 1)
                )
            
            VStack(alignment: .leading, spacing: 3) {
                Text(expense.displayTitle)
                    .font(.zenHeading(15, weight: .semibold))
                    .foregroundStyle(expense.status == "voided" ? Color.zenPlumGrey.opacity(0.6) : Color.zenInk)
                    .strikethrough(expense.status == "voided")
                
                HStack(spacing: 6) {
                    Text(expense.category.capitalized)
                        .font(.zenBody(11, weight: .semibold))
                        .foregroundStyle(catColor)
                    
                    if let merchant = expense.merchant {
                        Text("• \(merchant)")
                            .font(.zenBody(11))
                            .foregroundStyle(Color.zenPlumGrey)
                    }
                }
            }
            
            Spacer()
            
            Text(expense.amountPaise.toRupees)
                .font(.zenNumber(16, weight: .bold))
                .foregroundStyle(expense.status == "voided" ? Color.zenPlumGrey.opacity(0.6) : Color.zenInk)
                .strikethrough(expense.status == "voided")
        }
        .padding(14)
        .background(Color.white.opacity(0.78))
        .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .stroke(LinearGradient.zenGlassBorderGradient, lineWidth: 1)
        )
        .shadow(color: Color.zenInk.opacity(0.04), radius: 6, y: 3)
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
                    .fill(Color.white.opacity(0.6))
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
                    .foregroundStyle(Color.zenPlumGrey.opacity(0.5))
                
                Text(selectedCategory == "All" ? "No expenses yet" : "No \(selectedCategory) expenses")
                    .font(.zenHeading(20, weight: .bold))
                    .foregroundStyle(Color.zenInk)
                
                Text(selectedCategory == "All" ? "Tap the + button to log your first expense" : "Expenses matching this category will show up here")
                    .font(.zenBody(13))
                    .foregroundStyle(Color.zenPlumGrey)
                    .multilineTextAlignment(.center)
                
                if selectedCategory != "All" {
                    Button("Show All Expenses") {
                        selectedCategory = "All"
                        groupExpenses()
                    }
                    .font(.zenBody(13, weight: .bold))
                    .foregroundStyle(Color.zenCrimson)
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
