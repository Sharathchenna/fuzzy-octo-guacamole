import AppKit
import Combine
import SwiftUI

// MARK: - Arc Style Content View
// Redesigned following SwiftUI Design Principles and Frontend Design best practices
// Key principles applied:
// - Restraint over decoration
// - Consistent spacing (4, 8, 12, 16, 20, 24, 32)
// - Limited typography scale (5 sizes max)
// - System semantic colors
// - One font design (.rounded) throughout
// - Bold, distinctive aesthetic

struct ContentView: View {
    @StateObject private var browserViewModel = BrowserViewModel()
    @StateObject private var shellViewModel = BrowserShellViewModel()
    @State private var addressBarText = ""
    @State private var isSidebarCollapsed = false
    @State private var showingCommandBar = false
    
    // Split view state
    @State private var isSplitViewActive = false
    @State private var splitTabID: UUID?
    @StateObject private var splitBrowserViewModel = BrowserViewModel()
    
    // Animation states
    @State private var sidebarAppeared = false
    
    private var themeColor: Color {
        shellViewModel.selectedProfile.theme.color
    }
    
    var body: some View {
        HStack(spacing: 0) {
            // Arc-style Sidebar
            if !isSidebarCollapsed {
                ArcSidebar(
                    shellViewModel: shellViewModel,
                    browserViewModel: browserViewModel,
                    addressBarText: $addressBarText,
                    isCollapsed: $isSidebarCollapsed,
                    showingCommandBar: $showingCommandBar,
                    isSplitViewActive: isSplitViewActive,
                    onToggleSplitView: toggleSplitView
                )
                .frame(width: 260)
                .transition(.move(edge: .leading).combined(with: .opacity))
            }
            
            // Main Content Area with Split View support
            ArcMainContent(
                browserViewModel: browserViewModel,
                splitBrowserViewModel: splitBrowserViewModel,
                shellViewModel: shellViewModel,
                addressBarText: $addressBarText,
                isSidebarCollapsed: isSidebarCollapsed,
                isSplitViewActive: isSplitViewActive,
                splitTabID: splitTabID,
                onToggleSidebar: { 
                    withAnimation(.spring(response: 0.35, dampingFraction: 0.85)) {
                        isSidebarCollapsed.toggle()
                    }
                },
                onToggleSplitView: toggleSplitView
            )
        }
        .frame(minWidth: 960, minHeight: 640)
        .sheet(isPresented: $showingCommandBar) {
            ArcSpotlightCommandBar(
                shellViewModel: shellViewModel,
                browserViewModel: browserViewModel,
                isPresented: $showingCommandBar,
                onOpenURL: { url in
                    addressBarText = url
                    // Update the current tab's URL so the view switches from NewTabView to WebView
                    shellViewModel.updateSelectedTab(title: "Loading...", url: url)
                    browserViewModel.load(url)
                }
            )
        }
        .onReceive(browserViewModel.$displayURL) { url in
            if !url.isEmpty {
                addressBarText = url
                shellViewModel.recordHistoryVisit(title: browserViewModel.pageTitle, url: url)
            }
        }
        .onAppear {
            setupBrowserCallbacks()
            loadInitialTab()
        }
    }
    
    private func toggleSplitView() {
        withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
            if isSplitViewActive {
                isSplitViewActive = false
                splitTabID = nil
            } else {
                let currentTabs = shellViewModel.tabsForSelectedSpace
                if let currentTab = shellViewModel.selectedTab,
                   let nextTab = currentTabs.first(where: { $0.id != currentTab.id }) {
                    isSplitViewActive = true
                    splitTabID = nextTab.id
                    splitBrowserViewModel.load(nextTab.url)
                }
            }
        }
    }
    
    private func setupBrowserCallbacks() {
        browserViewModel.onStateChange = { title, url in
            shellViewModel.updateSelectedTab(title: title, url: url)
        }
        browserViewModel.onDownloadRequested = { title, url in
            shellViewModel.recordDownloadRequested(title: title, sourceURL: url)
        }
        browserViewModel.onDownloadFinished = { destination in
            shellViewModel.markLatestDownloadFinished(destinationURL: destination)
        }
    }
    
    private func loadInitialTab() {
        if let tab = shellViewModel.selectedTab {
            addressBarText = tab.url
            browserViewModel.load(tab.url)
        }
    }
}

// MARK: - Arc Sidebar
// Redesigned with proper spacing and restraint
struct ArcSidebar: View {
    @ObservedObject var shellViewModel: BrowserShellViewModel
    @ObservedObject var browserViewModel: BrowserViewModel
    @Binding var addressBarText: String
    @Binding var isCollapsed: Bool
    @Binding var showingCommandBar: Bool
    let isSplitViewActive: Bool
    let onToggleSplitView: () -> Void
    
    @State private var hoveredSpaceID: UUID?
    @State private var hoveredTabID: UUID?
    
    private var themeColor: Color {
        shellViewModel.selectedProfile.theme.color
    }
    
    var body: some View {
        ZStack {
            // Background - using system semantic colors
            Color(NSColor.windowBackgroundColor)
            
            VStack(spacing: 0) {
                // Address Bar - minimal, functional
                ArcAddressBar(
                    text: $addressBarText,
                    isLoading: browserViewModel.isLoading,
                    onSubmit: {
                        // Update the current tab's URL so the view switches from NewTabView to WebView
                        shellViewModel.updateSelectedTab(title: "Loading...", url: addressBarText)
                        browserViewModel.load(addressBarText)
                    },
                    onCommandBar: {
                        showingCommandBar = true
                    }
                )
                .padding(.horizontal, 16)
                .padding(.top, 16)
                .padding(.bottom, 12)
                
                // Favorites Row - compact grid
                ArcFavoritesGrid(
                    savedLinks: Array(shellViewModel.savedLinks.prefix(8)),
                    themeColor: themeColor,
                    onSelect: { url in
                        addressBarText = url
                        // Update the current tab's URL so the view switches from NewTabView to WebView
                        shellViewModel.updateSelectedTab(title: "Loading...", url: url)
                        browserViewModel.load(url)
                    }
                )
                .padding(.horizontal, 16)
                .padding(.bottom, 16)
                
                Divider()
                    .padding(.horizontal, 16)
                
                // Tab List - the main content
                ScrollView(showsIndicators: false) {
                    LazyVStack(spacing: 4) {
                        // Pinned tabs section
                        if !shellViewModel.pinnedTabsForSelectedSpace.isEmpty {
                            ForEach(shellViewModel.pinnedTabsForSelectedSpace) { tab in
                                TabRow(
                                    tab: tab,
                                    isActive: tab.id == shellViewModel.selectedTabID,
                                    isHovered: hoveredTabID == tab.id,
                                    themeColor: themeColor
                                )
                                .onTapGesture {
                                    selectTab(tab)
                                }
                                .onHover { hovering in
                                    hoveredTabID = hovering ? tab.id : nil
                                }
                            }
                            
                            if !shellViewModel.unpinnedTabsForSelectedSpace.isEmpty {
                                Divider()
                                    .padding(.vertical, 8)
                                    .padding(.horizontal, 16)
                            }
                        }
                        
                        // Unpinned tabs
                        ForEach(shellViewModel.unpinnedTabsForSelectedSpace) { tab in
                            TabRow(
                                tab: tab,
                                isActive: tab.id == shellViewModel.selectedTabID,
                                isHovered: hoveredTabID == tab.id,
                                themeColor: themeColor
                            )
                            .onTapGesture {
                                selectTab(tab)
                            }
                            .onHover { hovering in
                                hoveredTabID = hovering ? tab.id : nil
                            }
                        }
                    }
                    .padding(.horizontal, 12)
                    .padding(.vertical, 12)
                }
                
                Spacer()
                
                // Spaces Row - minimal pills
                VStack(spacing: 12) {
                    Divider()
                        .padding(.horizontal, 16)
                    
                    // Spaces pills
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 8) {
                            ForEach(shellViewModel.spacesForSelectedProfile) { space in
                                let isSelected = space.id == shellViewModel.selectedSpaceID
                                
                                SpacePill(
                                    space: space,
                                    isSelected: isSelected,
                                    themeColor: themeColor
                                )
                                .onTapGesture {
                                    withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                                        switchToSpace(space)
                                    }
                                }
                            }
                        }
                        .padding(.horizontal, 16)
                    }
                    
                    // Bottom toolbar
                    HStack(spacing: 16) {
                        Button {
                            createNewTab()
                        } label: {
                            Image(systemName: "plus")
                                .font(.system(size: 14, weight: .medium, design: .rounded))
                                .foregroundStyle(.secondary)
                                .frame(width: 28, height: 28)
                                .background(
                                    Circle()
                                        .fill(Color(NSColor.controlBackgroundColor))
                                )
                        }
                        .buttonStyle(.plain)
                        
                        Spacer()
                        
                        Button(action: onToggleSplitView) {
                            Image(systemName: isSplitViewActive ? "rectangle.split.2x1.fill" : "rectangle.split.2x1")
                                .font(.system(size: 13, weight: .medium, design: .rounded))
                                .foregroundStyle(isSplitViewActive ? themeColor : .secondary)
                        }
                        .buttonStyle(.plain)
                        
                        Button {
                            withAnimation(.spring(response: 0.35, dampingFraction: 0.85)) {
                                isCollapsed.toggle()
                            }
                        } label: {
                            Image(systemName: "sidebar.left")
                                .font(.system(size: 13, weight: .medium, design: .rounded))
                                .foregroundStyle(.secondary)
                        }
                        .buttonStyle(.plain)
                    }
                    .padding(.horizontal, 16)
                    .padding(.bottom, 12)
                }
            }
        }
        .overlay(
            Rectangle()
                .fill(Color(NSColor.separatorColor))
                .frame(width: 1),
            alignment: .trailing
        )
    }
    
    private func selectTab(_ tab: BrowserTabSession) {
        shellViewModel.selectedTabID = tab.id
        addressBarText = tab.url
        browserViewModel.load(tab.url)
    }
    
    private func switchToSpace(_ space: BrowserSpace) {
        shellViewModel.selectedSpaceID = space.id
        // Select first tab of new space
        if let firstTab = shellViewModel.tabsForSelectedSpace.first {
            shellViewModel.selectedTabID = firstTab.id
            addressBarText = firstTab.url
            browserViewModel.load(firstTab.url)
        } else {
            // Create new tab if space is empty
            createNewTab()
        }
    }
    
    private func createNewTab() {
        shellViewModel.createTab(in: shellViewModel.selectedSpaceID ?? UUID())
        if let tab = shellViewModel.selectedTab {
            addressBarText = tab.url
            browserViewModel.load(tab.url)
        }
    }
}

// MARK: - Address Bar
// Minimal, functional, clean
struct ArcAddressBar: View {
    @Binding var text: String
    let isLoading: Bool
    let onSubmit: () -> Void
    let onCommandBar: () -> Void
    
    @FocusState private var isFocused: Bool
    @State private var isHovered = false
    
    var body: some View {
        HStack(spacing: 8) {
            // Icon
            if isLoading {
                ProgressView()
                    .progressViewStyle(CircularProgressViewStyle())
                    .scaleEffect(0.7)
                    .frame(width: 16, height: 16)
            } else {
                Image(systemName: "magnifyingglass")
                    .font(.system(size: 12, weight: .medium, design: .rounded))
                    .foregroundStyle(.secondary)
            }
            
            // TextField
            TextField("Search or enter address", text: $text)
                .font(.system(size: 14, weight: .regular, design: .rounded))
                .textFieldStyle(.plain)
                .focused($isFocused)
                .onSubmit {
                    onSubmit()
                    isFocused = false
                }
            
            Spacer()
            
            // Command shortcut (when not focused)
            if !isFocused && text.isEmpty {
                Button(action: onCommandBar) {
                    HStack(spacing: 2) {
                        Text("⌘")
                            .font(.system(size: 10, weight: .bold, design: .rounded))
                        Text("K")
                            .font(.system(size: 10, weight: .bold, design: .rounded))
                    }
                    .foregroundStyle(.tertiary)
                    .padding(.horizontal, 6)
                    .padding(.vertical, 3)
                    .background(
                        RoundedRectangle(cornerRadius: 4, style: .continuous)
                            .fill(Color(NSColor.tertiarySystemFill))
                    )
                }
                .buttonStyle(.plain)
            }
            
            // Clear button (when focused and has text)
            if isFocused && !text.isEmpty {
                Button {
                    text = ""
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .font(.system(size: 14, weight: .medium, design: .rounded))
                        .foregroundStyle(.tertiary)
                }
                .buttonStyle(.plain)
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(
            RoundedRectangle(cornerRadius: 8, style: .continuous)
                .fill(Color(NSColor.controlBackgroundColor))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 8, style: .continuous)
                .stroke(isFocused ? Color.accentColor.opacity(0.5) : Color.clear, lineWidth: 1.5)
        )
        .animation(.easeInOut(duration: 0.15), value: isFocused)
        .onHover { hovering in
            isHovered = hovering
        }
    }
}

// MARK: - Favorites Grid
struct ArcFavoritesGrid: View {
    let savedLinks: [SavedLink]
    let themeColor: Color
    let onSelect: (String) -> Void
    
    @State private var hoveredID: UUID?
    
    var body: some View {
        LazyVGrid(columns: [GridItem(.adaptive(minimum: 32, maximum: 36))], spacing: 8) {
            ForEach(savedLinks) { link in
                FavoriteIcon(
                    link: link,
                    themeColor: themeColor,
                    isHovered: hoveredID == link.id
                )
                .onTapGesture {
                    onSelect(link.url)
                }
                .onHover { hovering in
                    hoveredID = hovering ? link.id : nil
                }
            }
        }
    }
}

// MARK: - Favorite Icon
struct FavoriteIcon: View {
    let link: SavedLink
    let themeColor: Color
    let isHovered: Bool
    
    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 8, style: .continuous)
                .fill(isHovered ? themeColor.opacity(0.15) : Color(NSColor.tertiarySystemFill))
                .frame(width: 34, height: 34)
            
            Image(systemName: iconForURL(link.url))
                .font(.system(size: 16, weight: .medium, design: .rounded))
                .foregroundStyle(isHovered ? themeColor : .secondary)
        }
        .scaleEffect(isHovered ? 1.05 : 1.0)
        .animation(.easeInOut(duration: 0.15), value: isHovered)
    }
    
    private func iconForURL(_ url: String) -> String {
        let lowercased = url.lowercased()
        if lowercased.contains("google") { return "g.circle.fill" }
        if lowercased.contains("github") { return "number.circle.fill" }
        if lowercased.contains("youtube") { return "play.rectangle.fill" }
        if lowercased.contains("twitter") || lowercased.contains("x.com") { return "bird.fill" }
        if lowercased.contains("mail") || lowercased.contains("gmail") { return "envelope.fill" }
        return "globe"
    }
}

// MARK: - Tab Row
struct TabRow: View {
    let tab: BrowserTabSession
    let isActive: Bool
    let isHovered: Bool
    let themeColor: Color
    
    var body: some View {
        HStack(spacing: 10) {
            // Favicon
            ZStack {
                RoundedRectangle(cornerRadius: 6, style: .continuous)
                    .fill(isActive ? themeColor.opacity(0.12) : Color(NSColor.tertiarySystemFill))
                    .frame(width: 26, height: 26)
                
                Image(systemName: faviconFor(tab.url))
                    .font(.system(size: 12, weight: .medium, design: .rounded))
                    .foregroundStyle(isActive ? themeColor : .secondary)
            }
            
            // Title
            Text(tab.title)
                .font(.system(size: 13, weight: isActive ? .semibold : .regular, design: .rounded))
                .lineLimit(1)
                .foregroundStyle(isActive ? .primary : .secondary)
            
            Spacer()
            
            // Active indicator
            if isActive {
                Circle()
                    .fill(themeColor)
                    .frame(width: 5, height: 5)
            }
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 6)
        .background(
            RoundedRectangle(cornerRadius: 8, style: .continuous)
                .fill(isActive ? themeColor.opacity(0.08) : (isHovered ? Color(NSColor.quaternarySystemFill) : Color.clear))
        )
        .animation(.easeInOut(duration: 0.15), value: isHovered)
        .animation(.easeInOut(duration: 0.15), value: isActive)
        .contentShape(Rectangle())
    }
    
    private func faviconFor(_ url: String) -> String {
        let lowercased = url.lowercased()
        if lowercased.contains("google") { return "g.circle.fill" }
        if lowercased.contains("github") { return "number.circle.fill" }
        if lowercased.contains("youtube") { return "play.rectangle.fill" }
        if lowercased.contains("twitter") || lowercased.contains("x.com") { return "bird.fill" }
        if lowercased.contains("apple") { return "apple.logo" }
        return "globe"
    }
}

// MARK: - Space Pill
struct SpacePill: View {
    let space: BrowserSpace
    let isSelected: Bool
    let themeColor: Color
    
    var body: some View {
        HStack(spacing: 4) {
            Image(systemName: space.icon)
                .font(.system(size: 10, weight: isSelected ? .semibold : .medium, design: .rounded))
            
            if isSelected {
                Text(space.name)
                    .font(.system(size: 11, weight: .semibold, design: .rounded))
            }
        }
        .padding(.horizontal, isSelected ? 10 : 6)
        .padding(.vertical, 4)
        .background(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .fill(isSelected ? themeColor.opacity(0.15) : Color(NSColor.tertiarySystemFill))
        )
        .foregroundStyle(isSelected ? themeColor : .secondary)
    }
}

// MARK: - Main Content
struct ArcMainContent: View {
    @ObservedObject var browserViewModel: BrowserViewModel
    @ObservedObject var splitBrowserViewModel: BrowserViewModel
    @ObservedObject var shellViewModel: BrowserShellViewModel
    @Binding var addressBarText: String
    let isSidebarCollapsed: Bool
    let isSplitViewActive: Bool
    let splitTabID: UUID?
    let onToggleSidebar: () -> Void
    let onToggleSplitView: () -> Void
    
    private var themeColor: Color {
        shellViewModel.selectedProfile.theme.color
    }
    
    var body: some View {
        ZStack {
            // Gradient background for new tab
            if shouldShowGradient() {
                ArcGradientBackground(themeColor: themeColor)
            }
            
            // Content
            if isSplitViewActive {
                // Split View
                HStack(spacing: 0) {
                    if let tab = shellViewModel.selectedTab {
                        WebView(viewModel: browserViewModel)
                            .id(tab.id)
                            .onAppear {
                                browserViewModel.load(tab.url)
                            }
                            .overlay(
                                Rectangle()
                                    .fill(Color(NSColor.separatorColor))
                                    .frame(width: 1),
                                alignment: .trailing
                            )
                    }
                    
                    if let splitTabID = splitTabID,
                       let splitTab = shellViewModel.tabSessions.first(where: { $0.id == splitTabID }) {
                        WebView(viewModel: splitBrowserViewModel)
                            .id(splitTab.id)
                            .onAppear {
                                splitBrowserViewModel.load(splitTab.url)
                            }
                    }
                }
            } else {
                // Single tab
                if let tab = shellViewModel.selectedTab {
                    if isNewTab(tab.url) {
                        NewTabView(
                            savedLinks: shellViewModel.savedLinks,
                            recentHistory: shellViewModel.recentHistoryEntries,
                            selectedProfile: shellViewModel.selectedProfile,
                            onOpenURL: { url in
                                addressBarText = url
                                // Update the current tab's URL so the view switches from NewTabView to WebView
                                shellViewModel.updateSelectedTab(title: "Loading...", url: url)
                                browserViewModel.load(url)
                            },
                            onCreateTab: {},
                            onSelectTab: { _ in },
                            onSelectSpace: { _ in }
                        )
                    } else {
                        WebView(viewModel: browserViewModel)
                            .id(tab.id)
                            .onAppear {
                                browserViewModel.load(tab.url)
                            }
                    }
                }
            }
            
            // Sidebar toggle button (when collapsed)
            if isSidebarCollapsed {
                VStack {
                    HStack {
                        Button(action: onToggleSidebar) {
                            Image(systemName: "sidebar.left")
                                .font(.system(size: 15, weight: .medium, design: .rounded))
                                .foregroundStyle(.secondary)
                                .padding(10)
                                .background(
                                    Circle()
                                        .fill(Color(NSColor.controlBackgroundColor))
                                        .shadow(color: .black.opacity(0.08), radius: 4, x: 0, y: 2)
                                )
                        }
                        .buttonStyle(.plain)
                        .padding(.leading, 12)
                        .padding(.top, 12)
                        
                        Spacer()
                    }
                    
                    Spacer()
                }
            }
        }
    }
    
    private func shouldShowGradient() -> Bool {
        if isSplitViewActive { return false }
        if let tab = shellViewModel.selectedTab {
            return isNewTab(tab.url)
        }
        return true
    }
    
    private func isNewTab(_ url: String) -> Bool {
        url == "about:newtab" || url.isEmpty || url == "https://www.apple.com"
    }
}

// MARK: - Gradient Background
struct ArcGradientBackground: View {
    let themeColor: Color
    @State private var animateGradient = false
    
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                // Base gradient
                LinearGradient(
                    colors: [
                        Color(red: 0.42, green: 0.20, blue: 0.60),
                        Color(red: 0.58, green: 0.28, blue: 0.48),
                        Color(red: 0.25, green: 0.38, blue: 0.72),
                        Color(red: 0.42, green: 0.20, blue: 0.60)
                    ],
                    startPoint: animateGradient ? .topLeading : .bottomTrailing,
                    endPoint: animateGradient ? .bottomTrailing : .topLeading
                )
                .hueRotation(.degrees(animateGradient ? 5 : -5))
                .animation(.easeInOut(duration: 8).repeatForever(autoreverses: true), value: animateGradient)
                .onAppear { animateGradient = true }
                
                // Radial glows
                RadialGradient(
                    colors: [Color.pink.opacity(0.3), Color.clear],
                    center: .topTrailing,
                    startRadius: 0,
                    endRadius: geometry.size.width * 0.6
                )
                
                RadialGradient(
                    colors: [Color.purple.opacity(0.25), Color.clear],
                    center: .topLeading,
                    startRadius: 0,
                    endRadius: geometry.size.width * 0.5
                )
                
                // Vignette
                RadialGradient(
                    colors: [Color.clear, Color.black.opacity(0.2)],
                    center: .center,
                    startRadius: geometry.size.width * 0.4,
                    endRadius: geometry.size.width
                )
            }
        }
        .ignoresSafeArea()
    }
}

// MARK: - Command Bar
struct ArcSpotlightCommandBar: View {
    @ObservedObject var shellViewModel: BrowserShellViewModel
    @ObservedObject var browserViewModel: BrowserViewModel
    @Binding var isPresented: Bool
    let onOpenURL: (String) -> Void
    
    @State private var query = ""
    @FocusState private var isFocused: Bool
    
    var body: some View {
        ZStack {
            Color.black.opacity(0.25)
                .ignoresSafeArea()
                .onTapGesture {
                    isPresented = false
                }
            
            VStack(spacing: 0) {
                // Search field
                HStack(spacing: 12) {
                    Image(systemName: "magnifyingglass")
                        .font(.system(size: 18, weight: .medium, design: .rounded))
                        .foregroundStyle(.secondary)
                    
                    TextField("Search or enter address...", text: $query)
                        .font(.system(size: 17, weight: .regular, design: .rounded))
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
                                .font(.system(size: 16, design: .rounded))
                                .foregroundStyle(.secondary)
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 12)
                
                Divider()
                
                // Results area
                ScrollView {
                    VStack(spacing: 8) {
                        if query.isEmpty {
                            VStack(spacing: 12) {
                                Image(systemName: "command")
                                    .font(.system(size: 32, design: .rounded))
                                    .foregroundStyle(.secondary.opacity(0.5))
                                
                                Text("Type to search or enter a URL")
                                    .font(.system(size: 13, weight: .medium, design: .rounded))
                                    .foregroundStyle(.secondary)
                            }
                            .padding(.top, 40)
                        } else {
                            // URL entry option
                            Button {
                                handleSubmit()
                            } label: {
                                HStack(spacing: 12) {
                                    Image(systemName: "arrow.up.forward")
                                        .font(.system(size: 16, weight: .medium, design: .rounded))
                                        .foregroundStyle(themeColor)
                                        .frame(width: 24)
                                    
                                    VStack(alignment: .leading, spacing: 2) {
                                        Text("Go to \"\(query)\"")
                                            .font(.system(size: 14, weight: .semibold, design: .rounded))
                                            .foregroundStyle(.primary)
                                        
                                        Text("Navigate to this address")
                                            .font(.system(size: 12, weight: .regular, design: .rounded))
                                            .foregroundStyle(.secondary)
                                    }
                                    
                                    Spacer()
                                    
                                    Text("↵")
                                        .font(.system(size: 14, weight: .bold, design: .rounded))
                                        .foregroundStyle(.secondary)
                                }
                                .padding(.horizontal, 12)
                                .padding(.vertical, 10)
                                .background(
                                    RoundedRectangle(cornerRadius: 8, style: .continuous)
                                        .fill(themeColor.opacity(0.08))
                                )
                            }
                            .buttonStyle(.plain)
                            .padding(.horizontal, 8)
                            .padding(.top, 8)
                        }
                    }
                    .padding(.vertical, 8)
                }
                .frame(maxHeight: 300)
            }
            .frame(width: 600)
            .background(
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .fill(Color(NSColor.windowBackgroundColor))
                    .shadow(color: .black.opacity(0.2), radius: 40, x: 0, y: 20)
            )
        }
        .onAppear {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                isFocused = true
            }
        }
    }
    
    private var themeColor: Color {
        shellViewModel.selectedProfile.theme.color
    }
    
    private func handleSubmit() {
        guard !query.isEmpty else { return }
        isPresented = false
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) {
            onOpenURL(query)
        }
    }
}
