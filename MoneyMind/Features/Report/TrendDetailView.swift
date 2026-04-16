import SwiftUI
import Charts

struct TrendDetailView: View {
    let viewModel: ReportViewModel
    let currencyCode: String

    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                chartSection
                    .padding(.horizontal)

                statsSection
                    .padding(.horizontal)
            }
            .padding(.vertical, 16)
            .padding(.bottom, 24)
        }
        .background(Color(.systemGroupedBackground))
        .navigationTitle(viewModel.trendSectionTitle)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                ShareLink(item: exportText) {
                    Image(systemName: "square.and.arrow.up")
                }
            }
        }
    }

    // MARK: - Chart Section

    private var chartSection: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text(viewModel.periodDisplayLabel)
                .font(.caption)
                .foregroundStyle(.secondary)

            if viewModel.trendData.allSatisfy({ $0.income == 0 && $0.expense == 0 }) {
                ContentUnavailableView {
                    Label("No Data", systemImage: "chart.bar")
                } description: {
                    Text("Not enough data to show a trend.")
                }
                .frame(minHeight: 200)
            } else {
                Chart {
                    ForEach(viewModel.trendData) { data in
                        BarMark(
                            x: .value("Period", data.label),
                            y: .value("Income", data.income),
                            width: .ratio(0.35)
                        )
                        .foregroundStyle(Color.green.gradient)
                        .position(by: .value("Type", "Income"))
                        .cornerRadius(4)

                        BarMark(
                            x: .value("Period", data.label),
                            y: .value("Expense", data.expense),
                            width: .ratio(0.35)
                        )
                        .foregroundStyle(Color.red.gradient)
                        .position(by: .value("Type", "Expense"))
                        .cornerRadius(4)
                    }
                }
                .frame(height: 220)
                .chartLegend(.hidden)
                .chartYAxis {
                    AxisMarks(position: .leading) { _ in
                        AxisGridLine(stroke: StrokeStyle(lineWidth: 0.5, dash: [4]))
                            .foregroundStyle(Color(.systemGray5))
                        AxisValueLabel().font(.caption2).foregroundStyle(.secondary)
                    }
                }
                .chartXAxis {
                    AxisMarks { _ in
                        AxisValueLabel().font(.caption2).foregroundStyle(.secondary)
                    }
                }

                HStack(spacing: 20) {
                    legendDot(color: .green, label: "Income")
                    legendDot(color: .red, label: "Expense")
                    Spacer()
                }
            }
        }
        .padding(16)
        .background(Color(.secondarySystemGroupedBackground), in: RoundedRectangle(cornerRadius: 20, style: .continuous))
    }

    // MARK: - Stats Section

    private var statsSection: some View {
        let totalIncome = viewModel.trendData.reduce(0) { $0 + $1.income }
        let totalExpense = viewModel.trendData.reduce(0) { $0 + $1.expense }
        let peakIncome = viewModel.trendData.max(by: { $0.income < $1.income })
        let peakExpense = viewModel.trendData.max(by: { $0.expense < $1.expense })

        return VStack(spacing: 1) {
            statRow(
                icon: "arrow.down.circle.fill", iconColor: .green,
                title: "Total Income",
                value: CurrencyFormatter.format(totalIncome, currencyCode: currencyCode),
                valueColor: .green
            )
            Divider().padding(.leading, 52)

            statRow(
                icon: "arrow.up.circle.fill", iconColor: .red,
                title: "Total Expense",
                value: CurrencyFormatter.format(totalExpense, currencyCode: currencyCode),
                valueColor: .red
            )
            Divider().padding(.leading, 52)

            if let peak = peakIncome, peak.income > 0 {
                statRow(
                    icon: "chart.line.uptrend.xyaxis", iconColor: .green,
                    title: "Peak Income",
                    value: "\(peak.label)  \(CurrencyFormatter.format(peak.income, currencyCode: currencyCode))",
                    valueColor: .green
                )
                Divider().padding(.leading, 52)
            }

            if let peak = peakExpense, peak.expense > 0 {
                statRow(
                    icon: "chart.line.downtrend.xyaxis", iconColor: .red,
                    title: "Peak Expense",
                    value: "\(peak.label)  \(CurrencyFormatter.format(peak.expense, currencyCode: currencyCode))",
                    valueColor: .red
                )
            }
        }
        .padding(16)
        .background(Color(.secondarySystemGroupedBackground), in: RoundedRectangle(cornerRadius: 20, style: .continuous))
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
                .lineLimit(1)
                .minimumScaleFactor(0.7)
        }
        .padding(.vertical, 4)
    }

    private func legendDot(color: Color, label: String) -> some View {
        HStack(spacing: 6) {
            Circle().fill(color.gradient).frame(width: 8, height: 8)
            Text(label).font(.caption2).foregroundStyle(.secondary)
        }
    }

    // MARK: - Export

    private var exportText: String {
        var lines: [String] = []
        lines.append("MoneyMind — \(viewModel.trendSectionTitle)")
        lines.append("Period: \(viewModel.periodDisplayLabel)")
        lines.append(String(repeating: "─", count: 44))

        let labelWidth = viewModel.trendData.map { $0.label.count }.max() ?? 6
        for point in viewModel.trendData {
            let label = point.label.padding(toLength: max(labelWidth, 6), withPad: " ", startingAt: 0)
            let income = CurrencyFormatter.format(point.income, currencyCode: currencyCode)
            let expense = CurrencyFormatter.format(point.expense, currencyCode: currencyCode)
            lines.append("\(label)  ↓ \(income)  ↑ \(expense)")
        }

        lines.append(String(repeating: "─", count: 44))
        let totalIncome = viewModel.trendData.reduce(0) { $0 + $1.income }
        let totalExpense = viewModel.trendData.reduce(0) { $0 + $1.expense }
        lines.append("Total Income:  \(CurrencyFormatter.format(totalIncome, currencyCode: currencyCode))")
        lines.append("Total Expense: \(CurrencyFormatter.format(totalExpense, currencyCode: currencyCode))")
        return lines.joined(separator: "\n")
    }
}
