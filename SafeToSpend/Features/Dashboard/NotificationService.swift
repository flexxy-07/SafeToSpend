import Foundation
import UserNotifications

/// Handles local notifications for daily expense reminders
@MainActor
final class NotificationService: NSObject, UNUserNotificationCenterDelegate {
    static let shared = NotificationService()
    
    static let reminderIdentifier = "com.safetospend.dailyReminder"
    static let testReminderIdentifier = "com.safetospend.testReminder"
    
    private override init() {
        super.init()
        UNUserNotificationCenter.current().delegate = self
    }
    
    // MARK: - Permission
    
    func requestAuthorization() async -> Bool {
        do {
            let granted = try await UNUserNotificationCenter.current().requestAuthorization(
                options: [.alert, .sound, .badge]
            )
            return granted
        } catch {
            print("Failed to request notification permission: \(error)")
            return false
        }
    }
    
    func authorizationStatus() async -> UNAuthorizationStatus {
        let settings = await UNUserNotificationCenter.current().notificationSettings()
        return settings.authorizationStatus
    }
    
    // MARK: - Scheduling
    
    func scheduleDailyReminder(hour: Int, minute: Int) {
        let center = UNUserNotificationCenter.current()
        center.removePendingNotificationRequests(withIdentifiers: [Self.reminderIdentifier])
        
        let content = UNMutableNotificationContent()
        content.title = "Safe to Spend"
        content.body = "Remember to check your balance and log today's expenses!"
        content.sound = .default
        
        var dateComponents = DateComponents()
        dateComponents.hour = hour
        dateComponents.minute = minute
        
        let trigger = UNCalendarNotificationTrigger(dateMatching: dateComponents, repeats: true)
        let request = UNNotificationRequest(
            identifier: Self.reminderIdentifier,
            content: content,
            trigger: trigger
        )
        
        center.add(request) { error in
            if let error = error {
                print("Failed to schedule daily reminder: \(error)")
            }
        }
    }
    
    func cancelDailyReminder() {
        UNUserNotificationCenter.current().removePendingNotificationRequests(
            withIdentifiers: [Self.reminderIdentifier]
        )
    }
    
    func sendTestNotification(delaySeconds: TimeInterval = 3) async -> Bool {
        let status = await authorizationStatus()
        guard status == .authorized || status == .provisional else {
            let granted = await requestAuthorization()
            guard granted else { return false }
            return await scheduleTest(delay: delaySeconds)
        }
        return await scheduleTest(delay: delaySeconds)
    }
    
    private func scheduleTest(delay: TimeInterval) async -> Bool {
        let center = UNUserNotificationCenter.current()
        let content = UNMutableNotificationContent()
        content.title = "SafeToSpend Daily Reminder"
        content.body = "You have ₹36,084 safe to spend today. Keep up your streak!"
        content.sound = .default
        
        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: max(delay, 1), repeats: false)
        let request = UNNotificationRequest(
            identifier: Self.testReminderIdentifier,
            content: content,
            trigger: trigger
        )
        
        do {
            try await center.add(request)
            return true
        } catch {
            print("Error scheduling test notification: \(error)")
            return false
        }
    }
    
    // MARK: - UNUserNotificationCenterDelegate
    
    // Allow notifications to display as banners even when app is in the foreground
    nonisolated func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        willPresent notification: UNNotification,
        withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void
    ) {
        completionHandler([.banner, .sound, .badge])
    }
}
