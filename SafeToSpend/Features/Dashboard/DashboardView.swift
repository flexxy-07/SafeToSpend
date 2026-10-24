import SwiftUI

struct DashboardView: View {
    @EnvironmentObject var appState: AppState
    @State private var todayData: TodayResponse?
    @State private var insights: InsightsResponse?
    @State private var allExpenses: [ExpenseResponse] = []
    @State private var isLoading = true
    @State private var showInsightsSheet = false
    @State private var showAddExpenseSheet = false
    @State private var isHeroExpanded = true
    @State private var isBreakdownExpanded = true
    @State private var isCycleExpanded = true
    @State private var isInsightsExpanded = true
    @State private var animateAmount = false
    @State private var showSettings = false
    @State private var showZenShowcase = false
    
    var body: some View {
        ZStack {
            AppBackground()
            AmbientPetalsView()
            
            ScrollView(.vertical, showsIndicators: false) {
                VStack(spacing: 18) {
                    heroCard
                    cycleProgressCard
                    breakdownCard
                    RecurringExpenseCalendarCard()
                    quickInsightsCard
                    
                    // Bottom padding for tab bar
                    Color.clear.frame(height: 80)
                }
                .padding(.horizontal, 16)
                .padding(.top, 14)
            }
            .clipped()
            .scrollBounceBehavior(.always, axes: .vertical)
            .refreshable {
                await loadData()
            }
            .safeAreaInset(edge: .top, spacing: 0) {
                headerBar
                    .padding(.horizontal, 16)
                    .padding(.top, 8)
                    .padding(.bottom, 12)
                    .background(
                        ZStack {
                            Color.white.opacity(0.92)
                            Rectangle()
                                .fill(.ultraThinMaterial)
                        }
                        .ignoresSafeArea(edges: .top)
                    )
                    .overlay(alignment: .bottom) {
                        LinearGradient(
                            colors: [Color.zenPlumBorder.opacity(0.5), Color.clear],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                        .frame(height: 1)
                    }
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
                .presentationBackground(Color.white.opacity(0.95))
        }
        .sheet(isPresented: $showInsightsSheet) {
            if let insights = insights {
                InsightsDetailSheet(insights: insights)
                    .presentationDetents([.medium, .large])
                    .presentationDragIndicator(.visible)
                    .presentationBackground(Color.white.opacity(0.95))
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
                .presentationBackground(Color.white.opacity(0.95))
        }
        .sheet(isPresented: $showZenShowcase) {
            ZenShowcaseView()
        }
    }
    
    // MARK: - Header
    private var headerBar: some View {
        HStack(spacing: 12) {
            // Mascot Guide Chip: Ronin Ryo from the anime artwork
            MascotAvatarView(mascot: .ryo, size: 38)
            
            VStack(alignment: .leading, spacing: 2) {
                Text("SafeToSpend")
                    .font(.zenHeading(16, weight: .bold))
                    .foregroundStyle(Color.zenInk)
                
                Text(currentDateString)
                    .font(.zenBody(12))
                    .foregroundStyle(Color.zenPlumGrey)
            }
            
            Spacer()
            
            Button {
                showSettings = true
            } label: {
                Image(systemName: "gearshape.fill")
                    .font(.system(size: 16, weight: .medium))
                    .foregroundStyle(Color.zenPlumGrey)
                    .frame(width: 38, height: 38)
                    .background(Color.white.opacity(0.8))
                    .clipShape(Circle())
                    .overlay(
                        Circle()
                            .stroke(Color.zenPlumBorder, lineWidth: 1)
                    )
            }
        }
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
            HStack(spacing: 8) {
                HStack(spacing: 6) {
                    Image(systemName: "mountain.2.fill")
                        .font(.system(size: 12))
                        .foregroundStyle(Color.zenCrimson)
                    
                    Text("SAFE TO SPEND")
                        .font(.system(size: 11, weight: .bold, design: .serif))
                        .foregroundStyle(Color.zenPlumGrey)
                        .tracking(0.8)
                }
                
                Spacer()
                
                HankoSealStamp(kanji: "日", label: "TODAY", color: .zenCrimson)
                
                Button {
                    withAnimation(.spring(response: 0.42, dampingFraction: 0.78)) {
                        isHeroExpanded.toggle()
                        Haptics.impact(.medium)
                    }
                } label: {
                    HStack(spacing: 4) {
                        Text(isHeroExpanded ? "COLLAPSE" : "EXPAND")
                            .font(.system(size: 10, weight: .bold, design: .serif))
                        Image(systemName: isHeroExpanded ? "chevron.up" : "chevron.down")
                            .font(.system(size: 9, weight: .bold))
                    }
                    .foregroundStyle(Color.zenCrimson)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(Color.zenCrimson.opacity(0.08))
                    .clipShape(Capsule())
                    .overlay(
                        Capsule().stroke(Color.zenCrimson.opacity(0.2), lineWidth: 1)
                    )
                }
            }
            
            if isLoading {
                loadingPlaceholder
            } else if let data = todayData {
                if isHeroExpanded {
                    ZStack {
                        // Soft ambient radiant aura behind the allowance amount
                        RadialGradient(
                            colors: [Color.zenCrimson.opacity(0.08), Color.zenGold.opacity(0.04), Color.clear],
                            center: .center,
                            startRadius: 10,
                            endRadius: 90
                        )
                        .frame(height: 100)
                        
                        VStack(spacing: 4) {
                            Text(data.stsPaise.toRupees)
                                .font(.zenHeading(38, weight: .bold))
                                .foregroundStyle(Color.zenInk)
                                .contentTransition(.numericText())
                                .scaleEffect(animateAmount ? 1.0 : 0.8)
                                .opacity(animateAmount ? 1.0 : 0)
                            
                            Text("Safe Allowance for Today")
                                .font(.zenBody(13, weight: .medium))
                                .foregroundStyle(Color.zenPlumGrey)
                        }
                    }
                    .padding(.vertical, 4)
                    
                    KatanaDivider()
                    
                    // Horizontal 3-metric summary
                    HStack(spacing: 20) {
                        VStack(spacing: 3) {
                            Text("per day")
                                .font(.zenBody(11))
                                .foregroundStyle(Color.zenPlumGrey)
                            
                            Text(perDay(data))
                                .font(.zenNumber(16, weight: .bold))
                                .foregroundStyle(Color.zenCrimson)
                        }
                        
                        Divider().frame(height: 28).background(Color.zenPlumBorder)
                        
                        VStack(spacing: 3) {
                            Text("days left")
                                .font(.zenBody(11))
                                .foregroundStyle(Color.zenPlumGrey)
                            
                            Text("\(data.daysRemaining)")
                                .font(.zenNumber(16, weight: .bold))
                                .foregroundStyle(Color.zenInk)
                        }
                        
                        Divider().frame(height: 28).background(Color.zenPlumBorder)
                        
                        VStack(spacing: 3) {
                            Text("pool")
                                .font(.zenBody(11))
                                .foregroundStyle(Color.zenPlumGrey)
                            
                            Text(data.poolPaise.toRupees)
                                .font(.zenNumber(16, weight: .bold))
                                .foregroundStyle(Color.zenJade)
                        }
                    }
                } else {
                    // Collapsed compact row
                    HStack(alignment: .center) {
                        VStack(alignment: .leading, spacing: 2) {
                            Text(data.stsPaise.toRupees)
                                .font(.zenHeading(24, weight: .bold))
                                .foregroundStyle(Color.zenInk)
                            
                            Text("Safe for today")
                                .font(.zenBody(11, weight: .medium))
                                .foregroundStyle(Color.zenPlumGrey)
                        }
                        
                        Spacer()
                        
                        HStack(spacing: 10) {
                            VStack(spacing: 2) {
                                Text(perDay(data))
                                    .font(.zenNumber(13, weight: .bold))
                                    .foregroundStyle(Color.zenCrimson)
                                Text("per day")
                                    .font(.zenBody(10))
                                    .foregroundStyle(Color.zenPlumGrey)
                            }
                            
                            Divider()
                                .frame(height: 20)
                                .background(Color.zenPlumBorder)
                            
                            VStack(spacing: 2) {
                                Text("\(data.daysRemaining)d")
                                    .font(.zenNumber(13, weight: .bold))
                                    .foregroundStyle(Color.zenInk)
                                Text("left")
                                    .font(.zenBody(10))
                                    .foregroundStyle(Color.zenPlumGrey)
                            }
                            
                            Divider()
                                .frame(height: 20)
                                .background(Color.zenPlumBorder)
                            
                            VStack(spacing: 2) {
                                Text(data.poolPaise.toRupees)
                                    .font(.zenNumber(13, weight: .bold))
                                    .foregroundStyle(Color.zenJade)
                                Text("pool")
                                    .font(.zenBody(10))
                                    .foregroundStyle(Color.zenPlumGrey)
                            }
                        }
                        .padding(.horizontal, 10)
                        .padding(.vertical, 6)
                        .background(Color.zenMist.opacity(0.35))
                        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                        .overlay(
                            RoundedRectangle(cornerRadius: 12, style: .continuous)
                                .stroke(Color.zenPlumBorder.opacity(0.4), lineWidth: 1)
                        )
                    }
                    .padding(.top, -2)
                }
            } else {
                noDataView
            }
        }
        .glassCard(variant: .default, cornerRadius: 24)
        .contentShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
        .highPriorityGesture(
            TapGesture(count: 2).onEnded {
                withAnimation(.spring(response: 0.42, dampingFraction: 0.78)) {
                    isHeroExpanded.toggle()
                    Haptics.impact(.medium)
                }
            }
        )
    }
    
    // MARK: - Cycle Progress
    private var cycleProgressCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("CYCLE PROGRESS")
                    .font(.system(size: 11, weight: .bold, design: .serif))
                    .foregroundStyle(Color.zenPlumGrey)
                    .tracking(0.8)
                
                Spacer()
                
                if let data = todayData {
                    Text("\(Int(cycleProgress(data) * 100))% THROUGH")
                        .font(.system(size: 11, weight: .bold, design: .serif))
                        .foregroundStyle(Color.zenJadeDark)
                }
                
                Button {
                    withAnimation(.spring(response: 0.42, dampingFraction: 0.78)) {
                        isCycleExpanded.toggle()
                        Haptics.impact(.medium)
                    }
                } label: {
                    HStack(spacing: 4) {
                        Text(isCycleExpanded ? "COLLAPSE" : "EXPAND")
                            .font(.system(size: 10, weight: .bold, design: .serif))
                        Image(systemName: isCycleExpanded ? "chevron.up" : "chevron.down")
                            .font(.system(size: 9, weight: .bold))
                    }
                    .foregroundStyle(Color.zenJadeDark)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(Color.zenJade.opacity(0.08))
                    .clipShape(Capsule())
                    .overlay(
                        Capsule().stroke(Color.zenJade.opacity(0.2), lineWidth: 1)
                    )
                }
            }
            
            if let data = todayData {
                if isCycleExpanded {
                    DragonProgressBar(
                        progress: cycleProgress(data),
                        isWarning: cycleProgress(data) > 0.85
                    )
                    
                    HStack {
                        HStack(spacing: 4) {
                            Image(systemName: "camera.macro")
                                .font(.system(size: 11))
                                .foregroundStyle(Color.zenBlossomDeep)
                            Text("Active Budget Cycle")
                                .font(.zenBody(12))
                                .foregroundStyle(Color.zenPlumGrey)
                        }
                        
                        Spacer()
                        
                        Text("\(data.daysRemaining) days remaining")
                            .font(.zenBody(12, weight: .bold))
                            .foregroundStyle(Color.zenCrimson)
                    }
                } else {
                    GeometryReader { geo in
                        ZStack(alignment: .leading) {
                            Capsule()
                                .fill(Color.zenPlumBorder)
                                .frame(height: 4)
                            Capsule()
                                .fill(Color.zenJade)
                                .frame(width: max(0, min(geo.size.width, geo.size.width * cycleProgress(data))), height: 4)
                        }
                    }
                    .frame(height: 4)
                }
            }
        }
        .glassCard(variant: .default, cornerRadius: 20)
        .contentShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
        .highPriorityGesture(
            TapGesture(count: 2).onEnded {
                withAnimation(.spring(response: 0.42, dampingFraction: 0.78)) {
                    isCycleExpanded.toggle()
                    Haptics.impact(.medium)
                }
            }
        )
    }
    
    // MARK: - Financial Breakdown
    private var breakdownCard: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack {
                HStack(spacing: 8) {
                    MascotAvatarView(mascot: .midori, size: 22, showGlow: false)
                    
                    Text("MONTHLY OUTLOOK")
                        .font(.system(size: 11, weight: .bold, design: .serif))
                        .foregroundStyle(Color.zenInk)
                        .tracking(0.8)
                }
                
                Spacer()
                
                Button {
                    withAnimation(.spring(response: 0.42, dampingFraction: 0.78)) {
                        isBreakdownExpanded.toggle()
                        Haptics.impact(.medium)
                    }
                } label: {
                    HStack(spacing: 4) {
                        Text(isBreakdownExpanded ? "COLLAPSE" : "EXPAND")
                            .font(.system(size: 10, weight: .bold, design: .serif))
                        Image(systemName: isBreakdownExpanded ? "chevron.up" : "chevron.down")
                            .font(.system(size: 9, weight: .bold))
                    }
                    .foregroundStyle(Color.zenCrimson)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(Color.zenCrimson.opacity(0.08))
                    .clipShape(Capsule())
                    .overlay(
                        Capsule().stroke(Color.zenCrimson.opacity(0.2), lineWidth: 1)
                    )
                }
            }
            
            if let data = todayData {
                if isBreakdownExpanded {
                    breakdownRow("Available Balance", value: data.availableBalancePaise, color: .zenInk)
                    breakdownRow("Unpaid Bills", value: -data.unpaidCommitmentsPaise, color: .zenCrimson)
                    breakdownRow("Safety Buffer", value: -data.safetyBufferPaise, color: .zenPlumGrey)
                    breakdownRow("Savings Reserve", value: -data.remainingSavingsReservePaise, color: .zenJade)
                    
                    KatanaDivider()
                }
                
                breakdownRow("Spendable Pool", value: data.poolPaise, color: .zenJadeDark, bold: true)
                
                if data.shortfallPaise > 0 {
                    HStack(spacing: 8) {
                        Image(systemName: "exclamationmark.triangle.fill")
                            .foregroundStyle(Color.zenCrimson)
                        
                        Text("Shortfall: \(data.shortfallPaise.toRupees)")
                            .font(.zenBody(12, weight: .bold))
                            .foregroundStyle(Color.zenCrimson)
                    }
                    .padding(8)
                    .background(Color.zenCrimson.opacity(0.1))
                    .clipShape(RoundedRectangle(cornerRadius: 10))
                }
            }
        }
        .glassCard(variant: .default, cornerRadius: 20)
        .contentShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
        .highPriorityGesture(
            TapGesture(count: 2).onEnded {
                withAnimation(.spring(response: 0.42, dampingFraction: 0.78)) {
                    isBreakdownExpanded.toggle()
                    Haptics.impact(.medium)
                }
            }
        )
    }
    
    // MARK: - Quick Insights
    private var quickInsightsCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("QUICK INSIGHTS")
                    .font(.system(size: 11, weight: .bold, design: .serif))
                    .foregroundStyle(Color.zenPlumGrey)
                    .tracking(0.8)
                
                Spacer()
                
                if insights != nil {
                    Button {
                        showInsightsSheet = true
                    } label: {
                        Text("See All")
                            .font(.zenHeading(12, weight: .bold))
                            .foregroundStyle(Color.zenCrimson)
                    }
                }
            }
            
            if let insights = insights {
                HStack(spacing: 12) {
                    insightTile(
                        icon: "flame.fill",
                        value: "\(insights.loggingStreakDays)",
                        label: "Day Streak",
                        color: .zenGoldDeep
                    )
                    
                    insightTile(
                        icon: "cart.fill",
                        value: "\(insights.expensesCount)",
                        label: "Expenses",
                        color: .zenSkyTop
                    )
                    
                    insightTile(
                        icon: "arrow.down.circle.fill",
                        value: insights.totalSpentPaise.toCompactRupees,
                        label: "Total Spent",
                        color: .zenCrimson
                    )
                }
            } else {
                HStack(spacing: 12) {
                    ForEach(0..<3, id: \.self) { _ in
                        RoundedRectangle(cornerRadius: 12)
                            .fill(Color.white.opacity(0.6))
                            .frame(height: 80)
                    }
                }
            }
        }
        .glassCard(variant: .default, cornerRadius: 20)
    }
    
    // MARK: - Helpers
    
    private func statusBadge(_ status: String) -> some View {
        HStack(spacing: 4) {
            Circle()
                .fill(status == "ok" ? Color.zenJade : Color.zenGoldDeep)
                .frame(width: 6, height: 6)
            
            Text(status.capitalized)
                .font(.zenBody(11, weight: .semibold))
                .foregroundStyle(status == "ok" ? Color.zenJade : Color.zenGoldDeep)
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 4)
        .background((status == "ok" ? Color.zenJade : Color.zenGoldDeep).opacity(0.12))
        .clipShape(Capsule())
    }
    
    private var divider: some View {
        Rectangle()
            .fill(Color.zenPlumBorder)
            .frame(width: 1, height: 32)
    }
    
    private func breakdownRow(_ label: String, value: Int, color: Color, bold: Bool = false) -> some View {
        HStack {
            Text(label)
                .font(bold ? .zenHeading(14, weight: .bold) : .zenBody(13))
                .foregroundStyle(bold ? color : Color.zenPlumGrey)
            
            Spacer()
            
            Text(value.toRupees)
                .font(bold ? .zenNumber(15, weight: .bold) : .zenNumber(13))
                .foregroundStyle(color)
        }
    }
    
    private func insightTile(icon: String, value: String, label: String, color: Color) -> some View {
        VStack(spacing: 6) {
            Image(systemName: icon)
                .font(.system(size: 16, weight: .bold))
                .foregroundStyle(color)
            
            Text(value)
                .font(.zenNumber(16, weight: .bold))
                .foregroundStyle(Color.zenInk)
            
            Text(label)
                .font(.zenBody(11))
                .foregroundStyle(Color.zenPlumGrey)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 12)
        .background(Color.white.opacity(0.7))
        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .stroke(Color.white.opacity(0.9), lineWidth: 1)
        )
    }
    
    private var loadingPlaceholder: some View {
        VStack(spacing: 12) {
            RoundedRectangle(cornerRadius: 8)
                .fill(Color.white.opacity(0.5))
                .frame(width: 200, height: 48)
                .shimmer()
            
            RoundedRectangle(cornerRadius: 6)
                .fill(Color.white.opacity(0.4))
                .frame(width: 280, height: 20)
                .shimmer()
        }
    }
    
    private var noDataView: some View {
        VStack(spacing: 10) {
            MascotAvatarView(mascot: .ryo, size: 48)
            
            Text("Connecting with Guardians...")
                .font(.zenHeading(15, weight: .bold))
                .foregroundStyle(Color.zenInk)
            
            Text("Pull down to refresh daily allowance")
                .font(.zenBody(12))
                .foregroundStyle(Color.zenPlumGrey)
        }
        .padding(.vertical, 10)
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
