import Foundation
import Observation
import SQLiteData
import Dependencies

// MARK: - Supporting Types

struct CategorySpending: Identifiable, Equatable {
    var id: Int { categoryId }
    let categoryId: Int
    let categoryName: String
    let categoryIcon: String
    let categoryColorHex: String
    let amount: Double
    let percentage: Double
    let transactionCount: Int
}

struct TrendPoint: Identifiable, Equatable {
    let id = UUID()
    let label: String
    let income: Double
    let expense: Double

    static func == (lhs: Self, rhs: Self) -> Bool {
        lhs.label == rhs.label && lhs.income == rhs.income && lhs.expense == rhs.expense
    }
}

struct BalancePoint: Identifiable {
    let id = UUID()
    let date: Date
    let cumulativeNet: Double
}

enum ReportPeriod: String, CaseIterable {
    case week = "Week"
    case month = "Month"
    case year = "Year"
    case all = "All"
}

// MARK: - ViewModel

@Observable
@MainActor
final class ReportViewModel {
    @ObservationIgnored
    @FetchAll(Transaction.order { $0.date.desc() })
    var transactions: [Transaction]

    var selectedPeriod: ReportPeriod = .month {
        didSet {
            guard oldValue != selectedPeriod else { return }
            periodOffset = 0
            selectedCategoryId = nil
        }
    }
    var selectedType: TransactionType = .expense {
        didSet { selectedCategoryId = nil }
    }
    var periodOffset: Int = 0
    var selectedCategoryId: Int? = nil

    // MARK: - Period Navigation

    func previousPeriod() {
        periodOffset -= 1
        selectedCategoryId = nil
    }

    func nextPeriod() {
        guard canGoForward else { return }
        periodOffset += 1
        selectedCategoryId = nil
    }

    var canGoForward: Bool { periodOffset < 0 }

    var canNavigate: Bool { selectedPeriod != .all }

    var periodDisplayLabel: String {
        let calendar = Calendar.current
        let now = Date()

        switch selectedPeriod {
        case .week:
            guard let target = calendar.date(byAdding: .weekOfYear, value: periodOffset, to: now),
                  let interval = calendar.dateInterval(of: .weekOfYear, for: target) else { return "This Week" }
            let fmt = DateFormatter()
            fmt.dateFormat = "MMM d"
            let end = calendar.date(byAdding: .day, value: 6, to: interval.start) ?? interval.end
            return "\(fmt.string(from: interval.start)) – \(fmt.string(from: end))"

        case .month:
            guard let target = calendar.date(byAdding: .month, value: periodOffset, to: now) else { return "This Month" }
            let fmt = DateFormatter()
            fmt.dateFormat = "MMMM yyyy"
            return fmt.string(from: target)

        case .year:
            guard let target = calendar.date(byAdding: .year, value: periodOffset, to: now) else { return "This Year" }
            let fmt = DateFormatter()
            fmt.dateFormat = "yyyy"
            return fmt.string(from: target)

        case .all:
            return "All Time"
        }
    }

    // MARK: - Filtered Transactions

    var filteredTransactions: [Transaction] {
        let now = Date()
        let calendar = Calendar.current
        guard selectedPeriod != .all else { return transactions }

        return transactions.filter { t in
            switch selectedPeriod {
            case .week:
                guard let target = calendar.date(byAdding: .weekOfYear, value: periodOffset, to: now),
                      let interval = calendar.dateInterval(of: .weekOfYear, for: target) else { return false }
                return t.date >= interval.start && t.date < interval.end

            case .month:
                guard let target = calendar.date(byAdding: .month, value: periodOffset, to: now) else { return false }
                return calendar.isDate(t.date, equalTo: target, toGranularity: .month)

            case .year:
                guard let target = calendar.date(byAdding: .year, value: periodOffset, to: now) else { return false }
                return calendar.isDate(t.date, equalTo: target, toGranularity: .year)

            case .all:
                return true
            }
        }
    }

    // MARK: - Totals & Stats

    var totalIncome: Double {
        filteredTransactions.filter { $0.type == .income }.reduce(0) { $0 + $1.amount }
    }

    var totalExpense: Double {
        filteredTransactions.filter { $0.type == .expense }.reduce(0) { $0 + $1.amount }
    }

    var balance: Double { totalIncome - totalExpense }

    var savingsRate: Double {
        guard totalIncome > 0 else { return 0 }
        return max(0, (totalIncome - totalExpense) / totalIncome * 100)
    }

    var transactionCount: Int { filteredTransactions.count }

    var dailyAverage: Double {
        let calendar = Calendar.current
        let now = Date()
        let days: Int

        switch selectedPeriod {
        case .week:
            days = periodOffset == 0 ? max(1, calendar.component(.weekday, from: now)) : 7
        case .month:
            if periodOffset == 0 {
                days = max(1, calendar.component(.day, from: now))
            } else {
                guard let target = calendar.date(byAdding: .month, value: periodOffset, to: now) else { return 0 }
                days = calendar.range(of: .day, in: .month, for: target)?.count ?? 30
            }
        case .year:
            if periodOffset == 0 {
                days = max(1, calendar.ordinality(of: .day, in: .year, for: now) ?? 1)
            } else {
                guard let target = calendar.date(byAdding: .year, value: periodOffset, to: now) else { return 0 }
                days = calendar.range(of: .day, in: .year, for: target)?.count ?? 365
            }
        case .all:
            guard let earliest = transactions.last?.date else { return 0 }
            days = max(1, calendar.dateComponents([.day], from: earliest, to: now).day ?? 1)
        }

        guard days > 0 else { return 0 }
        return totalExpense / Double(days)
    }

    // MARK: - Category Breakdown

    var categoryBreakdown: [CategorySpending] {
        let relevant = filteredTransactions.filter { $0.type == selectedType }
        let total = relevant.reduce(0) { $0 + $1.amount }
        guard total > 0 else { return [] }

        let grouped = Dictionary(grouping: relevant) { $0.categoryId }
        return grouped.compactMap { (categoryId, txns) -> CategorySpending? in
            guard let first = txns.first else { return nil }
            let amount = txns.reduce(0) { $0 + $1.amount }
            return CategorySpending(
                categoryId: categoryId,
                categoryName: first.categoryName,
                categoryIcon: first.categoryIcon,
                categoryColorHex: first.categoryColorHex,
                amount: amount,
                percentage: amount / total * 100,
                transactionCount: txns.count
            )
        }
        .sorted { $0.amount > $1.amount }
    }

    var selectedCategory: CategorySpending? {
        guard let id = selectedCategoryId else { return nil }
        return categoryBreakdown.first { $0.categoryId == id }
    }

    func findCategory(byAngleValue value: Double) -> CategorySpending? {
        var cumulative: Double = 0
        for item in categoryBreakdown {
            cumulative += item.amount
            if value <= cumulative { return item }
        }
        return categoryBreakdown.last
    }

    func transactionsForCategory(_ categoryId: Int) -> [Transaction] {
        filteredTransactions
            .filter { $0.type == selectedType && $0.categoryId == categoryId }
            .sorted { $0.date > $1.date }
    }

    // MARK: - Cumulative Balance Curve

    var netCurveData: [BalancePoint] {
        let calendar = Calendar.current
        let now = Date()
        var result: [BalancePoint] = []
        var running: Double = 0

        func net(_ txns: [Transaction]) -> Double {
            txns.reduce(0) { $0 + ($1.type == .income ? $1.amount : -$1.amount) }
        }

        switch selectedPeriod {
        case .week:
            guard let target = calendar.date(byAdding: .weekOfYear, value: periodOffset, to: now),
                  let interval = calendar.dateInterval(of: .weekOfYear, for: target) else { return [] }
            for day in 0..<7 {
                guard let date = calendar.date(byAdding: .day, value: day, to: interval.start) else { continue }
                let dc = calendar.dateComponents([.year, .month, .day], from: date)
                running += net(filteredTransactions.filter {
                    let c = calendar.dateComponents([.year, .month, .day], from: $0.date)
                    return c == dc
                })
                result.append(BalancePoint(date: date, cumulativeNet: running))
            }

        case .month:
            guard let target = calendar.date(byAdding: .month, value: periodOffset, to: now),
                  let monthStart = calendar.date(from: calendar.dateComponents([.year, .month], from: target)) else { return [] }
            let maxDay: Int
            if periodOffset == 0 {
                maxDay = calendar.component(.day, from: now)
            } else {
                maxDay = calendar.range(of: .day, in: .month, for: target)?.count ?? 30
            }
            for day in 1...max(1, maxDay) {
                guard let date = calendar.date(bySetting: .day, value: day, of: monthStart) else { continue }
                let dc = calendar.dateComponents([.year, .month, .day], from: date)
                running += net(filteredTransactions.filter {
                    let c = calendar.dateComponents([.year, .month, .day], from: $0.date)
                    return c == dc
                })
                result.append(BalancePoint(date: date, cumulativeNet: running))
            }

        case .year:
            guard let target = calendar.date(byAdding: .year, value: periodOffset, to: now) else { return [] }
            let yr = calendar.component(.year, from: target)
            let maxMonth = periodOffset == 0 ? calendar.component(.month, from: now) : 12
            for month in 1...max(1, maxMonth) {
                var dc = DateComponents(); dc.year = yr; dc.month = month; dc.day = 1
                guard let date = calendar.date(from: dc) else { continue }
                running += net(filteredTransactions.filter {
                    let c = calendar.dateComponents([.year, .month], from: $0.date)
                    return c.year == yr && c.month == month
                })
                result.append(BalancePoint(date: date, cumulativeNet: running))
            }

        case .all:
            let grouped = Dictionary(grouping: filteredTransactions) { t -> String in
                let c = calendar.dateComponents([.year, .month], from: t.date)
                return String(format: "%04d-%02d", c.year ?? 0, c.month ?? 0)
            }
            for key in grouped.keys.sorted() {
                running += net(grouped[key] ?? [])
                let parts = key.split(separator: "-")
                if parts.count == 2, let yr = Int(parts[0]), let mo = Int(parts[1]) {
                    var dc = DateComponents(); dc.year = yr; dc.month = mo; dc.day = 1
                    if let date = calendar.date(from: dc) {
                        result.append(BalancePoint(date: date, cumulativeNet: running))
                    }
                }
            }
        }

        return result
    }

    // MARK: - Trend Data

    var trendSectionTitle: String {
        switch selectedPeriod {
        case .week: return "Daily Trend"
        case .month: return "Weekly Trend"
        case .year: return "Monthly Trend"
        case .all: return "Monthly Trend"
        }
    }

    var trendData: [TrendPoint] {
        let calendar = Calendar.current
        let now = Date()
        var result: [TrendPoint] = []
        let fmt = DateFormatter()

        switch selectedPeriod {
        case .week:
            guard let target = calendar.date(byAdding: .weekOfYear, value: periodOffset, to: now),
                  let interval = calendar.dateInterval(of: .weekOfYear, for: target) else { return [] }
            for day in 0..<7 {
                guard let date = calendar.date(byAdding: .day, value: day, to: interval.start) else { continue }
                let dc = calendar.dateComponents([.year, .month, .day], from: date)
                let dayTxns = filteredTransactions.filter {
                    let c = calendar.dateComponents([.year, .month, .day], from: $0.date)
                    return c == dc
                }
                fmt.dateFormat = "EEE"
                result.append(TrendPoint(
                    label: fmt.string(from: date),
                    income: dayTxns.filter { $0.type == .income }.reduce(0) { $0 + $1.amount },
                    expense: dayTxns.filter { $0.type == .expense }.reduce(0) { $0 + $1.amount }
                ))
            }

        case .month:
            guard let target = calendar.date(byAdding: .month, value: periodOffset, to: now),
                  let monthInterval = calendar.dateInterval(of: .month, for: target) else { return [] }
            var weekStart = monthInterval.start
            var weekNum = 1
            while weekStart < monthInterval.end {
                let weekEnd = min(
                    calendar.date(byAdding: .day, value: 7, to: weekStart) ?? monthInterval.end,
                    monthInterval.end
                )
                let weekTxns = filteredTransactions.filter { $0.date >= weekStart && $0.date < weekEnd }
                result.append(TrendPoint(
                    label: "W\(weekNum)",
                    income: weekTxns.filter { $0.type == .income }.reduce(0) { $0 + $1.amount },
                    expense: weekTxns.filter { $0.type == .expense }.reduce(0) { $0 + $1.amount }
                ))
                weekStart = weekEnd
                weekNum += 1
            }

        case .year:
            guard let target = calendar.date(byAdding: .year, value: periodOffset, to: now) else { return [] }
            let yr = calendar.component(.year, from: target)
            for month in 1...12 {
                var dc = DateComponents(); dc.year = yr; dc.month = month; dc.day = 1
                guard let date = calendar.date(from: dc) else { continue }
                let monthTxns = filteredTransactions.filter {
                    calendar.component(.month, from: $0.date) == month
                }
                fmt.dateFormat = "MMM"
                result.append(TrendPoint(
                    label: fmt.string(from: date),
                    income: monthTxns.filter { $0.type == .income }.reduce(0) { $0 + $1.amount },
                    expense: monthTxns.filter { $0.type == .expense }.reduce(0) { $0 + $1.amount }
                ))
            }

        case .all:
            for offset in stride(from: -5, through: 0, by: 1) {
                guard let date = calendar.date(byAdding: .month, value: offset, to: now) else { continue }
                let comps = calendar.dateComponents([.year, .month], from: date)
                let monthTxns = transactions.filter {
                    let c = calendar.dateComponents([.year, .month], from: $0.date)
                    return c.year == comps.year && c.month == comps.month
                }
                fmt.dateFormat = "MMM"
                result.append(TrendPoint(
                    label: fmt.string(from: date),
                    income: monthTxns.filter { $0.type == .income }.reduce(0) { $0 + $1.amount },
                    expense: monthTxns.filter { $0.type == .expense }.reduce(0) { $0 + $1.amount }
                ))
            }
        }

        return result
    }
}
