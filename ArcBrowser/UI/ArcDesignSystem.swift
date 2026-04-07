import SwiftUI

// MARK: - Profile Theme
enum ProfileTheme: String, CaseIterable, Hashable, Codable {
    case sky
    case sunset
    case forest
    case midnight
    case cherry
    case ocean
    case lavender
    case coffee
    case roseGold
    case cyberpunk
    case mint
    case autumn
    case galaxy
    case solar
    case berry
    case slate
    case coral
    case emerald
    case violet
    case peach

    var color: Color {
        switch self {
        case .sky:
            return .blue
        case .sunset:
            return .orange
        case .forest:
            return .green
        case .midnight:
            return Color(red: 0.42, green: 0.20, blue: 0.60)
        case .cherry:
            return Color(red: 0.9, green: 0.2, blue: 0.4)
        case .ocean:
            return Color(red: 0.15, green: 0.55, blue: 0.85)
        case .lavender:
            return Color(red: 0.65, green: 0.45, blue: 0.85)
        case .coffee:
            return Color(red: 0.55, green: 0.38, blue: 0.25)
        case .roseGold:
            return Color(red: 0.85, green: 0.55, blue: 0.55)
        case .cyberpunk:
            return Color(red: 1.0, green: 0.0, blue: 0.85)
        case .mint:
            return Color(red: 0.35, green: 0.85, blue: 0.65)
        case .autumn:
            return Color(red: 0.85, green: 0.45, blue: 0.15)
        case .galaxy:
            return Color(red: 0.45, green: 0.25, blue: 0.75)
        case .solar:
            return Color(red: 0.95, green: 0.65, blue: 0.15)
        case .berry:
            return Color(red: 0.75, green: 0.15, blue: 0.45)
        case .slate:
            return Color(red: 0.35, green: 0.45, blue: 0.55)
        case .coral:
            return Color(red: 1.0, green: 0.5, blue: 0.4)
        case .emerald:
            return Color(red: 0.2, green: 0.75, blue: 0.45)
        case .violet:
            return Color(red: 0.55, green: 0.25, blue: 0.85)
        case .peach:
            return Color(red: 1.0, green: 0.65, blue: 0.55)
        }
    }
    
    var icon: String {
        switch self {
        case .sky: return "cloud.sun.fill"
        case .sunset: return "sunset.fill"
        case .forest: return "leaf.fill"
        case .midnight: return "moon.stars.fill"
        case .cherry: return "heart.fill"
        case .ocean: return "water.waves"
        case .lavender: return "sparkles"
        case .coffee: return "cup.and.saucer.fill"
        case .roseGold: return "diamond.fill"
        case .cyberpunk: return "bolt.fill"
        case .mint: return "wind"
        case .autumn: return "leaf.arrow.triangle.circlepath"
        case .galaxy: return "star.fill"
        case .solar: return "sun.max.fill"
        case .berry: return "circle.fill"
        case .slate: return "square.fill"
        case .coral: return "fish.fill"
        case .emerald: return "hexagon.fill"
        case .violet: return "wand.and.stars"
        case .peach: return "flame.fill"
        }
    }
    
    var displayName: String {
        switch self {
        case .sky: return "Sky"
        case .sunset: return "Sunset"
        case .forest: return "Forest"
        case .midnight: return "Midnight"
        case .cherry: return "Cherry"
        case .ocean: return "Ocean"
        case .lavender: return "Lavender"
        case .coffee: return "Coffee"
        case .roseGold: return "Rose Gold"
        case .cyberpunk: return "Cyberpunk"
        case .mint: return "Mint"
        case .autumn: return "Autumn"
        case .galaxy: return "Galaxy"
        case .solar: return "Solar"
        case .berry: return "Berry"
        case .slate: return "Slate"
        case .coral: return "Coral"
        case .emerald: return "Emerald"
        case .violet: return "Violet"
        case .peach: return "Peach"
        }
    }
}

// MARK: - App Theme
enum AppTheme: String, CaseIterable, Codable {
    case light = "Light"
    case dark = "Dark"
}

// MARK: - Theme Colors
struct ArcThemeColors {
    let sidebarBackground: Color
    let favoriteTileBackground: Color
    let favoriteTileHover: Color
    let activeTabBackground: Color
    let activeTabShadow: Color
    let textPrimary: Color
    let textSecondary: Color
    let textTertiary: Color
    let folderIcon: Color
    let folderIconExpanded: Color
    let secondaryBackground: Color
    let tertiaryBackground: Color
    let quaternaryBackground: Color
    let separator: Color
    let accentColor: Color
    
    // Light theme colors (from reference design)
    static let light = ArcThemeColors(
        sidebarBackground: Color(red: 0.96, green: 0.94, blue: 0.97),      // #F5F0F5 (lavender/pink)
        favoriteTileBackground: Color(red: 0.92, green: 0.91, blue: 0.94), // #EBE8EF (light gray)
        favoriteTileHover: Color(red: 0.88, green: 0.86, blue: 0.90),      // Slightly darker
        activeTabBackground: Color.white,
        activeTabShadow: Color.black.opacity(0.08),
        textPrimary: Color(red: 0.10, green: 0.10, blue: 0.10),           // #1A1A1A
        textSecondary: Color(red: 0.40, green: 0.40, blue: 0.40),         // #666666
        textTertiary: Color(red: 0.60, green: 0.60, blue: 0.60),         // #999999
        folderIcon: Color(red: 0.60, green: 0.60, blue: 0.60),
        folderIconExpanded: Color(red: 0.80, green: 0.25, blue: 0.55),    // Pink/magenta for expanded
        secondaryBackground: Color(red: 0.94, green: 0.93, blue: 0.95),
        tertiaryBackground: Color(red: 0.90, green: 0.89, blue: 0.92),
        quaternaryBackground: Color(red: 0.86, green: 0.85, blue: 0.88),
        separator: Color.black.opacity(0.06),
        accentColor: Color(red: 0.42, green: 0.20, blue: 0.60)
    )
    
    // Dark theme colors (glassmorphism)
    static let dark = ArcThemeColors(
        sidebarBackground: Color(red: 0.12, green: 0.12, blue: 0.14),
        favoriteTileBackground: Color(red: 0.18, green: 0.18, blue: 0.20),
        favoriteTileHover: Color(red: 0.22, green: 0.22, blue: 0.24),
        activeTabBackground: Color(red: 0.25, green: 0.25, blue: 0.28),
        activeTabShadow: Color.black.opacity(0.20),
        textPrimary: Color.white,
        textSecondary: Color.white.opacity(0.70),
        textTertiary: Color.white.opacity(0.50),
        folderIcon: Color.white.opacity(0.60),
        folderIconExpanded: Color(red: 0.42, green: 0.20, blue: 0.60),    // Purple accent
        secondaryBackground: Color(red: 0.18, green: 0.18, blue: 0.20),
        tertiaryBackground: Color(red: 0.22, green: 0.22, blue: 0.24),
        quaternaryBackground: Color(red: 0.26, green: 0.26, blue: 0.28),
        separator: Color.white.opacity(0.10),
        accentColor: Color(red: 0.42, green: 0.20, blue: 0.60)
    )
    
    // Generate theme-specific colors based on accent color
    static func themedColors(for theme: ProfileTheme, appTheme: AppTheme) -> ArcThemeColors {
        let base = appTheme == .light ? light : dark
        let accent = theme.color
        
        if appTheme == .light {
            // Generate light theme variations based on accent
            let sidebarBg = generateLightSidebarBackground(for: theme)
            
            return ArcThemeColors(
                sidebarBackground: sidebarBg,
                favoriteTileBackground: accent.opacity(0.08),
                favoriteTileHover: accent.opacity(0.12),
                activeTabBackground: Color.white,
                activeTabShadow: accent.opacity(0.15),
                textPrimary: Color(red: 0.10, green: 0.10, blue: 0.10),
                textSecondary: Color(red: 0.40, green: 0.40, blue: 0.40),
                textTertiary: Color(red: 0.60, green: 0.60, blue: 0.60),
                folderIcon: Color(red: 0.60, green: 0.60, blue: 0.60),
                folderIconExpanded: accent,
                secondaryBackground: accent.opacity(0.06),
                tertiaryBackground: accent.opacity(0.04),
                quaternaryBackground: accent.opacity(0.02),
                separator: Color.black.opacity(0.06),
                accentColor: accent
            )
        } else {
            return ArcThemeColors(
                sidebarBackground: accent.opacity(0.15),
                favoriteTileBackground: accent.opacity(0.20),
                favoriteTileHover: accent.opacity(0.25),
                activeTabBackground: Color(red: 0.25, green: 0.25, blue: 0.28),
                activeTabShadow: accent.opacity(0.30),
                textPrimary: Color.white,
                textSecondary: Color.white.opacity(0.70),
                textTertiary: Color.white.opacity(0.50),
                folderIcon: Color.white.opacity(0.60),
                folderIconExpanded: accent,
                secondaryBackground: accent.opacity(0.18),
                tertiaryBackground: accent.opacity(0.12),
                quaternaryBackground: accent.opacity(0.08),
                separator: Color.white.opacity(0.10),
                accentColor: accent
            )
        }
    }
    
    // Generate theme-specific light sidebar backgrounds
    private static func generateLightSidebarBackground(for theme: ProfileTheme) -> Color {
        switch theme {
        case .sky:
            return Color(red: 0.94, green: 0.97, blue: 1.0)      // Light blue tint
        case .sunset:
            return Color(red: 1.0, green: 0.95, blue: 0.92)     // Warm peach
        case .forest:
            return Color(red: 0.94, green: 0.98, blue: 0.94)    // Light green
        case .midnight:
            return Color(red: 0.94, green: 0.92, blue: 0.98)   // Light purple
        case .cherry:
            return Color(red: 1.0, green: 0.93, blue: 0.95)    // Light pink
        case .ocean:
            return Color(red: 0.92, green: 0.96, blue: 1.0)    // Ocean blue
        case .lavender:
            return Color(red: 0.96, green: 0.94, blue: 0.98)   // Lavender
        case .coffee:
            return Color(red: 0.96, green: 0.93, blue: 0.90)   // Warm cream
        case .roseGold:
            return Color(red: 1.0, green: 0.94, blue: 0.93)    // Rose tint
        case .cyberpunk:
            return Color(red: 0.94, green: 0.92, blue: 0.96)    // Neon purple tint
        case .mint:
            return Color(red: 0.93, green: 0.98, blue: 0.95)  // Mint green
        case .autumn:
            return Color(red: 0.98, green: 0.94, blue: 0.90)   // Warm autumn
        case .galaxy:
            return Color(red: 0.93, green: 0.92, blue: 0.97)   // Deep purple
        case .solar:
            return Color(red: 1.0, green: 0.96, blue: 0.90)    // Solar yellow
        case .berry:
            return Color(red: 0.98, green: 0.92, blue: 0.95)   // Berry pink
        case .slate:
            return Color(red: 0.94, green: 0.95, blue: 0.97)   // Cool gray
        case .coral:
            return Color(red: 1.0, green: 0.94, blue: 0.92)     // Coral tint
        case .emerald:
            return Color(red: 0.92, green: 0.97, blue: 0.94)   // Emerald
        case .violet:
            return Color(red: 0.95, green: 0.93, blue: 0.98)    // Violet
        case .peach:
            return Color(red: 1.0, green: 0.95, blue: 0.93)     // Peach
        }
    }
}

// MARK: - Colors
struct ArcColors {
    // Primary accent colors
    static let purple = Color(red: 0.42, green: 0.20, blue: 0.60)
    static let pink = Color(red: 0.58, green: 0.28, blue: 0.48)
    static let blue = Color(red: 0.25, green: 0.38, blue: 0.72)
    
    // Surface colors
    static let surfaceDark = Color(red: 0.12, green: 0.12, blue: 0.14)
    static let surfaceLight = Color(red: 0.95, green: 0.95, blue: 0.97)
    
    // Light theme specific colors (from reference)
    static let sidebarLightBackground = Color(red: 0.96, green: 0.94, blue: 0.97)  // #F5F0F5
    static let favoriteTileLight = Color(red: 0.92, green: 0.91, blue: 0.94)       // #EBE8EF
    static let textLightPrimary = Color(red: 0.10, green: 0.10, blue: 0.10)        // #1A1A1A
    static let textLightSecondary = Color(red: 0.40, green: 0.40, blue: 0.40)      // #666666
    static let folderExpandedPink = Color(red: 0.80, green: 0.25, blue: 0.55)     // Pink folder
    
    // Text colors (legacy, use themeColors instead)
    static let textPrimary = Color.white
    static let textSecondary = Color.white.opacity(0.70)
    static let textTertiary = Color.white.opacity(0.50)
    static let textQuaternary = Color.white.opacity(0.30)
    
    // System semantic colors (for light/dark mode)
    static var background: Color {
        Color(NSColor.windowBackgroundColor)
    }
    
    static var secondaryBackground: Color {
        Color(NSColor.controlBackgroundColor)
    }
    
    static var tertiaryBackground: Color {
        Color(NSColor.tertiarySystemFill)
    }
    
    static var quaternaryBackground: Color {
        Color(NSColor.quaternarySystemFill)
    }
    
    static var separator: Color {
        Color(NSColor.separatorColor)
    }
    
    // Helper to get theme colors
    static func themeColors(for theme: AppTheme) -> ArcThemeColors {
        switch theme {
        case .light:
            return ArcThemeColors.light
        case .dark:
            return ArcThemeColors.dark
        }
    }
}

// MARK: - Typography
struct ArcTypography {
    // Nunito Font Family - Premium font integration
    
    // Hero (new tab greeting)
    static let hero = Font.custom("Nunito-Light", size: 48)
    
    // Large titles
    static let largeTitle = Font.custom("Nunito-SemiBold", size: 32)
    static let title = Font.custom("Nunito-SemiBold", size: 24)
    static let title2 = Font.custom("Nunito-SemiBold", size: 20)
    
    // Body text
    static let bodyLarge = Font.custom("Nunito-Regular", size: 16)
    static let body = Font.custom("Nunito-Regular", size: 14)
    static let bodySmall = Font.custom("Nunito-Regular", size: 13)
    
    // Tab titles
    static let tabTitle = Font.custom("Nunito-Medium", size: 13)
    static let tabTitleActive = Font.custom("Nunito-SemiBold", size: 13)
    
    // Captions and labels
    static let caption = Font.custom("Nunito-Regular", size: 12)
    static let label = Font.custom("Nunito-Medium", size: 11)
    static let labelSmall = Font.custom("Nunito-Medium", size: 10)
    
    // Command bar
    static let commandBar = Font.custom("Nunito-Regular", size: 18)
    static let commandBarSearch = Font.custom("Nunito-Regular", size: 20)
    
    // Section headers (uppercase style)
    static let sectionHeader = Font.custom("Nunito-Medium", size: 11)
}

// MARK: - Spacing
struct ArcSpacing {
    static let xs: CGFloat = 4      // Tight spacing
    static let sm: CGFloat = 8      // Icon padding
    static let md: CGFloat = 12     // Small gaps
    static let lg: CGFloat = 16     // Section padding
    static let xl: CGFloat = 20     // Major sections
    static let xxl: CGFloat = 24    // Large gaps
    static let xxxl: CGFloat = 32   // Page margins
    static let xxxxl: CGFloat = 48   // Large margins
}

// MARK: - Shadows
struct ArcShadows {
    // Subtle shadow for subtle elevation
    static let subtle = ShadowStyle(
        color: Color.black.opacity(0.05),
        radius: 8,
        x: 0,
        y: 2
    )
    
    // Medium shadow for cards and buttons
    static let medium = ShadowStyle(
        color: Color.black.opacity(0.1),
        radius: 16,
        x: 0,
        y: 4
    )
    
    // Strong shadow for floating elements
    static let strong = ShadowStyle(
        color: Color.black.opacity(0.15),
        radius: 32,
        x: 0,
        y: 8
    )
    
    // Glow effect for active elements
    static func glow(color: Color, intensity: Double = 0.4) -> ShadowStyle {
        ShadowStyle(
            color: color.opacity(intensity),
            radius: 12,
            x: 0,
            y: 0
        )
    }
    
    // Command bar shadow
    static let commandBar = ShadowStyle(
        color: Color.black.opacity(0.2),
        radius: 40,
        x: 0,
        y: 20
    )
}

struct ShadowStyle {
    let color: Color
    let radius: CGFloat
    let x: CGFloat
    let y: CGFloat
}

// MARK: - Animations
struct ArcAnimations {
    // Tab switching
    static let tabSwitch = Animation.spring(response: 0.35, dampingFraction: 0.85)
    
    // Space switching
    static let spaceSwitch = Animation.spring(response: 0.4, dampingFraction: 0.8)
    
    // Hover effects
    static let hover = Animation.easeInOut(duration: 0.15)
    
    // Sidebar collapse/expand
    static let sidebarCollapse = Animation.spring(response: 0.35, dampingFraction: 0.85)
    
    // Modal presentations
    static let modalPresent = Animation.spring(response: 0.5, dampingFraction: 0.8)
    
    // Peek preview
    static let peekPreview = Animation.spring(response: 0.3, dampingFraction: 0.7)
    
    // Quick interactions
    static let quick = Animation.easeInOut(duration: 0.1)
    
    // Gradient animation
    static let gradient = Animation.easeInOut(duration: 8).repeatForever(autoreverses: true)
}

// MARK: - Corner Radii
struct ArcCornerRadius {
    static let sm: CGFloat = 6
    static let md: CGFloat = 8
    static let lg: CGFloat = 12
    static let xl: CGFloat = 16
    static let xxl: CGFloat = 20
    static let pill: CGFloat = 100 // For pill shapes
}

// MARK: - Glassmorphism
struct ArcGlass {
    // Standard glass card
    static func card(backgroundColor: Color = Color(NSColor.controlBackgroundColor)) -> some View {
        RoundedRectangle(cornerRadius: ArcCornerRadius.lg, style: .continuous)
            .fill(.ultraThinMaterial)
            .overlay(
                RoundedRectangle(cornerRadius: ArcCornerRadius.lg, style: .continuous)
                    .stroke(Color.white.opacity(0.1), lineWidth: 1)
            )
    }
    
    // Floating glass panel
    static func floatingPanel() -> some View {
        RoundedRectangle(cornerRadius: ArcCornerRadius.xl, style: .continuous)
            .fill(.ultraThinMaterial)
            .overlay(
                RoundedRectangle(cornerRadius: ArcCornerRadius.xl, style: .continuous)
                    .stroke(Color.white.opacity(0.15), lineWidth: 1)
            )
            .shadow(color: ArcShadows.medium.color, radius: ArcShadows.medium.radius, x: ArcShadows.medium.x, y: ArcShadows.medium.y)
    }
}

// MARK: - Sidebar Dimensions
struct ArcSidebarDimensions {
    static let minWidth: CGFloat = 280
    static let defaultWidth: CGFloat = 320
    static let maxWidth: CGFloat = 380
}

// MARK: - Themes
enum ArcTheme: String, CaseIterable {
    case midnight = "Midnight"
    case sky = "Sky"
    case sunset = "Sunset"
    case forest = "Forest"
    case cherry = "Cherry"
    case ocean = "Ocean"
    case lavender = "Lavender"
    case coffee = "Coffee"
    case roseGold = "Rose Gold"
    case cyberpunk = "Cyberpunk"
    case mint = "Mint"
    case autumn = "Autumn"
    case galaxy = "Galaxy"
    case solar = "Solar"
    case berry = "Berry"
    case slate = "Slate"
    case coral = "Coral"
    case emerald = "Emerald"
    case violet = "Violet"
    case peach = "Peach"
    
    var accentColor: Color {
        switch self {
        case .midnight:
            return ArcColors.purple
        case .sky:
            return Color(red: 0.2, green: 0.6, blue: 0.9)
        case .sunset:
            return Color(red: 0.9, green: 0.4, blue: 0.3)
        case .forest:
            return Color(red: 0.2, green: 0.7, blue: 0.4)
        case .cherry:
            return Color(red: 0.9, green: 0.2, blue: 0.4)
        case .ocean:
            return Color(red: 0.15, green: 0.55, blue: 0.85)
        case .lavender:
            return Color(red: 0.65, green: 0.45, blue: 0.85)
        case .coffee:
            return Color(red: 0.55, green: 0.38, blue: 0.25)
        case .roseGold:
            return Color(red: 0.85, green: 0.55, blue: 0.55)
        case .cyberpunk:
            return Color(red: 1.0, green: 0.0, blue: 0.85)
        case .mint:
            return Color(red: 0.35, green: 0.85, blue: 0.65)
        case .autumn:
            return Color(red: 0.85, green: 0.45, blue: 0.15)
        case .galaxy:
            return Color(red: 0.45, green: 0.25, blue: 0.75)
        case .solar:
            return Color(red: 0.95, green: 0.65, blue: 0.15)
        case .berry:
            return Color(red: 0.75, green: 0.15, blue: 0.45)
        case .slate:
            return Color(red: 0.35, green: 0.45, blue: 0.55)
        case .coral:
            return Color(red: 1.0, green: 0.5, blue: 0.4)
        case .emerald:
            return Color(red: 0.2, green: 0.75, blue: 0.45)
        case .violet:
            return Color(red: 0.55, green: 0.25, blue: 0.85)
        case .peach:
            return Color(red: 1.0, green: 0.65, blue: 0.55)
        }
    }
    
    var gradientColors: [Color] {
        switch self {
        case .midnight:
            return [ArcColors.purple, ArcColors.pink, ArcColors.blue]
        case .sky:
            return [
                Color(red: 0.2, green: 0.5, blue: 0.8),
                Color(red: 0.3, green: 0.6, blue: 0.9),
                Color(red: 0.4, green: 0.7, blue: 1.0)
            ]
        case .sunset:
            return [
                Color(red: 0.8, green: 0.3, blue: 0.4),
                Color(red: 0.9, green: 0.5, blue: 0.3),
                Color(red: 1.0, green: 0.7, blue: 0.4)
            ]
        case .forest:
            return [
                Color(red: 0.2, green: 0.5, blue: 0.3),
                Color(red: 0.3, green: 0.7, blue: 0.4),
                Color(red: 0.4, green: 0.8, blue: 0.5)
            ]
        case .cherry:
            return [
                Color(red: 0.7, green: 0.2, blue: 0.4),
                Color(red: 0.9, green: 0.3, blue: 0.5),
                Color(red: 1.0, green: 0.4, blue: 0.6)
            ]
        case .ocean:
            return [
                Color(red: 0.1, green: 0.4, blue: 0.7),
                Color(red: 0.15, green: 0.55, blue: 0.85),
                Color(red: 0.25, green: 0.7, blue: 0.9),
                Color(red: 0.35, green: 0.8, blue: 0.95)
            ]
        case .lavender:
            return [
                Color(red: 0.5, green: 0.35, blue: 0.7),
                Color(red: 0.65, green: 0.45, blue: 0.85),
                Color(red: 0.75, green: 0.55, blue: 0.9),
                Color(red: 0.85, green: 0.7, blue: 0.95)
            ]
        case .coffee:
            return [
                Color(red: 0.35, green: 0.25, blue: 0.15),
                Color(red: 0.55, green: 0.38, blue: 0.25),
                Color(red: 0.7, green: 0.5, blue: 0.35),
                Color(red: 0.8, green: 0.65, blue: 0.5)
            ]
        case .roseGold:
            return [
                Color(red: 0.7, green: 0.45, blue: 0.45),
                Color(red: 0.85, green: 0.55, blue: 0.55),
                Color(red: 0.95, green: 0.7, blue: 0.65),
                Color(red: 1.0, green: 0.85, blue: 0.75)
            ]
        case .cyberpunk:
            return [
                Color(red: 0.9, green: 0.0, blue: 0.7),
                Color(red: 0.0, green: 0.9, blue: 1.0),
                Color(red: 1.0, green: 0.0, blue: 0.85),
                Color(red: 0.5, green: 0.0, blue: 1.0)
            ]
        case .mint:
            return [
                Color(red: 0.25, green: 0.65, blue: 0.5),
                Color(red: 0.35, green: 0.85, blue: 0.65),
                Color(red: 0.5, green: 0.9, blue: 0.75),
                Color(red: 0.7, green: 0.95, blue: 0.85)
            ]
        case .autumn:
            return [
                Color(red: 0.7, green: 0.3, blue: 0.1),
                Color(red: 0.85, green: 0.45, blue: 0.15),
                Color(red: 0.95, green: 0.6, blue: 0.25),
                Color(red: 0.9, green: 0.75, blue: 0.35)
            ]
        case .galaxy:
            return [
                Color(red: 0.2, green: 0.1, blue: 0.4),
                Color(red: 0.45, green: 0.25, blue: 0.75),
                Color(red: 0.65, green: 0.4, blue: 0.9),
                Color(red: 0.85, green: 0.6, blue: 1.0)
            ]
        case .solar:
            return [
                Color(red: 0.9, green: 0.5, blue: 0.1),
                Color(red: 0.95, green: 0.65, blue: 0.15),
                Color(red: 1.0, green: 0.8, blue: 0.3),
                Color(red: 1.0, green: 0.9, blue: 0.5)
            ]
        case .berry:
            return [
                Color(red: 0.55, green: 0.1, blue: 0.35),
                Color(red: 0.75, green: 0.15, blue: 0.45),
                Color(red: 0.9, green: 0.25, blue: 0.55),
                Color(red: 1.0, green: 0.4, blue: 0.65)
            ]
        case .slate:
            return [
                Color(red: 0.2, green: 0.25, blue: 0.35),
                Color(red: 0.35, green: 0.45, blue: 0.55),
                Color(red: 0.5, green: 0.6, blue: 0.7),
                Color(red: 0.65, green: 0.75, blue: 0.85)
            ]
        case .coral:
            return [
                Color(red: 0.85, green: 0.35, blue: 0.25),
                Color(red: 1.0, green: 0.5, blue: 0.4),
                Color(red: 1.0, green: 0.65, blue: 0.55),
                Color(red: 1.0, green: 0.8, blue: 0.7)
            ]
        case .emerald:
            return [
                Color(red: 0.1, green: 0.55, blue: 0.35),
                Color(red: 0.2, green: 0.75, blue: 0.45),
                Color(red: 0.35, green: 0.85, blue: 0.55),
                Color(red: 0.55, green: 0.95, blue: 0.7)
            ]
        case .violet:
            return [
                Color(red: 0.35, green: 0.15, blue: 0.65),
                Color(red: 0.55, green: 0.25, blue: 0.85),
                Color(red: 0.7, green: 0.45, blue: 0.95),
                Color(red: 0.85, green: 0.65, blue: 1.0)
            ]
        case .peach:
            return [
                Color(red: 0.9, green: 0.5, blue: 0.4),
                Color(red: 1.0, green: 0.65, blue: 0.55),
                Color(red: 1.0, green: 0.8, blue: 0.7),
                Color(red: 1.0, green: 0.9, blue: 0.85)
            ]
        }
    }
    
    var icon: String {
        switch self {
        case .midnight: return "moon.stars.fill"
        case .sky: return "cloud.sun.fill"
        case .sunset: return "sunset.fill"
        case .forest: return "leaf.fill"
        case .cherry: return "heart.fill"
        case .ocean: return "water.waves"
        case .lavender: return "sparkles"
        case .coffee: return "cup.and.saucer.fill"
        case .roseGold: return "diamond.fill"
        case .cyberpunk: return "bolt.fill"
        case .mint: return "wind"
        case .autumn: return "leaf.arrow.triangle.circlepath"
        case .galaxy: return "star.fill"
        case .solar: return "sun.max.fill"
        case .berry: return "circle.fill"
        case .slate: return "square.fill"
        case .coral: return "fish.fill"
        case .emerald: return "hexagon.fill"
        case .violet: return "wand.and.stars"
        case .peach: return "flame.fill"
        }
    }
    
    var description: String {
        switch self {
        case .midnight: return "Deep purple tones for focused work"
        case .sky: return "Calm blues for a clear mind"
        case .sunset: return "Warm oranges for creative flow"
        case .forest: return "Natural greens for tranquility"
        case .cherry: return "Vibrant pinks for energy"
        case .ocean: return "Deep sea blues for depth"
        case .lavender: return "Soft purples for relaxation"
        case .coffee: return "Warm browns for comfort"
        case .roseGold: return "Elegant pink-gold sophistication"
        case .cyberpunk: return "Neon futuristic vibes"
        case .mint: return "Fresh greens for clarity"
        case .autumn: return "Rich oranges and golds"
        case .galaxy: return "Cosmic purple depths"
        case .solar: return "Bright yellows for optimism"
        case .berry: return "Rich reds for passion"
        case .slate: return "Cool grays for professionalism"
        case .coral: return "Sea-inspired warmth"
        case .emerald: return "Jewel greens for luxury"
        case .violet: return "Royal purple elegance"
        case .peach: return "Soft warmth and comfort"
        }
    }
}
