import Foundation
import Observation
import SQLiteData
import Dependencies

// MARK: - Supporting Types

struct BudgetProgress: Identifiable, Equatable {
    let budget: Budget
    let category: TransactionCategory?
    let spent: Double

    var id: Int { budget.id }

    var amount: Double { budget.amount }
    var remaining: Double { max(0, amount - spent) }
    var overspent: Double { max(0, spent - amount) }

    var percentage: Double {
        guard amount > 0 else { return 0 }
        return min(spent / amount * 100, 999)
    }

    var status: BudgetStatus {
        guard amount > 0 else { return .healthy }
        let ratio = spent / amount
        if ratio >= 1.0 { return .overspent }
        if ratio >= 0.8 { return .warning }
        return .healthy
    }

    static func == (lhs: Self, rhs: Self) -> Bool {
        lhs.budget.id == rhs.budget.id &&
        lhs.budget.amount == rhs.budget.amount &&
        lhs.budget.categoryId == rhs.budget.categoryId &&
        lhs.spent == rhs.spent &&
        lhs.category?.id == rhs.category?.id
    }
}

enum BudgetStatus {
    case healthy
    case warning
    case overspent
}

// MARK: - ViewModel

@Observable
@MainActor
final class BudgetsViewModel {
    @ObservationIgnored
    @FetchAll(Budget.order(by: \.createdAt))
    var budgets: [Budget]

    @ObservationIgnored
    @FetchAll(Transaction.order { $0.date.desc() })
    var transactions: [Transaction]

    @ObservationIgnored
    @FetchAll(TransactionCategory.order(by: \.name))
    var categories: [TransactionCategory]

    @ObservationIgnored
    @Dependency(\.defaultDatabase) var database

    var monthOffset: Int = 0
    var isShowingAddSheet = false
    var editingBudget: Budget?
    var budgetToDelete: Budget?
    var showDeleteAlert = false
    var errorMessage: String?

    // MARK: - Month Navigation

    func previousMonth() { monthOffset -= 1 }

    func nextMonth() {
        guard canGoForward else { return }
        monthOffset += 1
    }

    var canGoForward: Bool { monthOffset < 0 }

    var selectedMonthDate: Date {
        Calendar.current.date(byAdding: .month, value: monthOffset, to: Date()) ?? Date()
    }

    var monthDisplayLabel: String {
        let fmt = DateFormatter()
        fmt.dateFormat = "MMMM yyyy"
        return fmt.string(from: selectedMonthDate)
    }

    var isCurrentMonth: Bool { monthOffset == 0 }

    // MARK: - Monthly Data

    private var monthlyTransactions: [Transaction] {
        let calendar = Calendar.current
        let target = selectedMonthDate
        return transactions.filter {
            $0.type == .expense &&
            calendar.isDate($0.date, equalTo: target, toGranularity: .month)
        }
    }

    func spent(for categoryId: Int) -> Double {
        monthlyTransactions
            .filter { $0.categoryId == categoryId }
            .reduce(0) { $0 + $1.amount }
    }

    func transactions(for categoryId: Int) -> [Transaction] {
        monthlyTransactions
            .filter { $0.categoryId == categoryId }
            .sorted { $0.date > $1.date }
    }

    func category(id: Int) -> TransactionCategory? {
        categories.first { $0.id == id }
    }

    // MARK: - Progress

    var budgetProgress: [BudgetProgress] {
        budgets.map { budget in
            BudgetProgress(
                budget: budget,
                category: category(id: budget.categoryId),
                spent: spent(for: budget.categoryId)
            )
        }
        .sorted { $0.percentage > $1.percentage }
    }

    var totalBudgeted: Double {
        budgets.reduce(0) { $0 + $1.amount }
    }

    var totalSpent: Double {
        budgetProgress.reduce(0) { $0 + $1.spent }
    }

    var totalRemaining: Double {
        max(0, totalBudgeted - totalSpent)
    }

    var overallPercentage: Double {
        guard totalBudgeted > 0 else { return 0 }
        return min(totalSpent / totalBudgeted * 100, 999)
    }

    var overallStatus: BudgetStatus {
        guard totalBudgeted > 0 else { return .healthy }
        let ratio = totalSpent / totalBudgeted
        if ratio >= 1.0 { return .overspent }
        if ratio >= 0.8 { return .warning }
        return .healthy
    }

    var daysRemainingInMonth: Int {
        guard isCurrentMonth else { return 0 }
        let calendar = Calendar.current
        let now = Date()
        let range = calendar.range(of: .day, in: .month, for: now)?.count ?? 30
        let today = calendar.component(.day, from: now)
        return max(0, range - today)
    }

    var dailyRemainingBudget: Double {
        guard isCurrentMonth, daysRemainingInMonth > 0 else { return 0 }
        return totalRemaining / Double(daysRemainingInMonth)
    }

    // MARK: - Category Options

    var unbudgetedExpenseCategories: [TransactionCategory] {
        let budgetedIds = Set(budgets.map { $0.categoryId })
        return categories
            .filter { $0.type == .expense && !budgetedIds.contains($0.id) }
    }

    func canEdit(_ budget: Budget, withCategoryId newId: Int) -> Bool {
        if budget.categoryId == newId { return true }
        return !budgets.contains { $0.id != budget.id && $0.categoryId == newId }
    }

    // MARK: - CRUD

    func addBudget(categoryId: Int, amount: Double) {
        do {
            try database.write { db in
                try Budget.insert {
                    Budget.Draft(categoryId: categoryId, amount: amount, createdAt: Date())
                }.execute(db)
            }
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func updateBudget(_ budget: Budget) {
        do {
            try database.write { db in
                try Budget.update(budget).execute(db)
            }
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func deleteBudget(_ budget: Budget) {
        do {
            try database.write { db in
                try Budget.delete(budget).execute(db)
            }
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}
