import Foundation
import SQLiteData

enum TransactionType: String, CaseIterable, Hashable, QueryBindable {
    case expense
    case income

    var displayName: String {
        switch self {
        case .expense: "Expense"
        case .income: "Income"
        }
    }

    var systemImage: String {
        switch self {
        case .expense: "arrow.up.circle.fill"
        case .income: "arrow.down.circle.fill"
        }
    }
}
