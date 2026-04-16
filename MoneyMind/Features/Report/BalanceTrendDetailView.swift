import SwiftUI
import Charts

struct BalanceTrendDetailView: View {
    let viewModel: ReportViewModel
    let currencyCode: String

    private var accent: Color { viewModel.balance >= 0 ? .green : .red }

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
        .navigationTitle("Balance Trend")
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

            if viewModel.netCurveData.count < 2 {
                ContentUnavailableView {
                    Label("No Data", systemImage: "chart.xyaxis.line")
                } description: {
                    Text("Not enough data for this period.")
                }
                .frame(minHeight: 200)
            } else {
                fullLineChart
            }
        }
        .padding(16)
        .background(Color(.secondarySystemGroupedBackground), in: RoundedRectangle(cornerRadius: 20, style: .continuous))
    }

    @ViewBuilder
    private var fullLineChart: some View {
        let unit: Calendar.Component = {
            switch viewModel.selectedPeriod {
            case .week, .month: return .day
            case .year, .all: return .month
            }
        }()

        Chart(viewModel.netCurveData) { point in
            AreaMark(
                x: .value("Date", point.date, unit: unit),
                yStart: .value("Zero", 0),
                yEnd: .value("Net", point.cumulativeNet)
            )
            .foregroundStyle(
                LinearGradient(
                    colors: [accent.opacity(0.25), accent.opacity(0.03)],
                    startPoint: .top, endPoint: .bottom
                )
            )
            .interpolationMethod(.monotone)

            LineMark(
                x: .value("Date", point.date, unit: unit),
                y: .value("Net", point.cumulativeNet)
            )
            .foregroundStyle(accent)
            .lineStyle(StrokeStyle(lineWidth: 2.5))
            .interpolationMethod(.monotone)

            PointMark(
                x: .value("Date", point.date, unit: unit),
                y: .value("Net", point.cumulativeNet)
            )
            .symbolSize(point.date == viewModel.netCurveData.last?.date ? 40 : 0)
            .foregroundStyle(accent)
        }
        .frame(height: 200)
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
        .animation(.spring(duration: 0.4), value: viewModel.periodOffset)
    }

    // MARK: - Stats Section

    private var statsSection: some View {
        let data = viewModel.netCurveData
        let peakBalance = data.max(by: { $0.cumulativeNet < $1.cumulativeNet })
        let lowestBalance = data.min(by: { $0.cumulativeNet < $1.cumulativeNet })
        let currentBalance = data.last

        return VStack(spacing: 1) {
            balanceStat(
                icon: "equal.circle.fill",
                iconColor: viewModel.balance >= 0 ? .green : .red,
                title: "Current Balance",
                value: formatSigned(currentBalance?.cumulativeNet ?? 0),
                valueColor: viewModel.balance >= 0 ? .green : .red
            )

            Divider().padding(.leading, 52)

            if let peak = peakBalance {
                balanceStat(
                    icon: "arrow.up.right.circle.fill",
                    iconColor: .green,
                    title: "Highest Balance",
                    value: formatSigned(peak.cumulativeNet),
                    valueColor: .green
                )
                Divider().padding(.leading, 52)
            }

            if let lowest = lowestBalance {
                balanceStat(
                    icon: "arrow.down.right.circle.fill",
                    iconColor: .red,
                    title: "Lowest Balance",
                    value: formatSigned(lowest.cumulativeNet),
                    valueColor: .red
                )
                Divider().padding(.leading, 52)
            }

            balanceStat(
                icon: "arrow.down.circle.fill", iconColor: .green,
                title: "Total Income",
                value: CurrencyFormatter.format(viewModel.totalIncome, currencyCode: currencyCode),
                valueColor: .green
            )
            Divider().padding(.leading, 52)

            balanceStat(
                icon: "arrow.up.circle.fill", iconColor: .red,
                title: "Total Expense",
                value: CurrencyFormatter.format(viewModel.totalExpense, currencyCode: currencyCode),
                valueColor: .red
            )
        }
        .padding(16)
        .background(Color(.secondarySystemGroupedBackground), in: RoundedRectangle(cornerRadius: 20, style: .continuous))
    }

    private func balanceStat(icon: String, iconColor: Color, title: String, value: String, valueColor: Color) -> some View {
        HStack {
            Label(title, systemImage: icon)
                .foregroundStyle(iconColor)
            Spacer()
            Text(value)
                .font(.body.weight(.semibold))
                .fontDesign(.rounded)
                .foregroundStyle(valueColor)
        }
        .padding(.vertical, 4)
    }

    // MARK: - Helpers

    private func formatSigned(_ value: Double) -> String {
        let prefix = value > 0 ? "+" : (value < 0 ? "-" : "")
        return "\(prefix)\(CurrencyFormatter.format(abs(value), currencyCode: currencyCode))"
    }

    // MARK: - Export

    private var exportText: String {
        let dateFormatter = DateFormatter()
        dateFormatter.dateStyle = .short
        dateFormatter.timeStyle = .none

        var lines: [String] = []
        lines.append("MoneyMind — Balance Trend")
        lines.append("Period: \(viewModel.periodDisplayLabel)")
        lines.append(String(repeating: "─", count: 36))

        for point in viewModel.netCurveData {
            let dateStr = dateFormatter.string(from: point.date)
            let balStr = formatSigned(point.cumulativeNet)
            lines.append("\(dateStr.padding(toLength: 10, withPad: " ", startingAt: 0))  \(balStr)")
        }

        lines.append(String(repeating: "─", count: 36))
        lines.append("Final Balance: \(formatSigned(viewModel.balance))")
        lines.append("Income:        \(CurrencyFormatter.format(viewModel.totalIncome, currencyCode: currencyCode))")
        lines.append("Expense:       \(CurrencyFormatter.format(viewModel.totalExpense, currencyCode: currencyCode))")
        return lines.joined(separator: "\n")
    }
}
