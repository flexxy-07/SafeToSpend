import SwiftUI

struct ContentView: View {
    @EnvironmentObject var appState: AppState
    
    var body: some View {
        Group {
            if appState.isOnboarded {
                MainTabView()
            } else {
                OnboardingView()
            }
        }
        .animation(.easeInOut(duration: 0.3), value: appState.isOnboarded)
    }
}

#Preview {
    ContentView()
        .environmentObject(AppState())
}
