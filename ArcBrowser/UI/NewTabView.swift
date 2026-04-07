import SwiftUI
import Combine

// MARK: - Arc Browser New Tab View
// A beautiful, Arc-inspired new tab page with favorites and recent history

struct NewTabView: View {
    @StateObject private var viewModel: NewTabViewModel
    var onOpenURL: (String) -> Void
    var onCreateTab: () -> Void
    var onSelectTab: (UUID) -> Void
    var onSelectSpace: (UUID) -> Void
    
    init(
        savedLinks: [SavedLink],
        recentHistory: [BrowserHistoryEntry],
        selectedProfile: BrowserProfile,
        onOpenURL: @escaping (String) -> Void,
        onCreateTab: @escaping () -> Void,
        onSelectTab: @escaping (UUID) -> Void,
        onSelectSpace: @escaping (UUID) -> Void
    ) {
        self._viewModel = StateObject(wrappedValue: NewTabViewModel(
            savedLinks: savedLinks,
            recentHistory: recentHistory,
            selectedProfile: selectedProfile
        ))
        self.onOpenURL = onOpenURL
        self.onCreateTab = onCreateTab
        self.onSelectTab = onSelectTab
        self.onSelectSpace = onSelectSpace
    }
    
    var body: some View {
        ZStack {
            // Background matching sidebar theme - lavender for light theme
            ArcThemeColors.light.sidebarBackground
                .ignoresSafeArea()
        }
        .sheet(isPresented: $viewModel.showingCommandBar) {
            ArcCommandBarSheet(
                isPresented: $viewModel.showingCommandBar,
                onCreateTab: onCreateTab,
                onOpenURL: onOpenURL
            )
        }
    }
}

// MARK: - View Model
@MainActor
class NewTabViewModel: ObservableObject {
    @Published var savedLinks: [SavedLink]
    @Published var recentHistory: [BrowserHistoryEntry]
    @Published var selectedProfile: BrowserProfile
    @Published var showingCommandBar = false
    
    init(savedLinks: [SavedLink], recentHistory: [BrowserHistoryEntry], selectedProfile: BrowserProfile) {
        self.savedLinks = savedLinks
        self.recentHistory = recentHistory
        self.selectedProfile = selectedProfile
    }
}

// MARK: - Background
struct ArcBackgroundView: View {
    let themeColor: Color
    @State private var animateGradient = false
    
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                // Animated base gradient - Arc's signature purple/pink/blue blend
                LinearGradient(
                    colors: [
                        Color(red: 0.42, green: 0.20, blue: 0.60),  // Deep purple
                        Color(red: 0.58, green: 0.28, blue: 0.48),  // Pink-purple
                        Color(red: 0.25, green: 0.38, blue: 0.72),  // Soft blue
                        Color(red: 0.42, green: 0.20, blue: 0.60),  // Deep purple (loop back)
                    ],
                    startPoint: animateGradient ? .topLeading : .bottomTrailing,
                    endPoint: animateGradient ? .bottomTrailing : .topLeading
                )
                .hueRotation(.degrees(animateGradient ? 5 : -5))
                .animation(.easeInOut(duration: 8).repeatForever(autoreverses: true), value: animateGradient)
                .onAppear { animateGradient = true }
                
                // Animated radial glow overlays for that Arc "glow" effect
                RadialGradient(
                    colors: [
                        Color.pink.opacity(0.4),
                        Color.clear
                    ],
                    center: .topTrailing,
                    startRadius: 0,
                    endRadius: geometry.size.width * 0.7
                )
                .offset(x: animateGradient ? 50 : -50, y: animateGradient ? -30 : 30)
                .animation(.easeInOut(duration: 6).repeatForever(autoreverses: true), value: animateGradient)
                
                RadialGradient(
                    colors: [
                        Color.purple.opacity(0.35),
                        Color.clear
                    ],
                    center: .topLeading,
                    startRadius: 0,
                    endRadius: geometry.size.width * 0.6
                )
                .offset(x: animateGradient ? -30 : 30, y: animateGradient ? 20 : -20)
                .animation(.easeInOut(duration: 7).repeatForever(autoreverses: true), value: animateGradient)
                
                RadialGradient(
                    colors: [
                        Color.blue.opacity(0.3),
                        Color.clear
                    ],
                    center: .bottomTrailing,
                    startRadius: 0,
                    endRadius: geometry.size.width * 0.5
                )
                .offset(x: animateGradient ? 40 : -40, y: animateGradient ? -40 : 40)
                .animation(.easeInOut(duration: 5).repeatForever(autoreverses: true), value: animateGradient)
                
                // Soft glow spots with blur
                Circle()
                    .fill(Color.pink.opacity(0.2))
                    .frame(width: geometry.size.width * 0.8)
                    .blur(radius: 100)
                    .offset(x: geometry.size.width * 0.2, y: -geometry.size.height * 0.1)
                
                Circle()
                    .fill(Color.purple.opacity(0.15))
                    .frame(width: geometry.size.width * 0.6)
                    .blur(radius: 80)
                    .offset(x: -geometry.size.width * 0.1, y: geometry.size.height * 0.4)
                
                // Noise texture overlay for subtle grain
                Color.white.opacity(0.03)
                    .blendMode(.overlay)
                
                // Subtle vignette for depth
                RadialGradient(
                    colors: [
                        Color.clear,
                        Color.black.opacity(0.25)
                    ],
                    center: .center,
                    startRadius: geometry.size.width * 0.4,
                    endRadius: geometry.size.width
                )
            }
        }
        .ignoresSafeArea()
    }
}

// MARK: - Greeting Section
struct ArcGreetingSection: View {
    @State private var appearOffset: CGFloat = 30
    @State private var appearOpacity: Double = 0
    
    var body: some View {
        VStack(spacing: 12) {
            Text(greetingText)
                .font(Font.custom("Nunito-Light", size: 56))
                .foregroundStyle(.primary)
                .shadow(color: .black.opacity(0.1), radius: 20, x: 0, y: 10)
            
            Text("Ready to browse?")
                .font(Font.custom("Nunito-Medium", size: 20))
                .foregroundStyle(.secondary.opacity(0.9))
        }
        .offset(y: appearOffset)
        .opacity(appearOpacity)
        .onAppear {
            withAnimation(.spring(response: 0.8, dampingFraction: 0.7)) {
                appearOffset = 0
                appearOpacity = 1
            }
        }
    }
    
    private var greetingText: String {
        let hour = Calendar.current.component(.hour, from: Date())
        switch hour {
        case 0..<12: return "Good morning"
        case 12..<17: return "Good afternoon"
        case 17..<21: return "Good evening"
        default: return "Good night"
        }
    }
}

// MARK: - Command Bar Button
struct ArcCommandBarButton: View {
    let themeColor: Color
    let action: () -> Void
    
    @State private var isHovered = false
    @State private var isPressed = false
    @State private var appearOffset: CGFloat = 20
    @State private var appearOpacity: Double = 0
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 14) {
                Image(systemName: "magnifyingglass")
                    .font(.system(size: 20, weight: .semibold))
                    .foregroundStyle(themeColor)
                
                Text("Search or enter address...")
                    .font(.system(size: 17, weight: .regular, design: .rounded))
                    .foregroundStyle(.primary.opacity(0.8))
                
                Spacer()
                
                HStack(spacing: 6) {
                    KeyboardShortcutBadge(shortcut: "⌘")
                    KeyboardShortcutBadge(shortcut: "K")
                }
            }
            .padding(.horizontal, 24)
            .padding(.vertical, 18)
        }
        .buttonStyle(.plain)
        .background(
            ZStack {
                // Glassmorphism background
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .fill(.ultraThinMaterial)
                
                // Subtle gradient overlay
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .fill(
                        LinearGradient(
                            colors: [
                                Color.white.opacity(0.1),
                                Color.white.opacity(0.05)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                
                // Border with glow on hover
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .stroke(
                        isHovered ? 
                            themeColor.opacity(0.5) :
                            Color.white.opacity(0.2),
                        lineWidth: isHovered ? 2 : 1
                    )
                    .shadow(color: themeColor.opacity(isHovered ? 0.4 : 0), radius: isHovered ? 15 : 0)
            }
        )
        .shadow(
            color: .black.opacity(isHovered ? 0.2 : 0.1),
            radius: isHovered ? 30 : 20,
            x: 0,
            y: isHovered ? 12 : 8
        )
        .scaleEffect(isPressed ? 0.98 : 1.0)
        .offset(y: appearOffset)
        .opacity(appearOpacity)
        .frame(maxWidth: 640)
        .animation(.spring(response: 0.4, dampingFraction: 0.8), value: isHovered)
        .animation(.spring(response: 0.2, dampingFraction: 0.7), value: isPressed)
        .onHover { hovering in
            isHovered = hovering
        }
        .onAppear {
            withAnimation(.spring(response: 0.6, dampingFraction: 0.8).delay(0.1)) {
                appearOffset = 0
                appearOpacity = 1
            }
        }
    }
}

// MARK: - Keyboard Shortcut Badge
struct KeyboardShortcutBadge: View {
    let shortcut: String
    
    var body: some View {
        Text(shortcut)
            .font(Font.custom("Nunito-SemiBold", size: 12))
            .foregroundStyle(.secondary.opacity(0.8))
            .padding(.horizontal, 8)
            .padding(.vertical, 5)
            .background(
                RoundedRectangle(cornerRadius: 6, style: .continuous)
                    .fill(Color.secondary.opacity(0.12))
                    .overlay(
                        RoundedRectangle(cornerRadius: 6, style: .continuous)
                            .stroke(Color.secondary.opacity(0.2), lineWidth: 0.5)
                    )
            )
    }
}

// MARK: - Favorites Section
struct ArcFavoritesSection: View {
    let savedLinks: [SavedLink]
    let themeColor: Color
    let onOpenURL: (String) -> Void
    
    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            HStack {
                Text("Favorites")
                    .font(.system(size: 20, weight: .semibold, design: .rounded))
                
                Spacer()
                
                Button {
                    // Add favorite
                } label: {
                    Image(systemName: "plus.circle.fill")
                        .font(.system(size: 22))
                        .foregroundStyle(themeColor)
                }
                .buttonStyle(.plain)
            }
            
            LazyVGrid(columns: [GridItem(.adaptive(minimum: 140, maximum: 160))], spacing: 16) {
                ForEach(Array(savedLinks.prefix(8))) { link in
                    ArcFavoriteCard(
                        link: link,
                        themeColor: themeColor,
                        onOpenURL: onOpenURL
                    )
                }
                
                ArcAddFavoriteCard(themeColor: themeColor)
            }
        }
    }
}

// MARK: - Favorite Card
struct ArcFavoriteCard: View {
    let link: SavedLink
    let themeColor: Color
    let onOpenURL: (String) -> Void
    
    @State private var isHovered = false
    @State private var isPressed = false
    @State private var appearOffset: CGFloat = 20
    @State private var appearOpacity: Double = 0
    
    var body: some View {
        Button {
            withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                isPressed = true
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                onOpenURL(link.url)
                isPressed = false
            }
        } label: {
            VStack(spacing: 14) {
                // Enhanced icon container with glassmorphism
                ArcIconContainer(themeColor: themeColor, icon: faviconFor(link.url), isHovered: isHovered)
                
                VStack(spacing: 4) {
                    Text(link.title)
                        .font(.system(size: 14, weight: .semibold, design: .rounded))
                        .lineLimit(1)
                        .foregroundStyle(.primary)
                    
                    Text(URL(string: link.url)?.host ?? link.url)
                        .font(.system(size: 11, weight: .regular, design: .rounded))
                        .lineLimit(1)
                        .foregroundStyle(.secondary.opacity(0.8))
                }
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 20)
            .background(
                ZStack {
                    // Glassmorphism background
                    RoundedRectangle(cornerRadius: 24, style: .continuous)
                        .fill(.ultraThinMaterial)
                    
                    // Subtle border
                    RoundedRectangle(cornerRadius: 24, style: .continuous)
                        .stroke(Color.white.opacity(isHovered ? 0.3 : 0.15), lineWidth: 1)
                    
                    // Glow effect when hovered
                    RoundedRectangle(cornerRadius: 24, style: .continuous)
                        .fill(themeColor.opacity(isHovered ? 0.1 : 0))
                        .blur(radius: isHovered ? 20 : 0)
                }
            )
            .shadow(
                color: isHovered ? themeColor.opacity(0.25) : .black.opacity(0.08),
                radius: isHovered ? 30 : 16,
                x: 0,
                y: isHovered ? 15 : 6
            )
            .scaleEffect(isPressed ? 0.95 : (isHovered ? 1.05 : 1.0))
            .offset(y: appearOffset)
            .opacity(appearOpacity)
        }
        .buttonStyle(.plain)
        .animation(.spring(response: 0.4, dampingFraction: 0.8), value: isHovered)
        .animation(.spring(response: 0.2, dampingFraction: 0.7), value: isPressed)
        .onHover { hovering in
            isHovered = hovering
        }
        .onAppear {
            withAnimation(.spring(response: 0.6, dampingFraction: 0.8).delay(Double.random(in: 0...0.3))) {
                appearOffset = 0
                appearOpacity = 1
            }
        }
    }
    
    private func faviconFor(_ url: String) -> String {
        let lowercased = url.lowercased()
        if lowercased.contains("google") { return "g.circle.fill" }
        if lowercased.contains("github") { return "number.circle.fill" }
        if lowercased.contains("youtube") { return "play.rectangle.fill" }
        if lowercased.contains("twitter") || lowercased.contains("x.com") { return "bird.fill" }
        if lowercased.contains("mail") || lowercased.contains("gmail") { return "envelope.fill" }
        if lowercased.contains("linear") { return "line.horizontal.3" }
        if lowercased.contains("apple") { return "apple.logo" }
        return "globe"
    }
}

// MARK: - Icon Container
struct ArcIconContainer: View {
    let themeColor: Color
    let icon: String
    var isHovered: Bool = false
    
    var body: some View {
        ZStack {
            // Background with gradient
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .fill(
                    LinearGradient(
                        colors: [
                            themeColor.opacity(0.2),
                            themeColor.opacity(0.1)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .frame(width: 60, height: 60)
                .overlay(
                    RoundedRectangle(cornerRadius: 18, style: .continuous)
                        .stroke(Color.white.opacity(0.3), lineWidth: 1)
                )
            
            // Icon with glow when hovered
            Image(systemName: icon)
                .font(.system(size: 26, weight: .medium))
                .foregroundStyle(themeColor)
                .shadow(color: themeColor.opacity(isHovered ? 0.5 : 0), radius: isHovered ? 10 : 0)
                .scaleEffect(isHovered ? 1.1 : 1.0)
                .animation(.spring(response: 0.3, dampingFraction: 0.7), value: isHovered)
        }
    }
}

// MARK: - Add Favorite Card
struct ArcAddFavoriteCard: View {
    let themeColor: Color
    @State private var isHovered = false
    @State private var isPressed = false
    @State private var appearOffset: CGFloat = 20
    @State private var appearOpacity: Double = 0
    
    var body: some View {
        Button {
            withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                isPressed = true
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                isPressed = false
            }
        } label: {
            VStack(spacing: 14) {
                ZStack {
                    // Dashed border background
                    RoundedRectangle(cornerRadius: 18, style: .continuous)
                        .fill(Color.secondary.opacity(isHovered ? 0.08 : 0.05))
                        .frame(width: 60, height: 60)
                        .overlay(
                            RoundedRectangle(cornerRadius: 18, style: .continuous)
                                .stroke(
                                    Color.secondary.opacity(isHovered ? 0.4 : 0.25),
                                    style: StrokeStyle(lineWidth: 2, dash: [6, 4])
                                )
                        )
                    
                    Image(systemName: "plus")
                        .font(.system(size: 26, weight: .medium))
                        .foregroundStyle(.secondary)
                        .rotationEffect(.degrees(isHovered ? 90 : 0))
                }
                
                Text("Add Favorite")
                    .font(.system(size: 14, weight: .semibold, design: .rounded))
                    .foregroundStyle(.secondary.opacity(0.8))
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 20)
            .background(
                RoundedRectangle(cornerRadius: 24, style: .continuous)
                    .fill(.ultraThinMaterial.opacity(0.5))
                    .overlay(
                        RoundedRectangle(cornerRadius: 24, style: .continuous)
                            .stroke(Color.secondary.opacity(isHovered ? 0.25 : 0.15), style: StrokeStyle(lineWidth: 2, dash: [8, 5]))
                    )
            )
            .shadow(
                color: isHovered ? .black.opacity(0.08) : .clear,
                radius: isHovered ? 20 : 0,
                x: 0,
                y: isHovered ? 8 : 0
            )
            .scaleEffect(isPressed ? 0.95 : (isHovered ? 1.03 : 1.0))
            .offset(y: appearOffset)
            .opacity(appearOpacity)
        }
        .buttonStyle(.plain)
        .animation(.spring(response: 0.4, dampingFraction: 0.8), value: isHovered)
        .animation(.spring(response: 0.2, dampingFraction: 0.7), value: isPressed)
        .onHover { hovering in
            isHovered = hovering
        }
        .onAppear {
            withAnimation(.spring(response: 0.6, dampingFraction: 0.8).delay(Double.random(in: 0.1...0.4))) {
                appearOffset = 0
                appearOpacity = 1
            }
        }
    }
}

// MARK: - Recent Section
struct ArcRecentSection: View {
    let history: [BrowserHistoryEntry]
    let themeColor: Color
    let onOpenURL: (String) -> Void
    
    var body: some View {
        VStack(alignment: .leading, spacing: 24) {
            Text("Recent")
                .font(.system(size: 22, weight: .bold, design: .rounded))
                .foregroundStyle(.primary.opacity(0.9))
            
            VStack(spacing: 8) {
                ForEach(Array(history.prefix(6).enumerated()), id: \.element.id) { index, entry in
                    ArcRecentItemRow(
                        entry: entry,
                        themeColor: themeColor,
                        onOpenURL: onOpenURL,
                        index: index
                    )
                }
            }
            .padding(16)
            .background(
                RoundedRectangle(cornerRadius: 20, style: .continuous)
                    .fill(.ultraThinMaterial)
                    .overlay(
                        RoundedRectangle(cornerRadius: 20, style: .continuous)
                            .stroke(Color.white.opacity(0.15), lineWidth: 1)
                    )
            )
            .shadow(color: .black.opacity(0.08), radius: 20, x: 0, y: 8)
        }
    }
}

// MARK: - Recent Item Row
struct ArcRecentItemRow: View {
    let entry: BrowserHistoryEntry
    let themeColor: Color
    let onOpenURL: (String) -> Void
    let index: Int
    
    @State private var isHovered = false
    @State private var appearOffset: CGFloat = 15
    @State private var appearOpacity: Double = 0
    
    var body: some View {
        Button {
            onOpenURL(entry.url)
        } label: {
            HStack(spacing: 14) {
                // Enhanced favicon
                ZStack {
                    RoundedRectangle(cornerRadius: 10, style: .continuous)
                        .fill(
                            LinearGradient(
                                colors: [
                                    themeColor.opacity(0.15),
                                    themeColor.opacity(0.08)
                                ],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 36, height: 36)
                        .overlay(
                            RoundedRectangle(cornerRadius: 10, style: .continuous)
                                .stroke(Color.white.opacity(0.3), lineWidth: 0.5)
                        )
                    
                    Image(systemName: faviconFor(entry.url))
                        .font(.system(size: 16, weight: .medium))
                        .foregroundStyle(themeColor)
                }
                
                VStack(alignment: .leading, spacing: 3) {
                    Text(entry.title)
                        .font(.system(size: 14, weight: .semibold, design: .rounded))
                        .lineLimit(1)
                        .foregroundStyle(.primary)
                    
                    Text(URL(string: entry.url)?.host ?? entry.url)
                        .font(.system(size: 12, weight: .medium, design: .rounded))
                        .foregroundStyle(.secondary.opacity(0.8))
                        .lineLimit(1)
                }
                
                Spacer()
                
                Image(systemName: "arrow.up.right")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(themeColor)
                    .opacity(isHovered ? 1 : 0)
                    .scaleEffect(isHovered ? 1 : 0.8)
                    .animation(.spring(response: 0.3, dampingFraction: 0.7), value: isHovered)
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 10)
            .background(
                ZStack {
                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                        .fill(isHovered ? themeColor.opacity(0.08) : Color.clear)
                    
                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                        .stroke(isHovered ? themeColor.opacity(0.2) : Color.clear, lineWidth: 1)
                }
            )
            .offset(x: appearOffset)
            .opacity(appearOpacity)
        }
        .buttonStyle(.plain)
        .animation(.spring(response: 0.3, dampingFraction: 0.8), value: isHovered)
        .onHover { hovering in
            isHovered = hovering
        }
        .onAppear {
            withAnimation(.spring(response: 0.5, dampingFraction: 0.8).delay(Double(index) * 0.05)) {
                appearOffset = 0
                appearOpacity = 1
            }
        }
    }
    
    private func faviconFor(_ url: String) -> String {
        let lowercased = url.lowercased()
        if lowercased.contains("google") { return "g.circle.fill" }
        if lowercased.contains("github") { return "number.circle.fill" }
        if lowercased.contains("youtube") { return "play.rectangle.fill" }
        if lowercased.contains("twitter") || lowercased.contains("x.com") { return "bird.fill" }
        if lowercased.contains("mail") || lowercased.contains("gmail") { return "envelope.fill" }
        return "globe"
    }
}

// MARK: - Command Bar Sheet
struct ArcCommandBarSheet: View {
    @Binding var isPresented: Bool
    let onCreateTab: () -> Void
    let onOpenURL: (String) -> Void
    
    var body: some View {
        ZStack {
            Color.black.opacity(0.25)
                .ignoresSafeArea()
                .onTapGesture {
                    isPresented = false
                }
            
            ArcCommandBarContent(
                isPresented: $isPresented,
                onCreateTab: onCreateTab,
                onOpenURL: onOpenURL
            )
        }
    }
}

// MARK: - Command Bar Content
struct ArcCommandBarContent: View {
    @Binding var isPresented: Bool
    let onCreateTab: () -> Void
    let onOpenURL: (String) -> Void
    
    @State private var query = ""
    @FocusState private var isFocused: Bool
    
    var body: some View {
        VStack(spacing: 0) {
            // Search field
            HStack(spacing: 12) {
                Image(systemName: "magnifyingglass")
                    .font(.system(size: 20))
                    .foregroundStyle(.secondary)
                
                TextField("Search tabs, history, or enter URL...", text: $query)
                    .font(.system(size: 18, weight: .regular, design: .rounded))
                    .textFieldStyle(.plain)
                    .focused($isFocused)
                    .onSubmit {
                        handleSubmit()
                    }
                
                if !query.isEmpty {
                    Button {
                        query = ""
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .font(.system(size: 18))
                            .foregroundStyle(.secondary)
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 16)
            
            Divider()
            
            // Results
            ScrollView {
                VStack(spacing: 8) {
                    if query.isEmpty {
                        // Default state
                        VStack(spacing: 12) {
                            Image(systemName: "command")
                                .font(.system(size: 32))
                                .foregroundStyle(.secondary.opacity(0.5))
                            
                            Text("Type a URL or search term")
                                .font(.system(size: 14, weight: .medium, design: .rounded))
                                .foregroundStyle(.secondary)
                            
                            Text("Press Enter to navigate")
                                .font(.system(size: 12, weight: .regular, design: .rounded))
                                .foregroundStyle(.secondary.opacity(0.6))
                        }
                        .padding(.top, 40)
                    } else {
                        // URL entry option
                        Button {
                            handleSubmit()
                        } label: {
                            HStack(spacing: 12) {
                                Image(systemName: "arrow.up.forward")
                                    .font(.system(size: 16))
                                    .foregroundStyle(.blue)
                                    .frame(width: 24)
                                
                                VStack(alignment: .leading, spacing: 2) {
                                    Text("Go to \"\(query)\"")
                                        .font(.system(size: 14, weight: .semibold, design: .rounded))
                                        .foregroundStyle(.primary)
                                    
                                    Text("Navigate to this URL")
                                        .font(.system(size: 12, weight: .regular, design: .rounded))
                                        .foregroundStyle(.secondary)
                                }
                                
                                Spacer()
                                
                                Text("↵")
                                    .font(.system(size: 14, weight: .bold))
                                    .foregroundStyle(.secondary.opacity(0.6))
                            }
                            .padding(.horizontal, 16)
                            .padding(.vertical, 12)
                            .background(
                                RoundedRectangle(cornerRadius: 8, style: .continuous)
                                    .fill(Color.blue.opacity(0.08))
                            )
                        }
                        .buttonStyle(.plain)
                        .padding(.horizontal, 12)
                        .padding(.top, 8)
                    }
                }
                .padding(.vertical, 8)
            }
            .frame(maxHeight: 300)
        }
        .frame(width: 640)
        .background(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(Color(NSColor.windowBackgroundColor))
                .shadow(color: .black.opacity(0.2), radius: 60, x: 0, y: 30)
        )
        .onAppear {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                isFocused = true
            }
        }
    }
    
    private func handleSubmit() {
        guard !query.isEmpty else { return }
        
        // Close command bar first
        isPresented = false
        
        // Small delay to let the sheet dismiss
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) {
            onOpenURL(query)
        }
    }
}

// MARK: - Preview
#Preview {
    NewTabView(
        savedLinks: [
            SavedLink(id: UUID(), spaceID: UUID(), folderID: nil, title: "Google", url: "https://google.com"),
            SavedLink(id: UUID(), spaceID: UUID(), folderID: nil, title: "GitHub", url: "https://github.com"),
            SavedLink(id: UUID(), spaceID: UUID(), folderID: nil, title: "YouTube", url: "https://youtube.com")
        ],
        recentHistory: [
            BrowserHistoryEntry(id: UUID(), title: "Apple", url: "https://apple.com", visitedAt: Date()),
            BrowserHistoryEntry(id: UUID(), title: "GitHub", url: "https://github.com", visitedAt: Date().addingTimeInterval(-3600))
        ],
        selectedProfile: BrowserProfile(id: UUID(), name: "Work", theme: .sky),
        onOpenURL: { _ in },
        onCreateTab: {},
        onSelectTab: { _ in },
        onSelectSpace: { _ in }
    )
}
