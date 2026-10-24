import Foundation
import LocalAuthentication

/// Manages biometric authentication and local data security
@MainActor
final class SecurityManager: ObservableObject {
    static let shared = SecurityManager()
    
    @Published var isUnlocked: Bool = true
    
    private init() {}
    
    // MARK: - Biometrics Info
    
    enum BiometricType {
        case faceID
        case touchID
        case opticID
        case passcodeOnly
        case none
        
        var title: String {
            switch self {
            case .faceID: return "Face ID"
            case .touchID: return "Touch ID"
            case .opticID: return "Optic ID"
            case .passcodeOnly: return "Passcode"
            case .none: return "Biometrics Unavailable"
            }
        }
        
        var iconName: String {
            switch self {
            case .faceID: return "faceid"
            case .touchID: return "touchid"
            case .opticID: return "eye"
            case .passcodeOnly: return "lock.fill"
            case .none: return "lock.slash"
            }
        }
    }
    
    var biometryType: BiometricType {
        let context = LAContext()
        var error: NSError?
        
        if context.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: &error) {
            switch context.biometryType {
            case .faceID: return .faceID
            case .touchID: return .touchID
            case .opticID: return .opticID
            case .none: return .none
            @unknown default: return .none
            }
        } else if context.canEvaluatePolicy(.deviceOwnerAuthentication, error: &error) {
            return .passcodeOnly
        } else {
            return .none
        }
    }
    
    // MARK: - Authentication
    
    func authenticate(reason: String = "Authenticate to access SafeToSpend") async -> (success: Bool, error: String?) {
        let context = LAContext()
        context.localizedCancelTitle = "Cancel"
        
        var authError: NSError?
        let policy: LAPolicy = context.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: &authError)
            ? .deviceOwnerAuthenticationWithBiometrics
            : .deviceOwnerAuthentication
        
        guard context.canEvaluatePolicy(policy, error: &authError) else {
            return (false, authError?.localizedDescription ?? "Authentication unavailable on this device")
        }
        
        do {
            let success = try await context.evaluatePolicy(policy, localizedReason: reason)
            if success {
                self.isUnlocked = true
                return (true, nil)
            } else {
                return (false, "Authentication was not successful")
            }
        } catch {
            return (false, error.localizedDescription)
        }
    }
    
    // MARK: - Cache & Storage Maintenance
    
    func getTemporaryCacheSize() -> String {
        let fileManager = FileManager.default
        let tempDir = fileManager.temporaryDirectory
        guard let files = try? fileManager.contentsOfDirectory(at: tempDir, includingPropertiesForKeys: [.fileSizeKey], options: []) else {
            return "0 KB"
        }
        
        var totalBytes: Int64 = 0
        for file in files {
            if let attrs = try? fileManager.attributesOfItem(atPath: file.path),
               let size = attrs[.size] as? Int64 {
                totalBytes += size
            }
        }
        
        let formatter = ByteCountFormatter()
        formatter.allowedUnits = [.useKB, .useMB]
        formatter.countStyle = .file
        return formatter.string(fromByteCount: totalBytes)
    }
    
    func clearTemporaryCache() -> String {
        let fileManager = FileManager.default
        let tempDir = fileManager.temporaryDirectory
        guard let files = try? fileManager.contentsOfDirectory(at: tempDir, includingPropertiesForKeys: nil, options: []) else {
            return "0 KB cleared"
        }
        
        var deletedCount = 0
        for file in files {
            do {
                try fileManager.removeItem(at: file)
                deletedCount += 1
            } catch {
                // Continue cleaning other files
            }
        }
        
        return "\(deletedCount) files cleaned"
    }
}
