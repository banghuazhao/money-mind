import Foundation

struct CurrencyFormatter {
    static func format(_ amount: Double, currencyCode: String) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = currencyCode
        formatter.maximumFractionDigits = 2
        formatter.minimumFractionDigits = 2
        return formatter.string(from: NSNumber(value: amount)) ?? "\(currencyCode) \(String(format: "%.2f", amount))"
    }
}
