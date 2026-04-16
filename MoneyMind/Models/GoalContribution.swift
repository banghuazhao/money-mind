import Foundation
import SQLiteData

@Table("goal_contributions")
nonisolated struct GoalContribution: Identifiable, Hashable {
    let id: Int
    var goalId: Int
    var amount: Double
    var date: Date
    var note: String
    var createdAt: Date
}
