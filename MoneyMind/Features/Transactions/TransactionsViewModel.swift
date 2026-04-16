import Foundation
import Observation
import SQLiteData
import Dependencies

@Observable
@MainActor
final class TransactionsViewModel {
    @ObservationIgnored
    @FetchAll(Transaction.order { $0.date.desc() })
    var transactions: [Transaction]

    @ObservationIgnored
    @FetchAll(TransactionCategory.order(by: \.name))
    var categories: [TransactionCategory]

    @ObservationIgnored
    @Dependency(\.defaultDatabase) var database

    var isShowingAddSheet = false
    var editingTransaction: Transaction?
    var transactionToDelete: Transaction?
    var showDeleteAlert = false
    var errorMessage: String?
    var filterType: TransactionType? = nil
    var searchText: String = ""

    var filteredTransactions: [Transaction] {
        var result = transactions
        if let filter = filterType {
            result = result.filter { $0.type == filter }
        }
        if !searchText.isEmpty {
            result = result.filter {
                $0.note.localizedCaseInsensitiveContains(searchText) ||
                $0.categoryName.localizedCaseInsensitiveContains(searchText)
            }
        }
        return result
    }

    var groupedTransactions: [(String, [Transaction])] {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .none

        let grouped = Dictionary(grouping: filteredTransactions) { transaction -> String in
            formatter.string(from: transaction.date)
        }
        return grouped.sorted { a, b in
            guard let dateA = formatter.date(from: a.key),
                  let dateB = formatter.date(from: b.key)
            else { return a.key > b.key }
            return dateA > dateB
        }
    }

    var totalIncome: Double {
        transactions.filter { $0.type == .income }.reduce(0) { $0 + $1.amount }
    }

    var totalExpense: Double {
        transactions.filter { $0.type == .expense }.reduce(0) { $0 + $1.amount }
    }

    func addTransaction(_ transaction: Transaction) {
        do {
            try database.write { db in
                try Transaction.insert {
                    Transaction.Draft(
                        amount: transaction.amount,
                        note: transaction.note,
                        date: transaction.date,
                        type: transaction.type,
                        categoryId: transaction.categoryId,
                        categoryName: transaction.categoryName,
                        categoryIcon: transaction.categoryIcon,
                        categoryColorHex: transaction.categoryColorHex,
                        createdAt: transaction.createdAt
                    )
                }.execute(db)
            }
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func updateTransaction(_ transaction: Transaction) {
        do {
            try database.write { db in
                try Transaction.update(transaction).execute(db)
            }
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func deleteTransaction(_ transaction: Transaction) {
        do {
            try database.write { db in
                try Transaction.delete(transaction).execute(db)
            }
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func categoriesForType(_ type: TransactionType) -> [TransactionCategory] {
        categories.filter { $0.type == type }
    }
}
