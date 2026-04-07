import AppKit
import Combine
import SwiftUI
import UniformTypeIdentifiers
import WebKit

// MARK: - Arc Browser Content View
// Complete redesign matching the reference design

struct ContentView: View {
    @StateObject private var browserViewModel = BrowserViewModel()
    @StateObject private var shellViewModel = BrowserShellViewModel()
    @State private var addressBarText = ""
    @State private var isSidebarCollapsed = false
    @State private var sidebarWidth: CGFloat = 320  // Wider sidebar like reference
    @State private var isDraggingDivider = false
    @State private var showingCommandBar = false
    @State private var showingSettings = false
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
    
    // Theme
    private var themeColor: Color {
        shellViewModel.selectedProfile.theme.color
    }
    
    private var appTheme: AppTheme {
        shellViewModel.selectedProfile.appTheme
    }
    
    private var themeColors: ArcThemeColors {
        ArcColors.themeColors(for: appTheme)
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
                    showingSettings: $showingSettings,
                    isSplitViewActive: isSplitViewActive,
                    hoveredTabID: $hoveredTabID,
                    hoveredFavoriteID: $hoveredFavoriteID,
                    peekPreviewURL: $peekPreviewURL,
                    peekPreviewPosition: $peekPreviewPosition,
                    onToggleSplitView: toggleSplitView,
                    onSelectTab: selectTab,
                    onCloseTab: closeTab,
                    onSwitchSpace: switchToSpace,
                    themeColor: themeColor,
                    themeColors: themeColors
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
                appTheme: appTheme,
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
        .sheet(isPresented: $showingSettings) {
            ArcSettingsView(shellViewModel: shellViewModel, isPresented: $showingSettings)
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
        // Command Bar - ⌘K
        NotificationCenter.default.addObserver(
            forName: .openCommandPalette,
            object: nil,
            queue: .main
        ) { _ in
            showingCommandBar = true
        }
        
        // New Tab - ⌘T
        NotificationCenter.default.addObserver(
            forName: .newTab,
            object: nil,
            queue: .main
        ) { _ in
            Task { @MainActor in
                shellViewModel.createTab(in: shellViewModel.selectedSpaceID)
            }
        }
        
        // Close Tab - ⌘W
        NotificationCenter.default.addObserver(
            forName: .closeTab,
            object: nil,
            queue: .main
        ) { _ in
            Task { @MainActor in
                if let selectedTab = shellViewModel.selectedTab {
                    closeTab(selectedTab.id)
                }
            }
        }
        
        // Toggle Sidebar - ⇧⌘B
        NotificationCenter.default.addObserver(
            forName: .toggleSidebar,
            object: nil,
            queue: .main
        ) { _ in
            toggleSidebar()
        }
        
        // Next Space - ⇧⌘]
        NotificationCenter.default.addObserver(
            forName: .nextSpace,
            object: nil,
            queue: .main
        ) { _ in
            navigateToNextSpace()
        }
        
        // Previous Space - ⇧⌘[
        NotificationCenter.default.addObserver(
            forName: .previousSpace,
            object: nil,
            queue: .main
        ) { _ in
            navigateToPreviousSpace()
        }
        
        // Next Tab - ⌃⌘Tab
        NotificationCenter.default.addObserver(
            forName: .nextTab,
            object: nil,
            queue: .main
        ) { _ in
            navigateToNextTab()
        }
        
        // Previous Tab - ⌃⇧⌘Tab
        NotificationCenter.default.addObserver(
            forName: .previousTab,
            object: nil,
            queue: .main
        ) { _ in
            navigateToPreviousTab()
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
            .frame(width: 4)
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
                    .fill(isDragging ? ArcColors.purple.opacity(0.3) : Color.clear)
                    .frame(width: 1)
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

// MARK: - Arc Sidebar (Redesigned for Light Theme)
struct ArcSidebar: View {
    @ObservedObject var shellViewModel: BrowserShellViewModel
    @ObservedObject var browserViewModel: BrowserViewModel
    @Binding var addressBarText: String
    @Binding var isCollapsed: Bool
    @Binding var sidebarWidth: CGFloat
    @Binding var showingCommandBar: Bool
    @Binding var showingSettings: Bool
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
    let themeColors: ArcThemeColors
    
    var body: some View {
        ZStack {
            // Background - extends to window top (uses theme colors - light lavender for light theme)
            Rectangle()
                .fill(themeColors.sidebarBackground)
            
            VStack(spacing: 0) {
                // Traffic lights padding area (for hidden title bar) - MUST match sidebar background
                themeColors.sidebarBackground
                    .frame(height: 28)
                
                // Top Bar with Sidebar Toggle
                HStack {
                    // Sidebar toggle button
                    Button {
                        withAnimation(ArcAnimations.sidebarCollapse) {
                            isCollapsed.toggle()
                        }
                    } label: {
                        Image(systemName: "sidebar.left")
                            .font(.system(size: 14, weight: .medium))
                            .foregroundStyle(themeColors.textSecondary)
                    }
                    .buttonStyle(.plain)
                    
                    Spacer()
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
                
                // Favorites Grid - Draggable 2x3 layout (max 6 items)
                ArcSidebarFavoritesSection(
                    shellViewModel: shellViewModel,
                    savedLinks: Array(shellViewModel.savedLinks.prefix(6)),
                    themeColor: themeColor,
                    themeColors: themeColors,
                    hoveredFavoriteID: $hoveredFavoriteID,
                    peekPreviewURL: $peekPreviewURL,
                    peekPreviewPosition: $peekPreviewPosition,
                    onSelect: { url in
                        shellViewModel.updateSelectedTab(title: "Loading...", url: url)
                        browserViewModel.load(url)
                    }
                )
                .padding(.horizontal, 12)
                .padding(.vertical, 12)
                
                // Space name label (e.g., "Main Space", "Research")
                HStack {
                    Text(shellViewModel.selectedSpace.name)
                        .font(ArcTypography.label)
                        .foregroundStyle(themeColors.textTertiary)
                        .tracking(1)
                    
                    Spacer()
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
                
                // Combined Tab List with Folders and Hierarchy
                ArcTabListWithFolders(
                    shellViewModel: shellViewModel,
                    themeColor: themeColor,
                    themeColors: themeColors,
                    hoveredTabID: $hoveredTabID,
                    onSelectTab: onSelectTab,
                    onCloseTab: onCloseTab
                )
                .padding(.top, 4)
                
                Spacer()
                
                // Bottom section
                VStack(spacing: 12) {
                    Divider()
                        .padding(.horizontal, 12)
                        .opacity(0.5)
                    
                    // New Tab Button
                    Button {
                        shellViewModel.createTab(in: shellViewModel.selectedSpaceID)
                        if let tab = shellViewModel.selectedTab {
                            onSelectTab(tab)
                        }
                    } label: {
                        HStack(spacing: 8) {
                            Image(systemName: "plus")
                                .font(.system(size: 12, weight: .medium))
                            Text("New Tab")
                                .font(ArcTypography.bodySmall)
                        }
                        .foregroundStyle(themeColors.textSecondary)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                    }
                    .buttonStyle(.plain)
                    
                    // Spaces
                    ArcSpacesRow(
                        spaces: shellViewModel.spacesForSelectedProfile,
                        selectedSpaceID: shellViewModel.selectedSpaceID,
                        themeColor: themeColor,
                        themeColors: themeColors,
                        onSwitchSpace: onSwitchSpace
                    )
                    .padding(.horizontal, 12)
                    
                    // Bottom toolbar
                    ArcBottomToolbar(
                        shellViewModel: shellViewModel,
                        isSplitViewActive: isSplitViewActive,
                        themeColor: themeColor,
                        themeColors: themeColors,
                        onToggleSplitView: onToggleSplitView,
                        onToggleSidebar: {
                            withAnimation(ArcAnimations.sidebarCollapse) {
                                isCollapsed.toggle()
                            }
                        },
                        showingSettings: $showingSettings
                    )
                    .padding(.horizontal, 12)
                    .padding(.bottom, 12)
                }
            }
        }
        .overlay(
            Rectangle()
                .fill(themeColors.separator)
                .frame(width: 1),
            alignment: .trailing
        )
    }
}

// MARK: - Floating Address Bar (Updated for Light Theme)
struct ArcFloatingAddressBar: View {
    @Binding var text: String
    let isLoading: Bool
    let themeColors: ArcThemeColors
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
                    .foregroundStyle(themeColors.textSecondary)
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
                    .foregroundStyle(themeColors.textTertiary)
                    .padding(.horizontal, 6)
                    .padding(.vertical, 3)
                    .background(
                        RoundedRectangle(cornerRadius: 4, style: .continuous)
                            .fill(themeColors.tertiaryBackground)
                    )
                }
                .buttonStyle(.plain)
            }
            
            // Clear button
            if isFocused && !text.isEmpty {
                Button { text = "" } label: {
                    Image(systemName: "xmark.circle.fill")
                        .font(.system(size: 14, weight: .medium, design: .rounded))
                        .foregroundStyle(themeColors.textTertiary)
                }
                .buttonStyle(.plain)
            }
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 8)
        .background(
            RoundedRectangle(cornerRadius: 8, style: .continuous)
                .fill(themeColors.secondaryBackground)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 8, style: .continuous)
                .stroke(isFocused ? themeColors.textSecondary.opacity(0.3) : Color.clear, lineWidth: 1.5)
        )
        .scaleEffect(isFocused ? 1.02 : 1.0)
        .animation(ArcAnimations.hover, value: isFocused)
        .onHover { hovering in isHovered = hovering }
    }
}

// MARK: - Main Content Address Bar (for top of browser window)
struct ArcMainContentAddressBar: View {
    @Binding var text: String
    let isLoading: Bool
    let themeColor: Color
    let appTheme: AppTheme
    let onSubmit: () -> Void
    let onCommandBar: () -> Void
    
    @FocusState private var isFocused: Bool
    
    private var themeColors: ArcThemeColors {
        ArcColors.themeColors(for: appTheme)
    }
    
    var body: some View {
        HStack(spacing: 12) {
            // Back/Forward buttons
            HStack(spacing: 8) {
                Button(action: { }) {
                    Image(systemName: "chevron.left")
                        .font(.system(size: 14, weight: .medium, design: .rounded))
                        .foregroundStyle(themeColors.textSecondary)
                }
                .buttonStyle(.plain)
                
                Button(action: { }) {
                    Image(systemName: "chevron.right")
                        .font(.system(size: 14, weight: .medium, design: .rounded))
                        .foregroundStyle(themeColors.textTertiary)
                }
                .buttonStyle(.plain)
                .disabled(true)
            }
            
            // Address field
            HStack(spacing: 8) {
                if isLoading {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle())
                        .scaleEffect(0.6)
                        .frame(width: 16, height: 16)
                } else {
                    Image(systemName: "lock.fill")
                        .font(.system(size: 10, weight: .medium, design: .rounded))
                        .foregroundStyle(themeColors.textTertiary)
                }
                
                TextField("Search or enter address", text: $text)
                    .font(ArcTypography.bodySmall)
                    .textFieldStyle(.plain)
                    .focused($isFocused)
                    .onSubmit(onSubmit)
                
                Spacer()
                
                // Refresh button
                Button(action: { }) {
                    Image(systemName: "arrow.clockwise")
                        .font(.system(size: 12, weight: .medium, design: .rounded))
                        .foregroundStyle(themeColors.textSecondary)
                }
                .buttonStyle(.plain)
            }
            .padding(.horizontal, 10)
            .padding(.vertical, 6)
            .background(
                RoundedRectangle(cornerRadius: 8, style: .continuous)
                    .fill(appTheme == .light ? Color.white : themeColors.secondaryBackground)
                    .shadow(color: Color.black.opacity(appTheme == .light ? 0.04 : 0.1), radius: 2, x: 0, y: 1)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 8, style: .continuous)
                    .stroke(appTheme == .light ? Color.black.opacity(0.08) : Color.clear, lineWidth: 1)
            )
            
            // Share and options
            HStack(spacing: 8) {
                Button(action: { }) {
                    Image(systemName: "square.and.arrow.up")
                        .font(.system(size: 14, weight: .medium, design: .rounded))
                        .foregroundStyle(themeColors.textSecondary)
                }
                .buttonStyle(.plain)
                
                Button(action: { }) {
                    Image(systemName: "ellipsis")
                        .font(.system(size: 14, weight: .medium, design: .rounded))
                        .foregroundStyle(themeColors.textSecondary)
                }
                .buttonStyle(.plain)
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 6)
        .background(appTheme == .light ? Color.clear : themeColors.secondaryBackground.opacity(0.5))
    }
}

// MARK: - Favorites Section (Redesigned - 2x3 Grid, Draggable, Max 6)
struct ArcSidebarFavoritesSection: View {
    @ObservedObject var shellViewModel: BrowserShellViewModel
    let savedLinks: [SavedLink]
    let themeColor: Color
    let themeColors: ArcThemeColors
    @Binding var hoveredFavoriteID: UUID?
    @Binding var peekPreviewURL: String?
    @Binding var peekPreviewPosition: CGPoint
    let onSelect: (String) -> Void
    
    // Responsive tile size based on sidebar width
    @State private var containerWidth: CGFloat = 320
    
    private var tileSize: CGFloat {
        // Adaptive sizing: smaller for narrow sidebar, larger for wide
        if containerWidth < 300 {
            return 64
        } else if containerWidth < 340 {
            return 72
        } else {
            return 88
        }
    }
    
    private var faviconSize: CGFloat {
        tileSize * 0.45 // 45% of tile size
    }
    
    var body: some View {
        VStack(spacing: 0) {
            // Drop zone overlay when dragging tab
            if shellViewModel.savedLinks.count < 6 {
                Color.clear
                    .frame(height: 0)
                    .dropDestination(for: BrowserTabDragItem.self) { items, location in
                        guard let item = items.first else { return false }
                        // Add tab URL as new favorite
                        shellViewModel.createSavedLink(
                            title: item.title,
                            url: item.url,
                            folderID: nil
                        )
                        return true
                    }
            }
            
            LazyVGrid(columns: [
                GridItem(.flexible()),
                GridItem(.flexible()),
                GridItem(.flexible())
            ], spacing: 12) {
                ForEach(Array(savedLinks.enumerated()), id: \.element.id) { index, link in
                    ArcFavoriteItem(
                        link: link,
                        index: index,
                        tileSize: tileSize,
                        faviconSize: faviconSize,
                        themeColor: themeColor,
                        themeColors: themeColors,
                        isHovered: hoveredFavoriteID == link.id,
                        isDragging: false,
                        onHover: { isHovered in
                            hoveredFavoriteID = isHovered ? link.id : nil
                            if isHovered {
                                peekPreviewURL = link.url
                            } else {
                                peekPreviewURL = nil
                            }
                        },
                        onSelect: { onSelect(link.url) },
                        onReorder: { fromIndex, toIndex in
                            // Reorder favorites
                            reorderFavorites(from: fromIndex, to: toIndex)
                        }
                    )
                }
                
                // Empty slots (if less than 6 favorites)
                ForEach(0..<max(0, 6 - savedLinks.count), id: \.self) { _ in
                    ArcFavoriteEmptySlot(
                        tileSize: tileSize,
                        themeColors: themeColors
                    )
                }
            }
            .background(
                GeometryReader { geo in
                    Color.clear
                        .onAppear {
                            containerWidth = geo.size.width
                        }
                        .onChange(of: geo.size.width) { oldWidth, newWidth in
                            containerWidth = newWidth
                        }
                }
            )
        }
    }
    
    private func reorderFavorites(from: Int, to: Int) {
        // Implementation for reordering favorites
        // This would update the savedLinks order in shellViewModel
    }
}

// MARK: - Draggable Tab Item
struct BrowserTabDragItem: Transferable, Codable {
    let id: UUID
    let title: String
    let url: String
    
    static var transferRepresentation: some TransferRepresentation {
        CodableRepresentation(contentType: .plainText)
    }
}

// MARK: - Favorite Item (Draggable & Responsive)
struct ArcFavoriteItem: View {
    let link: SavedLink
    let index: Int
    let tileSize: CGFloat
    let faviconSize: CGFloat
    let themeColor: Color
    let themeColors: ArcThemeColors
    let isHovered: Bool
    let isDragging: Bool
    let onHover: (Bool) -> Void
    let onSelect: () -> Void
    let onReorder: (Int, Int) -> Void
    
    @State private var isDragged = false
    
    var body: some View {
        Button(action: onSelect) {
            VStack(spacing: 6) {
                // Responsive tile with favicon
                ZStack {
                    RoundedRectangle(cornerRadius: tileSize * 0.22, style: .continuous)
                        .fill(themeColors.favoriteTileBackground)
                        .frame(width: tileSize, height: tileSize)
                        .shadow(
                            color: isHovered ? Color.black.opacity(0.08) : Color.clear,
                            radius: isHovered ? 8 : 0,
                            x: 0,
                            y: isHovered ? 4 : 0
                        )
                    
                    FaviconAsyncImage(url: link.url, size: faviconSize, fallback: "globe")
                        .frame(width: faviconSize, height: faviconSize)
                }
                
                Text(link.title)
                    .font(ArcTypography.caption)
                    .lineLimit(1)
                    .foregroundStyle(isHovered ? themeColors.textPrimary : themeColors.textSecondary)
            }
        }
        .buttonStyle(.plain)
        .scaleEffect(isHovered ? 1.05 : 1.0)
        .opacity(isDragged ? 0.5 : 1.0)
        .animation(ArcAnimations.hover, value: isHovered)
        .onHover { hovering in onHover(hovering) }
        .draggable(link.title) {
            // Create drag preview
            RoundedRectangle(cornerRadius: tileSize * 0.22)
                .fill(themeColors.favoriteTileBackground)
                .frame(width: tileSize, height: tileSize)
                .overlay(
                    FaviconAsyncImage(url: link.url, size: faviconSize, fallback: "globe")
                )
        }
        .dropDestination(for: String.self) { items, location in
            // Handle drop for reordering
            return false
        }
    }
}

// MARK: - Favorite Empty Slot
struct ArcFavoriteEmptySlot: View {
    let tileSize: CGFloat
    let themeColors: ArcThemeColors
    
    var body: some View {
        VStack(spacing: 6) {
            ZStack {
                RoundedRectangle(cornerRadius: tileSize * 0.22, style: .continuous)
                    .fill(themeColors.tertiaryBackground.opacity(0.5))
                    .frame(width: tileSize, height: tileSize)
                    .overlay(
                        RoundedRectangle(cornerRadius: tileSize * 0.22, style: .continuous)
                            .stroke(
                                themeColors.textTertiary.opacity(0.2),
                                style: StrokeStyle(lineWidth: 1, dash: [4, 4])
                            )
                    )
                
                Image(systemName: "plus")
                    .font(.system(size: tileSize * 0.25, weight: .medium))
                    .foregroundStyle(themeColors.textTertiary)
            }
            
            Text("Add")
                .font(ArcTypography.caption)
                .lineLimit(1)
                .foregroundStyle(themeColors.textTertiary)
        }
        .opacity(0.6)
    }
}

// MARK: - Tab List with Folders (New - Nested Folder Hierarchy)
struct ArcTabListWithFolders: View {
    @ObservedObject var shellViewModel: BrowserShellViewModel
    let themeColor: Color
    let themeColors: ArcThemeColors
    @Binding var hoveredTabID: UUID?
    let onSelectTab: (BrowserTabSession) -> Void
    let onCloseTab: (UUID) -> Void
    
    @State private var showingNewFolderAlert = false
    @State private var newFolderName = ""
    
    var body: some View {
        VStack(spacing: 0) {
            // Section Header with New Folder button
            HStack(spacing: 8) {
                Image(systemName: "folder")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundStyle(themeColors.textTertiary)
                
                Text("Folders & Tabs")
                    .font(ArcTypography.label)
                    .foregroundStyle(themeColors.textTertiary)
                    .tracking(1)
                
                Spacer()
                
                Button {
                    showingNewFolderAlert = true
                } label: {
                    Image(systemName: "plus")
                        .font(.system(size: 11, weight: .semibold))
                        .foregroundStyle(themeColors.textSecondary)
                        .frame(width: 20, height: 20)
                        .background(
                            Circle()
                                .fill(themeColors.tertiaryBackground)
                        )
                }
                .buttonStyle(.plain)
            }
            .padding(.horizontal, 16)
            .padding(.bottom, 8)
            
            ScrollView(showsIndicators: false) {
                LazyVStack(spacing: 2) {
                    // Top-level folders with expand/collapse
                    ForEach(shellViewModel.topLevelFoldersForSelectedSpace) { folder in
                        ArcFolderRow(
                            folder: folder,
                            shellViewModel: shellViewModel,
                            themeColor: themeColor,
                            themeColors: themeColors,
                            hoveredTabID: $hoveredTabID,
                            onSelectTab: onSelectTab,
                            onCloseTab: onCloseTab
                        )
                    }
                    
                // Top-level tabs (not in any folder)
                ForEach(shellViewModel.topLevelTabsForSelectedSpace) { tab in
                    ArcTabRow(
                        tab: tab,
                        isActive: tab.id == shellViewModel.selectedTabID,
                        isHovered: hoveredTabID == tab.id,
                        isPinned: tab.isPinned,
                        themeColor: themeColor,
                        themeColors: themeColors,
                        onSelect: { onSelectTab(tab) },
                        onClose: { onCloseTab(tab.id) },
                        shellViewModel: shellViewModel
                    )
                    .onHover { hovering in
                        hoveredTabID = hovering ? tab.id : nil
                    }
                }
                }
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
            }
        }
        .alert("New Folder", isPresented: $showingNewFolderAlert) {
            TextField("Folder name", text: $newFolderName)
            Button("Cancel", role: .cancel) {
                newFolderName = ""
            }
            Button("Create") {
                if !newFolderName.isEmpty {
                    shellViewModel.createFolder(name: newFolderName)
                    newFolderName = ""
                }
            }
        } message: {
            Text("Enter a name for the new folder")
        }
    }
}

// MARK: - Folder Row (New - with Chevron and Expand/Collapse)
struct ArcFolderRow: View {
    let folder: BrowserFolder
    @ObservedObject var shellViewModel: BrowserShellViewModel
    let themeColor: Color
    let themeColors: ArcThemeColors
    @Binding var hoveredTabID: UUID?
    let onSelectTab: (BrowserTabSession) -> Void
    let onCloseTab: (UUID) -> Void
    
    private var isExpanded: Bool {
        folder.isExpanded
    }
    
    private var folderIconColor: Color {
        if isExpanded {
            return themeColors.folderIconExpanded
        } else if folder.icon == "bookmark.fill" {
            return themeColors.folderIconExpanded  // Pink for bookmark folders like "Career"
        } else {
            return themeColors.folderIcon
        }
    }
    
    private var folderIconName: String {
        if isExpanded {
            return "folder.fill"
        } else if folder.icon == "bookmark.fill" {
            return "bookmark.fill"
        } else {
            return "folder"
        }
    }
    
    @State private var showingRenameAlert = false
    @State private var renameText = ""
    
    var body: some View {
        VStack(spacing: 2) {
            // Folder header row
            Button(action: {
                withAnimation(.easeInOut(duration: 0.2)) {
                    shellViewModel.toggleFolderExpanded(folder.id)
                }
            }) {
                HStack(spacing: 6) {
                    // Chevron indicator - subtle gray
                    Image(systemName: isExpanded ? "chevron.down" : "chevron.right")
                        .font(.system(size: 10, weight: .semibold, design: .rounded))
                        .foregroundStyle(themeColors.textTertiary)
                        .frame(width: 14)
                    
                    // Folder icon - pink/magenta when expanded
                    Image(systemName: folderIconName)
                        .font(.system(size: 14, weight: .medium, design: .rounded))
                        .foregroundStyle(folderIconColor)
                    
                    // Folder name
                    Text(folder.name)
                        .font(ArcTypography.tabTitle)
                        .lineLimit(1)
                        .foregroundStyle(isExpanded ? themeColors.textPrimary : themeColors.textSecondary)
                    
                    Spacer()
                    
                    // Tab count badge
                    let tabCount = shellViewModel.tabs(in: folder.id).count
                    if tabCount > 0 {
                        Text("\(tabCount)")
                            .font(ArcTypography.labelSmall)
                            .foregroundStyle(themeColors.textTertiary)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(
                                RoundedRectangle(cornerRadius: 8, style: .continuous)
                                    .fill(themeColors.tertiaryBackground)
                            )
                    }
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(
                    RoundedRectangle(cornerRadius: 8, style: .continuous)
                        .fill(isExpanded ? themeColor.opacity(0.05) : Color.clear)
                )
            }
            .buttonStyle(.plain)
            #if os(macOS)
            .onDrop(of: ["public.text"], isTargeted: nil) { providers in
                // Handle dropped tab
                guard let provider = providers.first else { return false }
                provider.loadObject(ofClass: NSString.self) { (object, error) in
                    if let tabIDString = object as? String,
                       let tabID = UUID(uuidString: tabIDString) {
                        DispatchQueue.main.async {
                            shellViewModel.moveTab(tabID, toFolder: folder.id)
                        }
                    }
                }
                return true
            }
            #endif
            .contextMenu {
                Button {
                    renameText = folder.name
                    showingRenameAlert = true
                } label: {
                    Label("Rename", systemImage: "pencil")
                }
                
                Button {
                    shellViewModel.createNestedFolder(name: "New Subfolder", parentFolderID: folder.id)
                } label: {
                    Label("Add Subfolder", systemImage: "folder.badge.plus")
                }
                
                Divider()
                
                Button(role: .destructive) {
                    shellViewModel.deleteFolder(folder.id)
                } label: {
                    Label("Delete", systemImage: "trash")
                }
            }
            
            // Expanded folder contents - child tabs with indentation
            if isExpanded {
                VStack(spacing: 2) {
                    ForEach(shellViewModel.tabs(in: folder.id)) { tab in
                        ArcTabRow(
                            tab: tab,
                            isActive: tab.id == shellViewModel.selectedTabID,
                            isHovered: hoveredTabID == tab.id,
                            isPinned: tab.isPinned,
                            themeColor: themeColor,
                            themeColors: themeColors,
                            isChildTab: true,  // Indented child tab
                            onSelect: { onSelectTab(tab) },
                            onClose: { onCloseTab(tab.id) },
                            shellViewModel: shellViewModel
                        )
                        .onHover { hovering in
                            hoveredTabID = hovering ? tab.id : nil
                        }
                    }
                    
                    // Nested child folders
                    ForEach(shellViewModel.childFolders(of: folder.id)) { childFolder in
                        ArcFolderRow(
                            folder: childFolder,
                            shellViewModel: shellViewModel,
                            themeColor: themeColor,
                            themeColors: themeColors,
                            hoveredTabID: $hoveredTabID,
                            onSelectTab: onSelectTab,
                            onCloseTab: onCloseTab
                        )
                        .padding(.leading, 16)  // Indent nested folders
                    }
                }
                .padding(.leading, 12)  // Indent folder contents
            }
        }
        .alert("Rename Folder", isPresented: $showingRenameAlert) {
            TextField("Folder name", text: $renameText)
            Button("Cancel", role: .cancel) {
                renameText = ""
            }
            Button("Rename") {
                if !renameText.isEmpty {
                    shellViewModel.renameFolder(folder.id, to: renameText)
                    renameText = ""
                }
            }
        } message: {
            Text("Enter a new name for the folder")
        }
    }
}

// MARK: - Tab Row (Redesigned - White Pill for Active Tab)
struct ArcTabRow: View {
    let tab: BrowserTabSession
    let isActive: Bool
    let isHovered: Bool
    let isPinned: Bool
    let themeColor: Color
    let themeColors: ArcThemeColors
    var isChildTab: Bool = false  // For indented child tabs in folders
    let onSelect: () -> Void
    let onClose: () -> Void
    
    // Access shellViewModel from environment or pass it in
    @ObservedObject var shellViewModel: BrowserShellViewModel
    
    var body: some View {
        Button(action: onSelect) {
            HStack(spacing: 8) {
                // Indent for child tabs
                if isChildTab {
                    Rectangle()
                        .fill(Color.clear)
                        .frame(width: 12)
                }
                
                // Favicon - using actual favicon from FaviconService
                ZStack {
                    // Active tab uses white pill background with shadow
                    if isActive {
                        RoundedRectangle(cornerRadius: 6, style: .continuous)
                            .fill(themeColors.activeTabBackground)
                            .frame(width: 28, height: 28)
                            .shadow(color: themeColors.activeTabShadow, radius: 4, x: 0, y: 2)
                    } else {
                        RoundedRectangle(cornerRadius: 6, style: .continuous)
                            .fill(themeColors.tertiaryBackground)
                            .frame(width: 28, height: 28)
                    }
                    
                    // Use FaviconService for actual website icons
                    FaviconAsyncImage(url: tab.url, size: 16, fallback: "globe")
                        .frame(width: 16, height: 16)
                }
                
                // Title
                Text(tab.title)
                    .font(isActive ? ArcTypography.tabTitleActive : ArcTypography.tabTitle)
                    .lineLimit(1)
                    .foregroundStyle(isActive ? themeColors.textPrimary : themeColors.textSecondary)
                
                Spacer()
                
                // Close button or active indicator
                if isHovered || isActive {
                    if isHovered {
                        Button(action: onClose) {
                            Image(systemName: "xmark")
                                .font(.system(size: 10, weight: .semibold, design: .rounded))
                                .foregroundStyle(themeColors.textSecondary)
                                .frame(width: 16, height: 16)
                                .background(
                                    Circle()
                                        .fill(themeColors.quaternaryBackground)
                                )
                        }
                        .buttonStyle(.plain)
                        .transition(.opacity)
                    } else if isActive {
                        // Active indicator dot with theme color
                        Circle()
                            .fill(themeColor)
                            .frame(width: 5, height: 5)
                            .shadow(color: themeColor.opacity(0.4), radius: 2)
                    }
                }
            }
            .padding(.horizontal, 10)
            .padding(.vertical, 6)
            .background(
                // White pill background for active tab with shadow - matching reference
                RoundedRectangle(cornerRadius: 10, style: .continuous)
                    .fill(isActive ? themeColors.activeTabBackground : Color.clear)
                    .shadow(color: isActive ? themeColors.activeTabShadow : Color.clear, radius: 4, x: 0, y: 2)
            )
        }
        .buttonStyle(.plain)
        .animation(ArcAnimations.hover, value: isHovered)
        .animation(ArcAnimations.hover, value: isActive)
        .contentShape(Rectangle())
        .draggable(
            BrowserTabDragItem(id: tab.id, title: tab.title, url: tab.url),
            preview: {
                // Drag preview
                HStack(spacing: 8) {
                    FaviconAsyncImage(url: tab.url, size: 16, fallback: "globe")
                        .frame(width: 16, height: 16)
                    Text(tab.title)
                        .font(ArcTypography.bodySmall)
                        .lineLimit(1)
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .background(
                    RoundedRectangle(cornerRadius: 8)
                        .fill(themeColors.secondaryBackground)
                        .shadow(color: Color.black.opacity(0.1), radius: 4, x: 0, y: 2)
                )
            }
        )
        .contextMenu {
            Button {
                shellViewModel.togglePinned(for: tab.id)
            } label: {
                Label(tab.isPinned ? "Unpin" : "Pin", systemImage: tab.isPinned ? "pin.slash" : "pin")
            }
            
            Menu("Move to Folder") {
                Button {
                    shellViewModel.moveTab(tab.id, toFolder: nil)
                } label: {
                    Label("Top Level", systemImage: "arrow.up")
                }
                
                Divider()
                
                ForEach(shellViewModel.foldersForSelectedSpace) { folder in
                    Button {
                        shellViewModel.moveTab(tab.id, toFolder: folder.id)
                    } label: {
                        Label(folder.name, systemImage: "folder")
                    }
                }
            }
            
            Divider()
            
            Button(role: .destructive) {
                onClose()
            } label: {
                Label("Close", systemImage: "xmark")
            }
        }
    }
}

// MARK: - Spaces Row (Updated for Light Theme)
struct ArcSpacesRow: View {
    let spaces: [BrowserSpace]
    let selectedSpaceID: UUID
    let themeColor: Color
    let themeColors: ArcThemeColors
    let onSwitchSpace: (BrowserSpace) -> Void
    
    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 6) {
                ForEach(spaces) { space in
                    let isSelected = space.id == selectedSpaceID
                    
                    Button { onSwitchSpace(space) } label: {
                        HStack(spacing: 4) {
                            Image(systemName: space.icon)
                                .font(.system(size: 10, weight: isSelected ? .semibold : .medium, design: .rounded))
                            
                            if isSelected {
                                Text(space.name)
                                    .font(ArcTypography.label)
                            }
                        }
                        .padding(.horizontal, isSelected ? 10 : 6)
                        .padding(.vertical, 4)
                        .background(
                            RoundedRectangle(cornerRadius: 100, style: .continuous)
                                .fill(isSelected ? themeColor.opacity(0.15) : themeColors.tertiaryBackground)
                        )
                        .foregroundStyle(isSelected ? themeColor : themeColors.textSecondary)
                    }
                    .buttonStyle(.plain)
                    .animation(ArcAnimations.hover, value: isSelected)
                }
            }
        }
    }
}

// MARK: - Bottom Toolbar (Redesigned - "New Arc Version Available" + Icons)
struct ArcBottomToolbar: View {
    @ObservedObject var shellViewModel: BrowserShellViewModel
    let isSplitViewActive: Bool
    let themeColor: Color
    let themeColors: ArcThemeColors
    let onToggleSplitView: () -> Void
    let onToggleSidebar: () -> Void
    @Binding var showingSettings: Bool
    
    var body: some View {
        VStack(spacing: 8) {
            // "New Arc Version Available" button (per reference design)
            Button(action: {
                // Open Arc download page
                if let url = URL(string: "https://arc.net/download") {
                    NSWorkspace.shared.open(url)
                }
            }) {
                HStack(spacing: 6) {
                    Image(systemName: "sparkles")
                        .font(.system(size: 12, weight: .medium, design: .rounded))
                    Text("New Arc Version Available")
                        .font(ArcTypography.caption)
                    Spacer()
                    Image(systemName: "arrow.up.right")
                        .font(.system(size: 10, weight: .medium, design: .rounded))
                }
                .padding(.horizontal, 10)
                .padding(.vertical, 8)
                .background(
                    RoundedRectangle(cornerRadius: 8, style: .continuous)
                        .stroke(themeColors.textSecondary.opacity(0.3), lineWidth: 1)
                )
                .foregroundStyle(themeColors.textSecondary)
            }
            .buttonStyle(.plain)
            
            // Icon row: Archive, Heart, Bookmark, Settings, +
            HStack(spacing: 12) {
                Button {
                    // Archive action
                } label: {
                    Image(systemName: "archivebox")
                        .font(.system(size: 14, weight: .medium, design: .rounded))
                        .foregroundStyle(themeColors.textSecondary)
                }
                .buttonStyle(.plain)
                
                Button {
                    // Favorite action
                } label: {
                    Image(systemName: "heart")
                        .font(.system(size: 14, weight: .medium, design: .rounded))
                        .foregroundStyle(themeColors.textSecondary)
                }
                .buttonStyle(.plain)
                
                Button {
                    // Bookmark action
                } label: {
                    Image(systemName: "bookmark")
                        .font(.system(size: 14, weight: .medium, design: .rounded))
                        .foregroundStyle(themeColors.textSecondary)
                }
                .buttonStyle(.plain)
                
                Button {
                    showingSettings = true
                } label: {
                    Image(systemName: "gear")
                        .font(.system(size: 14, weight: .medium, design: .rounded))
                        .foregroundStyle(themeColors.textSecondary)
                }
                .buttonStyle(.plain)
                
                // Theme toggle button
                Button {
                    shellViewModel.toggleSelectedProfileAppTheme()
                } label: {
                    Image(systemName: shellViewModel.selectedProfile.appTheme == .light ? "sun.max.fill" : "moon.fill")
                        .font(.system(size: 14, weight: .medium, design: .rounded))
                        .foregroundStyle(themeColors.textSecondary)
                }
                .buttonStyle(.plain)
                
                Spacer()
                
                // + button
                Button {
                    shellViewModel.createTab(in: shellViewModel.selectedSpaceID)
                } label: {
                    Image(systemName: "plus")
                        .font(.system(size: 16, weight: .semibold, design: .rounded))
                        .foregroundStyle(themeColors.textPrimary)
                        .frame(width: 28, height: 28)
                        .background(
                            Circle()
                                .fill(themeColors.tertiaryBackground)
                        )
                }
                .buttonStyle(.plain)
            }
        }
    }
}

// MARK: - Main Content (Updated for Light Theme Support)
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
    let appTheme: AppTheme
    let onToggleSidebar: () -> Void
    let onToggleSplitView: () -> Void
    let onOpenURL: (String) -> Void
    
    var body: some View {
        ZStack {
            // Background that matches sidebar theme - extends under traffic lights
            ArcColors.themeColors(for: appTheme).sidebarBackground
                .ignoresSafeArea()
            
            VStack(spacing: 0) {
                // Address Bar at top of main content (per reference design)
                if let tab = shellViewModel.selectedTab, !isNewTab(tab.url) {
                    ArcMainContentAddressBar(
                        text: $addressBarText,
                        isLoading: browserViewModel.isLoading,
                        themeColor: themeColor,
                        appTheme: appTheme,
                        onSubmit: {
                            let url = addressBarText
                            shellViewModel.updateSelectedTab(title: "Loading...", url: url)
                            browserViewModel.load(url)
                        },
                        onCommandBar: {
                            // Command bar will be handled via keyboard shortcut
                        }
                    )
                    .padding(.horizontal, 16)
                    .padding(.top, 8)
                    .padding(.bottom, 8)
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
                                appTheme: appTheme,
                                onOpenURL: onOpenURL,
                                onCreateTab: {
                                    shellViewModel.createTab(in: shellViewModel.selectedSpaceID)
                                }
                            )
                        } else {
                            WebView(viewModel: browserViewModel)
                                .id(tab.id)
                                .onAppear { browserViewModel.load(tab.url) }
                        }
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
    
    private func isNewTab(_ url: String) -> Bool {
        url == "about:newtab" || url.isEmpty || url == "https://www.apple.com"
    }
}

// MARK: - New Tab View (Updated for Light Theme)
struct ArcNewTabView: View {
    let savedLinks: [SavedLink]
    let recentHistory: [BrowserHistoryEntry]
    let theme: ArcTheme
    let appTheme: AppTheme
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
    
    private var themeColors: ArcThemeColors {
        ArcColors.themeColors(for: appTheme)
    }
    
    var body: some View {
        ZStack {
            // Background matching sidebar theme - lavender for light theme
            themeColors.sidebarBackground
                .ignoresSafeArea()
        }
    }
}

// MARK: - New Tab Favorite Card (Updated for Light Theme + Favicons)
struct ArcNewTabFavoriteCard: View {
    let link: SavedLink
    let appTheme: AppTheme
    let onSelect: () -> Void
    @State private var isHovered = false
    
    private var themeColors: ArcThemeColors {
        ArcColors.themeColors(for: appTheme)
    }
    
    var body: some View {
        Button(action: onSelect) {
            VStack(spacing: 8) {
                ZStack {
                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                        .fill(appTheme == .dark ? themeColors.secondaryBackground : themeColors.favoriteTileBackground)
                        .frame(width: 72, height: 72)
                        .overlay(
                            RoundedRectangle(cornerRadius: 16, style: .continuous)
                                .stroke(appTheme == .dark ? themeColors.separator : Color.clear, lineWidth: 1)
                        )
                    
                    // Use FaviconService for actual website icons
                    FaviconAsyncImage(url: link.url, size: 36, fallback: "globe")
                        .frame(width: 36, height: 36)
                }
                
                Text(link.title)
                    .font(ArcTypography.caption)
                    .lineLimit(1)
                    .foregroundStyle(appTheme == .dark ? .secondary : themeColors.textSecondary)
            }
        }
        .buttonStyle(.plain)
        .scaleEffect(isHovered ? 1.05 : 1.0)
        .animation(ArcAnimations.hover, value: isHovered)
        .onHover { hovering in isHovered = hovering }
    }
}

// MARK: - Gradient Background (Unchanged)
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

// MARK: - Peek Preview Card (Unchanged)
struct ArcPeekPreviewCard: View {
    let url: String
    let position: CGPoint
    let themeColor: Color
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            // Preview placeholder
            RoundedRectangle(cornerRadius: 8, style: .continuous)
                .fill(themeColor.opacity(0.1))
                .frame(width: 200, height: 120)
                .overlay(
                    Image(systemName: "eye.fill")
                        .font(.system(size: 32))
                        .foregroundStyle(themeColor.opacity(0.5))
                )
            
            VStack(alignment: .leading, spacing: 4) {
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
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .fill(.ultraThinMaterial)
                .overlay(
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .stroke(Color.white.opacity(0.2), lineWidth: 1)
                )
        )
        .shadow(color: .black.opacity(0.2), radius: 20, x: 0, y: 10)
        .position(x: position.x + 120, y: position.y)
    }
}

// MARK: - Command Bar (Unchanged)
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
                HStack(spacing: 12) {
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
                .padding(.horizontal, 16)
                .padding(.vertical, 12)
                
                Divider()
                
                // Results
                ScrollView {
                    VStack(spacing: 8) {
                        if query.isEmpty {
                            // Show recent tabs when empty
                            if !shellViewModel.recentHistoryEntries.isEmpty {
                                Text("Recent History")
                                    .font(ArcTypography.label)
                                    .foregroundStyle(.secondary)
                                    .padding(.top, 8)
                                    .frame(maxWidth: .infinity, alignment: .leading)
                                    .padding(.horizontal, 12)
                                
                                ForEach(shellViewModel.recentHistoryEntries.prefix(5)) { entry in
                                    Button {
                                        onOpenURL(entry.url)
                                        isPresented = false
                                    } label: {
                                        HStack(spacing: 12) {
                                            Image(systemName: "clock")
                                                .font(.system(size: 16, weight: .medium))
                                                .foregroundStyle(themeColor)
                                                .frame(width: 24)
                                            
                                            VStack(alignment: .leading, spacing: 2) {
                                                Text(entry.title)
                                                    .font(ArcTypography.body)
                                                    .foregroundStyle(.primary)
                                                    .lineLimit(1)
                                                
                                                Text(entry.url)
                                                    .font(ArcTypography.caption)
                                                    .foregroundStyle(.secondary)
                                                    .lineLimit(1)
                                            }
                                            
                                            Spacer()
                                        }
                                        .padding(.horizontal, 12)
                                        .padding(.vertical, 6)
                                        .background(
                                            RoundedRectangle(cornerRadius: 8, style: .continuous)
                                                .fill(Color.clear)
                                        )
                                    }
                                    .buttonStyle(.plain)
                                }
                            } else {
                                // Default state
                                VStack(spacing: 24) {
                                    Image(systemName: "command")
                                        .font(.system(size: 32, design: .rounded))
                                        .foregroundStyle(.secondary.opacity(0.5))
                                    
                                    Text("Type to search tabs, history, or enter a URL")
                                        .font(ArcTypography.caption)
                                        .foregroundStyle(.secondary)
                                }
                                .padding(.top, 32)
                            }
                        } else {
                            // Search tabs
                            let matchingTabs = shellViewModel.tabsForSelectedSpace.filter { 
                                $0.title.lowercased().contains(query.lowercased()) || 
                                $0.url.lowercased().contains(query.lowercased())
                            }
                            
                            if !matchingTabs.isEmpty {
                                Text("Tabs")
                                    .font(ArcTypography.label)
                                    .foregroundStyle(.secondary)
                                    .frame(maxWidth: .infinity, alignment: .leading)
                                    .padding(.horizontal, 12)
                                    .padding(.top, 8)
                                
                                ForEach(matchingTabs) { tab in
                                    Button {
                                        onSelectTab(tab)
                                        isPresented = false
                                    } label: {
                                        HStack(spacing: 12) {
                                            FaviconAsyncImage(url: tab.url, size: 16, fallback: "globe")
                                                .frame(width: 24, height: 24)
                                            
                                            VStack(alignment: .leading, spacing: 2) {
                                                Text(tab.title)
                                                    .font(ArcTypography.body)
                                                    .foregroundStyle(.primary)
                                                    .lineLimit(1)
                                                
                                                Text(tab.url)
                                                    .font(ArcTypography.caption)
                                                    .foregroundStyle(.secondary)
                                                    .lineLimit(1)
                                            }
                                            
                                            Spacer()
                                        }
                                        .padding(.horizontal, 12)
                                        .padding(.vertical, 6)
                                        .background(
                                            RoundedRectangle(cornerRadius: 8, style: .continuous)
                                                .fill(themeColor.opacity(0.08))
                                        )
                                    }
                                    .buttonStyle(.plain)
                                }
                            }
                            
                            // URL entry option
                            Button {
                                onOpenURL(query)
                                isPresented = false
                            } label: {
                                HStack(spacing: 12) {
                                    Image(systemName: "arrow.up.forward")
                                        .font(.system(size: 16, weight: .medium, design: .rounded))
                                        .foregroundStyle(themeColor)
                                        .frame(width: 24)
                                    
                                    VStack(alignment: .leading, spacing: 4) {
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
                                .padding(.horizontal, 12)
                                .padding(.vertical, 8)
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
                .frame(maxHeight: 400)
            }
            .frame(width: 640)
            .background(
                RoundedRectangle(cornerRadius: 20, style: .continuous)
                    .fill(.ultraThinMaterial)
                    .overlay(
                        RoundedRectangle(cornerRadius: 20, style: .continuous)
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
            shellViewModel.createTab(in: shellViewModel.selectedSpaceID)
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
