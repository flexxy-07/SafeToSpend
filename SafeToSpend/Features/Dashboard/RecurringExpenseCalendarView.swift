import SwiftUI

// MARK: - Recurring Expense Data Models

struct RecurringPaymentRecord: Identifiable, Codable, Hashable {
    var id: String = UUID().uuidString
    var cycleDate: String // "yyyy-MM-dd"
    var amountPaise: Int
    var isPaid: Bool
    var paidDate: String?
}

struct RecurringExpenseItem: Identifiable, Codable, Hashable {
    var id: String = UUID().uuidString
    var name: String
    var amountPaise: Int
    var dayOfMonth: Int // 1...31
    var cadence: String // "monthly", "yearly", "quarterly"
    var category: String
    var brandKey: String // "spotify", "house", "youtube", "google", "claude", "netflix", "fees", "cleaning", "wifi", "gym"
    var history: [RecurringPaymentRecord] = []
    var isAutoRenew: Bool = true
    
    // Total times followed / paid
    var timesFollowed: Int {
        history.filter { $0.isPaid }.count
    }
    
    // Total lifetime spend on this recurring expense
    var totalAmountPaidPaise: Int {
        history.filter { $0.isPaid }.reduce(0) { $0 + $1.amountPaise }
    }
    
    // Consecutive streak of successful payments
    var streakCount: Int {
        var streak = 0
        for record in history.sorted(by: { $0.cycleDate > $1.cycleDate }) {
            if record.isPaid {
                streak += 1
            } else {
                break
            }
        }
        return max(streak, timesFollowed)
    }
}

// MARK: - Recurring Expense Store & Service

@MainActor
final class RecurringExpenseStore: ObservableObject {
    static let shared = RecurringExpenseStore()
    
    @Published var items: [RecurringExpenseItem] = []
    
    private let storageKey = "safetospend_recurring_expenses_v2"
    
    init() {
        loadItems()
        if items.isEmpty {
            seedInitialRecurringExpenses()
        }
    }
    
    func loadItems() {
        if let data = UserDefaults.standard.data(forKey: storageKey),
           let decoded = try? JSONDecoder().decode([RecurringExpenseItem].self, from: data) {
            self.items = decoded
        }
    }
    
    func saveItems() {
        if let encoded = try? JSONEncoder().encode(items) {
            UserDefaults.standard.set(encoded, forKey: storageKey)
        }
    }
    
    /// Sync with backend bills if any
    func syncWithBackendBills(_ bills: [BillResponse]) {
        for bill in bills {
            let components = bill.dueDate.split(separator: "-")
            let day = components.count >= 3 ? (Int(components[2]) ?? 1) : 1
            let brand = detectBrand(from: bill.name)
            
            if let index = items.firstIndex(where: { $0.name.lowercased() == bill.name.lowercased() }) {
                items[index].amountPaise = bill.amountPaise
                items[index].dayOfMonth = day
            } else {
                let newItem = RecurringExpenseItem(
                    id: bill.id,
                    name: bill.name,
                    amountPaise: bill.amountPaise,
                    dayOfMonth: day,
                    cadence: bill.cadence,
                    category: bill.cadence.capitalized,
                    brandKey: brand,
                    history: generateHistoryForBill(bill, day: day),
                    isAutoRenew: true
                )
                items.append(newItem)
            }
        }
        saveItems()
    }
    
    private func generateHistoryForBill(_ bill: BillResponse, day: Int) -> [RecurringPaymentRecord] {
        var records: [RecurringPaymentRecord] = []
        let currentYear = 2026
        let currentMonth = 10
        
        for m in (4...currentMonth).reversed() {
            let dateStr = String(format: "%04d-%02d-%02d", currentYear, m, day)
            let isPaid = m < currentMonth || bill.isPaid
            records.append(RecurringPaymentRecord(
                cycleDate: dateStr,
                amountPaise: bill.amountPaise,
                isPaid: isPaid,
                paidDate: isPaid ? dateStr : nil
            ))
        }
        return records
    }
    
    func markPaid(itemId: String, forDate dateStr: String) {
        guard let idx = items.firstIndex(where: { $0.id == itemId }) else { return }
        
        if let recIdx = items[idx].history.firstIndex(where: { $0.cycleDate == dateStr }) {
            items[idx].history[recIdx].isPaid = true
            items[idx].history[recIdx].paidDate = dateStr
        } else {
            items[idx].history.append(RecurringPaymentRecord(
                cycleDate: dateStr,
                amountPaise: items[idx].amountPaise,
                isPaid: true,
                paidDate: dateStr
            ))
        }
        saveItems()
        Haptics.notification(.success)
    }
    
    func addExpense(_ item: RecurringExpenseItem) {
        items.append(item)
        saveItems()
    }
    
    func addCustomItem(name: String, amountPaise: Int, dayOfMonth: Int, cadence: String = "monthly", category: String = "Bill", isAutoRenew: Bool = true) {
        let brand = detectBrand(from: name)
        let newItem = RecurringExpenseItem(
            id: UUID().uuidString,
            name: name,
            amountPaise: amountPaise,
            dayOfMonth: dayOfMonth,
            cadence: cadence,
            category: category,
            brandKey: brand,
            history: [],
            isAutoRenew: isAutoRenew
        )
        addExpense(newItem)
    }
    
    func deleteExpense(_ id: String) {
        items.removeAll { $0.id == id }
        saveItems()
    }
    
    func detectBrand(from name: String) -> String {
        let n = name.lowercased()
        if n.contains("spotify") { return "spotify" }
        if n.contains("rent") || n.contains("house") || n.contains("flat") { return "house" }
        if n.contains("youtube") { return "youtube" }
        if n.contains("google") { return "google" }
        if n.contains("clean") || n.contains("maintenance") || n.contains("maid") { return "cleaning" }
        if n.contains("claude") || n.contains("anthropic") { return "claude" }
        if n.contains("netflix") { return "netflix" }
        if n.contains("fee") || n.contains("tuition") || n.contains("college") { return "fees" }
        if n.contains("wifi") || n.contains("internet") || n.contains("broadband") { return "wifi" }
        if n.contains("gym") || n.contains("fitness") { return "gym" }
        if n.contains("apple") || n.contains("icloud") { return "apple" }
        return "generic"
    }
    
    /// Seed recurring payments matching the reference design (Spotify, House, YouTube, Google, Cleaning, Netflix, Fees, Wi-Fi)
    private func seedInitialRecurringExpenses() {
        let spotify = RecurringExpenseItem(
            name: "Spotify Premium",
            amountPaise: 11900, // ₹119
            dayOfMonth: 3,
            cadence: "monthly",
            category: "Music & Audio",
            brandKey: "spotify",
            history: [
                RecurringPaymentRecord(cycleDate: "2026-10-03", amountPaise: 11900, isPaid: true, paidDate: "2026-10-03"),
                RecurringPaymentRecord(cycleDate: "2026-09-03", amountPaise: 11900, isPaid: true, paidDate: "2026-09-03"),
                RecurringPaymentRecord(cycleDate: "2026-08-03", amountPaise: 11900, isPaid: true, paidDate: "2026-08-03"),
                RecurringPaymentRecord(cycleDate: "2026-07-03", amountPaise: 11900, isPaid: true, paidDate: "2026-07-03"),
                RecurringPaymentRecord(cycleDate: "2026-06-03", amountPaise: 11900, isPaid: true, paidDate: "2026-06-03"),
                RecurringPaymentRecord(cycleDate: "2026-05-03", amountPaise: 11900, isPaid: true, paidDate: "2026-05-03"),
                RecurringPaymentRecord(cycleDate: "2026-04-03", amountPaise: 11900, isPaid: true, paidDate: "2026-04-03")
            ],
            isAutoRenew: true
        )
        
        let house = RecurringExpenseItem(
            name: "Apartment Rent",
            amountPaise: 1800000, // ₹18,000
            dayOfMonth: 7,
            cadence: "monthly",
            category: "Housing",
            brandKey: "house",
            history: [
                RecurringPaymentRecord(cycleDate: "2026-10-07", amountPaise: 1800000, isPaid: true, paidDate: "2026-10-07"),
                RecurringPaymentRecord(cycleDate: "2026-09-07", amountPaise: 1800000, isPaid: true, paidDate: "2026-09-07"),
                RecurringPaymentRecord(cycleDate: "2026-08-07", amountPaise: 1800000, isPaid: true, paidDate: "2026-08-07"),
                RecurringPaymentRecord(cycleDate: "2026-07-07", amountPaise: 1800000, isPaid: true, paidDate: "2026-07-07")
            ],
            isAutoRenew: true
        )
        
        let youtube = RecurringExpenseItem(
            name: "YouTube Premium",
            amountPaise: 14900, // ₹149
            dayOfMonth: 12,
            cadence: "monthly",
            category: "Video Streaming",
            brandKey: "youtube",
            history: [
                RecurringPaymentRecord(cycleDate: "2026-10-12", amountPaise: 14900, isPaid: true, paidDate: "2026-10-12"),
                RecurringPaymentRecord(cycleDate: "2026-09-12", amountPaise: 14900, isPaid: true, paidDate: "2026-09-12"),
                RecurringPaymentRecord(cycleDate: "2026-08-12", amountPaise: 14900, isPaid: true, paidDate: "2026-08-12")
            ],
            isAutoRenew: true
        )
        
        let google = RecurringExpenseItem(
            name: "Google One Storage",
            amountPaise: 13000, // ₹130
            dayOfMonth: 15,
            cadence: "monthly",
            category: "Cloud Storage",
            brandKey: "google",
            history: [
                RecurringPaymentRecord(cycleDate: "2026-10-15", amountPaise: 13000, isPaid: true, paidDate: "2026-10-15"),
                RecurringPaymentRecord(cycleDate: "2026-09-15", amountPaise: 13000, isPaid: true, paidDate: "2026-09-15"),
                RecurringPaymentRecord(cycleDate: "2026-08-15", amountPaise: 13000, isPaid: true, paidDate: "2026-08-15")
            ],
            isAutoRenew: true
        )
        
        let cleaning = RecurringExpenseItem(
            name: "Home Maintenance",
            amountPaise: 250000, // ₹2,500
            dayOfMonth: 18,
            cadence: "monthly",
            category: "Services",
            brandKey: "cleaning",
            history: [
                RecurringPaymentRecord(cycleDate: "2026-10-18", amountPaise: 250000, isPaid: true, paidDate: "2026-10-18"),
                RecurringPaymentRecord(cycleDate: "2026-09-18", amountPaise: 250000, isPaid: true, paidDate: "2026-09-18")
            ],
            isAutoRenew: true
        )
        
        let netflix = RecurringExpenseItem(
            name: "Netflix 4K Premium",
            amountPaise: 64900, // ₹649
            dayOfMonth: 19,
            cadence: "monthly",
            category: "Entertainment",
            brandKey: "netflix",
            history: [
                RecurringPaymentRecord(cycleDate: "2026-10-19", amountPaise: 64900, isPaid: true, paidDate: "2026-10-19"),
                RecurringPaymentRecord(cycleDate: "2026-09-19", amountPaise: 64900, isPaid: true, paidDate: "2026-09-19")
            ],
            isAutoRenew: true
        )
        
        let fees = RecurringExpenseItem(
            name: "Semester Academic Fees",
            amountPaise: 1500000, // ₹15,000
            dayOfMonth: 20,
            cadence: "quarterly",
            category: "Education",
            brandKey: "fees",
            history: [
                RecurringPaymentRecord(cycleDate: "2026-10-20", amountPaise: 1500000, isPaid: true, paidDate: "2026-10-20"),
                RecurringPaymentRecord(cycleDate: "2026-07-20", amountPaise: 1500000, isPaid: true, paidDate: "2026-07-20")
            ],
            isAutoRenew: true
        )
        
        let claude = RecurringExpenseItem(
            name: "Claude AI Pro",
            amountPaise: 199900, // ₹1,999
            dayOfMonth: 24, // Today (24th)
            cadence: "monthly",
            category: "AI & Productivity",
            brandKey: "claude",
            history: [
                RecurringPaymentRecord(cycleDate: "2026-10-24", amountPaise: 199900, isPaid: true, paidDate: "2026-10-24"),
                RecurringPaymentRecord(cycleDate: "2026-09-24", amountPaise: 199900, isPaid: true, paidDate: "2026-09-24"),
                RecurringPaymentRecord(cycleDate: "2026-08-24", amountPaise: 199900, isPaid: true, paidDate: "2026-08-24")
            ],
            isAutoRenew: true
        )
        
        let wifi = RecurringExpenseItem(
            name: "Airtel Fiber Broadband",
            amountPaise: 99900, // ₹999
            dayOfMonth: 28,
            cadence: "monthly",
            category: "Utilities & Network",
            brandKey: "wifi",
            history: [
                RecurringPaymentRecord(cycleDate: "2026-09-28", amountPaise: 99900, isPaid: true, paidDate: "2026-09-28"),
                RecurringPaymentRecord(cycleDate: "2026-08-28", amountPaise: 99900, isPaid: true, paidDate: "2026-08-28")
            ],
            isAutoRenew: true
        )
        
        self.items = [spotify, house, youtube, google, cleaning, netflix, fees, claude, wifi]
        saveItems()
    }
}

// MARK: - Recurring Brand Icon View

struct RecurringBrandIconView: View {
    let brandKey: String
    var size: CGFloat = 20
    var showBackground: Bool = false
    
    var body: some View {
        ZStack {
            if showBackground {
                Circle()
                    .fill(backgroundColor)
                    .frame(width: size, height: size)
                    .shadow(color: backgroundColor.opacity(0.35), radius: 2, y: 1)
            }
            
            iconContent
                .foregroundStyle(.white)
        }
        .frame(width: size, height: size)
    }
    
    @ViewBuilder
    private var iconContent: some View {
        switch brandKey.lowercased() {
        case "spotify":
            Image(systemName: "waveform")
                .font(.system(size: size * 0.58, weight: .bold))
        case "house", "rent":
            Image(systemName: "house.fill")
                .font(.system(size: size * 0.54, weight: .semibold))
        case "youtube":
            Image(systemName: "play.rectangle.fill")
                .font(.system(size: size * 0.58, weight: .semibold))
        case "google":
            Text("G")
                .font(.system(size: size * 0.54, weight: .black, design: .rounded))
        case "cleaning":
            Image(systemName: "paintbrush.fill")
                .font(.system(size: size * 0.52, weight: .semibold))
        case "claude":
            Image(systemName: "sparkles")
                .font(.system(size: size * 0.58, weight: .bold))
        case "netflix":
            Image(systemName: "play.tv.fill")
                .font(.system(size: size * 0.54, weight: .semibold))
        case "fees":
            Image(systemName: "graduationcap.fill")
                .font(.system(size: size * 0.54, weight: .semibold))
        case "wifi":
            Image(systemName: "wifi")
                .font(.system(size: size * 0.54, weight: .bold))
        case "gym":
            Image(systemName: "dumbbell.fill")
                .font(.system(size: size * 0.52, weight: .semibold))
        case "apple":
            Image(systemName: "apple.logo")
                .font(.system(size: size * 0.56, weight: .semibold))
        default:
            Image(systemName: "arrow.triangle.2.circlepath")
                .font(.system(size: size * 0.52, weight: .semibold))
        }
    }
    
    private var backgroundColor: Color {
        switch brandKey.lowercased() {
        case "spotify": return Color(hex: "1DB954")
        case "house", "rent": return Color(hex: "10B981")
        case "youtube": return Color(hex: "EF4444")
        case "google": return Color(hex: "4285F4")
        case "claude": return Color(hex: "D96B43")
        case "netflix": return Color(hex: "E50914")
        case "fees": return Color(hex: "4F46E5")
        case "wifi": return Color(hex: "06B6D4")
        case "gym": return Color(hex: "F97316")
        case "cleaning": return Color(hex: "8B5CF6")
        case "apple": return Color(hex: "334155")
        default: return Color.stsElevated
        }
    }
}

// MARK: - Recurring Expenses Calendar Card (Design Matching Shared Screenshot)

struct RecurringExpenseCalendarCard: View {
    @ObservedObject var store = RecurringExpenseStore.shared
    
    @State private var currentMonthDate = Date()
    @State private var selectedDay: Int? = nil
    @State private var showDetailPopup = false
    @State private var showAddSheet = false
    
    private let calendar = Calendar.current
    private let daysOfWeek = ["Su", "Mo", "Tu", "We", "Th", "Fr", "Sa"]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            // 1. Header: (↻) RECURRING PAYMENTS  +
            topHeaderView
            
            // 2. Navigation Pills: [ Jan ▾ | 23 ▾ ]    [ < | cal | > ]
            navigationPillsView
            
            // 3. Days of Week: Su  Mo  Tu  We  Th  Fr  Sa
            daysOfWeekHeader
            
            // 4. Calendar Grid with top-left date badge & centered brand icon
            calendarGridView
        }
        .padding(18)
        .background(Color.stsCardBackground)
        .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .stroke(Color.stsBorder, lineWidth: 1)
        )
        .sheet(isPresented: $showDetailPopup) {
            if let day = selectedDay {
                RecurringDateDetailPopup(
                    day: day,
                    monthDate: currentMonthDate,
                    store: store,
                    onDismiss: { showDetailPopup = false }
                )
                .presentationDetents([.medium, .large])
                .presentationDragIndicator(.visible)
                .presentationBackground(Color.stsCardBackground)
            }
        }
        .sheet(isPresented: $showAddSheet) {
            AddRecurringExpenseSheet(store: store) {
                showAddSheet = false
            }
            .presentationDetents([.medium, .large])
            .presentationDragIndicator(.visible)
            .presentationBackground(Color.stsCardBackground)
        }
    }
    
    // MARK: - 1. Top Header View: (↻) RECURRING PAYMENTS   +
    private var topHeaderView: some View {
        HStack(spacing: 8) {
            Image(systemName: "arrow.triangle.2.circlepath")
                .font(.system(size: 15, weight: .bold))
                .foregroundStyle(.white)
            
            Text("RECURRING PAYMENTS")
                .font(.system(size: 13, weight: .bold))
                .tracking(1.0)
                .foregroundStyle(.white)
            
            Spacer()
            
            Button {
                showAddSheet = true
            } label: {
                Image(systemName: "plus")
                    .font(.system(size: 15, weight: .bold))
                    .foregroundStyle(.white)
            }
        }
    }
    
    // MARK: - 2. Navigation Control Pills
    private var navigationPillsView: some View {
        HStack {
            // Left Pill: [ Month ▾ | Year ▾ ]
            HStack(spacing: 8) {
                Menu {
                    ForEach(1...12, id: \.self) { m in
                        Button(monthName(m)) {
                            setMonth(m)
                        }
                    }
                } label: {
                    HStack(spacing: 4) {
                        Text(shortMonthString)
                            .font(.system(size: 13, weight: .semibold))
                            .foregroundStyle(.white)
                        
                        Image(systemName: "arrowtriangle.down.fill")
                            .font(.system(size: 6))
                            .foregroundStyle(.white.opacity(0.7))
                    }
                }
                
                Rectangle()
                    .fill(Color.white.opacity(0.2))
                    .frame(width: 1, height: 12)
                
                Menu {
                    ForEach(2024...2030, id: \.self) { y in
                        Button {
                            setYear(y)
                        } label: {
                            Text(verbatim: String(y))
                        }
                    }
                } label: {
                    HStack(spacing: 4) {
                        Text(verbatim: shortYearString)
                            .font(.system(size: 13, weight: .semibold))
                            .foregroundStyle(.white)
                        
                        Image(systemName: "arrowtriangle.down.fill")
                            .font(.system(size: 6))
                            .foregroundStyle(.white.opacity(0.7))
                    }
                }
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 8)
            .background(Color.stsElevated)
            .clipShape(Capsule())
            .overlay(
                Capsule()
                    .stroke(Color.stsBorder, lineWidth: 1)
            )
            
            Spacer()
            
            // Right Pill: [ < | cal | > ]
            HStack(spacing: 16) {
                Button {
                    withAnimation(.easeInOut(duration: 0.15)) {
                        changeMonth(by: -1)
                    }
                } label: {
                    Image(systemName: "chevron.left")
                        .font(.system(size: 11, weight: .bold))
                        .foregroundStyle(.white)
                }
                
                Button {
                    withAnimation(.easeInOut(duration: 0.15)) {
                        currentMonthDate = Date()
                    }
                } label: {
                    Image(systemName: "calendar")
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundStyle(.white)
                }
                
                Button {
                    withAnimation(.easeInOut(duration: 0.15)) {
                        changeMonth(by: 1)
                    }
                } label: {
                    Image(systemName: "chevron.right")
                        .font(.system(size: 11, weight: .bold))
                        .foregroundStyle(.white)
                }
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 8)
            .background(Color.stsElevated)
            .clipShape(Capsule())
            .overlay(
                Capsule()
                    .stroke(Color.stsBorder, lineWidth: 1)
            )
        }
    }
    
    // MARK: - 3. Days of Week Row
    private var daysOfWeekHeader: some View {
        HStack(spacing: 0) {
            ForEach(daysOfWeek, id: \.self) { day in
                Text(day)
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(Color.stsSecondary)
                    .frame(maxWidth: .infinity)
            }
        }
        .padding(.vertical, 2)
    }
    
    // MARK: - 4. Calendar Grid
    private var calendarGridView: some View {
        let gridDays = computeGridDays()
        let rows = gridDays.count / 7
        
        return VStack(spacing: 6) {
            ForEach(0..<rows, id: \.self) { row in
                HStack(spacing: 6) {
                    ForEach(0..<7, id: \.self) { col in
                        let item = gridDays[row * 7 + col]
                        calendarCell(for: item)
                    }
                }
            }
        }
    }
    
    // MARK: - Calendar Cell Representation
    @ViewBuilder
    private func calendarCell(for dayInfo: CalendarDayInfo) -> some View {
        let recurringOnDay = dayInfo.isCurrentMonth ? store.items.filter { $0.dayOfMonth == dayInfo.dayNumber } : []
        let hasRecurring = !recurringOnDay.isEmpty
        let isToday = dayInfo.isCurrentMonth && isTodayDate(day: dayInfo.dayNumber)
        
        Button {
            if dayInfo.isCurrentMonth {
                selectedDay = dayInfo.dayNumber
                showDetailPopup = true
                Haptics.selection()
            }
        } label: {
            if hasRecurring, let item = recurringOnDay.first {
                // SQUIRCLE CARD WITH TOP-LEFT DATE BADGE & VIBRANT BRAND ICON
                ZStack(alignment: .topLeading) {
                    // Rounded Squircle Card
                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                        .fill(Color.stsElevated)
                        .overlay(
                            RoundedRectangle(cornerRadius: 14, style: .continuous)
                                .stroke(Color.stsBorder, lineWidth: 1)
                        )
                        .overlay(
                            // Centered Colorful Brand Icon Badge (size 28 with full brand colors)
                            RecurringBrandIconView(brandKey: item.brandKey, size: 28, showBackground: true)
                        )
                        .frame(maxWidth: .infinity)
                        .frame(height: 48)
                        .padding(.top, 2)
                        .padding(.leading, 2)
                    
                    // Circular Date Badge in Top-Left Corner
                    Text("\(dayInfo.dayNumber)")
                        .font(.system(size: 9.5, weight: .heavy))
                        .foregroundStyle(.white)
                        .frame(width: 19, height: 19)
                        .background(Color.stsAccent)
                        .clipShape(Circle())
                        .overlay(
                            Circle()
                                .stroke(Color.stsCardBackground, lineWidth: 1.5)
                        )
                        .shadow(color: Color.black.opacity(0.3), radius: 1, y: 1)
                }
                .frame(maxWidth: .infinity)
                .frame(height: 50)
            } else {
                // Standard Date Text
                Text("\(dayInfo.dayNumber)")
                    .font(.system(size: 13, weight: isToday ? .bold : .medium))
                    .foregroundStyle(
                        isToday ? .white :
                        (dayInfo.isCurrentMonth ? Color.white.opacity(0.85) : Color.stsTertiary)
                    )
                    .frame(maxWidth: .infinity)
                    .frame(height: 46)
                    .background(
                        isToday ?
                        Circle()
                            .stroke(Color.stsAccent, lineWidth: 1.5)
                            .frame(width: 28, height: 28)
                        : nil
                    )
            }
        }
        .buttonStyle(.plain)
        .disabled(!dayInfo.isCurrentMonth)
    }
    
    // MARK: - Helpers for Grid Computation
    
    struct CalendarDayInfo: Hashable {
        let dayNumber: Int
        let isCurrentMonth: Bool
    }
    
    private func computeGridDays() -> [CalendarDayInfo] {
        var result: [CalendarDayInfo] = []
        
        let daysInCurrentMonth = getDaysInMonth(for: currentMonthDate)
        let firstWeekday = getFirstWeekdayOfMonth(for: currentMonthDate) // 1 = Sun, 7 = Sat
        let leadingDaysCount = max(0, firstWeekday - 1)
        
        // Previous month days
        if leadingDaysCount > 0, let prevMonthDate = calendar.date(byAdding: .month, value: -1, to: currentMonthDate) {
            let daysInPrevMonth = getDaysInMonth(for: prevMonthDate)
            let startDay = daysInPrevMonth - leadingDaysCount + 1
            if startDay <= daysInPrevMonth {
                for d in startDay...daysInPrevMonth {
                    result.append(CalendarDayInfo(dayNumber: d, isCurrentMonth: false))
                }
            }
        }
        
        // Current month days
        for d in 1...daysInCurrentMonth {
            result.append(CalendarDayInfo(dayNumber: d, isCurrentMonth: true))
        }
        
        // Trailing days from next month to complete standard calendar grid (multiple of 7)
        let currentTotal = result.count
        let minTarget = currentTotal > 35 ? 42 : 35
        let neededTrailing = minTarget - currentTotal
        if neededTrailing > 0 {
            for d in 1...neededTrailing {
                result.append(CalendarDayInfo(dayNumber: d, isCurrentMonth: false))
            }
        }
        
        return result
    }
    
    private var shortMonthString: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM"
        return formatter.string(from: currentMonthDate)
    }
    
    private var shortYearString: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yy"
        return formatter.string(from: currentMonthDate)
    }
    
    private func monthName(_ m: Int) -> String {
        let f = DateFormatter()
        f.dateFormat = "MMM"
        var comp = DateComponents()
        comp.month = m
        comp.day = 1
        let d = calendar.date(from: comp) ?? Date()
        return f.string(from: d)
    }
    
    private func setMonth(_ m: Int) {
        var comp = calendar.dateComponents([.year], from: currentMonthDate)
        comp.month = m
        comp.day = 1
        if let d = calendar.date(from: comp) {
            currentMonthDate = d
        }
    }
    
    private func setYear(_ y: Int) {
        var comp = calendar.dateComponents([.month], from: currentMonthDate)
        comp.year = y
        comp.day = 1
        if let d = calendar.date(from: comp) {
            currentMonthDate = d
        }
    }
    
    private func changeMonth(by value: Int) {
        if let newDate = calendar.date(byAdding: .month, value: value, to: currentMonthDate) {
            currentMonthDate = newDate
        }
    }
    
    private func getDaysInMonth(for date: Date) -> Int {
        let range = calendar.range(of: .day, in: .month, for: date)!
        return range.count
    }
    
    private func getFirstWeekdayOfMonth(for date: Date) -> Int {
        var components = calendar.dateComponents([.year, .month], from: date)
        components.day = 1
        let firstDay = calendar.date(from: components)!
        return calendar.component(.weekday, from: firstDay)
    }
    
    private func isTodayDate(day: Int) -> Bool {
        let now = Date()
        let compNow = calendar.dateComponents([.year, .month, .day], from: now)
        let compCurrent = calendar.dateComponents([.year, .month], from: currentMonthDate)
        return compNow.year == compCurrent.year &&
               compNow.month == compCurrent.month &&
               compNow.day == day
    }
}

// MARK: - Recurring Date Detail Popup (The Pop-up Window)

struct RecurringDateDetailPopup: View {
    let day: Int
    let monthDate: Date
    @ObservedObject var store: RecurringExpenseStore
    var onDismiss: () -> Void
    
    @State private var showAddExpense = false
    
    private let calendar = Calendar.current
    
    private var matchingExpenses: [RecurringExpenseItem] {
        store.items.filter { $0.dayOfMonth == day }
    }
    
    private var fullDateString: String {
        var comp = calendar.dateComponents([.year, .month], from: monthDate)
        comp.day = day
        if let date = calendar.date(from: comp) {
            let f = DateFormatter()
            f.dateFormat = "EEEE, d MMMM yyyy"
            return f.string(from: date)
        }
        return "Day \(day)"
    }
    
    private var cycleDateKey: String {
        let comp = calendar.dateComponents([.year, .month], from: monthDate)
        return String(format: "%04d-%02d-%02d", comp.year ?? 2026, comp.month ?? 10, day)
    }
    
    var body: some View {
        NavigationStack {
            ZStack {
                Color.stsCardBackground.ignoresSafeArea()
                
                ScrollView(.vertical, showsIndicators: false) {
                    VStack(alignment: .leading, spacing: 20) {
                        // Date Header Banner
                        headerBanner
                        
                        if matchingExpenses.isEmpty {
                            emptyDateView
                        } else {
                            // List each recurring expense on this date with full follow history
                            ForEach(matchingExpenses) { expense in
                                expenseCardWithHistory(expense)
                            }
                        }
                        
                        Color.clear.frame(height: 30)
                    }
                    .padding(20)
                }
                .scrollBounceBehavior(.always, axes: .vertical)
            }
            .navigationTitle("Recurring Expenses")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        onDismiss()
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .font(.title3)
                            .foregroundStyle(.stsSecondary)
                    }
                }
            }
        }
        .sheet(isPresented: $showAddExpense) {
            AddRecurringExpenseSheet(store: store, preselectedDay: day) {
                showAddExpense = false
            }
            .presentationDetents([.medium, .large])
            .presentationDragIndicator(.visible)
            .presentationBackground(Color.stsCardBackground)
        }
    }
    
    // MARK: - Header Banner
    private var headerBanner: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Text(fullDateString)
                    .font(.stsHeadline)
                    .foregroundStyle(.stsPrimary)
                
                Spacer()
                
                if !matchingExpenses.isEmpty {
                    Text("\(matchingExpenses.count) due")
                        .font(.system(size: 11, weight: .bold))
                        .foregroundStyle(.stsAccent)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(Color.stsAccent.opacity(0.15))
                        .clipShape(Capsule())
                }
            }
            
            Text("Scheduled subscriptions, utilities, and recurring bills for this day.")
                .font(.stsCaption)
                .foregroundStyle(.stsSecondary)
        }
        .padding(.bottom, 4)
    }
    
    // MARK: - Expense Card with History of Times Followed
    private func expenseCardWithHistory(_ expense: RecurringExpenseItem) -> some View {
        let isPaidThisMonth = expense.history.contains { $0.cycleDate == cycleDateKey && $0.isPaid }
        
        return VStack(alignment: .leading, spacing: 14) {
            // Top: Icon + Name + Amount + Paid Pill
            HStack(spacing: 14) {
                RecurringBrandIconView(brandKey: expense.brandKey, size: 48, showBackground: true)
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(expense.name)
                        .font(.stsHeadline)
                        .foregroundStyle(.stsPrimary)
                    
                    HStack(spacing: 6) {
                        Text(expense.category)
                            .font(.stsSmall)
                            .foregroundStyle(.stsSecondary)
                        
                        Text("•")
                            .font(.caption)
                            .foregroundStyle(.stsTertiary)
                        
                        Text(expense.cadence.capitalized)
                            .font(.stsSmall)
                            .foregroundStyle(.stsSecondary)
                    }
                }
                
                Spacer()
                
                VStack(alignment: .trailing, spacing: 4) {
                    Text(expense.amountPaise.toRupees)
                        .font(.stsHeadline)
                        .foregroundStyle(.stsPrimary)
                    
                    if isPaidThisMonth {
                        HStack(spacing: 4) {
                            Image(systemName: "checkmark.circle.fill")
                            Text("Paid")
                        }
                        .font(.system(size: 11, weight: .semibold))
                        .foregroundStyle(.stsAccent)
                    } else {
                        HStack(spacing: 4) {
                            Image(systemName: "clock.fill")
                            Text("Upcoming")
                        }
                        .font(.system(size: 11, weight: .semibold))
                        .foregroundStyle(.stsWarning)
                    }
                }
            }
            
            Divider()
                .background(Color.stsTertiary.opacity(0.3))
            
            // MARK: - Followed History Statistics & Times Followed Badge
            VStack(alignment: .leading, spacing: 10) {
                HStack {
                    HStack(spacing: 6) {
                        Image(systemName: "flame.fill")
                            .font(.caption)
                            .foregroundStyle(.stsWarning)
                        
                        Text("Followed \(expense.timesFollowed) times")
                            .font(.system(size: 13, weight: .bold))
                            .foregroundStyle(.stsPrimary)
                    }
                    
                    Spacer()
                    
                    Text("Streak: \(expense.streakCount) cycles")
                        .font(.stsSmall)
                        .foregroundStyle(.stsAccent)
                }
                
                // Lifetime summary badge
                HStack {
                    Text("Total paid across all cycles:")
                        .font(.stsSmall)
                        .foregroundStyle(.stsSecondary)
                    
                    Spacer()
                    
                    Text(expense.totalAmountPaidPaise.toRupees)
                        .font(.system(size: 12, weight: .bold))
                        .foregroundStyle(.stsPrimary)
                }
                .padding(10)
                .background(Color.stsElevated)
                .clipShape(RoundedRectangle(cornerRadius: 8))
                
                // History timeline / occurrences
                if !expense.history.isEmpty {
                    Text("History Log")
                        .font(.system(size: 11, weight: .semibold))
                        .foregroundStyle(.stsTertiary)
                        .padding(.top, 4)
                    
                    VStack(spacing: 6) {
                        ForEach(expense.history.sorted(by: { $0.cycleDate > $1.cycleDate })) { record in
                            HStack {
                                HStack(spacing: 6) {
                                    Circle()
                                        .fill(record.isPaid ? Color.stsAccent : Color.stsWarning)
                                        .frame(width: 6, height: 6)
                                    
                                    Text(formatHistoryDate(record.cycleDate))
                                        .font(.stsCaption)
                                        .foregroundStyle(.stsSecondary)
                                }
                                
                                Spacer()
                                
                                Text(record.amountPaise.toRupees)
                                    .font(.stsCaption)
                                    .foregroundStyle(.stsPrimary)
                                
                                HStack(spacing: 3) {
                                    if record.isPaid {
                                        Image(systemName: "checkmark")
                                            .font(.system(size: 8, weight: .bold))
                                    }
                                    Text(record.isPaid ? "Paid" : "Due")
                                        .font(.system(size: 10, weight: .bold))
                                }
                                .foregroundStyle(record.isPaid ? .stsAccent : .stsWarning)
                                .padding(.horizontal, 6)
                                .padding(.vertical, 2)
                                .background(
                                    (record.isPaid ? Color.stsAccent : Color.stsWarning).opacity(0.15)
                                )
                                .clipShape(Capsule())
                            }
                            .padding(.vertical, 4)
                        }
                    }
                }
            }
            
            // Mark Paid Button (if not already paid for this cycle)
            if !isPaidThisMonth {
                Button {
                    store.markPaid(itemId: expense.id, forDate: cycleDateKey)
                } label: {
                    HStack {
                        Image(systemName: "checkmark.circle.fill")
                        Text("Mark Paid for this Cycle")
                    }
                    .font(.system(size: 13, weight: .bold))
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 10)
                    .background(Color.stsAccent)
                    .clipShape(RoundedRectangle(cornerRadius: 10))
                }
                .padding(.top, 4)
            }
        }
        .padding(16)
        .background(Color.stsElevated.opacity(0.6))
        .clipShape(RoundedRectangle(cornerRadius: 14))
        .overlay(
            RoundedRectangle(cornerRadius: 14)
                .stroke(Color.stsTertiary.opacity(0.3), lineWidth: 1)
        )
    }
    
    // MARK: - Empty State for Day
    private var emptyDateView: some View {
        VStack(spacing: 16) {
            Image(systemName: "calendar.badge.plus")
                .font(.system(size: 40))
                .foregroundStyle(.stsTertiary)
                .padding(.top, 20)
            
            VStack(spacing: 6) {
                Text("No Recurring Expenses Scheduled")
                    .font(.stsHeadline)
                    .foregroundStyle(.stsPrimary)
                
                Text("You don't have any subscription or bill set for day \(day). Would you like to schedule one?")
                    .font(.stsCaption)
                    .foregroundStyle(.stsSecondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 20)
            }
            
            Button {
                showAddExpense = true
            } label: {
                HStack(spacing: 6) {
                    Image(systemName: "plus")
                    Text("Add Expense for Day \(day)")
                }
                .font(.system(size: 13, weight: .bold))
                .foregroundStyle(.white)
                .padding(.horizontal, 16)
                .padding(.vertical, 10)
                .background(Color.stsAccent)
                .clipShape(Capsule())
            }
            .padding(.top, 8)
        }
        .frame(maxWidth: .infinity)
        .padding(24)
        .background(Color.stsElevated.opacity(0.4))
        .clipShape(RoundedRectangle(cornerRadius: 14))
    }
    
    private func formatHistoryDate(_ dateStr: String) -> String {
        let f = DateFormatter()
        f.dateFormat = "yyyy-MM-dd"
        guard let d = f.date(from: dateStr) else { return dateStr }
        f.dateFormat = "MMM yyyy"
        return f.string(from: d)
    }
}

// MARK: - Add Recurring Expense Sheet

struct AddRecurringExpenseSheet: View {
    @ObservedObject var store: RecurringExpenseStore
    var preselectedDay: Int = 1
    var onComplete: () -> Void
    
    @Environment(\.dismiss) var dismiss
    
    @State private var name = ""
    @State private var amount = ""
    @State private var dayOfMonth = 1
    @State private var cadence = "monthly"
    @State private var brandKey = "spotify"
    
    private let brands: [(key: String, label: String)] = [
        ("spotify", "Spotify"),
        ("house", "Rent"),
        ("youtube", "YouTube"),
        ("google", "Google"),
        ("cleaning", "Cleaning"),
        ("claude", "Claude AI"),
        ("netflix", "Netflix"),
        ("fees", "Fees"),
        ("wifi", "Wi-Fi"),
        ("gym", "Gym"),
        ("apple", "Apple"),
        ("generic", "Other")
    ]
    
    private let cadences = ["monthly", "quarterly", "yearly"]
    
    init(store: RecurringExpenseStore, preselectedDay: Int = 1, onComplete: @escaping () -> Void) {
        self.store = store
        self.preselectedDay = preselectedDay
        self.onComplete = onComplete
        _dayOfMonth = State(initialValue: preselectedDay)
    }
    
    var body: some View {
        NavigationStack {
            ZStack {
                Color.stsCardBackground.ignoresSafeArea()
                
                ScrollView(.vertical, showsIndicators: false) {
                    VStack(spacing: 16) {
                        // Brand Presets
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Select Brand / Service")
                                .font(.stsCaption)
                                .foregroundStyle(.stsSecondary)
                            
                            ScrollView(.horizontal, showsIndicators: false) {
                                HStack(spacing: 10) {
                                    ForEach(brands, id: \.key) { b in
                                        Button {
                                            brandKey = b.key
                                            if name.isEmpty || brands.map({ $0.label }).contains(name) {
                                                name = b.label
                                            }
                                        } label: {
                                            HStack(spacing: 6) {
                                                RecurringBrandIconView(brandKey: b.key, size: 18)
                                                Text(b.label)
                                                    .font(.system(size: 12, weight: .semibold))
                                                    .foregroundStyle(brandKey == b.key ? .white : .stsSecondary)
                                            }
                                            .padding(.horizontal, 12)
                                            .padding(.vertical, 8)
                                            .background(brandKey == b.key ? Color.stsElevated : Color.clear)
                                            .clipShape(Capsule())
                                            .overlay(
                                                Capsule()
                                                    .stroke(
                                                        brandKey == b.key ? Color.stsAccent : Color.stsTertiary.opacity(0.4),
                                                        lineWidth: 1
                                                    )
                                            )
                                        }
                                    }
                                }
                            }
                        }
                        
                        // Name
                        VStack(alignment: .leading, spacing: 6) {
                            Text("Expense / Subscription Name")
                                .font(.stsCaption)
                                .foregroundStyle(.stsSecondary)
                            
                            TextField("e.g. Spotify, House Rent, YouTube Premium", text: $name)
                                .font(.stsBody)
                                .foregroundStyle(.stsPrimary)
                                .padding(14)
                                .background(Color.stsElevated)
                                .clipShape(RoundedRectangle(cornerRadius: 10))
                        }
                        
                        // Amount
                        VStack(alignment: .leading, spacing: 6) {
                            Text("Recurring Amount (₹)")
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
                        
                        // Day of Month
                        VStack(alignment: .leading, spacing: 6) {
                            HStack {
                                Text("Billing Day of Month")
                                    .font(.stsCaption)
                                    .foregroundStyle(.stsSecondary)
                                
                                Spacer()
                                
                                Text("\(dayOfMonth)\(ordinalSuffix(dayOfMonth)) of every month")
                                    .font(.system(size: 12, weight: .bold))
                                    .foregroundStyle(.stsAccent)
                            }
                            
                            Picker("Day of Month", selection: $dayOfMonth) {
                                ForEach(1...31, id: \.self) { d in
                                    Text("\(d)\(ordinalSuffix(d))").tag(d)
                                }
                            }
                            .pickerStyle(.wheel)
                            .frame(height: 100)
                            .background(Color.stsElevated)
                            .clipShape(RoundedRectangle(cornerRadius: 10))
                        }
                        
                        // Cadence
                        VStack(alignment: .leading, spacing: 6) {
                            Text("Cadence")
                                .font(.stsCaption)
                                .foregroundStyle(.stsSecondary)
                            
                            HStack(spacing: 8) {
                                ForEach(cadences, id: \.self) { c in
                                    Button {
                                        cadence = c
                                    } label: {
                                        Text(c.capitalized)
                                            .font(.stsCaption)
                                            .foregroundStyle(cadence == c ? .white : .stsSecondary)
                                            .frame(maxWidth: .infinity)
                                            .padding(.vertical, 10)
                                            .background(cadence == c ? Color.stsAccent : Color.stsElevated)
                                            .clipShape(RoundedRectangle(cornerRadius: 8))
                                    }
                                }
                            }
                        }
                        
                        // Save Button
                        Button {
                            guard let val = Double(amount), !name.isEmpty else { return }
                            let newItem = RecurringExpenseItem(
                                name: name.trimmingCharacters(in: .whitespacesAndNewlines),
                                amountPaise: Int(val * 100),
                                dayOfMonth: dayOfMonth,
                                cadence: cadence,
                                category: brandKey.capitalized,
                                brandKey: brandKey,
                                history: [
                                    RecurringPaymentRecord(
                                        cycleDate: String(format: "2026-10-%02d", dayOfMonth),
                                        amountPaise: Int(val * 100),
                                        isPaid: false
                                    )
                                ],
                                isAutoRenew: true
                            )
                            store.addExpense(newItem)
                            Haptics.notification(.success)
                            onComplete()
                            dismiss()
                        } label: {
                            Text("Save Recurring Expense")
                                .font(.stsHeadline)
                                .foregroundStyle(.white)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 14)
                                .background(Color.stsAccent)
                                .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                        }
                        .disabled(name.isEmpty || amount.isEmpty)
                        .opacity(name.isEmpty || amount.isEmpty ? 0.6 : 1)
                        .padding(.top, 10)
                    }
                    .padding(20)
                }
            }
            .navigationTitle("New Recurring Expense")
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
    
    private func ordinalSuffix(_ n: Int) -> String {
        switch n {
        case 11, 12, 13: return "th"
        default:
            switch n % 10 {
            case 1: return "st"
            case 2: return "nd"
            case 3: return "rd"
            default: return "th"
            }
        }
    }
}
