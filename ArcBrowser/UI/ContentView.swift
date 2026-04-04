import AppKit
import Combine
import SwiftUI

// MARK: - Arc Browser Content View
// Complete redesign with all Arc-style features

struct ContentView: View {
    @StateObject private var browserViewModel = BrowserViewModel()
    @StateObject private var shellViewModel = BrowserShellViewModel()
    @State private var addressBarText = ""
    @State private var isSidebarCollapsed = false
    @State private var sidebarWidth: CGFloat = 260
    @State private var isDraggingDivider = false
    @State private var showingCommandBar = false
    @State private var hoveredTabID: UUID?
    @State private var hoveredFavoriteID: UUID?
    @State private var peekPreviewURL: String?
    @State private var peekPreviewPosition: CGPoint = .zero
    
    // Split view state
    @State private var isSplitViewActive = false
    @State private var splitTabID: UUID?
    @State private var splitRatio: CGFloat = 0.5
    @StateObject private var splitBrowserViewModel = BrowserViewModel()
    
    // Keyboard navigation
    @FocusState private var isAddressBarFocused: Bool
    
    private var themeColor: Color {
        shellViewModel.selectedProfile.theme.color
    }
    
    var body: some View {
        HStack(spacing: 0) {
            // Resizable Sidebar
            if !isSidebarCollapsed {
                ArcSidebar(
                    shellViewModel: shellViewModel,
                    browserViewModel: browserViewModel,
                    addressBarText: $addressBarText,
                    isCollapsed: $isSidebarCollapsed,
                    sidebarWidth: $sidebarWidth,
                    showingCommandBar: $showingCommandBar,
                    isSplitViewActive: isSplitViewActive,
                    hoveredTabID: $hoveredTabID,
                    hoveredFavoriteID: $hoveredFavoriteID,
                    peekPreviewURL: $peekPreviewURL,
                    peekPreviewPosition: $peekPreviewPosition,
                    onToggleSplitView: toggleSplitView,
                    onSelectTab: selectTab,
                    onCloseTab: closeTab,
                    onSwitchSpace: switchToSpace,
                    themeColor: themeColor
                )
                .frame(width: sidebarWidth)
                .transition(.move(edge: .leading).combined(with: .opacity))
                
                // Draggable divider
                DividerHandle(
                    isDragging: $isDraggingDivider,
                    sidebarWidth: $sidebarWidth
                )
            }
            
            // Main Content
            ArcMainContent(
                browserViewModel: browserViewModel,
                splitBrowserViewModel: splitBrowserViewModel,
                shellViewModel: shellViewModel,
                addressBarText: $addressBarText,
                isSidebarCollapsed: isSidebarCollapsed,
                isSplitViewActive: isSplitViewActive,
                splitTabID: splitTabID,
                splitRatio: splitRatio,
                hoveredFavoriteID: hoveredFavoriteID,
                peekPreviewURL: peekPreviewURL,
                peekPreviewPosition: peekPreviewPosition,
                themeColor: themeColor,
                onToggleSidebar: toggleSidebar,
                onToggleSplitView: toggleSplitView,
                onOpenURL: openURL
            )
        }
        .frame(minWidth: 960, minHeight: 640)
        .sheet(isPresented: $showingCommandBar) {
            ArcCommandBar(
                shellViewModel: shellViewModel,
                browserViewModel: browserViewModel,
                isPresented: $showingCommandBar,
                onOpenURL: openURL,
                onSelectTab: selectTab,
                onSwitchSpace: switchToSpace,
                themeColor: themeColor
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
            setupKeyboardShortcuts()
        }
    }
    
    // MARK: - Actions
    
    private func toggleSidebar() {
        withAnimation(ArcAnimations.sidebarCollapse) {
            isSidebarCollapsed.toggle()
        }
    }
    
    private func toggleSplitView() {
        withAnimation(ArcAnimations.spaceSwitch) {
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
    
    private func selectTab(_ tab: BrowserTabSession) {
        withAnimation(ArcAnimations.tabSwitch) {
            shellViewModel.selectedTabID = tab.id
            addressBarText = tab.url
            browserViewModel.load(tab.url)
        }
    }
    
    private func closeTab(_ tabID: UUID) {
        shellViewModel.closeTab(tabID)
        // Select another tab if the closed one was active
        if shellViewModel.selectedTabID == tabID {
            if let nextTab = shellViewModel.tabsForSelectedSpace.first {
                selectTab(nextTab)
            }
        }
    }
    
    private func switchToSpace(_ space: BrowserSpace) {
        withAnimation(ArcAnimations.spaceSwitch) {
            shellViewModel.selectedSpaceID = space.id
            // Select first tab of new space
            if let firstTab = shellViewModel.tabsForSelectedSpace.first {
                selectTab(firstTab)
            } else {
                // Create new tab if space is empty
                shellViewModel.createTab(in: space.id)
                if let tab = shellViewModel.selectedTab {
                    addressBarText = tab.url
                    browserViewModel.load(tab.url)
                }
            }
        }
    }
    
    private func openURL(_ url: String) {
        addressBarText = url
        // Update the current tab's URL so the view switches from NewTabView to WebView
        shellViewModel.updateSelectedTab(title: "Loading...", url: url)
        browserViewModel.load(url)
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
    
    private func setupKeyboardShortcuts() {
        // Listen for command bar keyboard shortcut
        NotificationCenter.default.addObserver(
            forName: .openCommandPalette,
            object: nil,
            queue: .main
        ) { _ in
            showingCommandBar = true
        }
    }
}

// MARK: - Divider Handle (Draggable)
struct DividerHandle: View {
    @Binding var isDragging: Bool
    @Binding var sidebarWidth: CGFloat
    
    var body: some View {
        Rectangle()
            .fill(Color.clear)
            .frame(width: 8)
            .contentShape(Rectangle())
            .hoverCursor(.resizeLeftRight)
            .gesture(
                DragGesture()
                    .onChanged { value in
                        isDragging = true
                        let newWidth = sidebarWidth + value.translation.width
                        sidebarWidth = min(max(newWidth, ArcSidebarDimensions.minWidth), ArcSidebarDimensions.maxWidth)
                    }
                    .onEnded { _ in
                        isDragging = false
                    }
            )
            .overlay(
                Rectangle()
                    .fill(isDragging ? ArcColors.purple.opacity(0.5) : Color.clear)
                    .frame(width: 2)
            )
    }
}

// MARK: - Hover Cursor Extension
extension View {
    func hoverCursor(_ cursor: NSCursor) -> some View {
        self.onHover { hovering in
            if hovering {
                cursor.push()
            } else {
                NSCursor.pop()
            }
        }
    }
}

// MARK: - Arc Sidebar
struct ArcSidebar: View {
    @ObservedObject var shellViewModel: BrowserShellViewModel
    @ObservedObject var browserViewModel: BrowserViewModel
    @Binding var addressBarText: String
    @Binding var isCollapsed: Bool
    @Binding var sidebarWidth: CGFloat
    @Binding var showingCommandBar: Bool
    let isSplitViewActive: Bool
    @Binding var hoveredTabID: UUID?
    @Binding var hoveredFavoriteID: UUID?
    @Binding var peekPreviewURL: String?
    @Binding var peekPreviewPosition: CGPoint
    let onToggleSplitView: () -> Void
    let onSelectTab: (BrowserTabSession) -> Void
    let onCloseTab: (UUID) -> Void
    let onSwitchSpace: (BrowserSpace) -> Void
    let themeColor: Color
    
    var body: some View {
        ZStack {
            // Glass background
            ArcGlass.floatingPanel()
            
            VStack(spacing: 0) {
                // Header with collapse button
                HStack {
                    Spacer()
                    
                    Button(action: { 
                        withAnimation(ArcAnimations.sidebarCollapse) {
                            isCollapsed.toggle()
                        }
                    }) {
                        Image(systemName: "sidebar.left")
                            .font(ArcTypography.label)
                            .foregroundStyle(.secondary)
                            .padding(ArcSpacing.sm)
                            .background(
                                Circle()
                                    .fill(ArcColors.tertiaryBackground)
                            )
                    }
                    .buttonStyle(.plain)
                    .padding(.trailing, ArcSpacing.lg)
                    .padding(.top, ArcSpacing.lg)
                }
                
                // Address Bar
                ArcFloatingAddressBar(
                    text: $addressBarText,
                    isLoading: browserViewModel.isLoading,
                    onSubmit: {
                        let url = addressBarText
                        shellViewModel.updateSelectedTab(title: "Loading...", url: url)
                        browserViewModel.load(url)
                    },
                    onCommandBar: {
                        showingCommandBar = true
                    }
                )
                .padding(.horizontal, ArcSpacing.lg)
                .padding(.top, ArcSpacing.lg)
                .padding(.bottom, ArcSpacing.md)
                
                // Favorites Grid
                ArcSidebarFavoritesSection(
                    savedLinks: Array(shellViewModel.savedLinks.prefix(8)),
                    themeColor: themeColor,
                    hoveredFavoriteID: $hoveredFavoriteID,
                    peekPreviewURL: $peekPreviewURL,
                    peekPreviewPosition: $peekPreviewPosition,
                    onSelect: { url in
                        shellViewModel.updateSelectedTab(title: "Loading...", url: url)
                        browserViewModel.load(url)
                    }
                )
                .padding(.horizontal, ArcSpacing.lg)
                .padding(.bottom, ArcSpacing.lg)
                
                Divider()
                    .padding(.horizontal, ArcSpacing.lg)
                
                // Tab List
                ArcTabList(
                    shellViewModel: shellViewModel,
                    themeColor: themeColor,
                    hoveredTabID: $hoveredTabID,
                    onSelectTab: onSelectTab,
                    onCloseTab: onCloseTab
                )
                .padding(.top, ArcSpacing.sm)
                
                Spacer()
                
                // Bottom section
                VStack(spacing: ArcSpacing.lg) {
                    Divider()
                        .padding(.horizontal, ArcSpacing.lg)
                    
                    // Spaces
                    ArcSpacesRow(
                        spaces: shellViewModel.spacesForSelectedProfile,
                        selectedSpaceID: shellViewModel.selectedSpaceID,
                        themeColor: themeColor,
                        onSwitchSpace: onSwitchSpace
                    )
                    .padding(.horizontal, ArcSpacing.lg)
                    
                    // Bottom toolbar
                    ArcBottomToolbar(
                        shellViewModel: shellViewModel,
                        isSplitViewActive: isSplitViewActive,
                        themeColor: themeColor,
                        onToggleSplitView: onToggleSplitView,
                        onToggleSidebar: {
                            withAnimation(ArcAnimations.sidebarCollapse) {
                                isCollapsed.toggle()
                            }
                        }
                    )
                    .padding(.horizontal, ArcSpacing.lg)
                    .padding(.bottom, ArcSpacing.lg)
                }
            }
        }
        .overlay(
            Rectangle()
                .fill(ArcColors.separator)
                .frame(width: 1),
            alignment: .trailing
        )
    }
}

// MARK: - Floating Address Bar
struct ArcFloatingAddressBar: View {
    @Binding var text: String
    let isLoading: Bool
    let onSubmit: () -> Void
    let onCommandBar: () -> Void
    
    @FocusState private var isFocused: Bool
    @State private var isHovered = false
    
    var body: some View {
        HStack(spacing: ArcSpacing.sm) {
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
                .font(ArcTypography.body)
                .textFieldStyle(.plain)
                .focused($isFocused)
                .onSubmit(onSubmit)
            
            Spacer()
            
            // Command shortcut
            if !isFocused && text.isEmpty {
                Button(action: onCommandBar) {
                    HStack(spacing: 2) {
                        Text("⌘")
                            .font(ArcTypography.labelSmall)
                        Text("K")
                            .font(ArcTypography.labelSmall)
                    }
                    .foregroundStyle(.tertiary)
                    .padding(.horizontal, 6)
                    .padding(.vertical, 3)
                    .background(
                        RoundedRectangle(cornerRadius: ArcCornerRadius.sm, style: .continuous)
                            .fill(ArcColors.tertiaryBackground)
                    )
                }
                .buttonStyle(.plain)
            }
            
            // Clear button
            if isFocused && !text.isEmpty {
                Button { text = "" } label: {
                    Image(systemName: "xmark.circle.fill")
                        .font(.system(size: 14, weight: .medium, design: .rounded))
                        .foregroundStyle(.tertiary)
                }
                .buttonStyle(.plain)
            }
        }
        .padding(.horizontal, ArcSpacing.md)
        .padding(.vertical, ArcSpacing.sm)
        .background(
            RoundedRectangle(cornerRadius: ArcCornerRadius.md, style: .continuous)
                .fill(ArcColors.secondaryBackground)
        )
        .overlay(
            RoundedRectangle(cornerRadius: ArcCornerRadius.md, style: .continuous)
                .stroke(isFocused ? themeColor.opacity(0.5) : Color.clear, lineWidth: 1.5)
        )
        .shadow(
            color: isFocused ? themeColor.opacity(0.2) : Color.clear,
            radius: isFocused ? 12 : 0,
            x: 0,
            y: 4
        )
        .scaleEffect(isFocused ? 1.02 : 1.0)
        .animation(ArcAnimations.hover, value: isFocused)
        .onHover { hovering in isHovered = hovering }
    }
    
    private var themeColor: Color {
        ArcColors.purple
    }
}

// MARK: - Favorites Section
struct ArcSidebarFavoritesSection: View {
    let savedLinks: [SavedLink]
    let themeColor: Color
    @Binding var hoveredFavoriteID: UUID?
    @Binding var peekPreviewURL: String?
    @Binding var peekPreviewPosition: CGPoint
    let onSelect: (String) -> Void
    
    var body: some View {
        LazyVGrid(columns: [
            GridItem(.flexible()),
            GridItem(.flexible()),
            GridItem(.flexible()),
            GridItem(.flexible())
        ], spacing: ArcSpacing.sm) {
            ForEach(savedLinks) { link in
                ArcFavoriteItem(
                    link: link,
                    themeColor: themeColor,
                    isHovered: hoveredFavoriteID == link.id,
                    onHover: { isHovered in
                        hoveredFavoriteID = isHovered ? link.id : nil
                        if isHovered {
                            peekPreviewURL = link.url
                        } else {
                            peekPreviewURL = nil
                        }
                    },
                    onSelect: { onSelect(link.url) }
                )
            }
        }
    }
}

// MARK: - Favorite Item
struct ArcFavoriteItem: View {
    let link: SavedLink
    let themeColor: Color
    let isHovered: Bool
    let onHover: (Bool) -> Void
    let onSelect: () -> Void
    
    var body: some View {
        Button(action: onSelect) {
            VStack(spacing: ArcSpacing.xs) {
                ZStack {
                    RoundedRectangle(cornerRadius: ArcCornerRadius.md, style: .continuous)
                        .fill(isHovered ? themeColor.opacity(0.15) : ArcColors.tertiaryBackground)
                        .frame(width: 44, height: 44)
                    
                    Image(systemName: iconForURL(link.url))
                        .font(.system(size: 20, weight: .medium, design: .rounded))
                        .foregroundStyle(isHovered ? themeColor : .secondary)
                }
                
                Text(link.title)
                    .font(ArcTypography.labelSmall)
                    .lineLimit(1)
                    .foregroundStyle(isHovered ? .primary : .secondary)
            }
        }
        .buttonStyle(.plain)
        .scaleEffect(isHovered ? 1.1 : 1.0)
        .animation(ArcAnimations.hover, value: isHovered)
        .onHover { hovering in onHover(hovering) }
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

// MARK: - Tab List
struct ArcTabList: View {
    @ObservedObject var shellViewModel: BrowserShellViewModel
    let themeColor: Color
    @Binding var hoveredTabID: UUID?
    let onSelectTab: (BrowserTabSession) -> Void
    let onCloseTab: (UUID) -> Void
    
    var body: some View {
        ScrollView(showsIndicators: false) {
            LazyVStack(spacing: ArcSpacing.xs) {
                // Pinned tabs
                if !shellViewModel.pinnedTabsForSelectedSpace.isEmpty {
                    ForEach(shellViewModel.pinnedTabsForSelectedSpace) { tab in
                        ArcTabRow(
                            tab: tab,
                            isActive: tab.id == shellViewModel.selectedTabID,
                            isHovered: hoveredTabID == tab.id,
                            isPinned: true,
                            themeColor: themeColor,
                            onSelect: { onSelectTab(tab) },
                            onClose: { onCloseTab(tab.id) }
                        )
                        .onHover { hovering in
                            hoveredTabID = hovering ? tab.id : nil
                        }
                    }
                    
                    if !shellViewModel.unpinnedTabsForSelectedSpace.isEmpty {
                        Divider()
                            .padding(.vertical, ArcSpacing.sm)
                            .padding(.horizontal, ArcSpacing.lg)
                    }
                }
                
                // Unpinned tabs
                ForEach(shellViewModel.unpinnedTabsForSelectedSpace) { tab in
                    ArcTabRow(
                        tab: tab,
                        isActive: tab.id == shellViewModel.selectedTabID,
                        isHovered: hoveredTabID == tab.id,
                        isPinned: false,
                        themeColor: themeColor,
                        onSelect: { onSelectTab(tab) },
                        onClose: { onCloseTab(tab.id) }
                    )
                    .onHover { hovering in
                        hoveredTabID = hovering ? tab.id : nil
                    }
                }
            }
            .padding(.horizontal, ArcSpacing.md)
            .padding(.vertical, ArcSpacing.sm)
        }
    }
}

// MARK: - Tab Row
struct ArcTabRow: View {
    let tab: BrowserTabSession
    let isActive: Bool
    let isHovered: Bool
    let isPinned: Bool
    let themeColor: Color
    let onSelect: () -> Void
    let onClose: () -> Void
    
    var body: some View {
        Button(action: onSelect) {
            HStack(spacing: ArcSpacing.sm) {
                // Favicon
                ZStack {
                    RoundedRectangle(cornerRadius: ArcCornerRadius.sm, style: .continuous)
                        .fill(isActive ? themeColor.opacity(0.12) : ArcColors.tertiaryBackground)
                        .frame(width: 26, height: 26)
                    
                    Image(systemName: faviconFor(tab.url))
                        .font(.system(size: 12, weight: .medium, design: .rounded))
                        .foregroundStyle(isActive ? themeColor : .secondary)
                }
                
                // Title
                Text(tab.title)
                    .font(isActive ? ArcTypography.tabTitleActive : ArcTypography.tabTitle)
                    .lineLimit(1)
                    .foregroundStyle(isActive ? .primary : .secondary)
                
                Spacer()
                
                // Close button or active indicator
                if isHovered || isActive {
                    if isHovered {
                        Button(action: onClose) {
                            Image(systemName: "xmark")
                                .font(.system(size: 10, weight: .semibold, design: .rounded))
                                .foregroundStyle(.secondary)
                                .frame(width: 16, height: 16)
                                .background(
                                    Circle()
                                        .fill(ArcColors.quaternaryBackground)
                                )
                        }
                        .buttonStyle(.plain)
                        .transition(.opacity)
                    } else if isActive {
                        Circle()
                            .fill(themeColor)
                            .frame(width: 5, height: 5)
                            .shadow(color: themeColor.opacity(0.4), radius: 2)
                    }
                }
            }
            .padding(.horizontal, ArcSpacing.sm)
            .padding(.vertical, ArcSpacing.xs)
            .background(
                RoundedRectangle(cornerRadius: ArcCornerRadius.md, style: .continuous)
                    .fill(isActive ? themeColor.opacity(0.08) : (isHovered ? ArcColors.quaternaryBackground : Color.clear))
            )
        }
        .buttonStyle(.plain)
        .animation(ArcAnimations.hover, value: isHovered)
        .animation(ArcAnimations.hover, value: isActive)
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

// MARK: - Spaces Row
struct ArcSpacesRow: View {
    let spaces: [BrowserSpace]
    let selectedSpaceID: UUID
    let themeColor: Color
    let onSwitchSpace: (BrowserSpace) -> Void
    
    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: ArcSpacing.sm) {
                ForEach(spaces) { space in
                    let isSelected = space.id == selectedSpaceID
                    
                    Button { onSwitchSpace(space) } label: {
                        HStack(spacing: ArcSpacing.xs) {
                            Image(systemName: space.icon)
                                .font(.system(size: 10, weight: isSelected ? .semibold : .medium, design: .rounded))
                            
                            if isSelected {
                                Text(space.name)
                                    .font(ArcTypography.label)
                            }
                        }
                        .padding(.horizontal, isSelected ? ArcSpacing.md : ArcSpacing.sm)
                        .padding(.vertical, ArcSpacing.xs)
                        .background(
                            RoundedRectangle(cornerRadius: ArcCornerRadius.pill, style: .continuous)
                                .fill(isSelected ? themeColor.opacity(0.15) : ArcColors.tertiaryBackground)
                        )
                        .foregroundStyle(isSelected ? themeColor : .secondary)
                    }
                    .buttonStyle(.plain)
                    .animation(ArcAnimations.hover, value: isSelected)
                }
            }
        }
    }
}

// MARK: - Bottom Toolbar
struct ArcBottomToolbar: View {
    @ObservedObject var shellViewModel: BrowserShellViewModel
    let isSplitViewActive: Bool
    let themeColor: Color
    let onToggleSplitView: () -> Void
    let onToggleSidebar: () -> Void
    
    var body: some View {
        HStack(spacing: ArcSpacing.lg) {
            // New tab button
            Button {
                shellViewModel.createTab(in: shellViewModel.selectedSpaceID ?? UUID())
            } label: {
                Image(systemName: "plus")
                    .font(.system(size: 14, weight: .medium, design: .rounded))
                    .foregroundStyle(.secondary)
                    .frame(width: 28, height: 28)
                    .background(
                        Circle()
                            .fill(ArcColors.tertiaryBackground)
                    )
            }
            .buttonStyle(.plain)
            
            Spacer()
            
            // Split view button
            Button(action: onToggleSplitView) {
                Image(systemName: isSplitViewActive ? "rectangle.split.2x1.fill" : "rectangle.split.2x1")
                    .font(.system(size: 13, weight: .medium, design: .rounded))
                    .foregroundStyle(isSplitViewActive ? themeColor : .secondary)
            }
            .buttonStyle(.plain)
            
            // Sidebar toggle
            Button(action: onToggleSidebar) {
                Image(systemName: "sidebar.left")
                    .font(.system(size: 13, weight: .medium, design: .rounded))
                    .foregroundStyle(.secondary)
            }
            .buttonStyle(.plain)
        }
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
    let splitRatio: CGFloat
    let hoveredFavoriteID: UUID?
    let peekPreviewURL: String?
    let peekPreviewPosition: CGPoint
    let themeColor: Color
    let onToggleSidebar: () -> Void
    let onToggleSplitView: () -> Void
    let onOpenURL: (String) -> Void
    
    var body: some View {
        ZStack {
            // Gradient background for new tab
            if shouldShowGradient() {
                ArcGradientBackground(theme: ArcTheme.midnight)
            }
            
            // Content
            if isSplitViewActive {
                // Split View
                HStack(spacing: 0) {
                    if let tab = shellViewModel.selectedTab {
                        WebView(viewModel: browserViewModel)
                            .id(tab.id)
                            .onAppear { browserViewModel.load(tab.url) }
                            .frame(maxWidth: .infinity, maxHeight: .infinity)
                    }
                    
                    Divider()
                    
                    if let splitTabID = splitTabID,
                       let splitTab = shellViewModel.tabSessions.first(where: { $0.id == splitTabID }) {
                        WebView(viewModel: splitBrowserViewModel)
                            .id(splitTab.id)
                            .onAppear { splitBrowserViewModel.load(splitTab.url) }
                            .frame(maxWidth: .infinity, maxHeight: .infinity)
                    }
                }
            } else {
                // Single tab
                if let tab = shellViewModel.selectedTab {
                    if isNewTab(tab.url) {
                        ArcNewTabView(
                            savedLinks: shellViewModel.savedLinks,
                            recentHistory: shellViewModel.recentHistoryEntries,
                            theme: ArcTheme.midnight,
                            onOpenURL: onOpenURL,
                            onCreateTab: {
                                shellViewModel.createTab(in: shellViewModel.selectedSpaceID ?? UUID())
                            }
                        )
                    } else {
                        WebView(viewModel: browserViewModel)
                            .id(tab.id)
                            .onAppear { browserViewModel.load(tab.url) }
                    }
                }
            }
            
            // Peek Preview overlay
            if let url = peekPreviewURL {
                ArcPeekPreviewCard(
                    url: url,
                    position: peekPreviewPosition,
                    themeColor: themeColor
                )
                .transition(.scale.combined(with: .opacity))
                .animation(ArcAnimations.peekPreview, value: peekPreviewURL)
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
                                        .fill(ArcColors.secondaryBackground)
                                        .shadow(color: .black.opacity(0.08), radius: 4, x: 0, y: 2)
                                )
                        }
                        .buttonStyle(.plain)
                        .padding(.leading, ArcSpacing.lg)
                        .padding(.top, ArcSpacing.lg)
                        
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

// MARK: - New Tab View
struct ArcNewTabView: View {
    let savedLinks: [SavedLink]
    let recentHistory: [BrowserHistoryEntry]
    let theme: ArcTheme
    let onOpenURL: (String) -> Void
    let onCreateTab: () -> Void
    
    @State private var animateGradient = false
    
    private var greeting: String {
        let hour = Calendar.current.component(.hour, from: Date())
        switch hour {
        case 0..<12: return "Good morning"
        case 12..<17: return "Good afternoon"
        case 17..<21: return "Good evening"
        default: return "Good night"
        }
    }
    
    var body: some View {
        ZStack {
            // Animated gradient background
            ArcGradientBackground(theme: theme)
            
            VStack(spacing: ArcSpacing.xxl) {
                Spacer()
                
                // Greeting
                Text(greeting)
                    .font(ArcTypography.hero)
                    .foregroundStyle(.primary)
                    .shadow(color: .black.opacity(0.2), radius: 20, x: 0, y: 10)
                
                // Command bar button
                Button(action: { NotificationCenter.default.post(name: .openCommandPalette, object: nil) }) {
                    HStack(spacing: ArcSpacing.sm) {
                        Image(systemName: "magnifyingglass")
                            .font(ArcTypography.body)
                        Text("Search or enter address")
                            .font(ArcTypography.body)
                        Spacer()
                        HStack(spacing: 2) {
                            Text("⌘").font(ArcTypography.labelSmall)
                            Text("K").font(ArcTypography.labelSmall)
                        }
                        .foregroundStyle(.tertiary)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 3)
                        .background(
                            RoundedRectangle(cornerRadius: ArcCornerRadius.sm, style: .continuous)
                                .fill(.ultraThinMaterial)
                        )
                    }
                    .padding(.horizontal, ArcSpacing.lg)
                    .padding(.vertical, ArcSpacing.md)
                    .frame(maxWidth: 600)
                    .background(
                        RoundedRectangle(cornerRadius: ArcCornerRadius.lg, style: .continuous)
                            .fill(.ultraThinMaterial)
                            .overlay(
                                RoundedRectangle(cornerRadius: ArcCornerRadius.lg, style: .continuous)
                                    .stroke(Color.white.opacity(0.2), lineWidth: 1)
                            )
                    )
                    .shadow(color: .black.opacity(0.1), radius: 20, x: 0, y: 10)
                }
                .buttonStyle(.plain)
                
                // Favorites
                VStack(alignment: .leading, spacing: ArcSpacing.lg) {
                    Text("Favorites")
                        .font(ArcTypography.title2)
                        .foregroundStyle(.primary)
                    
                    LazyVGrid(columns: [
                        GridItem(.flexible()), GridItem(.flexible()),
                        GridItem(.flexible()), GridItem(.flexible())
                    ], spacing: ArcSpacing.lg) {
                        ForEach(savedLinks.prefix(8)) { link in
                            ArcNewTabFavoriteCard(link: link, onSelect: { onOpenURL(link.url) })
                        }
                    }
                    .frame(maxWidth: 600)
                }
                
                Spacer()
            }
            .padding(.horizontal, ArcSpacing.xxxl)
        }
    }
}

// MARK: - New Tab Favorite Card
struct ArcNewTabFavoriteCard: View {
    let link: SavedLink
    let onSelect: () -> Void
    @State private var isHovered = false
    
    var body: some View {
        Button(action: onSelect) {
            VStack(spacing: ArcSpacing.sm) {
                ZStack {
                    RoundedRectangle(cornerRadius: ArcCornerRadius.lg, style: .continuous)
                        .fill(.ultraThinMaterial)
                        .frame(width: 60, height: 60)
                        .overlay(
                            RoundedRectangle(cornerRadius: ArcCornerRadius.lg, style: .continuous)
                                .stroke(Color.white.opacity(0.2), lineWidth: 1)
                        )
                    
                    Image(systemName: iconForURL(link.url))
                        .font(.system(size: 24, weight: .medium, design: .rounded))
                        .foregroundStyle(.secondary)
                }
                
                Text(link.title)
                    .font(ArcTypography.caption)
                    .lineLimit(1)
                    .foregroundStyle(.secondary)
            }
        }
        .buttonStyle(.plain)
        .scaleEffect(isHovered ? 1.05 : 1.0)
        .animation(ArcAnimations.hover, value: isHovered)
        .onHover { hovering in isHovered = hovering }
    }
    
    private func iconForURL(_ url: String) -> String {
        let lowercased = url.lowercased()
        if lowercased.contains("google") { return "g.circle.fill" }
        if lowercased.contains("github") { return "number.circle.fill" }
        if lowercased.contains("youtube") { return "play.rectangle.fill" }
        if lowercased.contains("twitter") || lowercased.contains("x.com") { return "bird.fill" }
        return "globe"
    }
}

// MARK: - Gradient Background
struct ArcGradientBackground: View {
    let theme: ArcTheme
    @State private var animateGradient = false
    
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                // Base gradient
                LinearGradient(
                    colors: theme.gradientColors,
                    startPoint: animateGradient ? .topLeading : .bottomTrailing,
                    endPoint: animateGradient ? .bottomTrailing : .topLeading
                )
                .hueRotation(.degrees(animateGradient ? 5 : -5))
                .animation(ArcAnimations.gradient, value: animateGradient)
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

// MARK: - Peek Preview Card
struct ArcPeekPreviewCard: View {
    let url: String
    let position: CGPoint
    let themeColor: Color
    
    var body: some View {
        VStack(alignment: .leading, spacing: ArcSpacing.sm) {
            // Preview placeholder
            RoundedRectangle(cornerRadius: ArcCornerRadius.md, style: .continuous)
                .fill(themeColor.opacity(0.1))
                .frame(width: 200, height: 120)
                .overlay(
                    Image(systemName: "eye.fill")
                        .font(.system(size: 32))
                        .foregroundStyle(themeColor.opacity(0.5))
                )
            
            VStack(alignment: .leading, spacing: ArcSpacing.xs) {
                Text(URL(string: url)?.host ?? url)
                    .font(ArcTypography.caption)
                    .lineLimit(1)
                    .foregroundStyle(.primary)
                
                Text(url)
                    .font(ArcTypography.labelSmall)
                    .lineLimit(1)
                    .foregroundStyle(.secondary)
            }
        }
        .padding(ArcSpacing.md)
        .background(
            RoundedRectangle(cornerRadius: ArcCornerRadius.lg, style: .continuous)
                .fill(.ultraThinMaterial)
                .overlay(
                    RoundedRectangle(cornerRadius: ArcCornerRadius.lg, style: .continuous)
                        .stroke(Color.white.opacity(0.2), lineWidth: 1)
                )
        )
        .shadow(color: .black.opacity(0.2), radius: 20, x: 0, y: 10)
        .position(x: position.x + 120, y: position.y)
    }
}

// MARK: - Command Bar
struct ArcCommandBar: View {
    @ObservedObject var shellViewModel: BrowserShellViewModel
    @ObservedObject var browserViewModel: BrowserViewModel
    @Binding var isPresented: Bool
    let onOpenURL: (String) -> Void
    let onSelectTab: (BrowserTabSession) -> Void
    let onSwitchSpace: (BrowserSpace) -> Void
    let themeColor: Color
    
    @State private var query = ""
    @FocusState private var isFocused: Bool
    @State private var selectedIndex = 0
    
    var body: some View {
        ZStack {
            // Dimmed background
            Color.black.opacity(0.4)
                .ignoresSafeArea()
                .onTapGesture { isPresented = false }
            
            // Command bar panel
            VStack(spacing: 0) {
                // Search field
                HStack(spacing: ArcSpacing.md) {
                    Image(systemName: "magnifyingglass")
                        .font(.system(size: 18, weight: .medium, design: .rounded))
                        .foregroundStyle(.secondary)
                    
                    TextField("Search or enter address...", text: $query)
                        .font(ArcTypography.commandBar)
                        .textFieldStyle(.plain)
                        .focused($isFocused)
                        .onSubmit {
                            if !query.isEmpty {
                                onOpenURL(query)
                                isPresented = false
                            }
                        }
                    
                    if !query.isEmpty {
                        Button { query = "" } label: {
                            Image(systemName: "xmark.circle.fill")
                                .font(.system(size: 16, design: .rounded))
                                .foregroundStyle(.secondary)
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(.horizontal, ArcSpacing.lg)
                .padding(.vertical, ArcSpacing.md)
                
                Divider()
                
                // Results
                ScrollView {
                    VStack(spacing: ArcSpacing.sm) {
                        if query.isEmpty {
                            // Default state
                            VStack(spacing: ArcSpacing.lg) {
                                Image(systemName: "command")
                                    .font(.system(size: 32, design: .rounded))
                                    .foregroundStyle(.secondary.opacity(0.5))
                                
                                Text("Type to search tabs, history, or enter a URL")
                                    .font(ArcTypography.caption)
                                    .foregroundStyle(.secondary)
                            }
                            .padding(.top, ArcSpacing.xxl)
                        } else {
                            // URL entry option
                            Button {
                                onOpenURL(query)
                                isPresented = false
                            } label: {
                                HStack(spacing: ArcSpacing.md) {
                                    Image(systemName: "arrow.up.forward")
                                        .font(.system(size: 16, weight: .medium, design: .rounded))
                                        .foregroundStyle(themeColor)
                                        .frame(width: 24)
                                    
                                    VStack(alignment: .leading, spacing: ArcSpacing.xs) {
                                        Text("Go to \"\(query)\"")
                                            .font(ArcTypography.body)
                                            .foregroundStyle(.primary)
                                        
                                        Text("Navigate to this address")
                                            .font(ArcTypography.caption)
                                            .foregroundStyle(.secondary)
                                    }
                                    
                                    Spacer()
                                    
                                    Text("↵")
                                        .font(.system(size: 14, weight: .bold, design: .rounded))
                                        .foregroundStyle(.secondary)
                                }
                                .padding(.horizontal, ArcSpacing.md)
                                .padding(.vertical, ArcSpacing.sm)
                                .background(
                                    RoundedRectangle(cornerRadius: ArcCornerRadius.md, style: .continuous)
                                        .fill(themeColor.opacity(0.08))
                                )
                            }
                            .buttonStyle(.plain)
                            .padding(.horizontal, ArcSpacing.sm)
                            .padding(.top, ArcSpacing.sm)
                        }
                    }
                    .padding(.vertical, ArcSpacing.sm)
                }
                .frame(maxHeight: 400)
            }
            .frame(width: 640)
            .background(
                RoundedRectangle(cornerRadius: ArcCornerRadius.xl, style: .continuous)
                    .fill(.ultraThinMaterial)
                    .overlay(
                        RoundedRectangle(cornerRadius: ArcCornerRadius.xl, style: .continuous)
                            .stroke(Color.white.opacity(0.2), lineWidth: 1)
                    )
            )
            .shadow(color: .black.opacity(0.2), radius: 40, x: 0, y: 20)
        }
        .onAppear {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                isFocused = true
            }
        }
    }
}

// MARK: - Keyboard Shortcuts Extension
extension ContentView {
    func handleKeyboardShortcut(_ shortcut: KeyboardShortcut) {
        switch shortcut {
        case .commandBar:
            showingCommandBar = true
        case .newTab:
            shellViewModel.createTab(in: shellViewModel.selectedSpaceID ?? UUID())
        case .closeTab:
            if let selectedTab = shellViewModel.selectedTab {
                closeTab(selectedTab.id)
            }
        case .toggleSidebar:
            toggleSidebar()
        case .nextTab:
            navigateToNextTab()
        case .previousTab:
            navigateToPreviousTab()
        case .nextSpace:
            navigateToNextSpace()
        case .previousSpace:
            navigateToPreviousSpace()
        default:
            break
        }
    }
    
    func navigateToNextTab() {
        let tabs = shellViewModel.tabsForSelectedSpace
        guard let currentTab = shellViewModel.selectedTab,
              let currentIndex = tabs.firstIndex(where: { $0.id == currentTab.id }),
              tabs.count > 1 else { return }
        
        let nextIndex = (currentIndex + 1) % tabs.count
        selectTab(tabs[nextIndex])
    }
    
    func navigateToPreviousTab() {
        let tabs = shellViewModel.tabsForSelectedSpace
        guard let currentTab = shellViewModel.selectedTab,
              let currentIndex = tabs.firstIndex(where: { $0.id == currentTab.id }),
              tabs.count > 1 else { return }
        
        let previousIndex = (currentIndex - 1 + tabs.count) % tabs.count
        selectTab(tabs[previousIndex])
    }
    
    func navigateToNextSpace() {
        let spaces = shellViewModel.spacesForSelectedProfile
        guard let currentSpace = spaces.first(where: { $0.id == shellViewModel.selectedSpaceID }),
              let currentIndex = spaces.firstIndex(where: { $0.id == currentSpace.id }),
              spaces.count > 1 else { return }
        
        let nextIndex = (currentIndex + 1) % spaces.count
        switchToSpace(spaces[nextIndex])
    }
    
    func navigateToPreviousSpace() {
        let spaces = shellViewModel.spacesForSelectedProfile
        guard let currentSpace = spaces.first(where: { $0.id == shellViewModel.selectedSpaceID }),
              let currentIndex = spaces.firstIndex(where: { $0.id == currentSpace.id }),
              spaces.count > 1 else { return }
        
        let previousIndex = (currentIndex - 1 + spaces.count) % spaces.count
        switchToSpace(spaces[previousIndex])
    }
}

enum KeyboardShortcut {
    case commandBar      // ⌘K
    case newTab          // ⌘T
    case closeTab        // ⌘W
    case closeWindow     // ⌘⇧W
    case toggleSidebar   // ⌘\\
    case nextTab         // ⌘⌥→
    case previousTab     // ⌘⌥←
    case tab1, tab2, tab3, tab4, tab5, tab6, tab7, tab8, tab9  // ⌘1-9
    case nextSpace       // ⌘⇧]
    case previousSpace   // ⌘⇧[
    case toggleSplit     // ⌘⇧S
}
