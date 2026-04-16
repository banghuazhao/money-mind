import Foundation
import Observation
import SQLiteData
import Dependencies

struct CategorySpending: Identifiable {
    var id: Int { categoryId }
    let categoryId: Int
    let categoryName: String
    let categoryIcon: String
    let categoryColorHex: String
    let amount: Double
    let percentage: Double
}

struct TrendPoint: Identifiable {
    let id = UUID()
    let label: String
    let income: Double
    let expense: Double
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

@Observable
@MainActor
final class ReportViewModel {
    @ObservationIgnored
    @FetchAll(Transaction.order { $0.date.desc() })
    var transactions: [Transaction]

    var selectedPeriod: ReportPeriod = .month
    var selectedType: TransactionType = .expense

    var filteredTransactions: [Transaction] {
        let now = Date()
        let calendar = Calendar.current
        return transactions.filter { t in
            switch selectedPeriod {
            case .week:
                return calendar.isDate(t.date, equalTo: now, toGranularity: .weekOfYear)
            case .month:
                return calendar.isDate(t.date, equalTo: now, toGranularity: .month)
            case .year:
                return calendar.isDate(t.date, equalTo: now, toGranularity: .year)
            case .all:
                return true
            }
        }
    }

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

    // Cumulative net balance over time within the selected period.
    // Rising = income outpacing expense; falling = overspending.
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
            for offset in stride(from: -6, through: 0, by: 1) {
                guard let date = calendar.date(byAdding: .day, value: offset, to: now) else { continue }
                let dc = calendar.dateComponents([.year, .month, .day], from: date)
                running += net(filteredTransactions.filter {
                    let c = calendar.dateComponents([.year, .month, .day], from: $0.date)
                    return c.year == dc.year && c.month == dc.month && c.day == dc.day
                })
                result.append(BalancePoint(date: date, cumulativeNet: running))
            }

        case .month:
            let todayDay = calendar.component(.day, from: now)
            guard let monthStart = calendar.date(
                from: calendar.dateComponents([.year, .month], from: now)
            ) else { return [] }
            for day in 1...max(1, todayDay) {
                guard let date = calendar.date(bySetting: .day, value: day, of: monthStart) else { continue }
                let dc = calendar.dateComponents([.year, .month, .day], from: date)
                running += net(filteredTransactions.filter {
                    let c = calendar.dateComponents([.year, .month, .day], from: $0.date)
                    return c.year == dc.year && c.month == dc.month && c.day == dc.day
                })
                result.append(BalancePoint(date: date, cumulativeNet: running))
            }

        case .year:
            let yr = calendar.component(.year, from: now)
            let mo = calendar.component(.month, from: now)
            for month in 1...max(1, mo) {
                var dc = DateComponents(); dc.year = yr; dc.month = month; dc.day = 1
                guard let date = calendar.date(from: dc) else { continue }
                running += net(filteredTransactions.filter {
                    calendar.dateComponents([.month], from: $0.date).month == month
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
                percentage: amount / total * 100
            )
        }
        .sorted { $0.amount > $1.amount }
    }

    var trendSectionTitle: String {
        switch selectedPeriod {
        case .week: return "Daily Trend (7 Days)"
        case .month: return "Weekly Trend (4 Weeks)"
        case .year: return "Monthly Trend (12 Months)"
        case .all: return "6-Month Trend"
        }
    }

    // Chart data adapts to the selected period
    var trendData: [TrendPoint] {
        let calendar = Calendar.current
        let now = Date()
        var result: [TrendPoint] = []

        switch selectedPeriod {

        case .week:
            // Last 7 days, daily bars
            for dayOffset in stride(from: -6, through: 0, by: 1) {
                guard let date = calendar.date(byAdding: .day, value: dayOffset, to: now) else { continue }
                let dayComponents = calendar.dateComponents([.year, .month, .day], from: date)

                let dayTxns = transactions.filter { t in
                    let c = calendar.dateComponents([.year, .month, .day], from: t.date)
                    return c.year == dayComponents.year &&
                           c.month == dayComponents.month &&
                           c.day == dayComponents.day
                }

                let income = dayTxns.filter { $0.type == .income }.reduce(0) { $0 + $1.amount }
                let expense = dayTxns.filter { $0.type == .expense }.reduce(0) { $0 + $1.amount }

                let formatter = DateFormatter()
                formatter.dateFormat = "EEE"
                result.append(TrendPoint(label: formatter.string(from: date), income: income, expense: expense))
            }

        case .month:
            // Last 4 weeks, weekly bars
            for weekOffset in stride(from: -3, through: 0, by: 1) {
                guard let weekAnchor = calendar.date(byAdding: .weekOfYear, value: weekOffset, to: now) else { continue }
                let weekStart = calendar.dateInterval(of: .weekOfYear, for: weekAnchor)?.start ?? weekAnchor
                let weekEnd = calendar.date(byAdding: .day, value: 6, to: weekStart) ?? weekAnchor

                let weekTxns = transactions.filter { t in
                    t.date >= weekStart && t.date <= Calendar.current.date(byAdding: .day, value: 1, to: weekEnd)!
                }

                let income = weekTxns.filter { $0.type == .income }.reduce(0) { $0 + $1.amount }
                let expense = weekTxns.filter { $0.type == .expense }.reduce(0) { $0 + $1.amount }

                let formatter = DateFormatter()
                formatter.dateFormat = "MMM d"
                result.append(TrendPoint(label: formatter.string(from: weekStart), income: income, expense: expense))
            }

        case .year:
            // Last 12 months
            for monthOffset in stride(from: -11, through: 0, by: 1) {
                guard let date = calendar.date(byAdding: .month, value: monthOffset, to: now) else { continue }
                let components = calendar.dateComponents([.year, .month], from: date)

                let monthTxns = transactions.filter { t in
                    let c = calendar.dateComponents([.year, .month], from: t.date)
                    return c.year == components.year && c.month == components.month
                }

                let income = monthTxns.filter { $0.type == .income }.reduce(0) { $0 + $1.amount }
                let expense = monthTxns.filter { $0.type == .expense }.reduce(0) { $0 + $1.amount }

                let formatter = DateFormatter()
                formatter.dateFormat = "MMM"
                result.append(TrendPoint(label: formatter.string(from: date), income: income, expense: expense))
            }

        case .all:
            // Last 6 months
            for monthOffset in stride(from: -5, through: 0, by: 1) {
                guard let date = calendar.date(byAdding: .month, value: monthOffset, to: now) else { continue }
                let components = calendar.dateComponents([.year, .month], from: date)

                let monthTxns = transactions.filter { t in
                    let c = calendar.dateComponents([.year, .month], from: t.date)
                    return c.year == components.year && c.month == components.month
                }

                let income = monthTxns.filter { $0.type == .income }.reduce(0) { $0 + $1.amount }
                let expense = monthTxns.filter { $0.type == .expense }.reduce(0) { $0 + $1.amount }

                let formatter = DateFormatter()
                formatter.dateFormat = "MMM"
                result.append(TrendPoint(label: formatter.string(from: date), income: income, expense: expense))
            }
        }

        return result
    }
}
