import SwiftUI

extension Notification.Name {
    static let dataDidUpdate = Notification.Name("com.safetospend.dataDidUpdate")
}

/// App-wide state management
@MainActor
class AppState: ObservableObject {
    @AppStorage("isOnboarded") var isOnboarded: Bool = false
    @Published var todayData: TodayResponse?
    @Published var isLoading: Bool = false
    @Published var error: AppError?
    @Published var dataRevision: Int = 0
    
    private let api = APIClient.shared
    
    func completeOnboarding(_ request: OnboardingCompleteRequest) async {
        isLoading = true
        defer { isLoading = false }
        
        do {
            try await api.completeOnboarding(request)
            isOnboarded = true
            await refreshToday()
        } catch {
            self.error = AppError(message: error.localizedDescription)
        }
    }
    
    func refreshToday() async {
        do {
            let fresh = try await api.getToday()
            self.todayData = fresh
            self.dataRevision += 1
            NotificationCenter.default.post(name: .dataDidUpdate, object: nil)
        } catch {
            self.error = AppError(message: error.localizedDescription)
        }
    }
    
    func refreshAll() async {
        await refreshToday()
    }
    
    func resetOnboarding() {
        isOnboarded = false
        todayData = nil
        dataRevision += 1
    }
}

struct AppError: Identifiable {
    let id = UUID()
    let message: String
}
