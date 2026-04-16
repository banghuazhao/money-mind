import Foundation
import Observation

@Observable
@MainActor
final class SettingsViewModel {
    let availableCurrencies: [(code: String, name: String, symbol: String)] = [
        ("USD", "US Dollar", "$"),
        ("EUR", "Euro", "€"),
        ("GBP", "British Pound", "£"),
        ("JPY", "Japanese Yen", "¥"),
        ("CNY", "Chinese Yuan", "¥"),
        ("CAD", "Canadian Dollar", "CA$"),
        ("AUD", "Australian Dollar", "A$"),
        ("CHF", "Swiss Franc", "CHF"),
        ("HKD", "Hong Kong Dollar", "HK$"),
        ("SGD", "Singapore Dollar", "S$"),
        ("KRW", "South Korean Won", "₩"),
        ("INR", "Indian Rupee", "₹"),
        ("MXN", "Mexican Peso", "MX$"),
        ("BRL", "Brazilian Real", "R$"),
        ("SEK", "Swedish Krona", "kr"),
        ("NOK", "Norwegian Krone", "kr"),
        ("DKK", "Danish Krone", "kr"),
        ("NZD", "New Zealand Dollar", "NZ$"),
        ("ZAR", "South African Rand", "R"),
        ("AED", "UAE Dirham", "AED"),
    ]

    func currencySymbol(for code: String) -> String {
        availableCurrencies.first { $0.code == code }?.symbol ?? code
    }
}
