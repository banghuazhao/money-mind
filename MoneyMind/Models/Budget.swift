import Foundation
import SQLiteData

@Table("budgets")
nonisolated struct Budget: Identifiable, Hashable {
    let id: Int
    var categoryId: Int
    var amount: Double
    var createdAt: Date
}
