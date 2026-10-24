import SwiftUI
import UserNotifications

struct DailyReminderSheet: View {
    @Environment(\.dismiss) var dismiss
    
    @AppStorage("dailyReminderEnabled") private var isReminderEnabled: Bool = false
    @AppStorage("dailyReminderHour") private var reminderHour: Int = 21
    @AppStorage("dailyReminderMinute") private var reminderMinute: Int = 0
    
    @State private var reminderDate: Date = {
        var components = DateComponents()
        components.hour = 21
        components.minute = 0
        return Calendar.current.date(from: components) ?? Date()
    }()
    
    @State private var isPermissionDenied = false
    @State private var testSentMessage: String?
    @State private var isSendingTest = false
    
    var body: some View {
        ZStack {
            Color.stsCardBackground.ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 20) {
                        // Master Toggle Card
                        VStack(spacing: 16) {
                            HStack {
                                Image(systemName: "bell.badge.fill")
                                    .font(.title2)
                                    .foregroundStyle(isReminderEnabled ? .stsAccent : .stsSecondary)
                                    .frame(width: 44, height: 44)
                                    .background((isReminderEnabled ? Color.stsAccent : Color.stsSecondary).opacity(0.12))
                                    .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                                
                                VStack(alignment: .leading, spacing: 2) {
                                    Text("Daily Reminder")
                                        .font(.stsHeadline)
                                        .foregroundStyle(.stsPrimary)
                                    
                                    Text(isReminderEnabled ? "Scheduled for \(formattedTime)" : "Disabled")
                                        .font(.stsSmall)
                                        .foregroundStyle(isReminderEnabled ? .stsAccent : .stsTertiary)
                                }
                                
                                Spacer()
                                
                                Toggle("", isOn: Binding(
                                    get: { isReminderEnabled },
                                    set: { newValue in
                                        handleToggle(newValue)
                                    }
                                ))
                                .labelsHidden()
                                .tint(.stsAccent)
                            }
                            
                            if isReminderEnabled {
                                Divider()
                                    .background(Color.stsBorder)
                                
                                HStack {
                                    Text("Reminder Time")
                                        .font(.stsBody)
                                        .foregroundStyle(.stsPrimary)
                                    
                                    Spacer()
                                    
                                    DatePicker(
                                        "",
                                        selection: $reminderDate,
                                        displayedComponents: .hourAndMinute
                                    )
                                    .labelsHidden()
                                    .colorScheme(.dark)
                                    .tint(.stsAccent)
                                    .onChange(of: reminderDate) { newDate in
                                        let cal = Calendar.current
                                        reminderHour = cal.component(.hour, from: newDate)
                                        reminderMinute = cal.component(.minute, from: newDate)
                                        NotificationService.shared.scheduleDailyReminder(
                                            hour: reminderHour,
                                            minute: reminderMinute
                                        )
                                    }
                                }
                            }
                        }
                        .padding(18)
                        .background(Color.stsElevated)
                        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                        .overlay(
                            RoundedRectangle(cornerRadius: 16, style: .continuous)
                                .stroke(Color.stsBorder, lineWidth: 1)
                        )
                        
                        // Notification Preview Card
                        VStack(alignment: .leading, spacing: 12) {
                            Text("PREVIEW NOTIFICATION")
                                .font(.stsCaption)
                                .foregroundStyle(.stsSecondary)
                            
                            HStack(alignment: .top, spacing: 12) {
                                MascotAvatarView(mascot: .ryo, size: 36, showGlow: false)
                                
                                VStack(alignment: .leading, spacing: 4) {
                                    HStack {
                                        Text("Safe to Spend")
                                            .font(.caption)
                                            .fontWeight(.bold)
                                            .foregroundStyle(.stsPrimary)
                                        Spacer()
                                        Text("now")
                                            .font(.caption2)
                                            .foregroundStyle(.stsTertiary)
                                    }
                                    
                                    Text("Remember to check your balance and log today's expenses!")
                                        .font(.stsSmall)
                                        .foregroundStyle(.stsSecondary)
                                        .lineLimit(2)
                                }
                            }
                            .padding(14)
                            .background(Color.stsCardBackground)
                            .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                            .overlay(
                                RoundedRectangle(cornerRadius: 12, style: .continuous)
                                    .stroke(Color.stsBorder, lineWidth: 1)
                            )
                        }
                        .padding(18)
                        .background(Color.stsElevated)
                        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                        .overlay(
                            RoundedRectangle(cornerRadius: 16, style: .continuous)
                                .stroke(Color.stsBorder, lineWidth: 1)
                        )
                        
                        // Test Button
                        Button {
                            sendTestNotification()
                        } label: {
                            HStack(spacing: 8) {
                                if isSendingTest {
                                    ProgressView()
                                        .tint(.white)
                                } else {
                                    Image(systemName: "paperplane.fill")
                                        .font(.subheadline)
                                    Text("Send Test Notification (Fires in 3s)")
                                        .font(.stsBody)
                                        .fontWeight(.semibold)
                                }
                            }
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 14)
                            .background(Color.stsAccent)
                            .foregroundStyle(.white)
                            .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                        }
                        .disabled(isSendingTest)
                        
                        if let testMsg = testSentMessage {
                            HStack(spacing: 8) {
                                Image(systemName: "checkmark.circle.fill")
                                    .foregroundStyle(.stsSuccess)
                                Text(testMsg)
                                    .font(.stsSmall)
                                    .foregroundStyle(.stsSecondary)
                            }
                        }
                        
                        // Tips
                        VStack(alignment: .leading, spacing: 6) {
                            Text("WHY DAILY REMINDERS?")
                                .font(.stsCaption)
                                .foregroundStyle(.stsSecondary)
                            Text("Checking your safe allowance once every evening keeps your spending cadence disciplined and prevents unforeseen budget depletion before payday.")
                                .font(.stsSmall)
                                .foregroundStyle(.stsTertiary)
                        }
                        .padding(16)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(Color.stsCardBackground)
                        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                    }
                    .padding(20)
                }
            }
            .navigationTitle("Daily Reminders")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") { dismiss() }
                        .foregroundStyle(.stsAccent)
                }
            }
            .alert("Notifications Disabled", isPresented: $isPermissionDenied) {
                Button("Open Settings") {
                    if let url = URL(string: UIApplication.openSettingsURLString) {
                        UIApplication.shared.open(url)
                    }
                }
                Button("Cancel", role: .cancel) { }
            } message: {
                Text("Notifications are disabled for SafeToSpend. Please enable them in your device settings to receive your daily spending reminder.")
            }
            .onAppear {
                syncDateState()
            }
    }
    
    // MARK: - Helpers
    
    private var formattedTime: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "h:mm a"
        return formatter.string(from: reminderDate)
    }
    
    private func syncDateState() {
        var comp = DateComponents()
        comp.hour = reminderHour
        comp.minute = reminderMinute
        if let d = Calendar.current.date(from: comp) {
            reminderDate = d
        }
    }
    
    private func handleToggle(_ enabled: Bool) {
        if enabled {
            Task {
                let status = await NotificationService.shared.authorizationStatus()
                if status == .denied {
                    isPermissionDenied = true
                    isReminderEnabled = false
                    return
                }
                
                let granted = await NotificationService.shared.requestAuthorization()
                if granted {
                    isReminderEnabled = true
                    NotificationService.shared.scheduleDailyReminder(
                        hour: reminderHour,
                        minute: reminderMinute
                    )
                } else {
                    isPermissionDenied = true
                    isReminderEnabled = false
                }
            }
        } else {
            isReminderEnabled = false
            NotificationService.shared.cancelDailyReminder()
        }
    }
    
    private func sendTestNotification() {
        isSendingTest = true
        Task {
            let ok = await NotificationService.shared.sendTestNotification(delaySeconds: 3)
            isSendingTest = false
            if ok {
                testSentMessage = "Test scheduled! Banner will arrive in 3 seconds."
            } else {
                isPermissionDenied = true
            }
        }
    }
}
