import Foundation
import GRDB
import SQLiteData

/// Whether `db.sqlite` was already on disk before this launch (e.g. user upgraded the app).
/// Used so existing users are not forced through onboarding again.
func moneyMindDatabaseFileExistedBeforeLaunch() -> Bool {
    let fileManager = FileManager.default
    guard let appSupportURL = try? fileManager.url(
        for: .applicationSupportDirectory,
        in: .userDomainMask,
        appropriateFor: nil,
        create: false
    ) else { return false }
    let url = appSupportURL.appendingPathComponent("MoneyMind").appendingPathComponent("db.sqlite")
    return fileManager.fileExists(atPath: url.path)
}

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

    migrator.registerMigration("v3_goals_and_extra_categories") { db in
        try db.create(table: "savings_goals", ifNotExists: true) { t in
            t.autoIncrementedPrimaryKey("id")
            t.column("name", .text).notNull()
            t.column("icon", .text).notNull()
            t.column("colorHex", .text).notNull()
            t.column("targetAmount", .double).notNull()
            t.column("targetDate", .text)
            t.column("note", .text).notNull().defaults(to: "")
            t.column("createdAt", .text).notNull()
        }

        try db.create(table: "goal_contributions", ifNotExists: true) { t in
            t.autoIncrementedPrimaryKey("id")
            t.column("goalId", .integer).notNull()
                .references("savings_goals", onDelete: .cascade)
            t.column("amount", .double).notNull()
            t.column("date", .text).notNull()
            t.column("note", .text).notNull().defaults(to: "")
            t.column("createdAt", .text).notNull()
        }

        let additionalCategories: [(name: String, icon: String, colorHex: String, type: TransactionType)] = [
            ("Groceries",      "cart.fill",                   "#10B981", .expense),
            ("Coffee",         "cup.and.saucer.fill",         "#8B5E3C", .expense),
            ("Fuel",           "fuelpump.fill",               "#F59E0B", .expense),
            ("Subscriptions",  "arrow.triangle.2.circlepath", "#8B5CF6", .expense),
            ("Fitness",        "figure.run",                  "#EF4444", .expense),
            ("Personal Care",  "sparkles",                    "#EC4899", .expense),
            ("Insurance",      "shield.fill",                 "#0EA5E9", .expense),
            ("Travel",         "airplane",                    "#06B6D4", .expense),
            ("Pets",           "pawprint.fill",               "#D97706", .expense),
            ("Clothing",       "tshirt.fill",                 "#BE185D", .expense),

            ("Business",       "briefcase.fill",              "#059669", .income),
            ("Rental",         "building.2.fill",             "#7C3AED", .income),
            ("Bonus",          "star.fill",                   "#EAB308", .income),
            ("Refund",         "arrow.uturn.left.circle.fill","#3B82F6", .income),
        ]

        let existingNames: Set<String> = {
            let rows = (try? String.fetchAll(db, sql: "SELECT name FROM categories")) ?? []
            return Set(rows)
        }()

        let newCategories = additionalCategories.filter { !existingNames.contains($0.name) }
        guard !newCategories.isEmpty else { return }

        let now = Date()
        try db.seed {
            for item in newCategories {
                TransactionCategory.Draft(
                    name: item.name,
                    icon: item.icon,
                    colorHex: item.colorHex,
                    type: item.type,
                    createdAt: now
                )
            }
        }
    }

    try migrator.migrate(db)
}
