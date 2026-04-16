import Foundation
import Observation
import SQLiteData
import Dependencies

@Observable
@MainActor
final class CategoriesViewModel {
    @ObservationIgnored
    @FetchAll(TransactionCategory.order(by: \.name))
    var categories: [TransactionCategory]

    @ObservationIgnored
    @Dependency(\.defaultDatabase) var database

    var isShowingAddSheet = false
    var editingCategory: TransactionCategory?
    var categoryToDelete: TransactionCategory?
    var showDeleteAlert = false
    var errorMessage: String?

    func addCategory(_ category: TransactionCategory) {
        do {
            try database.write { db in
                try TransactionCategory.insert {
                    TransactionCategory.Draft(
                        name: category.name,
                        icon: category.icon,
                        colorHex: category.colorHex,
                        type: category.type,
                        createdAt: category.createdAt
                    )
                }.execute(db)
            }
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func updateCategory(_ category: TransactionCategory) {
        do {
            try database.write { db in
                try TransactionCategory.update(category).execute(db)
            }
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func deleteCategory(_ category: TransactionCategory) {
        do {
            try database.write { db in
                try TransactionCategory.delete(category).execute(db)
            }
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func categoriesForType(_ type: TransactionType) -> [TransactionCategory] {
        categories.filter { $0.type == type }
    }
}
