import Combine
import SwiftUI

struct ContentView: View {
    @StateObject private var browserViewModel = BrowserViewModel()
    @StateObject private var shellViewModel = BrowserShellViewModel()
    @State private var addressBarText = ""
    @State private var isCreatingSpace = false
    @State private var isRenamingSpace = false
    @State private var spaceNameDraft = ""
    @State private var isCreatingFolder = false
    @State private var folderNameDraft = ""
    @State private var isAddingSavedLink = false
    @State private var savedLinkTitleDraft = ""
    @State private var savedLinkURLDraft = ""
    @State private var isCommandPalettePresented = false
    @State private var commandQuery = ""
    @FocusState private var isCommandFieldFocused: Bool

    private var selectedProfileBinding: Binding<UUID> {
        Binding(
            get: { shellViewModel.selectedProfileID },
            set: { shellViewModel.selectProfile($0) }
        )
    }

    var body: some View {
        HSplitView {
            sidebar
                .frame(minWidth: 250, idealWidth: 280, maxWidth: 320)

            browserPane
        }
        .frame(minWidth: 900, minHeight: 600)
        .tint(shellViewModel.selectedProfile.theme.color)
        .overlay {
            if isCommandPalettePresented {
                commandPaletteOverlay
            }
        }
        .onReceive(browserViewModel.$displayURL.removeDuplicates()) { url in
            guard !url.isEmpty else { return }
            addressBarText = url
            shellViewModel.recordHistoryVisit(title: browserViewModel.pageTitle, url: url)
        }
        .onReceive(NotificationCenter.default.publisher(for: .openCommandPalette)) { _ in
            openCommandPalette()
        }
        .onChange(of: shellViewModel.selectedTabID) { _, _ in
            loadSelectedTab()
        }
        .onChange(of: shellViewModel.selectedSpaceID) { _, _ in
            loadSelectedTab()
        }
        .onAppear {
            browserViewModel.onStateChange = { title, url in
                shellViewModel.updateSelectedTab(title: title, url: url)
            }
            loadSelectedTab()
        }
    }

    private var sidebar: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Profiles")
                        .font(.caption)
                        .foregroundStyle(.secondary)

                    Picker("Profile", selection: selectedProfileBinding) {
                        ForEach(shellViewModel.profiles) { profile in
                            Text(profile.name).tag(profile.id)
                        }
                    }
                    .labelsHidden()
                    .pickerStyle(.menu)
                }

                section("Spaces") {
                    HStack(spacing: 8) {
                        Button {
                            spaceNameDraft = ""
                            isRenamingSpace = false
                            isCreatingSpace = true
                        } label: {
                            Image(systemName: "plus")
                        }
                        .buttonStyle(.plain)

                        Button {
                            spaceNameDraft = shellViewModel.selectedSpace.name
                            isCreatingSpace = false
                            isRenamingSpace = true
                        } label: {
                            Image(systemName: "pencil")
                        }
                        .buttonStyle(.plain)

                        Button(role: .destructive) {
                            shellViewModel.deleteSelectedSpace()
                        } label: {
                            Image(systemName: "trash")
                                .foregroundStyle(shellViewModel.canDeleteSelectedSpace ? .red : .secondary)
                        }
                        .buttonStyle(.plain)
                        .disabled(!shellViewModel.canDeleteSelectedSpace)
                    }

                    if isCreatingSpace || isRenamingSpace {
                        HStack(spacing: 8) {
                            TextField(isCreatingSpace ? "New space name" : "Rename space", text: $spaceNameDraft)
                                .textFieldStyle(.roundedBorder)

                            Button(isCreatingSpace ? "Add" : "Save") {
                                if isCreatingSpace {
                                    shellViewModel.createSpace(name: spaceNameDraft)
                                } else {
                                    shellViewModel.renameSelectedSpace(to: spaceNameDraft)
                                }

                                spaceNameDraft = ""
                                isCreatingSpace = false
                                isRenamingSpace = false
                            }
                            .disabled(spaceNameDraft.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)

                            Button("Cancel") {
                                spaceNameDraft = ""
                                isCreatingSpace = false
                                isRenamingSpace = false
                            }
                        }
                    }

                    ForEach(shellViewModel.spacesForSelectedProfile) { space in
                        Button {
                            shellViewModel.selectSpace(space.id)
                        } label: {
                            Label(space.name, systemImage: space.icon)
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .padding(.horizontal, 10)
                                .padding(.vertical, 8)
                                .background(space.id == shellViewModel.selectedSpaceID ? shellViewModel.selectedProfile.theme.color.opacity(0.15) : Color.clear)
                                .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
                        }
                        .buttonStyle(.plain)
                    }
                }

                section("Open Tabs") {
                    Button {
                        shellViewModel.createTab(in: shellViewModel.selectedSpaceID)
                    } label: {
                        Label("New Tab", systemImage: "plus")
                            .frame(maxWidth: .infinity, alignment: .leading)
                    }
                    .buttonStyle(.plain)

                    ForEach(shellViewModel.tabsForSelectedSpace) { tab in
                        HStack(spacing: 8) {
                            Button {
                                shellViewModel.selectTab(tab.id)
                            } label: {
                                VStack(alignment: .leading, spacing: 2) {
                                    Text(tab.title)
                                        .foregroundStyle(.primary)
                                        .lineLimit(1)

                                    Text(tab.url)
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                        .lineLimit(1)
                                }
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .padding(.horizontal, 10)
                                .padding(.vertical, 8)
                                .background(tab.id == shellViewModel.selectedTabID ? shellViewModel.selectedProfile.theme.color.opacity(0.15) : Color.clear)
                                .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
                            }
                            .buttonStyle(.plain)

                            Button {
                                shellViewModel.closeTab(tab.id)
                            } label: {
                                Image(systemName: "xmark")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                            .buttonStyle(.plain)
                        }
                    }
                }

                section("Folders") {
                    HStack(spacing: 8) {
                        Button {
                            folderNameDraft = ""
                            isCreatingFolder = true
                        } label: {
                            Image(systemName: "plus")
                        }
                        .buttonStyle(.plain)

                        Button {
                            shellViewModel.saveCurrentPage(folderID: nil, title: browserViewModel.pageTitle, url: browserViewModel.displayURL)
                        } label: {
                            Image(systemName: "bookmark")
                        }
                        .buttonStyle(.plain)
                        .disabled(browserViewModel.displayURL.isEmpty)
                    }

                    if isCreatingFolder {
                        HStack(spacing: 8) {
                            TextField("New folder name", text: $folderNameDraft)
                                .textFieldStyle(.roundedBorder)

                            Button("Add") {
                                shellViewModel.createFolder(name: folderNameDraft)
                                folderNameDraft = ""
                                isCreatingFolder = false
                            }
                            .disabled(folderNameDraft.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)

                            Button("Cancel") {
                                folderNameDraft = ""
                                isCreatingFolder = false
                            }
                        }
                    }

                    ForEach(shellViewModel.foldersForSelectedSpace) { folder in
                        VStack(alignment: .leading, spacing: 8) {
                            HStack(spacing: 8) {
                                Label(folder.name, systemImage: "folder")
                                    .font(.subheadline.weight(.medium))

                                Spacer(minLength: 0)

                                Button {
                                    shellViewModel.saveCurrentPage(folderID: folder.id, title: browserViewModel.pageTitle, url: browserViewModel.displayURL)
                                } label: {
                                    Image(systemName: "plus.circle")
                                        .foregroundStyle(.secondary)
                                }
                                .buttonStyle(.plain)
                                .disabled(browserViewModel.displayURL.isEmpty)

                                Button(role: .destructive) {
                                    shellViewModel.deleteFolder(folder.id)
                                } label: {
                                    Image(systemName: "trash")
                                        .foregroundStyle(.secondary)
                                }
                                .buttonStyle(.plain)
                            }

                            ForEach(shellViewModel.savedLinks(in: folder)) { link in
                                savedLinkRow(link, icon: "link")
                                    .padding(.leading, 18)
                            }
                        }
                    }
                }

                section("Saved Links") {
                    HStack(spacing: 8) {
                        Button {
                            savedLinkTitleDraft = browserViewModel.pageTitle == "ArcBrowser" ? "" : browserViewModel.pageTitle
                            savedLinkURLDraft = browserViewModel.displayURL
                            isAddingSavedLink.toggle()
                        } label: {
                            Image(systemName: "plus")
                        }
                        .buttonStyle(.plain)

                        Button {
                            shellViewModel.saveCurrentPage(folderID: nil, title: browserViewModel.pageTitle, url: browserViewModel.displayURL)
                        } label: {
                            Image(systemName: "bookmark.fill")
                        }
                        .buttonStyle(.plain)
                        .disabled(browserViewModel.displayURL.isEmpty)
                    }

                    if isAddingSavedLink {
                        VStack(spacing: 8) {
                            TextField("Title", text: $savedLinkTitleDraft)
                                .textFieldStyle(.roundedBorder)

                            TextField("URL", text: $savedLinkURLDraft)
                                .textFieldStyle(.roundedBorder)

                            HStack {
                                Button("Add") {
                                    shellViewModel.createSavedLink(title: savedLinkTitleDraft, url: savedLinkURLDraft, folderID: nil)
                                    savedLinkTitleDraft = ""
                                    savedLinkURLDraft = ""
                                    isAddingSavedLink = false
                                }
                                .disabled(
                                    savedLinkTitleDraft.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ||
                                    savedLinkURLDraft.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
                                )

                                Button("Cancel") {
                                    savedLinkTitleDraft = ""
                                    savedLinkURLDraft = ""
                                    isAddingSavedLink = false
                                }
                            }
                        }
                    }

                    ForEach(shellViewModel.topLevelSavedLinksForSelectedSpace) { link in
                        savedLinkRow(link, icon: "bookmark")
                    }
                }

                section("History") {
                    HStack(spacing: 8) {
                        Button(role: .destructive) {
                            shellViewModel.clearHistory()
                        } label: {
                            Image(systemName: "trash")
                        }
                        .buttonStyle(.plain)
                        .disabled(shellViewModel.historyEntries.isEmpty)
                    }

                    ForEach(Array(shellViewModel.recentHistoryEntries.prefix(8))) { entry in
                        historyRow(entry)
                    }
                }
            }
            .padding(16)
        }
        .background(Color(nsColor: .windowBackgroundColor))
    }

    private var browserPane: some View {
        VStack(spacing: 0) {
            HStack(spacing: 10) {
                Button(action: browserViewModel.goBack) {
                    Image(systemName: "chevron.left")
                }
                .disabled(!browserViewModel.canGoBack)

                Button(action: browserViewModel.goForward) {
                    Image(systemName: "chevron.right")
                }
                .disabled(!browserViewModel.canGoForward)

                Button(action: browserViewModel.reload) {
                    Image(systemName: browserViewModel.isLoading ? "xmark" : "arrow.clockwise")
                }

                TextField("Search or enter website name", text: $addressBarText)
                    .textFieldStyle(.roundedBorder)
                    .onSubmit {
                        shellViewModel.updateSelectedTab(title: addressBarText, url: addressBarText)
                        browserViewModel.load(addressBarText)
                    }

                Button("Go") {
                    shellViewModel.updateSelectedTab(title: addressBarText, url: addressBarText)
                    browserViewModel.load(addressBarText)
                }
            }
            .padding(12)
            .background(.bar)

            Divider()

            WebView(viewModel: browserViewModel)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
    }

    private var commandPaletteOverlay: some View {
        ZStack {
            Color.black.opacity(0.18)
                .ignoresSafeArea()
                .onTapGesture {
                    closeCommandPalette()
                }

            VStack(spacing: 0) {
                HStack(spacing: 10) {
                    Image(systemName: "magnifyingglass")
                        .foregroundStyle(.secondary)

                    TextField("Search tabs, spaces, links, or commands", text: $commandQuery)
                        .textFieldStyle(.plain)
                        .focused($isCommandFieldFocused)
                        .onSubmit {
                            guard let firstItem = commandPaletteItems.first else { return }
                            executeCommand(firstItem.action)
                        }

                    if !commandQuery.isEmpty {
                        Button {
                            commandQuery = ""
                        } label: {
                            Image(systemName: "xmark.circle.fill")
                                .foregroundStyle(.secondary)
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(14)

                Divider()

                ScrollView {
                    VStack(spacing: 0) {
                        ForEach(commandPaletteItems.prefix(12)) { item in
                            Button {
                                executeCommand(item.action)
                            } label: {
                                HStack(spacing: 12) {
                                    Image(systemName: item.systemImage)
                                        .frame(width: 18)
                                        .foregroundStyle(.secondary)

                                    VStack(alignment: .leading, spacing: 2) {
                                        Text(item.title)
                                            .foregroundStyle(.primary)
                                            .frame(maxWidth: .infinity, alignment: .leading)

                                        if !item.subtitle.isEmpty {
                                            Text(item.subtitle)
                                                .font(.caption)
                                                .foregroundStyle(.secondary)
                                                .frame(maxWidth: .infinity, alignment: .leading)
                                        }
                                    }
                                }
                                .padding(.horizontal, 14)
                                .padding(.vertical, 10)
                            }
                            .buttonStyle(.plain)

                            Divider()
                        }
                    }
                }
                .frame(maxHeight: 360)
            }
            .frame(width: 640)
            .background(.regularMaterial)
            .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
            .shadow(radius: 24)
        }
    }

    private var commandPaletteItems: [CommandPaletteItem] {
        let query = commandQuery.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()

        var items: [CommandPaletteItem] = [
            CommandPaletteItem(
                id: "command-new-tab",
                title: "New Tab",
                subtitle: "Create a tab in the current space",
                systemImage: "plus.square.on.square",
                action: .createTab
            ),
            CommandPaletteItem(
                id: "command-new-space",
                title: "New Space",
                subtitle: "Create a new space in the current profile",
                systemImage: "square.grid.2x2",
                action: .createSpace
            ),
            CommandPaletteItem(
                id: "command-save-page",
                title: "Save Current Page",
                subtitle: browserViewModel.displayURL,
                systemImage: "bookmark",
                action: .saveCurrentPage
            )
        ]

        items.append(contentsOf: shellViewModel.profiles.map { profile in
            CommandPaletteItem(
                id: "profile-\(profile.id.uuidString)",
                title: profile.name,
                subtitle: "Profile",
                systemImage: "person.crop.circle",
                action: .selectProfile(profile.id)
            )
        })

        items.append(contentsOf: shellViewModel.spaces.map { space in
            let profileName = shellViewModel.profiles.first(where: { $0.id == space.profileID })?.name ?? ""
            return CommandPaletteItem(
                id: "space-\(space.id.uuidString)",
                title: space.name,
                subtitle: profileName.isEmpty ? "Space" : "Space in \(profileName)",
                systemImage: space.icon,
                action: .selectSpace(space.id)
            )
        })

        items.append(contentsOf: shellViewModel.tabSessions.map { tab in
            CommandPaletteItem(
                id: "tab-\(tab.id.uuidString)",
                title: tab.title,
                subtitle: tab.url,
                systemImage: "globe",
                action: .selectTab(tab.id)
            )
        })

        items.append(contentsOf: shellViewModel.savedLinks.map { link in
            CommandPaletteItem(
                id: "saved-link-\(link.id.uuidString)",
                title: link.title,
                subtitle: link.url,
                systemImage: "bookmark",
                action: .openSavedLink(link.id)
            )
        })

        items.append(contentsOf: shellViewModel.recentHistoryEntries.prefix(50).map { entry in
            CommandPaletteItem(
                id: "history-\(entry.id.uuidString)",
                title: entry.title,
                subtitle: entry.url,
                systemImage: "clock.arrow.circlepath",
                action: .openHistoryEntry(entry.id)
            )
        })

        if !query.isEmpty {
            if URL(string: commandQuery)?.scheme != nil || commandQuery.contains(".") || commandQuery.contains(" ") {
                items.insert(
                    CommandPaletteItem(
                        id: "typed-input-\(commandQuery)",
                        title: commandQuery,
                        subtitle: "Open URL or search query",
                        systemImage: "arrow.up.right.square",
                        action: .openTypedInput(commandQuery)
                    ),
                    at: 0
                )
            }

            return items.filter {
                $0.title.lowercased().contains(query) ||
                $0.subtitle.lowercased().contains(query)
            }
        }

        return items
    }

    private func section<Content: View>(_ title: String, @ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(title)
                .font(.caption)
                .foregroundStyle(.secondary)

            content()
        }
    }

    private func savedLinkRow(_ link: SavedLink, icon: String) -> some View {
        HStack(spacing: 8) {
            Button {
                shellViewModel.openLinkInSelectedTab(link)
                addressBarText = link.url
                browserViewModel.load(link.url)
            } label: {
                Label(link.title, systemImage: icon)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
            .buttonStyle(.plain)

            Button(role: .destructive) {
                shellViewModel.deleteSavedLink(link.id)
            } label: {
                Image(systemName: "trash")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            .buttonStyle(.plain)
        }
    }

    private func historyRow(_ entry: BrowserHistoryEntry) -> some View {
        HStack(spacing: 8) {
            Button {
                shellViewModel.updateSelectedTab(title: entry.title, url: entry.url)
                addressBarText = entry.url
                browserViewModel.load(entry.url)
            } label: {
                VStack(alignment: .leading, spacing: 2) {
                    Text(entry.title)
                        .foregroundStyle(.primary)
                        .lineLimit(1)

                    Text(entry.url)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }
            .buttonStyle(.plain)

            Button(role: .destructive) {
                shellViewModel.deleteHistoryEntry(entry.id)
            } label: {
                Image(systemName: "trash")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            .buttonStyle(.plain)
        }
    }

    private func loadSelectedTab() {
        guard let selectedTab = shellViewModel.selectedTab else { return }

        addressBarText = selectedTab.url

        if browserViewModel.displayURL != selectedTab.url {
            browserViewModel.load(selectedTab.url)
        }
    }

    private func openCommandPalette() {
        commandQuery = ""
        isCommandPalettePresented = true

        DispatchQueue.main.async {
            isCommandFieldFocused = true
        }
    }

    private func closeCommandPalette() {
        isCommandPalettePresented = false
        isCommandFieldFocused = false
        commandQuery = ""
    }

    private func executeCommand(_ action: CommandPaletteAction) {
        switch action {
        case .createTab:
            shellViewModel.createTab(in: shellViewModel.selectedSpaceID)
            loadSelectedTab()

        case .createSpace:
            shellViewModel.createSpace(name: "New Space")
            loadSelectedTab()

        case .saveCurrentPage:
            shellViewModel.saveCurrentPage(folderID: nil, title: browserViewModel.pageTitle, url: browserViewModel.displayURL)

        case let .selectProfile(profileID):
            shellViewModel.selectProfile(profileID)
            loadSelectedTab()

        case let .selectSpace(spaceID):
            if let space = shellViewModel.spaces.first(where: { $0.id == spaceID }) {
                shellViewModel.selectProfile(space.profileID)
                shellViewModel.selectSpace(spaceID)
                loadSelectedTab()
            }

        case let .selectTab(tabID):
            if let tab = shellViewModel.tabSessions.first(where: { $0.id == tabID }),
               let space = shellViewModel.spaces.first(where: { $0.id == tab.spaceID }) {
                shellViewModel.selectProfile(space.profileID)
                shellViewModel.selectSpace(space.id)
                shellViewModel.selectTab(tabID)
                loadSelectedTab()
            }

        case let .openSavedLink(linkID):
            if let link = shellViewModel.savedLinks.first(where: { $0.id == linkID }),
               let space = shellViewModel.spaces.first(where: { $0.id == link.spaceID }) {
                shellViewModel.selectProfile(space.profileID)
                shellViewModel.selectSpace(space.id)
                shellViewModel.openLinkInSelectedTab(link)
                addressBarText = link.url
                browserViewModel.load(link.url)
            }

        case let .openHistoryEntry(entryID):
            if let entry = shellViewModel.historyEntries.first(where: { $0.id == entryID }) {
                shellViewModel.updateSelectedTab(title: entry.title, url: entry.url)
                addressBarText = entry.url
                browserViewModel.load(entry.url)
            }

        case let .openTypedInput(input):
            shellViewModel.updateSelectedTab(title: input, url: input)
            addressBarText = input
            browserViewModel.load(input)
        }

        closeCommandPalette()
    }
}

#Preview {
    ContentView()
}
