import SwiftUI

// MARK: - ShapeStyle convenience (so .foregroundStyle(.stsAccent) works)
extension ShapeStyle where Self == Color {
    // Backgrounds
    static var stsBackground: Color { Color(hex: "0A0E1A") }
    static var stsCardBackground: Color { Color(hex: "131B2E") }
    static var stsCardBackgroundLight: Color { Color(hex: "1A2540") }
    static var stsElevated: Color { Color(hex: "1E2A45") }
    
    // Accents
    static var stsAccent: Color { Color(hex: "00D09C") }
    static var stsCyan: Color { Color(hex: "00BCD4") }
    static var stsWarning: Color { Color(hex: "FFB74D") }
    static var stsDanger: Color { Color(hex: "FF5252") }
    static var stsGold: Color { Color(hex: "FFD700") }
    
    // Text
    static var stsPrimary: Color { .white }
    static var stsSecondary: Color { Color(hex: "8B99AE") }
    static var stsTertiary: Color { Color(hex: "5A6578") }
}

// MARK: - Color Palette
/// Design system inspired by the premium dark finance app aesthetic
extension Color {
    // Backgrounds
    static let stsBackground = Color(hex: "0A0E1A")
    static let stsCardBackground = Color(hex: "131B2E")
    static let stsCardBackgroundLight = Color(hex: "1A2540")
    static let stsElevated = Color(hex: "1E2A45")
    
    // Accents
    static let stsAccent = Color(hex: "00D09C")       // Teal/green primary
    static let stsAccentDim = Color(hex: "00D09C").opacity(0.15)
    static let stsCyan = Color(hex: "00BCD4")          // Progress bars
    static let stsWarning = Color(hex: "FFB74D")       // Orange warning
    static let stsDanger = Color(hex: "FF5252")        // Red danger
    static let stsGold = Color(hex: "FFD700")          // Gold highlights
    
    // Text
    static let stsPrimary = Color.white
    static let stsSecondary = Color(hex: "8B99AE")
    static let stsTertiary = Color(hex: "5A6578")
    
    // Gradients
    static let stsGradientStart = Color(hex: "0A0E1A")
    static let stsGradientEnd = Color(hex: "1A0A2E")
    
    // Helpers
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 6:
            (a, r, g, b) = (255, (int >> 16) & 0xFF, (int >> 8) & 0xFF, int & 0xFF)
        case 8:
            (a, r, g, b) = ((int >> 24) & 0xFF, (int >> 16) & 0xFF, (int >> 8) & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (255, 0, 0, 0)
        }
        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue: Double(b) / 255,
            opacity: Double(a) / 255
        )
    }
}

// MARK: - Background Gradient
struct AppBackground: View {
    var body: some View {
        LinearGradient(
            colors: [.stsGradientStart, .stsGradientEnd, .stsGradientStart],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
        .ignoresSafeArea()
    }
}

// MARK: - Card Modifier
struct CardStyle: ViewModifier {
    var padding: CGFloat = 16
    var cornerRadius: CGFloat = 16
    
    func body(content: Content) -> some View {
        content
            .padding(padding)
            .background(Color.stsCardBackground)
            .clipShape(RoundedRectangle(cornerRadius: cornerRadius, style: .continuous))
    }
}

extension View {
    func cardStyle(padding: CGFloat = 16, cornerRadius: CGFloat = 16) -> some View {
        modifier(CardStyle(padding: padding, cornerRadius: cornerRadius))
    }
}

// MARK: - Glassmorphism Card
struct GlassCard: ViewModifier {
    func body(content: Content) -> some View {
        content
            .background(.ultraThinMaterial.opacity(0.4))
            .background(Color.stsCardBackground.opacity(0.6))
            .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .stroke(Color.white.opacity(0.06), lineWidth: 1)
            )
    }
}

extension View {
    func glassCard() -> some View {
        modifier(GlassCard())
    }
}

// MARK: - Shimmer Loading Effect
struct ShimmerEffect: ViewModifier {
    @State private var phase: CGFloat = 0
    
    func body(content: Content) -> some View {
        content
            .overlay(
                LinearGradient(
                    colors: [
                        .clear,
                        Color.white.opacity(0.1),
                        .clear
                    ],
                    startPoint: .leading,
                    endPoint: .trailing
                )
                .offset(x: phase)
                .onAppear {
                    withAnimation(.linear(duration: 1.5).repeatForever(autoreverses: false)) {
                        phase = 400
                    }
                }
            )
            .clipped()
    }
}

extension View {
    func shimmer() -> some View {
        modifier(ShimmerEffect())
    }
}

// MARK: - Typography
extension Font {
    static let stsHeroAmount = Font.system(size: 48, weight: .bold, design: .rounded)
    static let stsLargeTitle = Font.system(size: 28, weight: .bold, design: .rounded)
    static let stsTitle = Font.system(size: 22, weight: .semibold, design: .rounded)
    static let stsHeadline = Font.system(size: 17, weight: .semibold)
    static let stsBody = Font.system(size: 15, weight: .regular)
    static let stsCaption = Font.system(size: 13, weight: .medium)
    static let stsSmall = Font.system(size: 11, weight: .medium)
}

// MARK: - Paise Formatting
extension Int {
    /// Formats paise amount to INR display string
    var toRupees: String {
        let rupees = Double(self) / 100.0
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = "INR"
        formatter.currencySymbol = "₹"
        formatter.maximumFractionDigits = rupees.truncatingRemainder(dividingBy: 1) == 0 ? 0 : 2
        formatter.minimumFractionDigits = 0
        return formatter.string(from: NSNumber(value: rupees)) ?? "₹\(rupees)"
    }
    
    /// Formats to compact rupees (e.g. ₹1.2K)
    var toCompactRupees: String {
        let rupees = Double(self) / 100.0
        if rupees >= 100_000 {
            return String(format: "₹%.1fL", rupees / 100_000)
        } else if rupees >= 1_000 {
            return String(format: "₹%.1fK", rupees / 1_000)
        }
        return "₹\(Int(rupees))"
    }
}

// MARK: - Haptics
struct Haptics {
    static func impact(_ style: UIImpactFeedbackGenerator.FeedbackStyle = .medium) {
        UIImpactFeedbackGenerator(style: style).impactOccurred()
    }
    
    static func notification(_ type: UINotificationFeedbackGenerator.FeedbackType) {
        UINotificationFeedbackGenerator().notificationOccurred(type)
    }
    
    static func selection() {
        UISelectionFeedbackGenerator().selectionChanged()
    }
}
