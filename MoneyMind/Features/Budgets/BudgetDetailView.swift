import SwiftUI

struct BudgetDetailView: View {
    let progress: BudgetProgress
    let transactions: [Transaction]
    let monthLabel: String
    let daysRemaining: Int
    let isCurrentMonth: Bool
    let currencyCode: String

    private var categoryColor: Color {
        guard let hex = progress.category?.colorHex else { return .gray }
        return Color(hex: hex)
    }

    private var statusColor: Color {
        switch progress.status {
        case .healthy: return .green
        case .warning: return .orange
        case .overspent: return .red
        }
    }

    private var dailyRemaining: Double {
        guard isCurrentMonth, daysRemaining > 0, progress.remaining > 0 else { return 0 }
        return progress.remaining / Double(daysRemaining)
    }

    private var averagePerTransaction: Double {
        guard !transactions.isEmpty else { return 0 }
        return progress.spent / Double(transactions.count)
    }

    private var groupedTransactions: [(String, [Transaction])] {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .none

        let grouped = Dictionary(grouping: transactions) { formatter.string(from: $0.date) }
        return grouped.sorted { lhs, rhs in
            guard let ld = lhs.value.first?.date, let rd = rhs.value.first?.date else { return false }
            return ld > rd
        }
    }

    var body: some View {
        List {
            headerSection
                .listRowInsets(EdgeInsets())
                .listRowBackground(Color.clear)
                .listRowSeparator(.hidden)

            statsSection

            transactionListSection
        }
        .listStyle(.insetGrouped)
        .background(Color(.systemGroupedBackground))
        .navigationTitle(progress.category?.name ?? "Budget")
        .navigationBarTitleDisplayMode(.inline)
    }

    // MARK: - Header

    private var headerSection: some View {
        VStack(spacing: 16) {
            BudgetRing(percentage: progress.percentage, color: statusColor, size: 150) {
                VStack(spacing: 2) {
                    Image(systemName: progress.category?.icon ?? "questionmark.circle")
                        .font(.title3)
                        .foregroundStyle(categoryColor)
                    Text("\(Int(progress.percentage))%")
                        .font(.system(size: 26, weight: .bold, design: .rounded))
                        .foregroundStyle(statusColor)
                    Text("used")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }
            }

            VStack(spacing: 4) {
                Text("\(CurrencyFormatter.format(progress.spent, currencyCode: currencyCode)) of \(CurrencyFormatter.format(progress.amount, currencyCode: currencyCode))")
                    .font(.subheadline.weight(.medium))
                    .foregroundStyle(.secondary)
                Text(monthLabel)
                    .font(.caption)
                    .foregroundStyle(.tertiary)
            }

            statusBanner
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 12)
    }

    @ViewBuilder
    private var statusBanner: some View {
        switch progress.status {
        case .healthy:
            banner(
                icon: "checkmark.circle.fill",
                color: .green,
                title: "On Track",
                subtitle: "\(CurrencyFormatter.format(progress.remaining, currencyCode: currencyCode)) remaining"
            )
        case .warning:
            banner(
                icon: "exclamationmark.triangle.fill",
                color: .orange,
                title: "Approaching Limit",
                subtitle: "\(CurrencyFormatter.format(progress.remaining, currencyCode: currencyCode)) left"
            )
        case .overspent:
            banner(
                icon: "exclamationmark.octagon.fill",
                color: .red,
                title: "Over Budget",
                subtitle: "Exceeded by \(CurrencyFormatter.format(progress.overspent, currencyCode: currencyCode))"
            )
        }
    }

    private func banner(icon: String, color: Color, title: String, subtitle: String) -> some View {
        HStack(spacing: 10) {
            Image(systemName: icon)
                .foregroundStyle(color)
                .font(.body)
            VStack(alignment: .leading, spacing: 1) {
                Text(title)
                    .font(.subheadline.weight(.semibold))
                Text(subtitle)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            Spacer()
        }
        .padding(12)
        .background(color.opacity(0.1), in: RoundedRectangle(cornerRadius: 12, style: .continuous))
        .padding(.horizontal, 16)
    }

    // MARK: - Stats Section

    private var statsSection: some View {
        Section {
            statRow(
                icon: "dollarsign.circle.fill",
                iconColor: .blue,
                title: "Monthly Limit",
                value: CurrencyFormatter.format(progress.amount, currencyCode: currencyCode),
                valueColor: .primary
            )
            statRow(
                icon: progress.status == .overspent ? "exclamationmark.octagon.fill" : "checkmark.circle.fill",
                iconColor: statusColor,
                title: progress.status == .overspent ? "Overspent" : "Remaining",
                value: progress.status == .overspent
                    ? CurrencyFormatter.format(progress.overspent, currencyCode: currencyCode)
                    : CurrencyFormatter.format(progress.remaining, currencyCode: currencyCode),
                valueColor: statusColor
            )

            if isCurrentMonth && daysRemaining > 0 {
                statRow(
                    icon: "calendar",
                    iconColor: .purple,
                    title: "Days Left in Month",
                    value: "\(daysRemaining)",
                    valueColor: .purple
                )

                if dailyRemaining > 0 {
                    statRow(
                        icon: "chart.line.flattrend.xyaxis",
                        iconColor: .teal,
                        title: "Daily Remaining",
                        value: CurrencyFormatter.format(dailyRemaining, currencyCode: currencyCode),
                        valueColor: .teal
                    )
                }
            }

            if !transactions.isEmpty {
                statRow(
                    icon: "number.circle.fill",
                    iconColor: .indigo,
                    title: "Transactions",
                    value: "\(transactions.count)",
                    valueColor: .indigo
                )

                statRow(
                    icon: "arrow.left.arrow.right.circle.fill",
                    iconColor: .orange,
                    title: "Avg Transaction",
                    value: CurrencyFormatter.format(averagePerTransaction, currencyCode: currencyCode),
                    valueColor: .orange
                )
            }
        } header: {
            Text("Breakdown")
                .font(.footnote.weight(.semibold))
                .foregroundStyle(.secondary)
                .textCase(nil)
        }
    }

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

    // MARK: - Transaction List

    @ViewBuilder
    private var transactionListSection: some View {
        if transactions.isEmpty {
            Section {
                ContentUnavailableView {
                    Label("No Transactions Yet", systemImage: "tray")
                } description: {
                    Text("Transactions in this category will appear here.")
                }
            }
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
                Text(transaction.note.isEmpty ? (progress.category?.name ?? "Expense") : transaction.note)
                    .font(.subheadline.weight(.medium))
                    .foregroundStyle(transaction.note.isEmpty ? .secondary : .primary)
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
