import Foundation

struct BrowserShellState: Codable {
    var profiles: [BrowserProfile]
    var spaces: [BrowserSpace]
    var folders: [BrowserFolder]
    var savedLinks: [SavedLink]
    var tabSessions: [BrowserTabSession]
    var historyEntries: [BrowserHistoryEntry]
    var selectedProfileID: UUID
    var selectedSpaceID: UUID
    var selectedTabID: UUID
}

enum BrowserPersistence {
    static func load() -> BrowserShellState? {
        let url = storageURL()

        guard let data = try? Data(contentsOf: url) else {
            return nil
        }

        return try? JSONDecoder().decode(BrowserShellState.self, from: data)
    }

    static func save(_ state: BrowserShellState) {
        let url = storageURL()
        let directoryURL = url.deletingLastPathComponent()

        do {
            try FileManager.default.createDirectory(at: directoryURL, withIntermediateDirectories: true)
            let data = try JSONEncoder().encode(state)
            try data.write(to: url, options: .atomic)
        } catch {
            print("Failed to save browser state: \(error)")
        }
    }

    private static func storageURL() -> URL {
        let baseURL = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask)[0]
        return baseURL
            .appendingPathComponent("ArcBrowser", isDirectory: true)
            .appendingPathComponent("browser-state.json")
    }
}
