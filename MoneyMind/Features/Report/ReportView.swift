import SwiftUI
import Charts

struct ReportView: View {
    @State private var viewModel = ReportViewModel()
    @AppStorage("currencyCode") private var currencyCode = "USD"

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    periodPicker
                    balanceSummarySection
                    trendChartSection
                    categoryBreakdownSection
                }
                .padding(.horizontal)
                .padding(.bottom, 24)
            }
            .background(Color(.systemGroupedBackground))
            .navigationTitle("Report")
            .navigationBarTitleDisplayMode(.large)
        }
    }

    // MARK: - Period Picker

    private var periodPicker: some View {
        Picker("Period", selection: $viewModel.selectedPeriod) {
            ForEach(ReportPeriod.allCases, id: \.self) { period in
                Text(period.rawValue).tag(period)
            }
        }
        .pickerStyle(.segmented)
        .padding(.top, 4)
    }

    // MARK: - Balance Summary

    private var balanceSummarySection: some View {
        VStack(spacing: 12) {
            HStack {
                Text("Overview")
                    .font(.headline)
                Spacer()
            }

            VStack(spacing: 4) {
                Text(viewModel.selectedPeriod.rawValue.uppercased())
                    .font(.caption2.weight(.semibold))
                    .foregroundStyle(.tertiary)
                    .tracking(1.0)
                Text("Net Balance")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Text(CurrencyFormatter.format(viewModel.balance, currencyCode: currencyCode))
                    .font(.system(size: 28, weight: .bold, design: .rounded))
                    .foregroundStyle(viewModel.balance >= 0 ? .green : .red)
                    .contentTransition(.numericText())
                    .animation(.spring(duration: 0.4), value: viewModel.balance)
                if viewModel.totalIncome > 0 {
                    Text("Savings rate \(Int(viewModel.savingsRate))%")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                        .padding(.top, 2)
                }
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
            .background(
                (viewModel.balance >= 0 ? Color.green : Color.red).opacity(0.08),
                in: RoundedRectangle(cornerRadius: 16, style: .continuous)
            )

            HStack(spacing: 12) {
                MetricCard(
                    title: "Income",
                    value: CurrencyFormatter.format(viewModel.totalIncome, currencyCode: currencyCode),
                    color: .green,
                    icon: "arrow.down.circle.fill"
                )
                MetricCard(
                    title: "Expense",
                    value: CurrencyFormatter.format(viewModel.totalExpense, currencyCode: currencyCode),
                    color: .red,
                    icon: "arrow.up.circle.fill"
                )
                MetricCard(
                    title: "Saved",
                    value: "\(Int(viewModel.savingsRate))%",
                    color: .blue,
                    icon: "chart.line.uptrend.xyaxis"
                )
            }
        }
    }

    // MARK: - Trend Chart

    private var trendChartSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(viewModel.trendSectionTitle)
                .font(.headline)

            Chart {
                ForEach(viewModel.trendData) { data in
                    BarMark(
                        x: .value("Period", data.label),
                        y: .value("Income", data.income),
                        width: .ratio(0.35)
                    )
                    .foregroundStyle(Color.green.gradient)
                    .position(by: .value("Type", "Income"))

                    BarMark(
                        x: .value("Period", data.label),
                        y: .value("Expense", data.expense),
                        width: .ratio(0.35)
                    )
                    .foregroundStyle(Color.red.gradient)
                    .position(by: .value("Type", "Expense"))
                }
            }
            .frame(height: 200)
            .chartLegend(.hidden)
            .chartYAxis {
                AxisMarks(position: .leading) { _ in
                    AxisGridLine(stroke: StrokeStyle(lineWidth: 0.5, dash: [4]))
                        .foregroundStyle(Color(.systemGray4))
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
            .animation(.spring(duration: 0.4), value: viewModel.selectedPeriod)

            HStack(spacing: 16) {
                HStack(spacing: 6) {
                    Circle().fill(Color.green.gradient).frame(width: 8, height: 8)
                    Text("Income").font(.caption2).foregroundStyle(.secondary)
                }
                HStack(spacing: 6) {
                    Circle().fill(Color.red.gradient).frame(width: 8, height: 8)
                    Text("Expense").font(.caption2).foregroundStyle(.secondary)
                }
            }
        }
        .padding(16)
        .background(
            Color(.secondarySystemGroupedBackground),
            in: RoundedRectangle(cornerRadius: 20, style: .continuous)
        )
    }

    // MARK: - Category Breakdown

    private var categoryBreakdownSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("By Category")
                    .font(.headline)
                Spacer()
                Picker("Type", selection: $viewModel.selectedType) {
                    ForEach(TransactionType.allCases, id: \.self) { type in
                        Text(type.displayName).tag(type)
                    }
                }
                .pickerStyle(.segmented)
                .frame(width: 160)
            }

            if viewModel.categoryBreakdown.isEmpty {
                Text("No \(viewModel.selectedType.displayName.lowercased()) data for this period.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding(.vertical, 24)
            } else {
                donutChartSection

                Divider()
                    .padding(.vertical, 4)

                ForEach(viewModel.categoryBreakdown) { item in
                    CategoryBreakdownRow(
                        item: item,
                        currencyCode: currencyCode
                    )
                }
            }
        }
        .padding(16)
        .background(
            Color(.secondarySystemGroupedBackground),
            in: RoundedRectangle(cornerRadius: 20, style: .continuous)
        )
    }

    // MARK: - Donut Chart

    private var donutChartSection: some View {
        let totalAmount = viewModel.selectedType == .expense
            ? viewModel.totalExpense
            : viewModel.totalIncome
        return Chart(viewModel.categoryBreakdown) { item in
            SectorMark(
                angle: .value("Amount", item.amount),
                innerRadius: .ratio(0.6),
                angularInset: 2
            )
            .foregroundStyle(Color(hex: item.categoryColorHex))
            .cornerRadius(5)
        }
        .frame(height: 200)
        .chartLegend(.hidden)
        .overlay {
            VStack(spacing: 2) {
                Text(viewModel.selectedType == .expense ? "Total Spent" : "Total Earned")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
                Text(CurrencyFormatter.format(totalAmount, currencyCode: currencyCode))
                    .font(.callout.weight(.bold))
                    .fontDesign(.rounded)
                    .minimumScaleFactor(0.7)
                    .lineLimit(1)
            }
            .padding(8)
        }
        .animation(.spring(duration: 0.4), value: viewModel.selectedPeriod)
    }
}

// MARK: - Metric Card

struct MetricCard: View {
    let title: String
    let value: String
    let color: Color
    let icon: String
    var fullWidth: Bool = false

    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: icon)
                .foregroundStyle(color)
                .font(.subheadline)

            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Text(value)
                    .font(.subheadline.weight(.bold))
                    .fontDesign(.rounded)
                    .foregroundStyle(color)
                    .lineLimit(1)
                    .minimumScaleFactor(0.6)
            }
            if fullWidth { Spacer() }
        }
        .frame(maxWidth: fullWidth ? .infinity : nil, alignment: .leading)
        .padding(12)
        .background(color.opacity(0.08), in: RoundedRectangle(cornerRadius: 14, style: .continuous))
        .frame(maxWidth: .infinity)
    }
}

// MARK: - Category Breakdown Row

struct CategoryBreakdownRow: View {
    let item: CategorySpending
    let currencyCode: String
    @State private var animatedPercentage: Double = 0

    var body: some View {
        HStack(spacing: 12) {
            ZStack {
                Circle()
                    .fill(Color(hex: item.categoryColorHex).opacity(0.12))
                    .frame(width: 40, height: 40)
                Image(systemName: item.categoryIcon)
                    .foregroundStyle(Color(hex: item.categoryColorHex))
                    .font(.system(size: 16, weight: .semibold))
            }

            VStack(alignment: .leading, spacing: 4) {
                Text(item.categoryName)
                    .font(.subheadline.weight(.medium))

                GeometryReader { geo in
                    ZStack(alignment: .leading) {
                        Capsule()
                            .fill(Color(.systemGray5))
                            .frame(height: 6)
                        Capsule()
                            .fill(Color(hex: item.categoryColorHex).gradient)
                            .frame(
                                width: geo.size.width * animatedPercentage / 100,
                                height: 6
                            )
                    }
                }
                .frame(height: 6)
            }

            Spacer()

            VStack(alignment: .trailing, spacing: 2) {
                Text(CurrencyFormatter.format(item.amount, currencyCode: currencyCode))
                    .font(.subheadline.weight(.semibold))
                    .fontDesign(.rounded)
                Text(String(format: "%.1f%%", item.percentage))
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }
        }
        .padding(.vertical, 4)
        .onAppear {
            withAnimation(.spring(duration: 0.8, bounce: 0.1).delay(0.15)) {
                animatedPercentage = item.percentage
            }
        }
        .onChange(of: item.percentage) { _, newValue in
            withAnimation(.spring(duration: 0.5)) {
                animatedPercentage = newValue
            }
        }
    }
}
