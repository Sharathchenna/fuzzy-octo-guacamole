import Combine
import SwiftUI

struct BrowserTabSession: Identifiable, Hashable, Codable {
    let id: UUID
    var spaceID: UUID
    var title: String
    var url: String
    var isPinned: Bool

    init(id: UUID, spaceID: UUID, title: String, url: String, isPinned: Bool = false) {
        self.id = id
        self.spaceID = spaceID
        self.title = title
        self.url = url
        self.isPinned = isPinned
    }

    enum CodingKeys: String, CodingKey {
        case id
        case spaceID
        case title
        case url
        case isPinned
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(UUID.self, forKey: .id)
        spaceID = try container.decode(UUID.self, forKey: .spaceID)
        title = try container.decode(String.self, forKey: .title)
        url = try container.decode(String.self, forKey: .url)
        isPinned = try container.decodeIfPresent(Bool.self, forKey: .isPinned) ?? false
    }
}

struct BrowserProfile: Identifiable, Hashable, Codable {
    let id: UUID
    var name: String
    var theme: ProfileTheme
}

struct BrowserSpace: Identifiable, Hashable, Codable {
    let id: UUID
    var profileID: UUID
    var name: String
    var icon: String
}

struct BrowserFolder: Identifiable, Hashable, Codable {
    let id: UUID
    var spaceID: UUID
    var name: String
}

struct SavedLink: Identifiable, Hashable, Codable {
    let id: UUID
    var spaceID: UUID
    var folderID: UUID?
    var title: String
    var url: String
}

struct BrowserHistoryEntry: Identifiable, Hashable, Codable {
    let id: UUID
    var title: String
    var url: String
    var visitedAt: Date
}

enum BrowserDownloadStatus: String, Hashable, Codable {
    case inProgress
    case finished
    case failed
}

struct BrowserDownloadRecord: Identifiable, Hashable, Codable {
    let id: UUID
    var title: String
    var sourceURL: String
    var destinationPath: String?
    var status: BrowserDownloadStatus
    var createdAt: Date
}

enum ProfileTheme: String, CaseIterable, Hashable, Codable {
    case sky
    case sunset
    case forest

    var color: Color {
        switch self {
        case .sky:
            return .blue
        case .sunset:
            return .orange
        case .forest:
            return .green
        }
    }
}

@MainActor
final class BrowserShellViewModel: ObservableObject {
    @Published private(set) var profiles: [BrowserProfile]
    @Published private(set) var spaces: [BrowserSpace]
    @Published private(set) var folders: [BrowserFolder]
    @Published private(set) var savedLinks: [SavedLink]
    @Published private(set) var tabSessions: [BrowserTabSession]
    @Published private(set) var historyEntries: [BrowserHistoryEntry]
    @Published private(set) var downloadRecords: [BrowserDownloadRecord]
    @Published var selectedProfileID: UUID
    @Published var selectedSpaceID: UUID
    @Published var selectedTabID: UUID
    private let persistenceEnabled: Bool

    init(initialState: BrowserShellState? = nil, persistenceEnabled: Bool = true) {
        self.persistenceEnabled = persistenceEnabled

        if let initialState {
            profiles = initialState.profiles
            spaces = initialState.spaces
            folders = initialState.folders
            savedLinks = initialState.savedLinks
            tabSessions = initialState.tabSessions
            historyEntries = initialState.historyEntries
            downloadRecords = initialState.downloadRecords
            selectedProfileID = initialState.selectedProfileID
            selectedSpaceID = initialState.selectedSpaceID
            selectedTabID = initialState.selectedTabID
            normalizeSelection()
            return
        }

        if persistenceEnabled, let persistedState = BrowserPersistence.load() {
            profiles = persistedState.profiles
            spaces = persistedState.spaces
            folders = persistedState.folders
            savedLinks = persistedState.savedLinks
            tabSessions = persistedState.tabSessions
            historyEntries = persistedState.historyEntries
            downloadRecords = persistedState.downloadRecords
            selectedProfileID = persistedState.selectedProfileID
            selectedSpaceID = persistedState.selectedSpaceID
            selectedTabID = persistedState.selectedTabID
            normalizeSelection()
            return
        }

        let workProfile = BrowserProfile(id: UUID(), name: "Work", theme: .sky)
        let personalProfile = BrowserProfile(id: UUID(), name: "Personal", theme: .sunset)

        let focusSpace = BrowserSpace(id: UUID(), profileID: workProfile.id, name: "Focus", icon: "bolt.fill")
        let researchSpace = BrowserSpace(id: UUID(), profileID: workProfile.id, name: "Research", icon: "book.fill")
        let unwindSpace = BrowserSpace(id: UUID(), profileID: personalProfile.id, name: "Unwind", icon: "sparkles")

        let dailyFolder = BrowserFolder(id: UUID(), spaceID: focusSpace.id, name: "Daily")
        let buildFolder = BrowserFolder(id: UUID(), spaceID: researchSpace.id, name: "Build")
        let readLaterFolder = BrowserFolder(id: UUID(), spaceID: unwindSpace.id, name: "Read Later")

        profiles = [workProfile, personalProfile]
        spaces = [focusSpace, researchSpace, unwindSpace]
        folders = [dailyFolder, buildFolder, readLaterFolder]
        savedLinks = [
            SavedLink(id: UUID(), spaceID: focusSpace.id, folderID: dailyFolder.id, title: "Gmail", url: "https://mail.google.com"),
            SavedLink(id: UUID(), spaceID: focusSpace.id, folderID: dailyFolder.id, title: "Linear", url: "https://linear.app"),
            SavedLink(id: UUID(), spaceID: focusSpace.id, folderID: nil, title: "GitHub", url: "https://github.com"),
            SavedLink(id: UUID(), spaceID: researchSpace.id, folderID: buildFolder.id, title: "Apple Developer", url: "https://developer.apple.com"),
            SavedLink(id: UUID(), spaceID: researchSpace.id, folderID: nil, title: "WebKit", url: "https://webkit.org"),
            SavedLink(id: UUID(), spaceID: unwindSpace.id, folderID: readLaterFolder.id, title: "Hacker News", url: "https://news.ycombinator.com"),
            SavedLink(id: UUID(), spaceID: unwindSpace.id, folderID: nil, title: "YouTube", url: "https://youtube.com")
        ]
        historyEntries = []
        downloadRecords = []
        let focusTab = BrowserTabSession(id: UUID(), spaceID: focusSpace.id, title: "Apple", url: "https://www.apple.com", isPinned: true)
        let docsTab = BrowserTabSession(id: UUID(), spaceID: focusSpace.id, title: "GitHub", url: "https://github.com")
        let researchTab = BrowserTabSession(id: UUID(), spaceID: researchSpace.id, title: "WebKit", url: "https://webkit.org")
        let unwindTab = BrowserTabSession(id: UUID(), spaceID: unwindSpace.id, title: "YouTube", url: "https://youtube.com")
        tabSessions = [focusTab, docsTab, researchTab, unwindTab]
        selectedProfileID = workProfile.id
        selectedSpaceID = focusSpace.id
        selectedTabID = focusTab.id
        persist()
    }

    var selectedProfile: BrowserProfile {
        profiles.first(where: { $0.id == selectedProfileID }) ?? profiles[0]
    }

    var selectedSpace: BrowserSpace {
        let availableSpaces = spacesForSelectedProfile
        return availableSpaces.first(where: { $0.id == selectedSpaceID }) ?? availableSpaces[0]
    }

    var spacesForSelectedProfile: [BrowserSpace] {
        spaces.filter { $0.profileID == selectedProfileID }
    }

    var tabsForSelectedSpace: [BrowserTabSession] {
        tabSessions.filter { $0.spaceID == selectedSpaceID }
    }

    var pinnedTabsForSelectedSpace: [BrowserTabSession] {
        tabsForSelectedSpace.filter(\.isPinned)
    }

    var unpinnedTabsForSelectedSpace: [BrowserTabSession] {
        tabsForSelectedSpace.filter { !$0.isPinned }
    }

    var selectedTab: BrowserTabSession? {
        tabsForSelectedSpace.first(where: { $0.id == selectedTabID }) ?? tabsForSelectedSpace.first
    }

    var foldersForSelectedSpace: [BrowserFolder] {
        folders.filter { $0.spaceID == selectedSpaceID }
    }

    var topLevelSavedLinksForSelectedSpace: [SavedLink] {
        savedLinks.filter { $0.spaceID == selectedSpaceID && $0.folderID == nil }
    }

    var canDeleteSelectedSpace: Bool {
        spacesForSelectedProfile.count > 1
    }

    var canDeleteSelectedProfile: Bool {
        profiles.count > 1
    }

    var recentHistoryEntries: [BrowserHistoryEntry] {
        historyEntries.sorted { $0.visitedAt > $1.visitedAt }
    }

    var recentDownloadRecords: [BrowserDownloadRecord] {
        downloadRecords.sorted { $0.createdAt > $1.createdAt }
    }

    func selectProfile(_ profileID: UUID) {
        guard selectedProfileID != profileID else { return }
        selectedProfileID = profileID

        if let firstSpace = spaces.first(where: { $0.profileID == profileID }) {
            selectedSpaceID = firstSpace.id
            selectedTabID = tabSessions.first(where: { $0.spaceID == firstSpace.id })?.id ?? selectedTabID
        }

        normalizeSelection()
        persist()
    }

    func createProfile(name: String, theme: ProfileTheme) {
        let trimmedName = name.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedName.isEmpty else { return }

        let profile = BrowserProfile(id: UUID(), name: trimmedName, theme: theme)
        profiles.append(profile)
        selectedProfileID = profile.id

        let space = BrowserSpace(id: UUID(), profileID: profile.id, name: "Start", icon: "sparkles")
        spaces.append(space)
        selectedSpaceID = space.id

        let tab = BrowserTabSession(id: UUID(), spaceID: space.id, title: "New Tab", url: "https://www.apple.com")
        tabSessions.append(tab)
        selectedTabID = tab.id

        persist()
    }

    func updateSelectedProfileTheme(_ theme: ProfileTheme) {
        guard let index = profiles.firstIndex(where: { $0.id == selectedProfileID }) else { return }
        profiles[index].theme = theme
        persist()
    }

    func renameSelectedProfile(to name: String) {
        let trimmedName = name.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedName.isEmpty else { return }
        guard let index = profiles.firstIndex(where: { $0.id == selectedProfileID }) else { return }
        profiles[index].name = trimmedName
        persist()
    }

    func deleteSelectedProfile() {
        guard canDeleteSelectedProfile else { return }
        guard let index = profiles.firstIndex(where: { $0.id == selectedProfileID }) else { return }

        let deletedProfileID = profiles[index].id
        let deletedSpaceIDs = spaces.filter { $0.profileID == deletedProfileID }.map(\.id)

        profiles.remove(at: index)
        spaces.removeAll { $0.profileID == deletedProfileID }
        folders.removeAll { deletedSpaceIDs.contains($0.spaceID) }
        savedLinks.removeAll { deletedSpaceIDs.contains($0.spaceID) }
        tabSessions.removeAll { deletedSpaceIDs.contains($0.spaceID) }

        if let fallbackProfile = profiles.first {
            selectedProfileID = fallbackProfile.id
        }

        normalizeSelection()
        persist()
    }

    func selectSpace(_ spaceID: UUID) {
        selectedSpaceID = spaceID
        if let firstTab = tabSessions.first(where: { $0.spaceID == spaceID }) {
            selectedTabID = firstTab.id
        }

        normalizeSelection()
        persist()
    }

    func selectTab(_ tabID: UUID) {
        selectedTabID = tabID
        persist()
    }

    func createTab(in spaceID: UUID, title: String = "New Tab", url: String = "https://www.apple.com") {
        let tab = BrowserTabSession(id: UUID(), spaceID: spaceID, title: title, url: url)
        tabSessions.append(tab)
        selectedSpaceID = spaceID
        selectedTabID = tab.id
        normalizeSelection()
        persist()
    }

    func closeTab(_ tabID: UUID) {
        guard let index = tabSessions.firstIndex(where: { $0.id == tabID }) else { return }

        let closedTab = tabSessions.remove(at: index)
        let remainingTabsInSpace = tabSessions.filter { $0.spaceID == closedTab.spaceID }

        if remainingTabsInSpace.isEmpty {
            createTab(in: closedTab.spaceID)
            return
        }

        if selectedTabID == tabID {
            selectedTabID = remainingTabsInSpace[min(index, remainingTabsInSpace.count - 1)].id
        }

        normalizeSelection()
        persist()
    }

    func moveSelectedTab(to spaceID: UUID) {
        guard let index = tabSessions.firstIndex(where: { $0.id == selectedTabID }) else { return }
        tabSessions[index].spaceID = spaceID
        selectedSpaceID = spaceID
        selectedTabID = tabSessions[index].id
        normalizeSelection()
        persist()
    }

    func togglePinnedForSelectedTab() {
        guard let index = tabSessions.firstIndex(where: { $0.id == selectedTabID }) else { return }
        tabSessions[index].isPinned.toggle()
        persist()
    }

    func togglePinned(for tabID: UUID) {
        guard let index = tabSessions.firstIndex(where: { $0.id == tabID }) else { return }
        tabSessions[index].isPinned.toggle()
        persist()
    }

    func createSpace(name: String) {
        let trimmedName = name.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedName.isEmpty else { return }

        let space = BrowserSpace(id: UUID(), profileID: selectedProfileID, name: trimmedName, icon: "square.grid.2x2.fill")
        spaces.append(space)
        createTab(in: space.id)
        selectedSpaceID = space.id
        normalizeSelection()
        persist()
    }

    func renameSelectedSpace(to name: String) {
        let trimmedName = name.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedName.isEmpty else { return }
        guard let index = spaces.firstIndex(where: { $0.id == selectedSpaceID }) else { return }

        spaces[index].name = trimmedName
        persist()
    }

    func deleteSelectedSpace() {
        guard canDeleteSelectedSpace else { return }
        guard let index = spaces.firstIndex(where: { $0.id == selectedSpaceID }) else { return }

        let deletedSpaceID = spaces[index].id
        spaces.remove(at: index)
        folders.removeAll { $0.spaceID == deletedSpaceID }
        savedLinks.removeAll { $0.spaceID == deletedSpaceID }
        tabSessions.removeAll { $0.spaceID == deletedSpaceID }

        if let fallbackSpace = spaces.first(where: { $0.profileID == selectedProfileID }) {
            selectedSpaceID = fallbackSpace.id

            if let fallbackTab = tabSessions.first(where: { $0.spaceID == fallbackSpace.id }) {
                selectedTabID = fallbackTab.id
            } else {
                createTab(in: fallbackSpace.id)
            }
        }

        normalizeSelection()
        persist()
    }

    func updateSelectedTab(title: String, url: String) {
        guard let index = tabSessions.firstIndex(where: { $0.id == selectedTabID }) else { return }

        if !title.isEmpty {
            tabSessions[index].title = title
        }

        if !url.isEmpty {
            tabSessions[index].url = url
        }

        persist()
    }

    func openLinkInSelectedTab(_ link: SavedLink) {
        if let index = tabSessions.firstIndex(where: { $0.id == selectedTabID }) {
            tabSessions[index].title = link.title
            tabSessions[index].url = link.url
        } else {
            createTab(in: selectedSpaceID, title: link.title, url: link.url)
            return
        }

        persist()
    }

    func createFolder(name: String) {
        let trimmedName = name.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedName.isEmpty else { return }

        folders.append(BrowserFolder(id: UUID(), spaceID: selectedSpaceID, name: trimmedName))
        persist()
    }

    func deleteFolder(_ folderID: UUID) {
        folders.removeAll { $0.id == folderID }
        savedLinks.removeAll { $0.folderID == folderID }
        persist()
    }

    func renameFolder(_ folderID: UUID, to name: String) {
        let trimmedName = name.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedName.isEmpty else { return }
        guard let index = folders.firstIndex(where: { $0.id == folderID }) else { return }
        folders[index].name = trimmedName
        persist()
    }

    func createSavedLink(title: String, url: String, folderID: UUID?) {
        let trimmedTitle = title.trimmingCharacters(in: .whitespacesAndNewlines)
        let trimmedURL = url.trimmingCharacters(in: .whitespacesAndNewlines)

        guard !trimmedTitle.isEmpty, !trimmedURL.isEmpty else { return }

        savedLinks.append(
            SavedLink(
                id: UUID(),
                spaceID: selectedSpaceID,
                folderID: folderID,
                title: trimmedTitle,
                url: trimmedURL
            )
        )
        persist()
    }

    func deleteSavedLink(_ linkID: UUID) {
        savedLinks.removeAll { $0.id == linkID }
        persist()
    }

    func updateSavedLink(_ linkID: UUID, title: String, url: String) {
        let trimmedTitle = title.trimmingCharacters(in: .whitespacesAndNewlines)
        let trimmedURL = url.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedTitle.isEmpty, !trimmedURL.isEmpty else { return }
        guard let index = savedLinks.firstIndex(where: { $0.id == linkID }) else { return }
        savedLinks[index].title = trimmedTitle
        savedLinks[index].url = trimmedURL
        persist()
    }

    func recordHistoryVisit(title: String, url: String) {
        let trimmedURL = url.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedURL.isEmpty else { return }

        let trimmedTitle = title.trimmingCharacters(in: .whitespacesAndNewlines)
        let resolvedTitle = trimmedTitle.isEmpty ? trimmedURL : trimmedTitle

        if let lastEntry = recentHistoryEntries.first,
           lastEntry.url == trimmedURL,
           Date().timeIntervalSince(lastEntry.visitedAt) < 5 {
            return
        }

        historyEntries.append(
            BrowserHistoryEntry(
                id: UUID(),
                title: resolvedTitle,
                url: trimmedURL,
                visitedAt: Date()
            )
        )

        if historyEntries.count > 500 {
            historyEntries = Array(recentHistoryEntries.prefix(500))
        }

        persist()
    }

    func deleteHistoryEntry(_ entryID: UUID) {
        historyEntries.removeAll { $0.id == entryID }
        persist()
    }

    func clearHistory() {
        historyEntries.removeAll()
        persist()
    }

    func recordDownloadRequested(title: String, sourceURL: URL?) {
        let resolvedTitle = title.trimmingCharacters(in: .whitespacesAndNewlines)
        let fallbackTitle = sourceURL?.lastPathComponent.isEmpty == false ? sourceURL?.lastPathComponent : sourceURL?.absoluteString

        downloadRecords.insert(
            BrowserDownloadRecord(
                id: UUID(),
                title: resolvedTitle.isEmpty ? (fallbackTitle ?? "Download") : resolvedTitle,
                sourceURL: sourceURL?.absoluteString ?? "",
                destinationPath: nil,
                status: .inProgress,
                createdAt: Date()
            ),
            at: 0
        )
        persist()
    }

    func markLatestDownloadFinished(destinationURL: URL) {
        guard let index = downloadRecords.firstIndex(where: { $0.status == .inProgress }) else { return }
        downloadRecords[index].status = .finished
        downloadRecords[index].destinationPath = destinationURL.path
        persist()
    }

    func markLatestDownloadFailed(reason: String, destinationURL: URL?) {
        guard let index = downloadRecords.firstIndex(where: { $0.status == .inProgress }) else { return }
        downloadRecords[index].status = .failed
        downloadRecords[index].destinationPath = destinationURL?.path ?? reason
        persist()
    }

    func clearDownloads() {
        downloadRecords.removeAll()
        persist()
    }

    func saveCurrentPage(folderID: UUID?, title: String, url: String) {
        let resolvedTitle = title.trimmingCharacters(in: .whitespacesAndNewlines)
        let fallbackTitle = url.trimmingCharacters(in: .whitespacesAndNewlines)
        createSavedLink(title: resolvedTitle.isEmpty ? fallbackTitle : resolvedTitle, url: url, folderID: folderID)
    }

    func savedLinks(in folder: BrowserFolder) -> [SavedLink] {
        savedLinks.filter { $0.folderID == folder.id }
    }

    private func normalizeSelection() {
        guard !profiles.isEmpty else { return }

        if !profiles.contains(where: { $0.id == selectedProfileID }) {
            selectedProfileID = profiles[0].id
        }

        let availableSpaces = spaces.filter { $0.profileID == selectedProfileID }
        guard !availableSpaces.isEmpty else { return }

        if !availableSpaces.contains(where: { $0.id == selectedSpaceID }) {
            selectedSpaceID = availableSpaces[0].id
        }

        let availableTabs = tabSessions.filter { $0.spaceID == selectedSpaceID }
        if availableTabs.isEmpty {
            let newTab = BrowserTabSession(id: UUID(), spaceID: selectedSpaceID, title: "New Tab", url: "https://www.apple.com")
            tabSessions.append(newTab)
            selectedTabID = newTab.id
            return
        }

        if !availableTabs.contains(where: { $0.id == selectedTabID }) {
            selectedTabID = availableTabs[0].id
        }
    }

    private func persist() {
        guard persistenceEnabled else { return }

        BrowserPersistence.save(
            BrowserShellState(
                profiles: profiles,
                spaces: spaces,
                folders: folders,
                savedLinks: savedLinks,
                tabSessions: tabSessions,
                historyEntries: historyEntries,
                downloadRecords: downloadRecords,
                selectedProfileID: selectedProfileID,
                selectedSpaceID: selectedSpaceID,
                selectedTabID: selectedTabID
            )
        )
    }
}
