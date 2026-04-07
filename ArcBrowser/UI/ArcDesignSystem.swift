import SwiftUI

// MARK: - Arc Design System
// Complete design tokens for the Arc Browser clone

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
        separator: Color.black.opacity(0.06)
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
        separator: Color.white.opacity(0.10)
    )
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
        }
    }
}
