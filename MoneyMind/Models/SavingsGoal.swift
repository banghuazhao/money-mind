import Foundation
import SQLiteData

@Table("savings_goals")
nonisolated struct SavingsGoal: Identifiable, Hashable {
    let id: Int
    var name: String
    var icon: String
    var colorHex: String
    var targetAmount: Double
    var targetDate: Date?
    var note: String
    var createdAt: Date
}
