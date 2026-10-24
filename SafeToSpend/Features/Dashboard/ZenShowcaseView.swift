import SwiftUI

/// Component Showcase screen for the "Ukiyo-e Anime Zen" Design System & Glassmorphism Library
struct ZenShowcaseView: View {
    @Environment(\.dismiss) var dismiss
    @State private var selectedChip = "All"
    @State private var sampleInputText = ""
    @State private var buttonPressCount = 0
    @State private var showPetalToast = false
    
    let chips = ["All", "Spending", "Savings", "Anime", "Honor"]
    
    @State private var showcaseTab = 0
    let showcaseSections = ["Overview", "Mascots", "Glass Cards", "Buttons", "Tokens"]
    
    var body: some View {
        NavigationStack {
            ZStack {
                AppBackground()
                AmbientPetalsView()
                
                ScrollView(.vertical, showsIndicators: false) {
                    VStack(spacing: 20) {
                        // Title banner
                        headerBanner
                        
                        // Category Picker
                        Picker("Showcase Section", selection: $showcaseTab) {
                            ForEach(0..<showcaseSections.count, id: \.self) { index in
                                Text(showcaseSections[index]).tag(index)
                            }
                        }
                        .pickerStyle(.segmented)
                        .padding(.vertical, 4)
                        
                        if showcaseTab == 0 {
                            // Full overview
                            mascotsSection
                            paletteSection
                            glassCardsSection
                            glassButtonsSection
                            chipsAndStampsSection
                            glassInputSection
                        } else if showcaseTab == 1 {
                            mascotsSection
                        } else if showcaseTab == 2 {
                            glassCardsSection
                        } else if showcaseTab == 3 {
                            glassButtonsSection
                            chipsAndStampsSection
                        } else {
                            glassInputSection
                            paletteSection
                        }
                        
                        // Footer
                        footerBranding
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 12)
                    .padding(.bottom, 48)
                }
            }
            .navigationTitle("Zen Showcase")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        dismiss()
                    } label: {
                        Text("Done")
                            .font(.zenHeading(16, weight: .bold))
                            .foregroundStyle(Color.zenCrimson)
                    }
                }
            }
        }
    }
    
    // MARK: - Header Banner
    private var headerBanner: some View {
        VStack(spacing: 8) {
            HStack(spacing: 8) {
                HankoSealStamp(kanji: "禅", label: "Zen System", color: .zenCrimson)
                HankoSealStamp(kanji: "光", label: "Light Only", color: .zenJade)
                Spacer()
            }
            
            Text("Ukiyo-e Anime Zen")
                .font(.zenHeading(32, weight: .bold))
                .foregroundStyle(Color.zenInk)
                .frame(maxWidth: .infinity, alignment: .leading)
            
            Text("Daytime painterly serenity with layered glassmorphism, crimson samurai armor details, jade guardian dragon accents, and drifting sakura petals.")
                .font(.zenBody(14))
                .foregroundStyle(Color.zenPlumGrey)
                .frame(maxWidth: .infinity, alignment: .leading)
            
            KatanaDivider()
                .padding(.top, 6)
        }
        .padding(.vertical, 8)
    }
    
    // MARK: - Mascots Section
    private var mascotsSection: some View {
        VStack(alignment: .leading, spacing: 14) {
            sectionHeader(title: "ARTWORK MASCOT COMPONENTS", subtitle: "Mascots & guardians extracted from anime artwork")
            
            VStack(spacing: 14) {
                // Trio 1: Lunch Break Anime Scene
                VStack(spacing: 6) {
                    Text("Daytime Mountain Dawn Trio")
                        .font(.zenHeading(12, weight: .bold))
                        .foregroundStyle(Color.zenGoldDeep)
                        .frame(maxWidth: .infinity, alignment: .leading)
                    
                    HStack(spacing: 12) {
                        mascotItem(mascot: .akai, name: "Akai Dragon", subtitle: "Crimson Guard", stamp: "守")
                        mascotItem(mascot: .ryo, name: "Ronin Ryo", subtitle: "Ramen Guide", stamp: "禅")
                        mascotItem(mascot: .midori, name: "Midori Dragon", subtitle: "Jade Guard", stamp: "護")
                    }
                }
                
                Divider()
                    .overlay(Color.zenPlumBorder)
                
                // Trio 2: Classic Ronin Warriors
                VStack(spacing: 6) {
                    Text("Warrior & Ronin Guardians")
                        .font(.zenHeading(12, weight: .bold))
                        .foregroundStyle(Color.zenCrimson)
                        .frame(maxWidth: .infinity, alignment: .leading)
                    
                    HStack(spacing: 12) {
                        mascotItem(mascot: .samurai, name: "Samurai Armor", subtitle: "Katana Honor", stamp: "武")
                        mascotItem(mascot: .mugen, name: "Ronin Mugen", subtitle: "Wild Blade", stamp: "風")
                        mascotItem(mascot: .jin, name: "Ronin Jin", subtitle: "Discipline", stamp: "道")
                    }
                }
            }
            .glassCard(variant: .default, cornerRadius: 20)
        }
    }
    
    private func mascotItem(mascot: MascotAvatarView.MascotType, name: String, subtitle: String, stamp: String) -> some View {
        VStack(spacing: 6) {
            MascotAvatarView(mascot: mascot, size: 52)
            
            Text(name)
                .font(.zenHeading(11, weight: .bold))
                .foregroundStyle(Color.zenInk)
                .lineLimit(1)
            
            Text(subtitle)
                .font(.zenBody(9))
                .foregroundStyle(Color.zenPlumGrey)
                .lineLimit(1)
            
            HankoSealStamp(kanji: stamp, label: name.components(separatedBy: " ").first ?? "Guide", color: mascot.borderColor)
        }
        .frame(maxWidth: .infinity)
    }
    
    // MARK: - Palette Section
    private var paletteSection: some View {
        VStack(alignment: .leading, spacing: 14) {
            sectionHeader(title: "DESIGN TOKENS", subtitle: "Harmonious daylight watercolor palette")
            
            VStack(spacing: 10) {
                HStack(spacing: 8) {
                    colorSwatch(name: "Sky Top", color: .zenSkyTop, hex: "#7FB2E5")
                    colorSwatch(name: "Sky Mid", color: .zenSkyMid, hex: "#B9CDF0")
                    colorSwatch(name: "Cloud", color: .zenCloudWhite, hex: "#F6F1FA")
                    colorSwatch(name: "Mist", color: .zenMist, hex: "#FBF8FF")
                }
                
                HStack(spacing: 8) {
                    colorSwatch(name: "Crimson", color: .zenCrimson, hex: "#C8323C", darkText: false)
                    colorSwatch(name: "Crimson Dk", color: .zenCrimsonDark, hex: "#8E1F2B", darkText: false)
                    colorSwatch(name: "Jade", color: .zenJade, hex: "#3FAE7A", darkText: false)
                    colorSwatch(name: "Jade Dk", color: .zenJadeDark, hex: "#1F6B4C", darkText: false)
                }
                
                HStack(spacing: 8) {
                    colorSwatch(name: "Gold", color: .zenGold, hex: "#E8B84A")
                    colorSwatch(name: "Gold Deep", color: .zenGoldDeep, hex: "#B88A1E", darkText: false)
                    colorSwatch(name: "Blossom", color: .zenBlossomPink, hex: "#E58AC9")
                    colorSwatch(name: "Blossom Dk", color: .zenBlossomDeep, hex: "#B24A9A", darkText: false)
                }
                
                HStack(spacing: 8) {
                    colorSwatch(name: "Ink (Text)", color: .zenInk, hex: "#2A1624", darkText: false)
                    colorSwatch(name: "Plum Grey", color: .zenPlumGrey, hex: "#5E4A66", darkText: false)
                    colorSwatch(name: "Lavender", color: .zenLavenderGrey, hex: "#9A93B5")
                }
            }
        }
    }
    
    private func colorSwatch(name: String, color: Color, hex: String, darkText: Bool = true) -> some View {
        VStack(alignment: .leading, spacing: 3) {
            RoundedRectangle(cornerRadius: 10, style: .continuous)
                .fill(color)
                .frame(height: 38)
                .overlay(
                    RoundedRectangle(cornerRadius: 10, style: .continuous)
                        .stroke(Color.zenPlumBorder, lineWidth: 1)
                )
            
            Text(name)
                .font(.system(size: 11, weight: .bold))
                .foregroundStyle(Color.zenInk)
                .lineLimit(1)
            
            Text(hex)
                .font(.system(size: 9, weight: .regular, design: .monospaced))
                .foregroundStyle(Color.zenPlumGrey)
        }
        .frame(maxWidth: .infinity)
        .padding(8)
        .background(Color.white.opacity(0.65))
        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .stroke(Color.white.opacity(0.9), lineWidth: 1)
        )
    }
    
    // MARK: - Glass Cards Section
    private var glassCardsSection: some View {
        VStack(alignment: .leading, spacing: 14) {
            sectionHeader(title: "GLASSMORPHISM CARDS", subtitle: "White 45-60% wash • 24px blur • Plum drop shadow")
            
            // 1. Default Glass Card (Hero STS Simulation)
            VStack(spacing: 12) {
                HStack {
                    Text("DEFAULT GLASS CARD")
                        .font(.system(size: 11, weight: .bold, design: .serif))
                        .foregroundStyle(Color.zenPlumGrey)
                        .tracking(0.6)
                    Spacer()
                    HankoSealStamp(kanji: "日", label: "TODAY", color: .zenCrimson)
                }
                
                VStack(spacing: 4) {
                    Text("₹36,084.71")
                        .font(.zenHeading(36, weight: .bold))
                        .foregroundStyle(Color.zenInk)
                    
                    Text("Safe Allowance for Today")
                        .font(.zenBody(13, weight: .medium))
                        .foregroundStyle(Color.zenPlumGrey)
                }
                .padding(.vertical, 4)
                
                HStack(spacing: 24) {
                    metricItem(label: "per day", value: "₹36,084", color: .zenCrimson)
                    Divider().frame(height: 28).background(Color.zenPlumBorder)
                    metricItem(label: "days left", value: "7", color: .zenInk)
                    Divider().frame(height: 28).background(Color.zenPlumBorder)
                    metricItem(label: "pool", value: "₹2,52,593", color: .zenJade)
                }
            }
            .glassCard(variant: .default, cornerRadius: 24)
            
            // 2. Tinted Jade (Savings) & Crimson (Spending)
            HStack(spacing: 12) {
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Image(systemName: "leaf.fill")
                            .foregroundStyle(Color.zenJade)
                        Text("SAVINGS")
                            .font(.system(size: 10, weight: .bold, design: .serif))
                            .foregroundStyle(Color.zenJadeDark)
                    }
                    Text("₹50,000")
                        .font(.zenHeading(20, weight: .bold))
                        .foregroundStyle(Color.zenInk)
                    Text("Dragon Midori Goal")
                        .font(.zenBody(11))
                        .foregroundStyle(Color.zenPlumGrey)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .glassCard(variant: .tintedJade, cornerRadius: 20)
                
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Image(systemName: "flame.fill")
                            .foregroundStyle(Color.zenCrimson)
                        Text("SPENT")
                            .font(.system(size: 10, weight: .bold, design: .serif))
                            .foregroundStyle(Color.zenCrimsonDark)
                    }
                    Text("₹2,450")
                        .font(.zenHeading(20, weight: .bold))
                        .foregroundStyle(Color.zenInk)
                    Text("Dragon Akai Alert")
                        .font(.zenBody(11))
                        .foregroundStyle(Color.zenPlumGrey)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .glassCard(variant: .tintedCrimson, cornerRadius: 20)
            }
            
            // 3. Tinted Gold & Blossom
            HStack(spacing: 12) {
                VStack(alignment: .leading, spacing: 6) {
                    HStack {
                        Image(systemName: "crown.fill")
                            .foregroundStyle(Color.zenGold)
                        Text("GILDED REWARD")
                            .font(.system(size: 10, weight: .bold, design: .serif))
                            .foregroundStyle(Color.zenGoldDeep)
                    }
                    Text("Samurai Tier")
                        .font(.zenHeading(18, weight: .bold))
                        .foregroundStyle(Color.zenInk)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .glassCard(variant: .tintedGold, cornerRadius: 20)
                
                VStack(alignment: .leading, spacing: 6) {
                    HStack {
                        Image(systemName: "camera.macro")
                            .foregroundStyle(Color.zenBlossomDeep)
                        Text("SAKURA CYCLE")
                            .font(.system(size: 10, weight: .bold, design: .serif))
                            .foregroundStyle(Color.zenBlossomDeep)
                    }
                    Text("76% Through")
                        .font(.zenHeading(18, weight: .bold))
                        .foregroundStyle(Color.zenInk)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .glassCard(variant: .tintedBlossom, cornerRadius: 20)
            }
        }
    }
    
    private func metricItem(label: String, value: String, color: Color) -> some View {
        VStack(spacing: 2) {
            Text(label)
                .font(.zenBody(11))
                .foregroundStyle(Color.zenPlumGrey)
            Text(value)
                .font(.zenNumber(15, weight: .bold))
                .foregroundStyle(color)
        }
    }
    
    // MARK: - Glass Buttons Section
    private var glassButtonsSection: some View {
        VStack(alignment: .leading, spacing: 14) {
            sectionHeader(title: "INTERACTIVE GLASS BUTTONS", subtitle: "Crimson CTA with gold highlight • Micro-scale bounce")
            
            ZenButton(
                title: "Log Expense (\(buttonPressCount) taps)",
                icon: "plus.circle.fill",
                style: .primary
            ) {
                buttonPressCount += 1
                showPetalToast = true
            }
            
            HStack(spacing: 12) {
                ZenButton(
                    title: "Add Savings",
                    icon: "arrow.up.forward.circle.fill",
                    style: .jade,
                    isFullWidth: true
                ) {
                    buttonPressCount += 1
                }
                
                ZenButton(
                    title: "View Scroll",
                    icon: "doc.text.fill",
                    style: .secondary,
                    isFullWidth: true
                ) {
                    buttonPressCount += 1
                }
            }
        }
    }
    
    // MARK: - Chips & Hanko Stamps
    private var chipsAndStampsSection: some View {
        VStack(alignment: .leading, spacing: 14) {
            sectionHeader(title: "CHIPS & HANKO SEALS", subtitle: "Capsule glass chips and traditional Japanese certification stamps")
            
            // Chips row
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    ForEach(chips, id: \.self) { chip in
                        GlassChip(
                            title: chip,
                            isSelected: selectedChip == chip,
                            tint: chip == "Savings" ? Color.zenJade : Color.zenCrimson
                        ) {
                            selectedChip = chip
                        }
                    }
                }
            }
            
            // Hanko Stamps
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 10) {
                    HankoSealStamp(kanji: "済", label: "Paid", color: .zenCrimson)
                    HankoSealStamp(kanji: "確", label: "Verified", color: .zenJade)
                    HankoSealStamp(kanji: "達", label: "Achieved", color: .zenGoldDeep)
                    HankoSealStamp(kanji: "桜", label: "Zen", color: .zenBlossomDeep)
                }
                .padding(.vertical, 2)
            }
            .padding(.top, 4)
        }
    }
    
    // MARK: - Glass Input Section
    private var glassInputSection: some View {
        VStack(alignment: .leading, spacing: 14) {
            sectionHeader(title: "GLASS INPUT FIELD", subtitle: "Frosted white input with gold focus glow")
            
            HStack(spacing: 10) {
                Image(systemName: "magnifyingglass")
                    .foregroundStyle(Color.zenPlumGrey)
                
                TextField("Search transactions or bills...", text: $sampleInputText)
                    .font(.zenBody(15))
                    .foregroundStyle(Color.zenInk)
                
                if !sampleInputText.isEmpty {
                    Button {
                        sampleInputText = ""
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundStyle(Color.zenLavenderGrey)
                    }
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 14)
            .background(Color.white.opacity(0.65))
            .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .stroke(
                        sampleInputText.isEmpty
                            ? LinearGradient.zenGlassBorderGradient
                            : LinearGradient.zenGoldGradient,
                        lineWidth: sampleInputText.isEmpty ? 1.2 : 1.6
                    )
            )
            .shadow(color: Color.zenInk.opacity(0.06), radius: 12, y: 6)
        }
    }
    
    // MARK: - Footer
    private var footerBranding: some View {
        VStack(spacing: 8) {
            KatanaDivider()
            
            HStack(spacing: 6) {
                Image(systemName: "shield.fill")
                    .font(.caption)
                    .foregroundStyle(Color.zenCrimson)
                Text("SafeToSpend • Ukiyo-e Anime Zen Design System")
                    .font(.zenBody(12, weight: .medium))
                    .foregroundStyle(Color.zenPlumGrey)
            }
            .padding(.top, 8)
        }
    }
    
    // MARK: - Helper Views
    private func sectionHeader(title: String, subtitle: String) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(title)
                .font(.system(size: 11, weight: .bold, design: .serif))
                .foregroundStyle(Color.zenCrimson)
                .tracking(1.0)
            
            Text(subtitle)
                .font(.zenBody(13))
                .foregroundStyle(Color.zenPlumGrey)
        }
    }
}

#Preview {
    ZenShowcaseView()
}
