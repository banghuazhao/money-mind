import Foundation
import SQLiteData

@Table("categories")
nonisolated struct TransactionCategory: Identifiable, Hashable {
    let id: Int
    var name: String
    var icon: String
    var colorHex: String
    var type: TransactionType
    var createdAt: Date
}
