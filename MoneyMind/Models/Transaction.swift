import Foundation
import SQLiteData

@Table("transactions")
nonisolated struct Transaction: Identifiable, Hashable {
    let id: Int
    var amount: Double
    var note: String
    var date: Date
    var type: TransactionType
    var categoryId: Int
    var categoryName: String
    var categoryIcon: String
    var categoryColorHex: String
    var createdAt: Date
}
