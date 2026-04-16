import Foundation
import GRDB
import SQLiteData

func appDatabase() throws -> DatabaseQueue {
    let fileManager = FileManager.default
    let appSupportURL = try fileManager.url(
        for: .applicationSupportDirectory,
        in: .userDomainMask,
        appropriateFor: nil,
        create: true
    )
    let directoryURL = appSupportURL.appendingPathComponent("MoneyMind", isDirectory: true)
    try fileManager.createDirectory(at: directoryURL, withIntermediateDirectories: true)
    let databaseURL = directoryURL.appendingPathComponent("db.sqlite")

    var config = Configuration()
    config.foreignKeysEnabled = true

    let dbQueue = try DatabaseQueue(path: databaseURL.path, configuration: config)
    try migrate(dbQueue)
    return dbQueue
}

private func migrate(_ db: DatabaseQueue) throws {
    var migrator = DatabaseMigrator()

    migrator.registerMigration("v1") { db in
        try db.create(table: "categories", ifNotExists: true) { t in
            t.autoIncrementedPrimaryKey("id")
            t.column("name", .text).notNull()
            t.column("icon", .text).notNull()
            t.column("colorHex", .text).notNull()
            t.column("type", .text).notNull()
            t.column("createdAt", .text).notNull()
        }

        try db.create(table: "transactions", ifNotExists: true) { t in
            t.autoIncrementedPrimaryKey("id")
            t.column("amount", .double).notNull()
            t.column("note", .text).notNull()
            t.column("date", .text).notNull()
            t.column("type", .text).notNull()
            t.column("categoryId", .integer).notNull()
            t.column("categoryName", .text).notNull()
            t.column("categoryIcon", .text).notNull()
            t.column("categoryColorHex", .text).notNull()
            t.column("createdAt", .text).notNull()
        }
    }

    migrator.registerMigration("v1_seed_categories") { db in
        let count = try Int.fetchOne(db, sql: "SELECT COUNT(*) FROM categories") ?? 0
        guard count == 0 else { return }

        let seedCategories: [(name: String, icon: String, colorHex: String, type: TransactionType)] = [
            ("Food & Dining",  "fork.knife",                  "#FF6B6B", .expense),
            ("Transport",      "car.fill",                    "#4ECDC4", .expense),
            ("Shopping",       "bag.fill",                    "#45B7D1", .expense),
            ("Entertainment",  "tv.fill",                     "#96CEB4", .expense),
            ("Health",         "heart.fill",                  "#FF9F43", .expense),
            ("Utilities",      "bolt.fill",                   "#A29BFE", .expense),
            ("Housing",        "house.fill",                  "#FD79A8", .expense),
            ("Education",      "book.fill",                   "#6C5CE7", .expense),
            ("Other",          "ellipsis.circle.fill",        "#B2BEC3", .expense),
            ("Salary",         "banknote.fill",               "#00B894", .income),
            ("Freelance",      "laptopcomputer",              "#00CEC9", .income),
            ("Investment",     "chart.line.uptrend.xyaxis",   "#FDCB6E", .income),
            ("Gift",           "gift.fill",                   "#E17055", .income),
            ("Other Income",   "plus.circle.fill",            "#74B9FF", .income),
        ]

        let now = Date()
        try db.seed {
            for item in seedCategories {
                TransactionCategory.Draft(name: item.name, icon: item.icon, colorHex: item.colorHex, type: item.type, createdAt: now)
            }
        }
    }

    migrator.registerMigration("v2_budgets") { db in
        try db.create(table: "budgets", ifNotExists: true) { t in
            t.autoIncrementedPrimaryKey("id")
            t.column("categoryId", .integer).notNull().unique()
                .references("categories", onDelete: .cascade)
            t.column("amount", .double).notNull()
            t.column("createdAt", .text).notNull()
        }
    }

    try migrator.migrate(db)
}
