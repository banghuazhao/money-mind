import Foundation

/// Single source of truth for currency codes offered in Settings and for locale-based defaults.
enum CurrencyCatalog {
    /// ISO 4217 codes with display symbols. Heavily used currencies first, then regional coverage.
    nonisolated static let all: [(code: String, name: String, symbol: String)] = [
        ("USD", "US Dollar", "$"),
        ("EUR", "Euro", "€"),
        ("GBP", "British Pound", "£"),
        ("JPY", "Japanese Yen", "¥"),
        ("CNY", "Chinese Yuan", "¥"),
        ("HKD", "Hong Kong Dollar", "HK$"),
        ("SGD", "Singapore Dollar", "S$"),
        ("TWD", "New Taiwan Dollar", "NT$"),
        ("KRW", "South Korean Won", "₩"),
        ("INR", "Indian Rupee", "₹"),
        ("THB", "Thai Baht", "฿"),
        ("MYR", "Malaysian Ringgit", "RM"),
        ("IDR", "Indonesian Rupiah", "Rp"),
        ("PHP", "Philippine Peso", "₱"),
        ("VND", "Vietnamese Dong", "₫"),
        ("PKR", "Pakistani Rupee", "₨"),
        ("BDT", "Bangladeshi Taka", "৳"),
        ("LKR", "Sri Lankan Rupee", "Rs"),
        ("NPR", "Nepalese Rupee", "Rs"),
        ("AUD", "Australian Dollar", "A$"),
        ("NZD", "New Zealand Dollar", "NZ$"),
        ("CAD", "Canadian Dollar", "CA$"),
        ("MXN", "Mexican Peso", "MX$"),
        ("BRL", "Brazilian Real", "R$"),
        ("ARS", "Argentine Peso", "AR$"),
        ("CLP", "Chilean Peso", "CL$"),
        ("COP", "Colombian Peso", "COL$"),
        ("PEN", "Peruvian Sol", "S/"),
        ("UYU", "Uruguayan Peso", "$U"),
        ("CRC", "Costa Rican Colón", "₡"),
        ("DOP", "Dominican Peso", "RD$"),
        ("JMD", "Jamaican Dollar", "J$"),
        ("TTD", "Trinidad & Tobago Dollar", "TT$"),
        ("CHF", "Swiss Franc", "CHF"),
        ("SEK", "Swedish Krona", "kr"),
        ("NOK", "Norwegian Krone", "kr"),
        ("DKK", "Danish Krone", "kr"),
        ("ISK", "Icelandic Króna", "kr"),
        ("PLN", "Polish Złoty", "zł"),
        ("CZK", "Czech Koruna", "Kč"),
        ("HUF", "Hungarian Forint", "Ft"),
        ("RON", "Romanian Leu", "lei"),
        ("BGN", "Bulgarian Lev", "лв"),
        ("RSD", "Serbian Dinar", "дин"),
        ("BAM", "Bosnia-Herzegovina Convertible Mark", "KM"),
        ("MKD", "Macedonian Denar", "ден"),
        ("ALL", "Albanian Lek", "L"),
        ("TRY", "Turkish Lira", "₺"),
        ("RUB", "Russian Ruble", "₽"),
        ("UAH", "Ukrainian Hryvnia", "₴"),
        ("GEL", "Georgian Lari", "₾"),
        ("AMD", "Armenian Dram", "֏"),
        ("AZN", "Azerbaijani Manat", "₼"),
        ("KZT", "Kazakhstani Tenge", "₸"),
        ("UZS", "Uzbekistani Som", "soʻm"),
        ("ILS", "Israeli New Shekel", "₪"),
        ("JOD", "Jordanian Dinar", "JD"),
        ("LBP", "Lebanese Pound", "ل.ل"),
        ("SAR", "Saudi Riyal", "SR"),
        ("AED", "UAE Dirham", "د.إ"),
        ("QAR", "Qatari Riyal", "QR"),
        ("KWD", "Kuwaiti Dinar", "KD"),
        ("BHD", "Bahraini Dinar", "BD"),
        ("OMR", "Omani Rial", "OR"),
        ("IQD", "Iraqi Dinar", "ع.د"),
        ("IRR", "Iranian Rial", "﷼"),
        ("EGP", "Egyptian Pound", "E£"),
        ("MAD", "Moroccan Dirham", "د.م."),
        ("TND", "Tunisian Dinar", "DT"),
        ("DZD", "Algerian Dinar", "د.ج"),
        ("NGN", "Nigerian Naira", "₦"),
        ("GHS", "Ghanaian Cedi", "GH₵"),
        ("KES", "Kenyan Shilling", "KSh"),
        ("UGX", "Ugandan Shilling", "USh"),
        ("TZS", "Tanzanian Shilling", "TSh"),
        ("ETB", "Ethiopian Birr", "Br"),
        ("XAF", "CFA Franc BEAC", "FCFA"),
        ("XOF", "CFA Franc BCEAO", "CFA"),
        ("ZAR", "South African Rand", "R"),
        ("BWP", "Botswana Pula", "P"),
        ("MUR", "Mauritian Rupee", "₨"),
    ]

    nonisolated static var supportedCodes: Set<String> {
        Set(all.map(\.code))
    }

    /// If the user has never chosen a currency, pick the device locale’s code when we support it; otherwise USD.
    nonisolated static func applyLocaleDefaultCurrencyIfNeeded() {
        guard UserDefaults.standard.string(forKey: "currencyCode") == nil else { return }
        let fallback = "USD"
        let preferred = Locale.current.currency?.identifier ?? fallback
        let code = supportedCodes.contains(preferred) ? preferred : fallback
        UserDefaults.standard.set(code, forKey: "currencyCode")
    }
}
