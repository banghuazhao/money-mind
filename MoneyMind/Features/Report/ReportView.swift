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
                    balanceTrendCard
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

    // MARK: - Balance Trend Card (replaces static overview)

    private var balanceTrendCard: some View {
        let isPositive = viewModel.balance >= 0
        let accentColor: Color = isPositive ? .green : .red

        return VStack(alignment: .leading, spacing: 14) {
            // Header row: title + headline number
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 2) {
                    Text("Balance Trend")
                        .font(.headline)
                    Text(viewModel.selectedPeriod.rawValue)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                Spacer()
                VStack(alignment: .trailing, spacing: 2) {
                    Text(CurrencyFormatter.format(abs(viewModel.balance), currencyCode: currencyCode))
                        .font(.title3.weight(.bold))
                        .fontDesign(.rounded)
                        .foregroundStyle(accentColor)
                        .contentTransition(.numericText())
                        .animation(.spring(duration: 0.4), value: viewModel.balance)
                    Text(isPositive ? "Net Positive" : "Net Negative")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }
            }

            // Line chart
            if viewModel.netCurveData.count < 2 {
                Text("Not enough data for this period yet.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity, minHeight: 120, alignment: .center)
            } else {
                cumulativeLineChart(accentColor: accentColor)
            }

            // Compact stats row
            HStack(spacing: 0) {
                compactStat(
                    title: "Income",
                    value: CurrencyFormatter.format(viewModel.totalIncome, currencyCode: currencyCode),
                    color: .green
                )
                Rectangle().fill(Color(.separator)).frame(width: 0.5, height: 32)
                compactStat(
                    title: "Expense",
                    value: CurrencyFormatter.format(viewModel.totalExpense, currencyCode: currencyCode),
                    color: .red
                )
                if viewModel.totalIncome > 0 {
                    Rectangle().fill(Color(.separator)).frame(width: 0.5, height: 32)
                    compactStat(
                        title: "Saved",
                        value: "\(Int(viewModel.savingsRate))%",
                        color: .blue
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

    @ViewBuilder
    private func cumulativeLineChart(accentColor: Color) -> some View {
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
                    colors: [accentColor.opacity(0.25), accentColor.opacity(0.04)],
                    startPoint: .top,
                    endPoint: .bottom
                )
            )
            .interpolationMethod(.monotone)

            LineMark(
                x: .value("Date", point.date, unit: unit),
                y: .value("Net", point.cumulativeNet)
            )
            .foregroundStyle(accentColor)
            .lineStyle(StrokeStyle(lineWidth: 2))
            .interpolationMethod(.monotone)
        }
        .frame(height: 130)
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
        .animation(.spring(duration: 0.4), value: viewModel.selectedPeriod)
    }

    private func compactStat(title: String, value: String, color: Color) -> some View {
        VStack(spacing: 2) {
            Text(title)
                .font(.caption2)
                .foregroundStyle(.secondary)
            Text(value)
                .font(.subheadline.weight(.semibold))
                .fontDesign(.rounded)
                .foregroundStyle(color)
                .lineLimit(1)
                .minimumScaleFactor(0.65)
        }
        .frame(maxWidth: .infinity)
    }

    // MARK: - Trend Bar Chart

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
                    CategoryBreakdownRow(item: item, currencyCode: currencyCode)
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
                            .frame(width: geo.size.width * animatedPercentage / 100, height: 6)
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
