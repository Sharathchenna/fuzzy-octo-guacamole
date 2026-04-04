import SwiftUI

// MARK: - Arc Design System
// Complete design tokens for the Arc Browser clone

// MARK: - Colors
struct ArcColors {
    // Primary accent colors
    static let purple = Color(red: 0.42, green: 0.20, blue: 0.60)
    static let pink = Color(red: 0.58, green: 0.28, blue: 0.48)
    static let blue = Color(red: 0.25, green: 0.38, blue: 0.72)
    
    // Surface colors
    static let surfaceDark = Color(red: 0.12, green: 0.12, blue: 0.14)
    static let surfaceLight = Color(red: 0.95, green: 0.95, blue: 0.97)
    
    // Text colors
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
}

// MARK: - Typography
struct ArcTypography {
    // Hero (new tab greeting)
    static let hero = Font.system(size: 48, weight: .light, design: .rounded)
    
    // Large titles
    static let largeTitle = Font.system(size: 32, weight: .semibold, design: .rounded)
    static let title = Font.system(size: 24, weight: .semibold, design: .rounded)
    static let title2 = Font.system(size: 20, weight: .semibold, design: .rounded)
    
    // Body text
    static let bodyLarge = Font.system(size: 16, weight: .regular, design: .rounded)
    static let body = Font.system(size: 14, weight: .regular, design: .rounded)
    static let bodySmall = Font.system(size: 13, weight: .regular, design: .rounded)
    
    // Tab titles
    static let tabTitle = Font.system(size: 13, weight: .medium, design: .rounded)
    static let tabTitleActive = Font.system(size: 13, weight: .semibold, design: .rounded)
    
    // Captions and labels
    static let caption = Font.system(size: 12, weight: .regular, design: .rounded)
    static let label = Font.system(size: 11, weight: .medium, design: .rounded)
    static let labelSmall = Font.system(size: 10, weight: .medium, design: .rounded)
    
    // Command bar
    static let commandBar = Font.system(size: 18, weight: .regular, design: .rounded)
    static let commandBarSearch = Font.system(size: 20, weight: .regular, design: .rounded)
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
    static let minWidth: CGFloat = 200
    static let defaultWidth: CGFloat = 260
    static let maxWidth: CGFloat = 320
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
