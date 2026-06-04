import Foundation
import GRDB

final class ClipStore {
    static var databasePath: String {
        (try? databaseURL().path) ?? "Unavailable"
    }

    private let dbQueue: DatabaseQueue
    private let maxHistoryCount: Int

    init(maxHistoryCount: Int = 500) throws {
        self.maxHistoryCount = maxHistoryCount
        let databaseURL = try Self.databaseURL()
        try FileManager.default.createDirectory(
            at: databaseURL.deletingLastPathComponent(),
            withIntermediateDirectories: true
        )
        dbQueue = try DatabaseQueue(path: databaseURL.path)
        try migrate()
    }

    func fetchClips() throws -> [ClipItem] {
        try dbQueue.read { db in
            try ClipRecord
                .order(Column("isPinned").desc, Column("updatedAt").desc)
                .limit(maxHistoryCount)
                .fetchAll(db)
                .map(\.clipItem)
        }
    }

    func upsert(_ clip: ClipItem) throws {
        try dbQueue.write { db in
            var record = ClipRecord(clip)
            try record.save(db)
            try pruneIfNeeded(db)
        }
    }

    func updatePin(clipID: ClipItem.ID, isPinned: Bool) throws {
        _ = try dbQueue.write { db in
            try ClipRecord
                .filter(Column("id") == clipID.uuidString)
                .updateAll(db, Column("isPinned").set(to: isPinned))
        }
    }

    private func migrate() throws {
        var migrator = DatabaseMigrator()

        migrator.registerMigration("createClips") { db in
            try db.create(table: "clips", ifNotExists: true) { table in
                table.column("id", .text).primaryKey()
                table.column("content", .text).notNull().unique(onConflict: .replace)
                table.column("kind", .text).notNull()
                table.column("title", .text).notNull()
                table.column("preview", .text).notNull()
                table.column("source", .text).notNull()
                table.column("createdAt", .datetime).notNull()
                table.column("updatedAt", .datetime).notNull().indexed()
                table.column("isPinned", .boolean).notNull().defaults(to: false).indexed()
                table.column("isSensitive", .boolean).notNull().defaults(to: false)
            }
        }

        try migrator.migrate(dbQueue)
    }

    private func pruneIfNeeded(_ db: Database) throws {
        let totalCount = try ClipRecord.fetchCount(db)

        guard totalCount > maxHistoryCount else {
            return
        }

        let removableIDs = try String.fetchAll(
            db,
            sql: """
            SELECT id
            FROM clips
            WHERE isPinned = 0
            ORDER BY updatedAt ASC
            LIMIT ?
            """,
            arguments: [totalCount - maxHistoryCount]
        )

        guard !removableIDs.isEmpty else {
            return
        }

        try ClipRecord
            .filter(removableIDs.contains(Column("id")))
            .deleteAll(db)
    }

    private static func databaseURL() throws -> URL {
        let applicationSupportURL = try FileManager.default.url(
            for: .applicationSupportDirectory,
            in: .userDomainMask,
            appropriateFor: nil,
            create: true
        )

        return applicationSupportURL
            .appendingPathComponent("Bufferly", isDirectory: true)
            .appendingPathComponent("bufferly.sqlite")
    }
}

private struct ClipRecord: Codable, FetchableRecord, MutablePersistableRecord {
    static let databaseTableName = "clips"

    var id: String
    var content: String
    var kind: String
    var title: String
    var preview: String
    var source: String
    var createdAt: Date
    var updatedAt: Date
    var isPinned: Bool
    var isSensitive: Bool

    init(_ clip: ClipItem) {
        id = clip.id.uuidString
        content = clip.content
        kind = clip.kind.rawValue
        title = clip.title
        preview = clip.preview
        source = clip.source
        createdAt = clip.createdAt
        updatedAt = clip.updatedAt
        isPinned = clip.isPinned
        isSensitive = clip.isSensitive
    }

    var clipItem: ClipItem {
        ClipItem(
            id: UUID(uuidString: id) ?? UUID(),
            kind: ClipKind(rawValue: kind) ?? .text,
            title: title,
            preview: preview,
            source: source,
            content: content,
            createdAt: createdAt,
            updatedAt: updatedAt,
            isPinned: isPinned,
            isSensitive: isSensitive
        )
    }
}
