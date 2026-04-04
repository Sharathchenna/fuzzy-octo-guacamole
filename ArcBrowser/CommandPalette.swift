import Foundation

extension Notification.Name {
    static let openCommandPalette = Notification.Name("ArcBrowser.openCommandPalette")
}

enum CommandPaletteAction: Hashable {
    case createTab
    case createSpace
    case saveCurrentPage
    case selectProfile(UUID)
    case selectSpace(UUID)
    case selectTab(UUID)
    case openSavedLink(UUID)
    case openHistoryEntry(UUID)
    case openTypedInput(String)
}

struct CommandPaletteItem: Identifiable, Hashable {
    let id: String
    let title: String
    let subtitle: String
    let systemImage: String
    let action: CommandPaletteAction
}
