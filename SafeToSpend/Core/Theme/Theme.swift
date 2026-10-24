import SwiftUI

// =====================================================================
// MARK: - UKIYO-E ANIME ZEN DESIGN TOKENS (LIGHT THEME ONLY)
// =====================================================================

extension Color {
    // MARK: - Sky & Atmosphere
    static let zenSkyTop        = Color(hex: "7FB2E5") // Bright daylight azure
    static let zenSkyMid        = Color(hex: "B9CDF0") // Soft airy cyan-blue
    static let zenSkyDeep       = Color(hex: "3F75A8") // Deep ceremonial azure
    static let zenCloudWhite    = Color(hex: "F6F1FA") // Pristine cloud cumulus
    static let zenMist          = Color(hex: "FBF8FF") // Horizon morning mist
    
    // MARK: - Cherry Blossom
    static let zenBlossomPink   = Color(hex: "E58AC9") // Vibrant sakura petal
    static let zenBlossomSoft   = Color(hex: "F6D3EA") // Soft blossom tint
    static let zenBlossomDeep   = Color(hex: "B24A9A") // Deep ceremonial orchid
    
    // MARK: - Crimson (Spending, Primary CTA, Dragon Akai)
    static let zenCrimson       = Color(hex: "C8323C") // Lacquered samurai armor crimson
    static let zenCrimsonDark   = Color(hex: "8E1F2B") // Deep shadow crimson
    static let zenCrimsonGlow   = Color(hex: "C8323C").opacity(0.18)
    
    // MARK: - Jade (Savings, Growth, Dragon Midori)
    static let zenJade          = Color(hex: "3FAE7A") // imperial tranquil jade
    static let zenJadeDark      = Color(hex: "1F6B4C") // Mountain pine jade
    static let zenJadeGlow      = Color(hex: "3FAE7A").opacity(0.18)
    
    // MARK: - Gold (Honor, Highlights, Trim)
    static let zenGold          = Color(hex: "E8B84A") // Gilded armor leaf
    static let zenGoldDeep      = Color(hex: "B88A1E") // Antique bronze gold for high contrast text
    static let zenGoldGlow      = Color(hex: "E8B84A").opacity(0.25)
    
    // MARK: - Ink & Calligraphy (Typography)
    static let zenInk           = Color(hex: "2A1624") // Deep sumi-e ink with warm plum undertone (WCAG AAA)
    static let zenPlumGrey      = Color(hex: "5E4A66") // Plum mist secondary text (WCAG AA)
    static let zenLavenderGrey  = Color(hex: "9A93B5") // Soft mountain heather tertiary text
    
    // MARK: - Glass Surfaces (Light Mode)
    static let zenGlassFill     = Color.white.opacity(0.60) // Plain translucent white wash
    static let zenGlassElevated = Color.white.opacity(0.78) // Elevated cards
    static let zenGlassBorder   = Color.white.opacity(0.85) // High-specular top border
    static let zenPlumBorder    = Color(hex: "2A1624").opacity(0.06) // 1px plum defining border
    static let zenShadow        = Color(hex: "2A1624").opacity(0.10) // Soft plum-tinted drop shadow
    
    // MARK: - Semantic Tokens
    static let zenIncome        = zenJade
    static let zenExpense       = zenCrimson
    static let zenWarning       = zenGoldDeep
    static let zenNeutral       = zenLavenderGrey
    
    // =================================================================
    // MARK: - Backward Compatibility Bridge (maps legacy .sts to Zen)
    // =================================================================
    static let stsBackground         = zenMist
    static let stsCardBackground     = Color.white.opacity(0.62)
    static let stsCardBackgroundLight = Color.white.opacity(0.78)
    static let stsElevated           = Color.white.opacity(0.82)
    static let stsBorder             = zenPlumBorder
    
    static let stsAccent             = zenCrimson
    static let stsAccentDim          = zenCrimson.opacity(0.14)
    static let stsCyan               = zenSkyTop
    static let stsWarning            = zenGoldDeep
    static let stsDanger             = zenCrimson
    static let stsGold               = zenGold
    static let stsSuccess            = zenJade
    
    static let stsPrimary            = zenInk
    static let stsSecondary          = zenPlumGrey
    static let stsTertiary           = zenLavenderGrey
    
    static let stsGradientStart      = zenSkyTop
    static let stsGradientEnd        = zenMist
    
    // Hex Initializer
    init(hex: String) {
        let hexClean = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hexClean).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hexClean.count {
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

// MARK: - ShapeStyle Extensions
extension ShapeStyle where Self == Color {
    static var zenSkyTop: Color        { Color.zenSkyTop }
    static var zenSkyMid: Color        { Color.zenSkyMid }
    static var zenSkyDeep: Color       { Color.zenSkyDeep }
    static var zenCloudWhite: Color    { Color.zenCloudWhite }
    static var zenMist: Color          { Color.zenMist }
    static var zenBlossomPink: Color   { Color.zenBlossomPink }
    static var zenCrimson: Color       { Color.zenCrimson }
    static var zenCrimsonDark: Color   { Color.zenCrimsonDark }
    static var zenJade: Color          { Color.zenJade }
    static var zenJadeDark: Color      { Color.zenJadeDark }
    static var zenGold: Color          { Color.zenGold }
    static var zenGoldDeep: Color      { Color.zenGoldDeep }
    static var zenInk: Color           { Color.zenInk }
    static var zenPlumGrey: Color      { Color.zenPlumGrey }
    static var zenLavenderGrey: Color  { Color.zenLavenderGrey }
    
    // Legacy ShapeStyle support
    static var stsBackground: Color    { Color.zenMist }
    static var stsCardBackground: Color{ Color.white.opacity(0.62) }
    static var stsCardBackgroundLight: Color { Color.white.opacity(0.78) }
    static var stsElevated: Color      { Color.white.opacity(0.82) }
    static var stsBorder: Color        { Color.zenPlumBorder }
    static var stsAccent: Color        { Color.zenCrimson }
    static var stsCyan: Color          { Color.zenSkyTop }
    static var stsWarning: Color       { Color.zenGoldDeep }
    static var stsDanger: Color        { Color.zenCrimson }
    static var stsGold: Color          { Color.zenGold }
    static var stsSuccess: Color       { Color.zenJade }
    static var stsPrimary: Color       { Color.zenInk }
    static var stsSecondary: Color     { Color.zenPlumGrey }
    static var stsTertiary: Color      { Color.zenLavenderGrey }
}

// =====================================================================
// MARK: - GRADIENTS
// =====================================================================

extension LinearGradient {
    /// Serene anime sky wash (sky-top -> sky-mid -> cloud-white -> mist)
    static var zenAppBackground: LinearGradient {
        LinearGradient(
            stops: [
                .init(color: Color.zenSkyTop.opacity(0.75), location: 0.0),
                .init(color: Color.zenSkyMid.opacity(0.55), location: 0.28),
                .init(color: Color.zenCloudWhite, location: 0.62),
                .init(color: Color.zenMist, location: 1.0)
            ],
            startPoint: .top,
            endPoint: .bottom
        )
    }
    
    /// Primary CTA gradient (crimson -> crimson-dark)
    static var zenCtaGradient: LinearGradient {
        LinearGradient(
            colors: [Color.zenCrimson, Color.zenCrimsonDark],
            startPoint: .top,
            endPoint: .bottom
        )
    }
    
    /// Success / savings gradient (jade -> jade-dark)
    static var zenSuccessGradient: LinearGradient {
        LinearGradient(
            colors: [Color.zenJade, Color.zenJadeDark],
            startPoint: .top,
            endPoint: .bottom
        )
    }
    
    /// Gold luxury gradient
    static var zenGoldGradient: LinearGradient {
        LinearGradient(
            colors: [Color.zenGold, Color.zenGoldDeep],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }
    
    /// Sakura petal gradient
    static var zenBlossomGradient: LinearGradient {
        LinearGradient(
            colors: [Color.zenBlossomPink, Color.zenBlossomDeep],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }
    
    /// Glass specular top-highlight border
    static var zenGlassBorderGradient: LinearGradient {
        LinearGradient(
            stops: [
                .init(color: Color.white.opacity(0.95), location: 0.0),
                .init(color: Color.white.opacity(0.40), location: 0.6),
                .init(color: Color.white.opacity(0.15), location: 1.0)
            ],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }
}

// =====================================================================
// MARK: - TYPOGRAPHY
// =====================================================================

extension Font {
    // East-Asian brush flair serif display fonts
    static func zenHeading(_ size: CGFloat, weight: Font.Weight = .bold) -> Font {
        Font.system(size: size, weight: weight, design: .serif)
    }
    
    // Tabular-figure numerical balances
    static func zenNumber(_ size: CGFloat, weight: Font.Weight = .bold) -> Font {
        Font.system(size: size, weight: weight, design: .rounded).monospacedDigit()
    }
    
    // Modern sans body
    static func zenBody(_ size: CGFloat, weight: Font.Weight = .regular) -> Font {
        Font.system(size: size, weight: weight, design: .default)
    }
    
    // Legacy Font aliases updated for Zen Light Theme
    static let stsHeroAmount  = Font.system(size: 44, weight: .bold, design: .serif).monospacedDigit()
    static let stsLargeTitle  = Font.system(size: 28, weight: .bold, design: .serif)
    static let stsTitle       = Font.system(size: 22, weight: .semibold, design: .serif)
    static let stsHeadline    = Font.system(size: 16, weight: .semibold, design: .default)
    static let stsBody        = Font.system(size: 15, weight: .regular, design: .default)
    static let stsCaption     = Font.system(size: 13, weight: .medium, design: .default)
    static let stsSmall       = Font.system(size: 11, weight: .medium, design: .default)
}

// =====================================================================
// MARK: - APP BACKGROUND (Ukiyo-e Anime Wash + Layered Artwork)
// =====================================================================

struct AppBackground: View {
    var imageName: String = "bg_mountain_dawn"
    var opacity: Double = 0.16
    var showMist: Bool = true
    
    var body: some View {
        GeometryReader { proxy in
            ZStack {
                // Base daylight sky wash
                LinearGradient.zenAppBackground
                    .frame(width: proxy.size.width, height: proxy.size.height)
                
                // Lowered opacity illustrated background scene
                Image(imageName)
                    .resizable()
                    .scaledToFill()
                    .frame(width: proxy.size.width, height: proxy.size.height)
                    .clipped()
                    .opacity(opacity)
                
                // Frosted watercolor white overlay so text & glass cards maintain AAA contrast
                if showMist {
                    LinearGradient(
                        colors: [
                            Color.white.opacity(0.28),
                            Color.zenCloudWhite.opacity(0.52),
                            Color.zenMist.opacity(0.82)
                        ],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                    .frame(width: proxy.size.width, height: proxy.size.height)
                    
                    // Morning mist fade at the bottom
                    VStack {
                        Spacer()
                        LinearGradient(
                            colors: [Color.clear, Color.zenMist.opacity(0.92), Color.zenMist],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                        .frame(height: 260)
                    }
                    .frame(width: proxy.size.width, height: proxy.size.height)
                } else {
                    // Soft translucent wash allowing whole screen illustration to fill cleanly
                    LinearGradient(
                        colors: [
                            Color.white.opacity(0.08),
                            Color.white.opacity(0.18),
                            Color.white.opacity(0.28)
                        ],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                    .frame(width: proxy.size.width, height: proxy.size.height)
                    
                    // Very soft bottom blend for home indicator and dock area
                    VStack {
                        Spacer()
                        LinearGradient(
                            colors: [Color.clear, Color.white.opacity(0.65)],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                        .frame(height: 75)
                    }
                    .frame(width: proxy.size.width, height: proxy.size.height)
                }
            }
        }
        .ignoresSafeArea()
    }
}

// =====================================================================
// MARK: - MASCOT AVATAR & DRAGON PROGRESS BAR
// =====================================================================

struct MascotAvatarView: View {
    enum MascotType: CaseIterable {
        case ryo
        case midori
        case akai
        case samurai
        case mugen
        case jin
        case fuu
        
        var imageName: String {
            switch self {
            case .ryo: return "mascot_ronin_ryo"
            case .midori: return "mascot_midori_dragon"
            case .akai: return "mascot_akai_dragon"
            case .samurai: return "mascot_samurai_armor"
            case .mugen: return "mascot_mugen"
            case .jin: return "mascot_jin"
            case .fuu: return "mascot_fuu"
            }
        }
        
        var borderColor: Color {
            switch self {
            case .ryo: return .zenGold
            case .midori: return .zenJade
            case .akai: return .zenCrimson
            case .samurai: return .zenCrimsonDark
            case .mugen: return .zenGoldDeep
            case .jin: return .zenInk
            case .fuu: return .zenCrimson
            }
        }
    }
    
    let mascot: MascotType
    var size: CGFloat = 36
    var showGlow: Bool = true
    
    var body: some View {
        Image(mascot.imageName)
            .resizable()
            .scaledToFill()
            .frame(width: size, height: size)
            .clipShape(Circle())
            .overlay(
                Circle()
                    .stroke(mascot.borderColor, lineWidth: 1.5)
            )
            .shadow(color: mascot.borderColor.opacity(showGlow ? 0.35 : 0), radius: 6, y: 2)
    }
}

struct DragonProgressBar: View {
    let progress: Double // 0.0 to 1.0
    var isWarning: Bool = false
    
    var body: some View {
        GeometryReader { geo in
            ZStack(alignment: .leading) {
                // Track
                Capsule()
                    .fill(Color.white.opacity(0.65))
                    .frame(height: 10)
                    .overlay(
                        Capsule()
                            .stroke(Color.zenPlumBorder, lineWidth: 1)
                    )
                
                let fillColors = isWarning
                    ? [Color.zenCrimson, Color.zenCrimsonDark]
                    : [Color.zenJade, Color.zenJadeDark]
                
                let clampedProgress = max(0.04, min(1.0, progress))
                let fillWidth = max(16.0, geo.size.width * CGFloat(clampedProgress))
                
                Capsule()
                    .fill(LinearGradient(colors: fillColors, startPoint: .leading, endPoint: .trailing))
                    .frame(width: fillWidth, height: 10)
                    .overlay(
                        HStack {
                            Spacer()
                            Circle()
                                .fill(Color.zenGold)
                                .frame(width: 8, height: 8)
                                .shadow(color: Color.zenGold.opacity(0.8), radius: 3)
                                .padding(.trailing, 2)
                        }
                    )
                    .shadow(color: (isWarning ? Color.zenCrimson : Color.zenJade).opacity(0.3), radius: 4, y: 1)
            }
        }
        .frame(height: 10)
    }
}

// =====================================================================
// MARK: - GLASSMORPHISM CARD SYSTEM
// =====================================================================

public enum GlassVariant {
    case `default`
    case elevated
    case tintedCrimson   // Spending, expenses
    case tintedJade      // Savings, income
    case tintedGold      // Rewards, milestones
    case tintedBlossom   // Sakura special
    
    var tintColor: Color {
        switch self {
        case .default:       return .clear
        case .elevated:      return Color.white.opacity(0.15)
        case .tintedCrimson: return Color.zenCrimson.opacity(0.10)
        case .tintedJade:    return Color.zenJade.opacity(0.10)
        case .tintedGold:    return Color.zenGold.opacity(0.12)
        case .tintedBlossom: return Color.zenBlossomPink.opacity(0.12)
        }
    }
    
    var baseFill: Color {
        switch self {
        case .elevated: return Color.white.opacity(0.80)
        default:        return Color.white.opacity(0.56)
        }
    }
    
    var shadowRadius: CGFloat {
        switch self {
        case .elevated: return 24
        default:        return 16
        }
    }
    
    var shadowY: CGFloat {
        switch self {
        case .elevated: return 12
        default:        return 8
        }
    }
    
    var shadowOpacity: Double {
        switch self {
        case .elevated: return 0.14
        default:        return 0.08
        }
    }
}

struct GlassCardModifier: ViewModifier {
    var variant: GlassVariant = .default
    var cornerRadius: CGFloat = 24
    var padding: CGFloat = 18
    
    func body(content: Content) -> some View {
        content
            .padding(padding)
            .background(
                ZStack {
                    // Plain translucent white wash
                    variant.baseFill
                    
                    // Subtle semantic tint
                    variant.tintColor
                    
                    // Glass backdrop material
                    Rectangle()
                        .fill(.ultraThinMaterial)
                        .opacity(0.85)
                }
            )
            .clipShape(RoundedRectangle(cornerRadius: cornerRadius, style: .continuous))
            .overlay(
                // Double border: 1px specular white gradient + faint plum stroke
                ZStack {
                    RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                        .stroke(LinearGradient.zenGlassBorderGradient, lineWidth: 1.2)
                    
                    RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                        .stroke(Color.zenPlumBorder, lineWidth: 1)
                }
            )
            // Inner top-edge highlight
            .overlay(alignment: .top) {
                RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                    .stroke(Color.white.opacity(0.9), lineWidth: 1)
                    .mask(
                        LinearGradient(
                            colors: [.white, .clear],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                        .frame(height: 18)
                    )
            }
            .shadow(
                color: Color.zenInk.opacity(variant.shadowOpacity),
                radius: variant.shadowRadius,
                x: 0,
                y: variant.shadowY
            )
    }
}

extension View {
    func glassCard(variant: GlassVariant = .default, cornerRadius: CGFloat = 24, padding: CGFloat = 18) -> some View {
        modifier(GlassCardModifier(variant: variant, cornerRadius: cornerRadius, padding: padding))
    }
    
    // Compatibility cardStyle
    func cardStyle(padding: CGFloat = 18, cornerRadius: CGFloat = 24) -> some View {
        glassCard(variant: .default, cornerRadius: cornerRadius, padding: padding)
    }
}

// =====================================================================
// MARK: - GLASS BUTTONS
// =====================================================================

public enum GlassButtonStyle {
    case primary      // Crimson to crimson-dark with gold top edge
    case secondary    // White glass with plum/ink border
    case jade         // Jade to jade-dark savings CTA
    case gold         // Gold gilded button
    case ghost        // Clean translucent text button
}

struct ZenButton: View {
    let title: String
    var icon: String? = nil
    var style: GlassButtonStyle = .primary
    var isFullWidth: Bool = true
    let action: () -> Void
    
    @State private var isPressed = false
    
    var body: some View {
        Button(action: {
            Haptics.impact(.medium)
            action()
        }) {
            HStack(spacing: 8) {
                if let icon = icon {
                    Image(systemName: icon)
                        .font(.system(size: 16, weight: .semibold))
                }
                Text(title)
                    .font(.zenHeading(16, weight: .semibold))
            }
            .foregroundStyle(textColor)
            .padding(.vertical, 14)
            .padding(.horizontal, isFullWidth ? 16 : 24)
            .frame(maxWidth: isFullWidth ? .infinity : nil)
            .background(backgroundView)
            .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
            .overlay(borderOverlay)
            .shadow(color: shadowColor, radius: 14, x: 0, y: 6)
            .scaleEffect(isPressed ? 0.97 : 1.0)
            .animation(.spring(response: 0.3, dampingFraction: 0.65), value: isPressed)
        }
        .simultaneousGesture(
            DragGesture(minimumDistance: 0)
                .onChanged { _ in isPressed = true }
                .onEnded { _ in isPressed = false }
        )
    }
    
    private var textColor: Color {
        switch style {
        case .primary, .jade:
            return .white
        case .gold:
            return Color.zenInk
        case .secondary, .ghost:
            return Color.zenInk
        }
    }
    
    @ViewBuilder
    private var backgroundView: some View {
        switch style {
        case .primary:
            LinearGradient.zenCtaGradient
        case .jade:
            LinearGradient.zenSuccessGradient
        case .gold:
            LinearGradient.zenGoldGradient
        case .secondary:
            ZStack {
                Color.white.opacity(0.75)
                Rectangle().fill(.ultraThinMaterial).opacity(0.85)
            }
        case .ghost:
            Color.clear
        }
    }
    
    @ViewBuilder
    private var borderOverlay: some View {
        switch style {
        case .primary:
            // 1px gold top highlight + crimson stroke
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .stroke(
                    LinearGradient(
                        colors: [Color.zenGold, Color.zenCrimsonDark],
                        startPoint: .top,
                        endPoint: .bottom
                    ),
                    lineWidth: 1.2
                )
        case .jade:
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .stroke(Color.white.opacity(0.3), lineWidth: 1)
        case .gold:
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .stroke(Color.zenGoldDeep.opacity(0.4), lineWidth: 1)
        case .secondary:
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .stroke(Color.zenPlumBorder.opacity(1.5), lineWidth: 1)
        case .ghost:
            EmptyView()
        }
    }
    
    private var shadowColor: Color {
        switch style {
        case .primary: return Color.zenCrimson.opacity(0.28)
        case .jade:    return Color.zenJade.opacity(0.25)
        case .gold:    return Color.zenGold.opacity(0.25)
        case .secondary, .ghost: return Color.zenInk.opacity(0.06)
        }
    }
}

// =====================================================================
// MARK: - GLASS CHIP & BADGES
// =====================================================================

struct GlassChip: View {
    let title: String
    var icon: String? = nil
    var isSelected: Bool = false
    var tint: Color = Color.zenCrimson
    var action: (() -> Void)? = nil
    
    var body: some View {
        Button(action: {
            Haptics.selection()
            action?()
        }) {
            HStack(spacing: 6) {
                if let icon = icon {
                    Image(systemName: icon)
                        .font(.system(size: 12, weight: .semibold))
                }
                Text(title)
                    .font(.zenBody(13, weight: isSelected ? .semibold : .medium))
            }
            .foregroundStyle(isSelected ? (tint == .zenGold ? Color.zenInk : .white) : Color.zenPlumGrey)
            .padding(.horizontal, 14)
            .padding(.vertical, 8)
            .background(
                Group {
                    if isSelected {
                        tint
                    } else {
                        Color.white.opacity(0.65)
                    }
                }
            )
            .clipShape(Capsule())
            .overlay(
                Capsule()
                    .stroke(
                        isSelected ? tint.opacity(0.8) : Color.white.opacity(0.9),
                        lineWidth: 1
                    )
            )
            .shadow(
                color: isSelected ? tint.opacity(0.25) : Color.zenInk.opacity(0.04),
                radius: 8,
                y: 3
            )
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Traditional Hanko Seal Stamp
struct HankoSealStamp: View {
    let kanji: String
    let label: String
    var color: Color = .zenCrimson
    
    var body: some View {
        HStack(spacing: 5) {
            ZStack {
                RoundedRectangle(cornerRadius: 4, style: .continuous)
                    .stroke(color, lineWidth: 1.5)
                    .frame(width: 18, height: 18)
                    .background(color.opacity(0.08))
                
                Text(kanji)
                    .font(.system(size: 10, weight: .bold, design: .serif))
                    .foregroundStyle(color)
            }
            
            Text(label.uppercased())
                .font(.system(size: 10, weight: .bold, design: .serif))
                .foregroundStyle(color)
                .tracking(0.5)
                .lineLimit(1)
                .fixedSize(horizontal: true, vertical: false)
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(color.opacity(0.06))
        .clipShape(RoundedRectangle(cornerRadius: 6, style: .continuous))
    }
}

// MARK: - Katana Line Separator
struct KatanaDivider: View {
    var body: some View {
        HStack(spacing: 0) {
            Circle()
                .fill(Color.zenGold)
                .frame(width: 4, height: 4)
            
            LinearGradient(
                colors: [Color.zenGold, Color.zenPlumGrey.opacity(0.2), Color.clear],
                startPoint: .leading,
                endPoint: .trailing
            )
            .frame(height: 1)
        }
    }
}

// =====================================================================
// MARK: - AMBIENT PETALS PARTICLE VIEW
// =====================================================================

struct SakuraPetal: Identifiable {
    let id = UUID()
    var x: CGFloat
    var y: CGFloat
    var size: CGFloat
    var rotation: Double
    var opacity: Double
    var speed: CGFloat
}

struct AmbientPetalsView: View {
    @State private var petals: [SakuraPetal] = []
    @State private var timerActive = true
    
    let maxPetals = 12
    
    var body: some View {
        TimelineView(.animation) { timeline in
            Canvas { context, size in
                for petal in petals {
                    var pContext = context
                    pContext.translateBy(x: petal.x * size.width, y: petal.y * size.height)
                    pContext.rotate(by: Angle(degrees: petal.rotation))
                    pContext.opacity = petal.opacity
                    
                    // Draw a soft blossom petal shape
                    let petalRect = CGRect(x: -petal.size / 2, y: -petal.size / 2, width: petal.size, height: petal.size * 1.4)
                    let path = Path { p in
                        p.addEllipse(in: petalRect)
                    }
                    
                    pContext.fill(path, with: .color(Color.zenBlossomPink))
                }
            }
        }
        .onAppear {
            generatePetals()
            startDrifting()
        }
        .allowsHitTesting(false)
        .ignoresSafeArea()
    }
    
    private func generatePetals() {
        petals = (0..<maxPetals).map { _ in
            SakuraPetal(
                x: CGFloat.random(in: 0...1),
                y: CGFloat.random(in: -0.2...1.2),
                size: CGFloat.random(in: 7...13),
                rotation: Double.random(in: 0...360),
                opacity: Double.random(in: 0.35...0.75),
                speed: CGFloat.random(in: 0.0008...0.0022)
            )
        }
    }
    
    private func startDrifting() {
        Timer.scheduledTimer(withTimeInterval: 0.03, repeats: true) { _ in
            for i in petals.indices {
                petals[i].y += petals[i].speed
                petals[i].x += sin(petals[i].y * 8) * 0.0006
                petals[i].rotation += 0.8
                
                if petals[i].y > 1.2 {
                    petals[i].y = -0.1
                    petals[i].x = CGFloat.random(in: 0...1)
                }
            }
        }
    }
}

// =====================================================================
// MARK: - SHIMMER LOADING EFFECT (Soft Gilded Shimmer)
// =====================================================================

struct ShimmerEffect: ViewModifier {
    @State private var phase: CGFloat = 0
    
    func body(content: Content) -> some View {
        content
            .overlay(
                LinearGradient(
                    colors: [
                        .clear,
                        Color.white.opacity(0.45),
                        .clear
                    ],
                    startPoint: .leading,
                    endPoint: .trailing
                )
                .offset(x: phase)
                .onAppear {
                    withAnimation(.linear(duration: 1.8).repeatForever(autoreverses: false)) {
                        phase = 450
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

// =====================================================================
// MARK: - PAISE FORMATTING & HAPTICS
// =====================================================================

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
    
    /// Formats to compact rupees (e.g. ₹1.2K, ₹1.5L)
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
