import SwiftUI

struct ReportSummaryDetailView: View {
    let viewModel: ReportViewModel
    let currencyCode: String

    var body: some View {
        List {
            overviewSection
            analysisSection
        }
        .listStyle(.insetGrouped)
        .background(Color(.systemGroupedBackground))
        .navigationTitle("Summary")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                ShareLink(item: exportText) {
                    Image(systemName: "square.and.arrow.up")
                }
            }
        }
    }

    // MARK: - Overview Section

    private var overviewSection: some View {
        Section("Overview") {
            statRow(
                icon: "arrow.down.circle.fill",
                iconColor: .green,
                title: "Income",
                value: CurrencyFormatter.format(viewModel.totalIncome, currencyCode: currencyCode),
                valueColor: .green
            )
            statRow(
                icon: "arrow.up.circle.fill",
                iconColor: .red,
                title: "Expense",
                value: CurrencyFormatter.format(viewModel.totalExpense, currencyCode: currencyCode),
                valueColor: .red
            )

            HStack {
                Label("Net Balance", systemImage: "equal.circle.fill")
                    .foregroundStyle(viewModel.balance >= 0 ? .green : .red)
                Spacer()
                Text(formatSigned(viewModel.balance))
                    .font(.body.weight(.semibold))
                    .fontDesign(.rounded)
                    .foregroundStyle(viewModel.balance >= 0 ? .green : .red)
            }
        }
    }

    // MARK: - Analysis Section

    private var analysisSection: some View {
        Section("Analysis") {
            if viewModel.totalIncome > 0 {
                statRow(
                    icon: "percent",
                    iconColor: .blue,
                    title: "Savings Rate",
                    value: String(format: "%.1f%%", viewModel.savingsRate),
                    valueColor: .blue
                )
            }

            statRow(
                icon: "calendar.day.timeline.left",
                iconColor: .orange,
                title: "Daily Avg Expense",
                value: CurrencyFormatter.format(viewModel.dailyAverage, currencyCode: currencyCode),
                valueColor: .orange
            )

            statRow(
                icon: "list.number",
                iconColor: .purple,
                title: "Transactions",
                value: "\(viewModel.transactionCount)",
                valueColor: .purple
            )

            if viewModel.transactionCount > 0 {
                statRow(
                    icon: "arrow.left.arrow.right.circle.fill",
                    iconColor: .indigo,
                    title: "Avg Transaction",
                    value: CurrencyFormatter.format(viewModel.totalExpense / max(1, Double(viewModel.transactionCount)), currencyCode: currencyCode),
                    valueColor: .indigo
                )
            }
        }
    }

    // MARK: - Helpers

    private func statRow(icon: String, iconColor: Color, title: String, value: String, valueColor: Color) -> some View {
        HStack {
            Label(title, systemImage: icon)
                .foregroundStyle(iconColor)
            Spacer()
            Text(value)
                .font(.body.weight(.semibold))
                .fontDesign(.rounded)
                .foregroundStyle(valueColor)
        }
    }

    private func formatSigned(_ value: Double) -> String {
        let prefix = value > 0 ? "+" : (value < 0 ? "-" : "")
        return "\(prefix)\(CurrencyFormatter.format(abs(value), currencyCode: currencyCode))"
    }

    // MARK: - Export

    private var exportText: String {
        var lines: [String] = []
        lines.append("MoneyMind — Summary Report")
        lines.append("Period: \(viewModel.periodDisplayLabel)")
        lines.append(String(repeating: "─", count: 36))
        lines.append("Income:       \(CurrencyFormatter.format(viewModel.totalIncome, currencyCode: currencyCode))")
        lines.append("Expense:      \(CurrencyFormatter.format(viewModel.totalExpense, currencyCode: currencyCode))")
        lines.append("Net Balance:  \(formatSigned(viewModel.balance))")
        lines.append(String(repeating: "─", count: 36))
        if viewModel.totalIncome > 0 {
            lines.append("Savings Rate: \(String(format: "%.1f%%", viewModel.savingsRate))")
        }
        lines.append("Daily Avg Expense: \(CurrencyFormatter.format(viewModel.dailyAverage, currencyCode: currencyCode))")
        lines.append("Total Transactions: \(viewModel.transactionCount)")
        return lines.joined(separator: "\n")
    }
}
