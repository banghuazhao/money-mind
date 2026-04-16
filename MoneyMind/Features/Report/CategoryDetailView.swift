import SwiftUI
import Charts

struct CategoryDetailView: View {
    let category: CategorySpending
    let transactions: [Transaction]
    let periodLabel: String
    let currencyCode: String

    private var groupedTransactions: [(String, [Transaction])] {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .none

        let grouped = Dictionary(grouping: transactions) { t in
            formatter.string(from: t.date)
        }
        return grouped
            .sorted { lhs, rhs in
                guard let ld = lhs.value.first?.date, let rd = rhs.value.first?.date else { return false }
                return ld > rd
            }
    }

    private var averagePerTransaction: Double {
        guard !transactions.isEmpty else { return 0 }
        return category.amount / Double(transactions.count)
    }

    private var dailySpending: [BalancePoint] {
        let calendar = Calendar.current
        let grouped = Dictionary(grouping: transactions) { t in
            calendar.dateComponents([.year, .month, .day], from: t.date)
        }
        return grouped.compactMap { (comps, txns) -> BalancePoint? in
            guard let date = calendar.date(from: comps) else { return nil }
            return BalancePoint(date: date, cumulativeNet: txns.reduce(0) { $0 + $1.amount })
        }
        .sorted { $0.date < $1.date }
    }

    private var categoryColor: Color { Color(hex: category.categoryColorHex) }

    var body: some View {
        List {
            headerSection
                .listRowInsets(EdgeInsets())
                .listRowBackground(Color.clear)
                .listRowSeparator(.hidden)

            if dailySpending.count >= 2 {
                miniChartSection
            }

            transactionListSection
        }
        .listStyle(.insetGrouped)
        .background(Color(.systemGroupedBackground))
        .navigationTitle(category.categoryName)
        .navigationBarTitleDisplayMode(.inline)
    }

    // MARK: - Header

    private var headerSection: some View {
        VStack(spacing: 16) {
            ZStack {
                Circle()
                    .fill(categoryColor.opacity(0.15))
                    .frame(width: 72, height: 72)
                Image(systemName: category.categoryIcon)
                    .font(.system(size: 30, weight: .semibold))
                    .foregroundStyle(categoryColor)
            }

            VStack(spacing: 4) {
                Text(CurrencyFormatter.format(category.amount, currencyCode: currencyCode))
                    .font(.system(size: 28, weight: .bold, design: .rounded))

                Text(periodLabel)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            HStack(spacing: 0) {
                statPill(title: "Share", value: String(format: "%.1f%%", category.percentage))
                Rectangle().fill(Color(.separator)).frame(width: 0.5, height: 28)
                statPill(title: "Count", value: "\(category.transactionCount)")
                Rectangle().fill(Color(.separator)).frame(width: 0.5, height: 28)
                statPill(title: "Avg", value: CurrencyFormatter.format(averagePerTransaction, currencyCode: currencyCode))
            }
            .padding(12)
            .background(Color(.secondarySystemGroupedBackground), in: RoundedRectangle(cornerRadius: 14, style: .continuous))
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 8)
    }

    private func statPill(title: String, value: String) -> some View {
        VStack(spacing: 2) {
            Text(title)
                .font(.caption2)
                .foregroundStyle(.secondary)
            Text(value)
                .font(.caption.weight(.semibold))
                .fontDesign(.rounded)
                .lineLimit(1)
                .minimumScaleFactor(0.6)
        }
        .frame(maxWidth: .infinity)
    }

    // MARK: - Mini Chart

    private var miniChartSection: some View {
        Section {
            Chart(dailySpending) { point in
                BarMark(
                    x: .value("Date", point.date, unit: .day),
                    y: .value("Amount", point.cumulativeNet)
                )
                .foregroundStyle(categoryColor.gradient)
                .cornerRadius(3)
            }
            .frame(height: 120)
            .chartYAxis {
                AxisMarks(position: .leading) { _ in
                    AxisGridLine(stroke: StrokeStyle(lineWidth: 0.5, dash: [4]))
                        .foregroundStyle(Color(.systemGray5))
                    AxisValueLabel()
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }
            }
            .chartXAxis {
                AxisMarks { _ in
                    AxisValueLabel()
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }
            }
            .padding(.vertical, 4)
        } header: {
            Text("Spending Over Time")
                .font(.footnote.weight(.semibold))
                .foregroundStyle(.secondary)
                .textCase(nil)
        }
    }

    // MARK: - Transaction List

    @ViewBuilder
    private var transactionListSection: some View {
        if transactions.isEmpty {
            ContentUnavailableView {
                Label("No Transactions", systemImage: "tray")
            }
            .listRowBackground(Color.clear)
        } else {
            ForEach(groupedTransactions, id: \.0) { dateString, txns in
                Section {
                    ForEach(txns) { transaction in
                        transactionRow(transaction)
                    }
                } header: {
                    Text(dateString)
                        .font(.footnote.weight(.semibold))
                        .foregroundStyle(.secondary)
                        .textCase(nil)
                }
            }
        }
    }

    private func transactionRow(_ transaction: Transaction) -> some View {
        HStack(spacing: 12) {
            VStack(alignment: .leading, spacing: 3) {
                if !transaction.note.isEmpty {
                    Text(transaction.note)
                        .font(.subheadline.weight(.medium))
                } else {
                    Text(category.categoryName)
                        .font(.subheadline.weight(.medium))
                        .foregroundStyle(.secondary)
                }
                Text(transaction.date, style: .time)
                    .font(.caption2)
                    .foregroundStyle(.tertiary)
            }

            Spacer()

            Text(CurrencyFormatter.format(transaction.amount, currencyCode: currencyCode))
                .font(.subheadline.weight(.semibold))
                .fontDesign(.rounded)
                .foregroundStyle(categoryColor)
        }
        .padding(.vertical, 2)
    }
}
