import SwiftUI

struct DashboardView: View {
    @EnvironmentObject var appState: AppState
    @State private var todayData: TodayResponse?
    @State private var insights: InsightsResponse?
    @State private var allExpenses: [ExpenseResponse] = []
    @State private var isLoading = true
    @State private var showInsightsSheet = false
    @State private var showAddExpenseSheet = false
    @State private var isBreakdownExpanded = true
    @State private var animateAmount = false
    @State private var showSettings = false
    
    var body: some View {
        ZStack {
            AppBackground()
            
            ScrollView(.vertical, showsIndicators: false) {
                VStack(spacing: 20) {
                    headerBar
                    heroCard
                    cycleProgressCard
                    breakdownCard
                    RecurringExpenseCalendarCard()
                    quickInsightsCard
                    
                    // Bottom padding for tab bar
                    Color.clear.frame(height: 80)
                }
                .padding(.horizontal, 16)
            }
            .scrollBounceBehavior(.always, axes: .vertical)
            .refreshable {
                await loadData()
            }
        }
        .task {
            await loadData()
        }
        .onAppear {
            Task {
                await loadData()
            }
        }
        .onReceive(NotificationCenter.default.publisher(for: .dataDidUpdate)) { _ in
            Task {
                await loadData()
            }
        }
        .onChange(of: appState.todayData) { _, fresh in
            if let fresh = fresh {
                withAnimation(.spring(response: 0.4)) {
                    self.todayData = fresh
                }
            }
        }
        .sheet(isPresented: $showSettings) {
            SettingsView()
                .presentationDetents([.large])
                .presentationDragIndicator(.visible)
                .presentationBackground(Color.stsCardBackground)
        }
        .sheet(isPresented: $showInsightsSheet) {
            if let insights = insights {
                InsightsDetailSheet(insights: insights)
                    .presentationDetents([.medium, .large])
                    .presentationDragIndicator(.visible)
                    .presentationBackground(Color.stsCardBackground)
            }
        }
        .sheet(isPresented: $showAddExpenseSheet, onDismiss: {
            Task {
                await loadData()
            }
        }) {
            AddExpenseView()
                .environmentObject(appState)
                .presentationDetents([.large, .medium])
                .presentationDragIndicator(.visible)
                .presentationBackground(Color.stsCardBackground)
        }
    }
    
    // MARK: - Header
    private var headerBar: some View {
        HStack(spacing: 12) {
            Image("AppLogo")
                .resizable()
                .scaledToFit()
                .frame(width: 32, height: 32)
                .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
                .overlay(
                    RoundedRectangle(cornerRadius: 8, style: .continuous)
                        .stroke(Color.stsBorder, lineWidth: 1)
                )
            
            Text(currentDateString)
                .font(.stsHeadline)
                .foregroundStyle(.stsPrimary)
            
            Spacer()
            
            Button {
                showSettings = true
            } label: {
                Image(systemName: "gearshape.fill")
                    .font(.title3)
                    .foregroundStyle(.stsSecondary)
                    .frame(width: 40, height: 40)
                    .background(Color.stsCardBackground)
                    .clipShape(Circle())
                    .overlay(
                        Circle()
                            .stroke(Color.stsBorder, lineWidth: 1)
                    )
            }
        }
        .padding(.top, 8)
    }
    
    // MARK: - Computed Properties for Today's Expenses
    private var todayDateString: String {
        let f = DateFormatter()
        f.dateFormat = "yyyy-MM-dd"
        return f.string(from: Date())
    }
    
    private var todayExpenses: [ExpenseResponse] {
        let today = todayDateString
        return allExpenses.filter { $0.occurredOn == today && $0.status != "VOIDED" }
    }
    
    private var todaySpentPaise: Int {
        todayExpenses.reduce(0) { $0 + $1.amountPaise }
    }
    
    // MARK: - Hero STS Card
    private var heroCard: some View {
        VStack(spacing: 16) {
            // Header: Safe to Spend
            HStack {
                Text("Safe to Spend")
                    .font(.stsCaption)
                    .foregroundStyle(.stsSecondary)
                
                Spacer()
            }
            
            if isLoading {
                loadingPlaceholder
            } else if let data = todayData {
                // Main hero amount
                VStack(spacing: 4) {
                    Text(data.stsPaise.toRupees)
                        .font(.stsHeroAmount)
                        .foregroundStyle(.stsPrimary)
                        .contentTransition(.numericText())
                        .scaleEffect(animateAmount ? 1.0 : 0.8)
                        .opacity(animateAmount ? 1.0 : 0)
                    
                    Text("safe allowance for today")
                        .font(.stsSmall)
                        .foregroundStyle(.stsTertiary)
                }
                
                // Horizontal 3-metric summary
                HStack(spacing: 24) {
                    VStack(spacing: 4) {
                        Text("per day")
                            .font(.stsSmall)
                            .foregroundStyle(.stsTertiary)
                        
                        Text(perDay(data))
                            .font(.stsHeadline)
                            .foregroundStyle(.stsAccent)
                    }
                    
                    divider
                    
                    VStack(spacing: 4) {
                        Text("days left")
                            .font(.stsSmall)
                            .foregroundStyle(.stsTertiary)
                        
                        Text("\(data.daysRemaining)")
                            .font(.stsHeadline)
                            .foregroundStyle(.stsPrimary)
                    }
                    
                    divider
                    
                    VStack(spacing: 4) {
                        Text("pool")
                            .font(.stsSmall)
                            .foregroundStyle(.stsTertiary)
                        
                        Text(data.poolPaise.toRupees)
                            .font(.stsHeadline)
                            .foregroundStyle(.stsPrimary)
                    }
                }
            } else {
                noDataView
            }
        }
        .padding(20)
        .background(Color.stsCardBackground)
        .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .stroke(Color.stsBorder, lineWidth: 1)
        )
        .shadow(color: Color.black.opacity(0.25), radius: 12, y: 4)
    }
    
    // MARK: - Cycle Progress
    private var cycleProgressCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Cycle Progress")
                .font(.stsCaption)
                .foregroundStyle(.stsSecondary)
            
            if let data = todayData {
                // Progress bar
                GeometryReader { geo in
                    ZStack(alignment: .leading) {
                        Capsule()
                            .fill(Color.stsElevated)
                            .frame(height: 8)
                        
                        Capsule()
                            .fill(Color.stsAccent)
                            .frame(width: geo.size.width * cycleProgress(data), height: 8)
                            .animation(.spring(response: 0.8), value: todayData)
                    }
                }
                .frame(height: 8)
                
                HStack {
                    Text("\(Int(cycleProgress(data) * 100))% through cycle")
                        .font(.stsSmall)
                        .foregroundStyle(.stsSecondary)
                    
                    Spacer()
                    
                    Text("\(data.daysRemaining) days remaining")
                        .font(.stsSmall)
                        .foregroundStyle(.stsAccent)
                }
            }
        }
        .cardStyle()
    }
    
    // MARK: - Financial Breakdown
    private var breakdownCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Monthly Outlook")
                .font(.stsHeadline)
                .foregroundStyle(.stsPrimary)
            
            if let data = todayData {
                if isBreakdownExpanded {
                    breakdownRow("Available Balance", value: data.availableBalancePaise, color: .stsPrimary)
                    breakdownRow("Unpaid Bills", value: -data.unpaidCommitmentsPaise, color: .stsWarning)
                    breakdownRow("Safety Buffer", value: -data.safetyBufferPaise, color: .stsTertiary)
                    breakdownRow("Savings Reserve", value: -data.remainingSavingsReservePaise, color: .stsCyan)
                    
                    Divider()
                        .background(Color.stsBorder)
                }
                
                breakdownRow("Spendable Pool", value: data.poolPaise, color: .stsAccent, bold: true)
                
                if data.shortfallPaise > 0 {
                    HStack(spacing: 8) {
                        Image(systemName: "exclamationmark.triangle.fill")
                            .foregroundStyle(.stsDanger)
                        
                        Text("Shortfall: \(data.shortfallPaise.toRupees)")
                            .font(.stsCaption)
                            .foregroundStyle(.stsDanger)
                    }
                    .padding(8)
                    .background(Color.stsDanger.opacity(0.1))
                    .clipShape(RoundedRectangle(cornerRadius: 8))
                }
            }
        }
        .cardStyle()
        .contentShape(Rectangle())
        .onTapGesture(count: 2) {
            withAnimation(.spring(response: 0.42, dampingFraction: 0.78)) {
                isBreakdownExpanded.toggle()
                Haptics.impact(.medium)
            }
        }
    }
    
    // MARK: - Quick Insights
    private var quickInsightsCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Quick Insights")
                    .font(.stsHeadline)
                    .foregroundStyle(.stsPrimary)
                
                Spacer()
                
                if insights != nil {
                    Button {
                        showInsightsSheet = true
                    } label: {
                        Text("See All")
                            .font(.stsCaption)
                            .foregroundStyle(.stsAccent)
                    }
                }
            }
            
            if let insights = insights {
                HStack(spacing: 12) {
                    insightTile(
                        icon: "flame.fill",
                        value: "\(insights.loggingStreakDays)",
                        label: "Day Streak",
                        color: .stsWarning
                    )
                    
                    insightTile(
                        icon: "cart.fill",
                        value: "\(insights.expensesCount)",
                        label: "Expenses",
                        color: .stsCyan
                    )
                    
                    insightTile(
                        icon: "arrow.down.circle.fill",
                        value: insights.totalSpentPaise.toCompactRupees,
                        label: "Total Spent",
                        color: .stsDanger
                    )
                }
            } else {
                HStack(spacing: 12) {
                    ForEach(0..<3, id: \.self) { _ in
                        RoundedRectangle(cornerRadius: 12)
                            .fill(Color.stsElevated)
                            .frame(height: 80)
                            .shimmer()
                    }
                }
            }
        }
        .cardStyle()
    }
    
    // MARK: - Helpers
    
    private func statusBadge(_ status: String) -> some View {
        HStack(spacing: 4) {
            Circle()
                .fill(status == "ok" ? Color.stsAccent : Color.stsWarning)
                .frame(width: 6, height: 6)
            
            Text(status.capitalized)
                .font(.stsSmall)
                .foregroundStyle(status == "ok" ? .stsAccent : .stsWarning)
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 4)
        .background((status == "ok" ? Color.stsAccent : Color.stsWarning).opacity(0.12))
        .clipShape(Capsule())
    }
    
    private var divider: some View {
        Rectangle()
            .fill(Color.stsTertiary.opacity(0.3))
            .frame(width: 1, height: 32)
    }
    
    private func breakdownRow(_ label: String, value: Int, color: Color, bold: Bool = false) -> some View {
        HStack {
            Text(label)
                .font(bold ? .stsHeadline : .stsBody)
                .foregroundStyle(bold ? color : .stsSecondary)
            
            Spacer()
            
            Text(value.toRupees)
                .font(bold ? .stsHeadline : .stsBody)
                .foregroundStyle(color)
        }
    }
    
    private func insightTile(icon: String, value: String, label: String, color: Color) -> some View {
        VStack(spacing: 8) {
            Image(systemName: icon)
                .font(.title3)
                .foregroundStyle(color)
            
            Text(value)
                .font(.stsHeadline)
                .foregroundStyle(.stsPrimary)
            
            Text(label)
                .font(.stsSmall)
                .foregroundStyle(.stsSecondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 12)
        .background(Color.stsElevated)
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
    
    private var loadingPlaceholder: some View {
        VStack(spacing: 12) {
            RoundedRectangle(cornerRadius: 8)
                .fill(Color.stsElevated)
                .frame(width: 200, height: 48)
                .shimmer()
            
            RoundedRectangle(cornerRadius: 6)
                .fill(Color.stsElevated)
                .frame(width: 280, height: 20)
                .shimmer()
        }
    }
    
    private var noDataView: some View {
        VStack(spacing: 8) {
            Image(systemName: "exclamationmark.circle")
                .font(.title)
                .foregroundStyle(.stsWarning)
            
            Text("Could not load data")
                .font(.stsBody)
                .foregroundStyle(.stsSecondary)
        }
    }
    
    private var greeting: String {
        let hour = Calendar.current.component(.hour, from: Date())
        switch hour {
        case 5..<12: return "Good morning"
        case 12..<17: return "Good afternoon"
        case 17..<21: return "Good evening"
        default: return "Good evening"
        }
    }
    
    private var currentDateString: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "EEEE, d MMM"
        return formatter.string(from: Date())
    }
    
    private func perDay(_ data: TodayResponse) -> String {
        guard data.daysRemaining > 0 else { return data.stsPaise.toRupees }
        return (data.poolPaise / data.daysRemaining).toRupees
    }
    
    private func cycleProgress(_ data: TodayResponse) -> CGFloat {
        // Approximate: assume 30-day cycle
        let total = 30.0
        let elapsed = total - Double(data.daysRemaining)
        return min(max(CGFloat(elapsed / total), 0), 1)
    }
    
    // MARK: - Data Loading
    
    private func loadData() async {
        if todayData == nil {
            isLoading = true
        }
        
        async let todayTask = APIClient.shared.getToday()
        async let insightsTask: InsightsResponse? = {
            do { return try await APIClient.shared.getInsights() }
            catch { return nil }
        }()
        async let expensesTask: [ExpenseResponse] = {
            do { return try await APIClient.shared.listExpenses() }
            catch { return [] }
        }()
        async let billsTask: [BillResponse] = {
            do { return try await APIClient.shared.listBills() }
            catch { return [] }
        }()
        
        do {
            let freshToday = try await todayTask
            todayData = freshToday
            appState.todayData = freshToday
            insights = await insightsTask
            allExpenses = await expensesTask
            let bills = await billsTask
            RecurringExpenseStore.shared.syncWithBackendBills(bills)
            
            withAnimation(.spring(response: 0.6, dampingFraction: 0.7)) {
                animateAmount = true
            }
        } catch {
            print("Error loading dashboard: \(error)")
        }
        
        isLoading = false
    }
}

// MARK: - Settings View
struct SettingsView: View {
    @EnvironmentObject var appState: AppState
    @Environment(\.dismiss) var dismiss
    @State private var showResetConfirm = false
    @State private var isResetting = false
    
    @State private var showExportSheet = false
    @State private var showReminderSheet = false
    @State private var showPrivacySheet = false
    
    @AppStorage("dailyReminderEnabled") private var isDailyReminderEnabled = false
    @AppStorage("dailyReminderHour") private var dailyReminderHour = 21
    @AppStorage("dailyReminderMinute") private var dailyReminderMinute = 0
    @AppStorage("biometricLockEnabled") private var isBiometricLockEnabled = false
    
    private var reminderStatusSubtitle: String {
        if isDailyReminderEnabled {
            let comp = DateComponents(hour: dailyReminderHour, minute: dailyReminderMinute)
            let date = Calendar.current.date(from: comp) ?? Date()
            let f = DateFormatter()
            f.dateFormat = "h:mm a"
            return "Active at \(f.string(from: date))"
        } else {
            return "Disabled"
        }
    }
    
    @State private var navigationPath = NavigationPath()
    
    var body: some View {
        NavigationStack(path: $navigationPath) {
            ZStack {
                Color.stsCardBackground.ignoresSafeArea()
                
                ScrollView(.vertical, showsIndicators: false) {
                    VStack(spacing: 16) {
                        NavigationLink(value: "export") {
                            settingsRowContent(
                                icon: "square.and.arrow.up",
                                title: "Export Data",
                                subtitle: "CSV spreadsheet, JSON backup",
                                color: .stsCyan
                            )
                        }
                        
                        NavigationLink(value: "reminders") {
                            settingsRowContent(
                                icon: "bell.fill",
                                title: "Daily Reminders",
                                subtitle: reminderStatusSubtitle,
                                color: .stsAccent
                            )
                        }
                        
                        NavigationLink(value: "privacy") {
                            settingsRowContent(
                                icon: "lock.shield.fill",
                                title: "Privacy & Security",
                                subtitle: isBiometricLockEnabled ? "Biometric Protection Active" : "On-device processing",
                                color: .stsSecondary
                            )
                        }
                        
                        Button {
                            showResetConfirm = true
                        } label: {
                            settingsRowContent(
                                icon: "arrow.triangle.2.circlepath",
                                title: "Reset All Data",
                                subtitle: "Clear all local & cloud financial data",
                                color: .stsDanger
                            )
                        }
                        
                        Color.clear.frame(height: 20)
                        
                        Image("AppLogo")
                            .resizable()
                            .scaledToFit()
                            .frame(width: 48, height: 48)
                            .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                            .overlay(
                                RoundedRectangle(cornerRadius: 12, style: .continuous)
                                    .stroke(Color.stsBorder, lineWidth: 1)
                            )
                        
                        Text("SafeToSpend v1.0")
                            .font(.stsSmall)
                            .foregroundStyle(.stsTertiary)
                    }
                    .padding()
                }
                .scrollBounceBehavior(.always, axes: .vertical)
            }
            .navigationTitle("Settings")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") { dismiss() }
                        .foregroundStyle(.stsAccent)
                }
            }
            .navigationDestination(for: String.self) { destination in
                switch destination {
                case "export":
                    ExportDataSheet()
                case "reminders":
                    DailyReminderSheet()
                case "privacy":
                    PrivacySecuritySheet()
                default:
                    EmptyView()
                }
            }
        }
        .alert("Reset All Data?", isPresented: $showResetConfirm) {
            Button("Cancel", role: .cancel) { }
            Button("Reset", role: .destructive) {
                Task {
                    isResetting = true
                    try? await APIClient.shared.resetData()
                    appState.resetOnboarding()
                    isResetting = false
                    dismiss()
                }
            }
        } message: {
            Text("This will permanently delete all your data. This action cannot be undone.")
        }
    }
    
    private func settingsRowContent(icon: String, title: String, subtitle: String? = nil, color: Color) -> some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.body)
                .foregroundStyle(color)
                .frame(width: 36, height: 36)
                .background(color.opacity(0.12))
                .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
            
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.stsBody)
                    .fontWeight(.medium)
                    .foregroundStyle(.stsPrimary)
                
                if let subtitle = subtitle {
                    Text(subtitle)
                        .font(.stsSmall)
                        .foregroundStyle(.stsTertiary)
                }
            }
            
            Spacer()
            
            Image(systemName: "chevron.right")
                .font(.caption)
                .foregroundStyle(.stsTertiary)
        }
        .padding(14)
        .background(Color.stsElevated)
        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .stroke(Color.stsBorder, lineWidth: 1)
        )
    }
}

// MARK: - Insights Detail Sheet (Scrollable)
struct InsightsDetailSheet: View {
    let insights: InsightsResponse
    @Environment(\.dismiss) var dismiss
    
    var sortedCategories: [(String, Int)] {
        insights.categoryBreakdown.sorted { $0.value > $1.value }
    }
    
    var body: some View {
        NavigationStack {
            ZStack {
                Color.stsCardBackground.ignoresSafeArea()
                
                ScrollView(.vertical, showsIndicators: true) {
                    VStack(spacing: 20) {
                        // Stat tiles
                        HStack(spacing: 12) {
                            statBox(
                                title: "Logging Streak",
                                value: "\(insights.loggingStreakDays) Days",
                                icon: "flame.fill",
                                color: .stsWarning
                            )
                            
                            statBox(
                                title: "Total Logged",
                                value: "\(insights.expensesCount)",
                                icon: "cart.fill",
                                color: .stsCyan
                            )
                        }
                        
                        statBox(
                            title: "Total Spent This Cycle",
                            value: insights.totalSpentPaise.toRupees,
                            icon: "indianrupeesign.circle.fill",
                            color: .stsAccent
                        )
                        
                        // Category Breakdown Section
                        VStack(alignment: .leading, spacing: 14) {
                            Text("Category Breakdown")
                                .font(.stsHeadline)
                                .foregroundStyle(.stsPrimary)
                            
                            if sortedCategories.isEmpty {
                                Text("No categorized expenses yet")
                                    .font(.stsBody)
                                    .foregroundStyle(.stsTertiary)
                                    .padding(.vertical, 12)
                            } else {
                                ForEach(sortedCategories, id: \.0) { category, amount in
                                    categoryProgressRow(category: category, amount: amount)
                                }
                            }
                        }
                        .padding(16)
                        .background(Color.stsElevated)
                        .clipShape(RoundedRectangle(cornerRadius: 16))
                        
                        Color.clear.frame(height: 20)
                    }
                    .padding(20)
                }
                .scrollBounceBehavior(.always, axes: .vertical)
            }
            .navigationTitle("Quick Insights")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") { dismiss() }
                        .foregroundStyle(.stsAccent)
                }
            }
        }
    }
    
    private func statBox(title: String, value: String, icon: String, color: Color) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: icon)
                    .foregroundStyle(color)
                Text(title)
                    .font(.stsCaption)
                    .foregroundStyle(.stsSecondary)
            }
            
            Text(value)
                .font(.stsTitle)
                .foregroundStyle(.stsPrimary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(16)
        .background(Color.stsElevated)
        .clipShape(RoundedRectangle(cornerRadius: 14))
    }
    
    private func categoryProgressRow(category: String, amount: Int) -> some View {
        let percent = insights.totalSpentPaise > 0 ? Double(amount) / Double(insights.totalSpentPaise) : 0.0
        
        return VStack(spacing: 6) {
            HStack {
                Text(category.capitalized)
                    .font(.stsBody)
                    .foregroundStyle(.stsPrimary)
                
                Spacer()
                
                Text(amount.toRupees)
                    .font(.stsHeadline)
                    .foregroundStyle(.stsPrimary)
            }
            
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    Capsule()
                        .fill(Color.white.opacity(0.06))
                        .frame(height: 8)
                    
                    Capsule()
                        .fill(Color.stsAccent)
                        .frame(width: max(8, geo.size.width * CGFloat(percent)), height: 8)
                }
            }
            .frame(height: 8)
        }
    }
}

#Preview {
    DashboardView()
        .environmentObject(AppState())
}
