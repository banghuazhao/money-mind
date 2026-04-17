import Foundation
import Observation
import SQLiteData

@Observable
@MainActor
final class SettingsViewModel {
    @ObservationIgnored
    @FetchAll(Transaction.order { $0.id.asc() })
    var transactions: [Transaction]

    @ObservationIgnored
    @FetchAll(TransactionCategory.order { $0.id.asc() })
    var categories: [TransactionCategory]

    @ObservationIgnored
    @FetchAll(Budget.order { $0.id.asc() })
    var budgets: [Budget]

    @ObservationIgnored
    @FetchAll(SavingsGoal.order { $0.id.asc() })
    var savingsGoals: [SavingsGoal]

    @ObservationIgnored
    @FetchAll(GoalContribution.order { $0.id.asc() })
    var goalContributions: [GoalContribution]

    let availableCurrencies = CurrencyCatalog.all

    func currencySymbol(for code: String) -> String {
        availableCurrencies.first { $0.code == code }?.symbol ?? code
    }

    /// e.g. "US Dollar · $"
    func currencySubtitle(for code: String) -> String {
        guard let c = availableCurrencies.first(where: { $0.code == code }) else {
            return code
        }
        return "\(c.name) · \(c.symbol)"
    }

    // MARK: - Export

    func exportCSVString() -> String {
        CSVDataExport.makeAllTables(
            transactions: transactions,
            categories: categories,
            budgets: budgets,
            goals: savingsGoals,
            contributions: goalContributions
        )
    }

    func exportCSVFileURL() throws -> URL {
        let csv = exportCSVString()
        let stamp = ISO8601DateFormatter().string(from: Date()).replacingOccurrences(of: ":", with: "-")
        let name = "MoneyMind-export-\(stamp).csv"
        let url = FileManager.default.temporaryDirectory.appendingPathComponent(name)
        try csv.write(to: url, atomically: true, encoding: .utf8)
        return url
    }
}
