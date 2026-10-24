import SwiftUI
import LocalAuthentication

struct PrivacySecuritySheet: View {
    @Environment(\.dismiss) var dismiss
    
    @AppStorage("biometricLockEnabled") private var isBiometricLockEnabled: Bool = false
    @AppStorage("hideValuesInSwitcher") private var hideValuesInSwitcher: Bool = true
    
    @StateObject private var securityManager = SecurityManager.shared
    @State private var authFeedback: String?
    @State private var isAuthenticating = false
    @State private var cacheSize: String = "0 KB"
    @State private var cacheClearedMessage: String?
    
    var body: some View {
        ZStack {
            Color.stsCardBackground.ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 20) {
                        // Biometric Lock Card
                        VStack(spacing: 16) {
                            HStack {
                                Image(systemName: securityManager.biometryType.iconName)
                                    .font(.title2)
                                    .foregroundStyle(isBiometricLockEnabled ? .stsAccent : .stsSecondary)
                                    .frame(width: 44, height: 44)
                                    .background((isBiometricLockEnabled ? Color.stsAccent : Color.stsSecondary).opacity(0.12))
                                    .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                                
                                VStack(alignment: .leading, spacing: 2) {
                                    Text("\(securityManager.biometryType.title) Protection")
                                        .font(.stsHeadline)
                                        .foregroundStyle(.stsPrimary)
                                    
                                    Text(isBiometricLockEnabled ? "Required to open app" : "Off")
                                        .font(.stsSmall)
                                        .foregroundStyle(isBiometricLockEnabled ? .stsAccent : .stsTertiary)
                                }
                                
                                Spacer()
                                
                                Toggle("", isOn: Binding(
                                    get: { isBiometricLockEnabled },
                                    set: { newValue in
                                        handleBiometricToggle(newValue)
                                    }
                                ))
                                .labelsHidden()
                                .tint(.stsAccent)
                            }
                            
                            if isBiometricLockEnabled {
                                Divider()
                                    .background(Color.stsBorder)
                                
                                Button {
                                    testBiometricAuth()
                                } label: {
                                    HStack {
                                        Image(systemName: "checkmark.shield.fill")
                                            .font(.subheadline)
                                        Text("Test \(securityManager.biometryType.title) Authentication")
                                            .font(.stsBody)
                                            .fontWeight(.medium)
                                        Spacer()
                                        if isAuthenticating {
                                            ProgressView()
                                                .tint(.stsAccent)
                                        } else {
                                            Image(systemName: "chevron.right")
                                                .font(.caption)
                                                .foregroundStyle(.stsTertiary)
                                        }
                                    }
                                    .foregroundStyle(.stsAccent)
                                }
                                .disabled(isAuthenticating)
                            }
                        }
                        .padding(18)
                        .background(Color.stsElevated)
                        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                        .overlay(
                            RoundedRectangle(cornerRadius: 16, style: .continuous)
                                .stroke(Color.stsBorder, lineWidth: 1)
                        )
                        
                        if let feedback = authFeedback {
                            HStack(spacing: 8) {
                                Image(systemName: feedback.contains("Success") ? "checkmark.circle.fill" : "exclamationmark.triangle.fill")
                                    .foregroundStyle(feedback.contains("Success") ? .stsSuccess : .stsWarning)
                                Text(feedback)
                                    .font(.stsSmall)
                                    .foregroundStyle(.stsSecondary)
                            }
                            .padding(.horizontal)
                        }
                        
                        // Privacy Architecture Card
                        VStack(alignment: .leading, spacing: 14) {
                            Text("SECURITY ARCHITECTURE")
                                .font(.stsCaption)
                                .foregroundStyle(.stsSecondary)
                            
                            securityPointRow(
                                title: "On-Device Receipt Processing",
                                desc: "Apple Vision OCR runs exclusively on your device. Bill receipts and payment screenshots are never stored in third-party databases.",
                                icon: "cpu"
                            )
                            
                            Divider().background(Color.stsBorder)
                            
                            securityPointRow(
                                title: "Zero Third-Party Trackers",
                                desc: "No advertising SDKs, tracking pixels, or user behavior tracking libraries are embedded in SafeToSpend.",
                                icon: "hand.raised.fill"
                            )
                            
                            Divider().background(Color.stsBorder)
                            
                            securityPointRow(
                                title: "TLS 1.3 Transport Security",
                                desc: "All network requests to the calculation engine use strict HTTPS encryption.",
                                icon: "lock.shield.fill"
                            )
                        }
                        .padding(18)
                        .background(Color.stsElevated)
                        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                        .overlay(
                            RoundedRectangle(cornerRadius: 16, style: .continuous)
                                .stroke(Color.stsBorder, lineWidth: 1)
                        )
                        
                        // Cache and Storage Management
                        VStack(alignment: .leading, spacing: 14) {
                            Text("LOCAL STORAGE & CACHE")
                                .font(.stsCaption)
                                .foregroundStyle(.stsSecondary)
                            
                            HStack {
                                VStack(alignment: .leading, spacing: 2) {
                                    Text("Temporary OCR & Scan Cache")
                                        .font(.stsBody)
                                        .foregroundStyle(.stsPrimary)
                                    Text("Current usage: \(cacheSize)")
                                        .font(.stsSmall)
                                        .foregroundStyle(.stsTertiary)
                                }
                                
                                Spacer()
                                
                                Button {
                                    clearCache()
                                } label: {
                                    Text("Clear Cache")
                                        .font(.stsSmall)
                                        .fontWeight(.semibold)
                                        .padding(.horizontal, 12)
                                        .padding(.vertical, 6)
                                        .background(Color.stsCardBackground)
                                        .foregroundStyle(.stsSecondary)
                                        .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
                                        .overlay(
                                            RoundedRectangle(cornerRadius: 8, style: .continuous)
                                                .stroke(Color.stsBorder, lineWidth: 1)
                                        )
                                }
                            }
                            
                            if let cleared = cacheClearedMessage {
                                Text(cleared)
                                    .font(.stsSmall)
                                    .foregroundStyle(.stsSuccess)
                            }
                        }
                        .padding(18)
                        .background(Color.stsElevated)
                        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                        .overlay(
                            RoundedRectangle(cornerRadius: 16, style: .continuous)
                                .stroke(Color.stsBorder, lineWidth: 1)
                        )
                    }
                    .padding(20)
                }
            }
            .navigationTitle("Privacy & Security")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") { dismiss() }
                        .foregroundStyle(.stsAccent)
                }
            }
            .onAppear {
                updateCacheSize()
            }
    }
    
    // MARK: - Components
    
    private func securityPointRow(title: String, desc: String, icon: String) -> some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: icon)
                .font(.body)
                .foregroundStyle(.stsAccent)
                .frame(width: 28, height: 28)
                .background(Color.stsAccent.opacity(0.12))
                .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
            
            VStack(alignment: .leading, spacing: 3) {
                Text(title)
                    .font(.stsBody)
                    .fontWeight(.medium)
                    .foregroundStyle(.stsPrimary)
                
                Text(desc)
                    .font(.stsSmall)
                    .foregroundStyle(.stsSecondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
    }
    
    // MARK: - Actions
    
    private func handleBiometricToggle(_ enable: Bool) {
        if enable {
            Task {
                isAuthenticating = true
                let result = await securityManager.authenticate(reason: "Verify your identity to enable biometric protection")
                isAuthenticating = false
                if result.success {
                    isBiometricLockEnabled = true
                    authFeedback = "Success: \(securityManager.biometryType.title) enabled"
                } else {
                    isBiometricLockEnabled = false
                    authFeedback = result.error ?? "Authentication failed"
                }
            }
        } else {
            isBiometricLockEnabled = false
            authFeedback = nil
        }
    }
    
    private func testBiometricAuth() {
        isAuthenticating = true
        Task {
            let result = await securityManager.authenticate(reason: "Test authentication for SafeToSpend")
            isAuthenticating = false
            if result.success {
                authFeedback = "Success: Authenticated via \(securityManager.biometryType.title)"
            } else {
                authFeedback = result.error ?? "Authentication failed"
            }
        }
    }
    
    private func updateCacheSize() {
        cacheSize = securityManager.getTemporaryCacheSize()
    }
    
    private func clearCache() {
        let result = securityManager.clearTemporaryCache()
        cacheClearedMessage = "Cleared temporary files (\(result))"
        updateCacheSize()
    }
}
