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

struct MonthlyData: Identifiable {
    let id = UUID()
    let month: String
    let income: Double
    let expense: Double
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

    var monthlyData: [MonthlyData] {
        let calendar = Calendar.current
        let now = Date()
        var result: [MonthlyData] = []

        for monthOffset in stride(from: -5, through: 0, by: 1) {
            guard let date = calendar.date(byAdding: .month, value: monthOffset, to: now) else { continue }
            let components = calendar.dateComponents([.year, .month], from: date)

            let monthTransactions = transactions.filter { t in
                let tComponents = calendar.dateComponents([.year, .month], from: t.date)
                return tComponents.year == components.year && tComponents.month == components.month
            }

            let income = monthTransactions.filter { $0.type == .income }.reduce(0) { $0 + $1.amount }
            let expense = monthTransactions.filter { $0.type == .expense }.reduce(0) { $0 + $1.amount }

            let formatter = DateFormatter()
            formatter.dateFormat = "MMM"
            let monthName = formatter.string(from: date)

            result.append(MonthlyData(month: monthName, income: income, expense: expense))
        }
        return result
    }
}
