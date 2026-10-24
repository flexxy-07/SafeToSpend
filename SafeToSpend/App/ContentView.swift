import SwiftUI
import LocalAuthentication

struct ContentView: View {
    @EnvironmentObject var appState: AppState
    @Environment(\.scenePhase) private var scenePhase
    
    @AppStorage("biometricLockEnabled") private var isBiometricLockEnabled = false
    @State private var isUnlocked = true
    @State private var isAuthenticating = false
    
    var body: some View {
        ZStack {
            Group {
                if appState.isOnboarded {
                    MainTabView()
                } else {
                    OnboardingView()
                }
            }
            .animation(.easeInOut(duration: 0.3), value: appState.isOnboarded)
            
            // Biometric Lock Overlay
            if isBiometricLockEnabled && !isUnlocked {
                lockOverlayView
                    .transition(.opacity)
                    .zIndex(999)
            }
        }
        .onAppear {
            if isBiometricLockEnabled {
                isUnlocked = false
                triggerUnlock()
            }
        }
        .onChange(of: scenePhase) { newPhase in
            if newPhase == .background && isBiometricLockEnabled {
                isUnlocked = false
            } else if newPhase == .active && isBiometricLockEnabled && !isUnlocked {
                triggerUnlock()
            }
        }
    }
    
    private var lockOverlayView: some View {
        ZStack {
            Color.stsCardBackground.ignoresSafeArea()
            
            VStack(spacing: 24) {
                Spacer()
                
                MascotAvatarView(mascot: .ryo, size: 76)
                
                VStack(spacing: 6) {
                    Text("SafeToSpend Locked")
                        .font(.stsTitle)
                        .foregroundStyle(.stsPrimary)
                    
                    Text("Biometric authentication required to view financial balance and transactions.")
                        .font(.stsSmall)
                        .foregroundStyle(.stsSecondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 32)
                }
                
                Spacer()
                
                Button {
                    triggerUnlock()
                } label: {
                    HStack(spacing: 10) {
                        if isAuthenticating {
                            ProgressView()
                                .tint(.white)
                        } else {
                            Image(systemName: "faceid")
                                .font(.title3)
                            Text("Unlock SafeToSpend")
                                .font(.stsHeadline)
                        }
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                    .background(Color.stsAccent)
                    .foregroundStyle(.white)
                    .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                }
                .disabled(isAuthenticating)
                .padding(.horizontal, 24)
                .padding(.bottom, 36)
            }
        }
    }
    
    private func triggerUnlock() {
        guard !isAuthenticating else { return }
        isAuthenticating = true
        Task {
            let result = await SecurityManager.shared.authenticate(reason: "Unlock SafeToSpend")
            isAuthenticating = false
            if result.success {
                withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                    isUnlocked = true
                }
            }
        }
    }
}

#Preview {
    ContentView()
        .environmentObject(AppState())
}
