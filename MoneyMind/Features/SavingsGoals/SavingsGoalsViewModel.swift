import Foundation
import Observation
import SQLiteData
import Dependencies

// MARK: - Supporting Types

enum GoalStatus {
    case onTrack
    case behind
    case completed
    case noDeadline
}

struct GoalProgress: Identifiable, Equatable {
    let goal: SavingsGoal
    let saved: Double
    let contributionCount: Int
    let latestContributionDate: Date?

    var id: Int { goal.id }

    var target: Double { goal.targetAmount }
    var remaining: Double { max(0, target - saved) }

    var percentage: Double {
        guard target > 0 else { return 0 }
        return min(saved / target * 100, 999)
    }

    var isCompleted: Bool { saved >= target && target > 0 }

    var daysRemaining: Int? {
        guard let targetDate = goal.targetDate else { return nil }
        let calendar = Calendar.current
        let start = calendar.startOfDay(for: Date())
        let end = calendar.startOfDay(for: targetDate)
        let days = calendar.dateComponents([.day], from: start, to: end).day ?? 0
        return days
    }

    /// Required per-day savings to hit target on time.
    var requiredPerDay: Double? {
        guard let days = daysRemaining, days > 0 else { return nil }
        return remaining / Double(days)
    }

    /// Required per-month savings to hit target on time.
    var requiredPerMonth: Double? {
        guard let days = daysRemaining, days > 0 else { return nil }
        let months = max(1.0, Double(days) / 30.0)
        return remaining / months
    }

    var status: GoalStatus {
        if isCompleted { return .completed }
        guard let days = daysRemaining else { return .noDeadline }
        if days <= 0 { return .behind }
        // behind if needed per-day exceeds 2x the historical daily pace
        let createdDays = max(
            1,
            Calendar.current.dateComponents([.day], from: goal.createdAt, to: Date()).day ?? 1
        )
        let historicalPerDay = saved / Double(createdDays)
        guard let needed = requiredPerDay else { return .onTrack }
        return needed > historicalPerDay * 2 ? .behind : .onTrack
    }

    var targetDateLabel: String? {
        guard let date = goal.targetDate else { return nil }
        let fmt = DateFormatter()
        fmt.dateStyle = .medium
        return fmt.string(from: date)
    }

    static func == (lhs: Self, rhs: Self) -> Bool {
        lhs.goal.id == rhs.goal.id &&
        lhs.goal.targetAmount == rhs.goal.targetAmount &&
        lhs.goal.targetDate == rhs.goal.targetDate &&
        lhs.saved == rhs.saved &&
        lhs.contributionCount == rhs.contributionCount
    }
}

// MARK: - ViewModel

@Observable
@MainActor
final class SavingsGoalsViewModel {
    @ObservationIgnored
    @FetchAll(SavingsGoal.order { $0.createdAt.desc() })
    var goals: [SavingsGoal]

    @ObservationIgnored
    @FetchAll(GoalContribution.order { $0.date.desc() })
    var contributions: [GoalContribution]

    @ObservationIgnored
    @FetchAll(Transaction.order { $0.date.desc() })
    var transactions: [Transaction]

    @ObservationIgnored
    @Dependency(\.defaultDatabase) var database

    var isShowingAddGoalSheet = false
    var editingGoal: SavingsGoal?
    var goalToDelete: SavingsGoal?
    var showDeleteAlert = false
    var errorMessage: String?

    // MARK: - Progress

    func contributions(for goalId: Int) -> [GoalContribution] {
        contributions.filter { $0.goalId == goalId }
    }

    func saved(for goalId: Int) -> Double {
        contributions(for: goalId).reduce(0) { $0 + $1.amount }
    }

    func progress(for goal: SavingsGoal) -> GoalProgress {
        let list = contributions(for: goal.id)
        return GoalProgress(
            goal: goal,
            saved: list.reduce(0) { $0 + $1.amount },
            contributionCount: list.count,
            latestContributionDate: list.first?.date
        )
    }

    var goalProgress: [GoalProgress] {
        goals
            .map { progress(for: $0) }
            .sorted { lhs, rhs in
                // completed goals sink, then by highest percentage
                if lhs.isCompleted != rhs.isCompleted {
                    return !lhs.isCompleted
                }
                return lhs.percentage > rhs.percentage
            }
    }

    // MARK: - Totals

    var totalSaved: Double {
        goalProgress.reduce(0) { $0 + $1.saved }
    }

    var totalTarget: Double {
        goals.reduce(0) { $0 + $1.targetAmount }
    }

    var overallPercentage: Double {
        guard totalTarget > 0 else { return 0 }
        return min(totalSaved / totalTarget * 100, 999)
    }

    var activeGoalsCount: Int {
        goalProgress.filter { !$0.isCompleted }.count
    }

    var completedGoalsCount: Int {
        goalProgress.filter { $0.isCompleted }.count
    }

    // MARK: - Savings Rate (this month)

    var currentMonthLabel: String {
        let fmt = DateFormatter()
        fmt.dateFormat = "MMMM"
        return fmt.string(from: Date())
    }

    var monthlyIncome: Double {
        let calendar = Calendar.current
        let now = Date()
        return transactions
            .filter {
                $0.type == .income &&
                calendar.isDate($0.date, equalTo: now, toGranularity: .month)
            }
            .reduce(0) { $0 + $1.amount }
    }

    var monthlyContributions: Double {
        let calendar = Calendar.current
        let now = Date()
        return contributions
            .filter { calendar.isDate($0.date, equalTo: now, toGranularity: .month) }
            .reduce(0) { $0 + $1.amount }
    }

    /// Percentage of this month's income that went into savings goals.
    /// Returns nil when income is zero (rate is undefined).
    var savingsRatePercent: Double? {
        guard monthlyIncome > 0 else { return nil }
        return monthlyContributions / monthlyIncome * 100
    }

    // MARK: - Goal CRUD

    func addGoal(
        name: String,
        icon: String,
        colorHex: String,
        targetAmount: Double,
        targetDate: Date?,
        note: String
    ) {
        do {
            try database.write { db in
                try SavingsGoal.insert {
                    SavingsGoal.Draft(
                        name: name,
                        icon: icon,
                        colorHex: colorHex,
                        targetAmount: targetAmount,
                        targetDate: targetDate,
                        note: note,
                        createdAt: Date()
                    )
                }.execute(db)
            }
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func updateGoal(_ goal: SavingsGoal) {
        do {
            try database.write { db in
                try SavingsGoal.update(goal).execute(db)
            }
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func deleteGoal(_ goal: SavingsGoal) {
        do {
            try database.write { db in
                try SavingsGoal.delete(goal).execute(db)
            }
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    // MARK: - Contribution CRUD

    func addContribution(
        goalId: Int,
        amount: Double,
        date: Date,
        note: String
    ) {
        do {
            try database.write { db in
                try GoalContribution.insert {
                    GoalContribution.Draft(
                        goalId: goalId,
                        amount: amount,
                        date: date,
                        note: note,
                        createdAt: Date()
                    )
                }.execute(db)
            }
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func updateContribution(_ contribution: GoalContribution) {
        do {
            try database.write { db in
                try GoalContribution.update(contribution).execute(db)
            }
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func deleteContribution(_ contribution: GoalContribution) {
        do {
            try database.write { db in
                try GoalContribution.delete(contribution).execute(db)
            }
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}
