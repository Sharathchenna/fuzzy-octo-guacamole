import Foundation
import SQLite3

private let SQLITE_TRANSIENT = unsafeBitCast(-1, to: sqlite3_destructor_type.self)

struct BrowserShellState: Codable {
    var profiles: [BrowserProfile]
    var spaces: [BrowserSpace]
    var folders: [BrowserFolder]
    var savedLinks: [SavedLink]
    var tabSessions: [BrowserTabSession]
    var historyEntries: [BrowserHistoryEntry]
    var downloadRecords: [BrowserDownloadRecord]
    var selectedProfileID: UUID
    var selectedSpaceID: UUID
    var selectedTabID: UUID
}

enum BrowserPersistence {
    static func load() -> BrowserShellState? {
        do {
            try ensureStorageDirectory()

            let database = try openDatabase()
            defer { sqlite3_close(database) }

            try createSchemaIfNeeded(in: database)

            if let state = try loadState(from: database) {
                return state
            }

            if let migratedState = try migrateLegacyJSON(into: database) {
                return migratedState
            }
        } catch {
            print("Failed to load browser state: \(error)")
        }

        return nil
    }

    static func save(_ state: BrowserShellState) {
        do {
            try ensureStorageDirectory()

            let database = try openDatabase()
            defer { sqlite3_close(database) }

            try createSchemaIfNeeded(in: database)
            try saveState(state, in: database)
        } catch {
            print("Failed to save browser state: \(error)")
        }
    }

    private static func ensureStorageDirectory() throws {
        try FileManager.default.createDirectory(at: storageDirectoryURL(), withIntermediateDirectories: true)
    }

    private static func openDatabase() throws -> OpaquePointer? {
        var database: OpaquePointer?

        guard sqlite3_open(databaseURL().path, &database) == SQLITE_OK else {
            let message = database.flatMap { String(cString: sqlite3_errmsg($0)) } ?? "Unknown SQLite error"
            sqlite3_close(database)
            throw PersistenceError.openFailed(message)
        }

        return database
    }

    private static func createSchemaIfNeeded(in database: OpaquePointer?) throws {
        let sql = """
        CREATE TABLE IF NOT EXISTS app_state (
            id INTEGER PRIMARY KEY CHECK (id = 1),
            state_blob BLOB NOT NULL,
            updated_at REAL NOT NULL
        );
        """

        guard sqlite3_exec(database, sql, nil, nil, nil) == SQLITE_OK else {
            throw PersistenceError.schemaCreationFailed(lastErrorMessage(in: database))
        }
    }

    private static func loadState(from database: OpaquePointer?) throws -> BrowserShellState? {
        let sql = "SELECT state_blob FROM app_state WHERE id = 1 LIMIT 1;"
        var statement: OpaquePointer?

        guard sqlite3_prepare_v2(database, sql, -1, &statement, nil) == SQLITE_OK else {
            throw PersistenceError.queryFailed(lastErrorMessage(in: database))
        }

        defer { sqlite3_finalize(statement) }

        let stepResult = sqlite3_step(statement)
        guard stepResult != SQLITE_DONE else { return nil }

        guard stepResult == SQLITE_ROW else {
            throw PersistenceError.queryFailed(lastErrorMessage(in: database))
        }

        let byteCount = sqlite3_column_bytes(statement, 0)
        guard let bytes = sqlite3_column_blob(statement, 0) else {
            throw PersistenceError.decodeFailed("Missing persisted browser state blob")
        }

        let data = Data(bytes: bytes, count: Int(byteCount))

        do {
            return try JSONDecoder().decode(BrowserShellState.self, from: data)
        } catch {
            throw PersistenceError.decodeFailed(error.localizedDescription)
        }
    }

    private static func saveState(_ state: BrowserShellState, in database: OpaquePointer?) throws {
        let sql = """
        INSERT INTO app_state (id, state_blob, updated_at)
        VALUES (1, ?, ?)
        ON CONFLICT(id) DO UPDATE SET
            state_blob = excluded.state_blob,
            updated_at = excluded.updated_at;
        """

        let data: Data

        do {
            data = try JSONEncoder().encode(state)
        } catch {
            throw PersistenceError.encodeFailed(error.localizedDescription)
        }

        var statement: OpaquePointer?

        guard sqlite3_prepare_v2(database, sql, -1, &statement, nil) == SQLITE_OK else {
            throw PersistenceError.queryFailed(lastErrorMessage(in: database))
        }

        defer { sqlite3_finalize(statement) }

        data.withUnsafeBytes { rawBuffer in
            _ = sqlite3_bind_blob(statement, 1, rawBuffer.baseAddress, Int32(data.count), SQLITE_TRANSIENT)
        }
        sqlite3_bind_double(statement, 2, Date().timeIntervalSince1970)

        guard sqlite3_step(statement) == SQLITE_DONE else {
            throw PersistenceError.queryFailed(lastErrorMessage(in: database))
        }
    }

    private static func migrateLegacyJSON(into database: OpaquePointer?) throws -> BrowserShellState? {
        let legacyURL = legacyJSONURL()

        guard FileManager.default.fileExists(atPath: legacyURL.path) else {
            return nil
        }

        let data = try Data(contentsOf: legacyURL)
        let state = try JSONDecoder().decode(BrowserShellState.self, from: data)
        try saveState(state, in: database)

        let migratedURL = storageDirectoryURL().appendingPathComponent("browser-state.migrated.json")

        if FileManager.default.fileExists(atPath: migratedURL.path) {
            try FileManager.default.removeItem(at: migratedURL)
        }

        try FileManager.default.moveItem(at: legacyURL, to: migratedURL)
        return state
    }

    private static func storageDirectoryURL() -> URL {
        let baseURL = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask)[0]
        return baseURL.appendingPathComponent("ArcBrowser", isDirectory: true)
    }

    private static func databaseURL() -> URL {
        storageDirectoryURL().appendingPathComponent("browser-state.sqlite")
    }

    private static func legacyJSONURL() -> URL {
        storageDirectoryURL().appendingPathComponent("browser-state.json")
    }

    private static func lastErrorMessage(in database: OpaquePointer?) -> String {
        database.flatMap { String(cString: sqlite3_errmsg($0)) } ?? "Unknown SQLite error"
    }
}

private enum PersistenceError: LocalizedError {
    case openFailed(String)
    case schemaCreationFailed(String)
    case queryFailed(String)
    case decodeFailed(String)
    case encodeFailed(String)

    var errorDescription: String? {
        switch self {
        case let .openFailed(message):
            return "SQLite open failed: \(message)"
        case let .schemaCreationFailed(message):
            return "SQLite schema creation failed: \(message)"
        case let .queryFailed(message):
            return "SQLite query failed: \(message)"
        case let .decodeFailed(message):
            return "State decode failed: \(message)"
        case let .encodeFailed(message):
            return "State encode failed: \(message)"
        }
    }
}
