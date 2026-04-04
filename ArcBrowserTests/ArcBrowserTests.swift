import Foundation
import Testing
@testable import ArcBrowser

struct ArcBrowserTests {
    @Test @MainActor
    func createProfileAddsStarterSpaceAndTab() {
        let state = makeState()
        let viewModel = BrowserShellViewModel(initialState: state, persistenceEnabled: false)

        viewModel.createProfile(name: "Travel", theme: .forest)

        #expect(viewModel.selectedProfile.name == "Travel")
        #expect(viewModel.spacesForSelectedProfile.count == 1)
        #expect(viewModel.selectedTab?.title == "New Tab")
    }

    @Test @MainActor
    func movingSelectedTabChangesCurrentSpace() {
        let state = makeState()
        let viewModel = BrowserShellViewModel(initialState: state, persistenceEnabled: false)
        let destinationSpaceID = viewModel.spaces.last!.id

        viewModel.moveSelectedTab(to: destinationSpaceID)

        #expect(viewModel.selectedSpaceID == destinationSpaceID)
        #expect(viewModel.selectedTab?.spaceID == destinationSpaceID)
    }

    @Test @MainActor
    func togglingPinnedUpdatesSelectedTab() {
        let state = makeState()
        let viewModel = BrowserShellViewModel(initialState: state, persistenceEnabled: false)

        #expect(viewModel.selectedTab?.isPinned == false)

        viewModel.togglePinnedForSelectedTab()

        #expect(viewModel.selectedTab?.isPinned == true)
        #expect(viewModel.pinnedTabsForSelectedSpace.count == 1)
    }

    @Test @MainActor
    func renamingFolderAndSavedLinkUpdatesState() {
        let state = makeState()
        let viewModel = BrowserShellViewModel(initialState: state, persistenceEnabled: false)
        let folderID = viewModel.foldersForSelectedSpace.first!.id
        let linkID = viewModel.topLevelSavedLinksForSelectedSpace.first!.id

        viewModel.renameFolder(folderID, to: "Priority")
        viewModel.updateSavedLink(linkID, title: "Docs", url: "https://example.com/docs")

        #expect(viewModel.foldersForSelectedSpace.first?.name == "Priority")
        #expect(viewModel.topLevelSavedLinksForSelectedSpace.first?.title == "Docs")
        #expect(viewModel.topLevelSavedLinksForSelectedSpace.first?.url == "https://example.com/docs")
    }

    @Test @MainActor
    func historyDeduplicatesImmediateRepeatVisits() {
        let state = makeState()
        let viewModel = BrowserShellViewModel(initialState: state, persistenceEnabled: false)

        viewModel.recordHistoryVisit(title: "Example", url: "https://example.com")
        viewModel.recordHistoryVisit(title: "Example", url: "https://example.com")

        #expect(viewModel.historyEntries.count == 1)
    }
}

private func makeState() -> BrowserShellState {
    let profile = BrowserProfile(id: UUID(), name: "Work", theme: .sky)
    let focusSpace = BrowserSpace(id: UUID(), profileID: profile.id, name: "Focus", icon: "bolt.fill")
    let secondSpace = BrowserSpace(id: UUID(), profileID: profile.id, name: "Research", icon: "book.fill")
    let folder = BrowserFolder(id: UUID(), spaceID: focusSpace.id, name: "Daily")
    let link = SavedLink(id: UUID(), spaceID: focusSpace.id, folderID: nil, title: "Example", url: "https://example.com")
    let tab = BrowserTabSession(id: UUID(), spaceID: focusSpace.id, title: "Example", url: "https://example.com")

    return BrowserShellState(
        profiles: [profile],
        spaces: [focusSpace, secondSpace],
        folders: [folder],
        savedLinks: [link],
        tabSessions: [tab],
        historyEntries: [],
        downloadRecords: [],
        selectedProfileID: profile.id,
        selectedSpaceID: focusSpace.id,
        selectedTabID: tab.id
    )
}
