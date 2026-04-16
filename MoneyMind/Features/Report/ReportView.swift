import SwiftUI
import Charts

struct ReportView: View {
    @State private var viewModel = ReportViewModel()
    @AppStorage("currencyCode") private var currencyCode = "USD"
    @State private var chartAngle: Double?

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 16) {
                    periodSelector
                    summaryCard
                    categoryBreakdownSection
                    trendChartSection
                    balanceTrendCard
                }
                .padding(.horizontal)
                .padding(.bottom, 24)
            }
            .background(Color(.systemGroupedBackground))
            .navigationTitle("Report")
            .navigationBarTitleDisplayMode(.large)
            .sensoryFeedback(.impact(flexibility: .soft), trigger: viewModel.periodOffset)
        }
    }

    // MARK: - Period Selector

    private var periodSelector: some View {
        VStack(spacing: 12) {
            Picker("Period", selection: $viewModel.selectedPeriod) {
                ForEach(ReportPeriod.allCases, id: \.self) { period in
                    Text(period.rawValue).tag(period)
                }
            }
            .pickerStyle(.segmented)

            if viewModel.canNavigate {
                periodNavigationBar
            }
        }
        .padding(.top, 4)
    }

    private var periodNavigationBar: some View {
        HStack {
            Button {
                withAnimation(.spring(duration: 0.35)) { viewModel.previousPeriod() }
            } label: {
                Image(systemName: "chevron.left")
                    .font(.body.weight(.semibold))
//                    .foregroundStyle(.accentColor)
                    .frame(width: 36, height: 36)
                    .contentShape(Rectangle())
            }

            Spacer()

            Text(viewModel.periodDisplayLabel)
                .font(.subheadline.weight(.semibold))
                .contentTransition(.numericText())
                .animation(.spring(duration: 0.3), value: viewModel.periodOffset)

            Spacer()

            Button {
                withAnimation(.spring(duration: 0.35)) { viewModel.nextPeriod() }
            } label: {
                Image(systemName: "chevron.right")
                    .font(.body.weight(.semibold))
                    .foregroundStyle(viewModel.canGoForward ? .accentColor : Color(.systemGray4))
                    .frame(width: 36, height: 36)
                    .contentShape(Rectangle())
            }
            .disabled(!viewModel.canGoForward)
        }
        .padding(.horizontal, 4)
    }

    // MARK: - Summary Card

    private var summaryCard: some View {
        let isPositive = viewModel.balance >= 0

        return VStack(spacing: 16) {
            // Balance headline
            VStack(spacing: 2) {
                Text(formatSigned(viewModel.balance))
                    .font(.system(size: 32, weight: .bold, design: .rounded))
                    .foregroundStyle(isPositive ? .green : .red)
                    .contentTransition(.numericText(value: viewModel.balance))
                    .animation(.spring(duration: 0.4), value: viewModel.balance)

                Text("Net Balance")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            .frame(maxWidth: .infinity)

            Divider()

            // Income / Expense comparison bars
            incomeExpenseComparison

            Divider()

            // Stats row
            HStack(spacing: 0) {
                if viewModel.totalIncome > 0 {
                    miniStat(title: "Saved", value: "\(Int(viewModel.savingsRate))%", color: .blue)
                    Rectangle().fill(Color(.separator)).frame(width: 0.5, height: 28)
                }
                miniStat(
                    title: "Daily Avg",
                    value: CurrencyFormatter.format(viewModel.dailyAverage, currencyCode: currencyCode),
                    color: .orange
                )
                Rectangle().fill(Color(.separator)).frame(width: 0.5, height: 28)
                miniStat(title: "Transactions", value: "\(viewModel.transactionCount)", color: .purple)
            }
        }
        .padding(16)
        .background(Color(.secondarySystemGroupedBackground), in: RoundedRectangle(cornerRadius: 20, style: .continuous))
    }

    private var incomeExpenseComparison: some View {
        let maxAmount = max(viewModel.totalIncome, viewModel.totalExpense, 1)

        return VStack(spacing: 10) {
            comparisonRow(
                icon: "arrow.down.circle.fill",
                label: "Income",
                amount: viewModel.totalIncome,
                ratio: viewModel.totalIncome / maxAmount,
                color: .green
            )
            comparisonRow(
                icon: "arrow.up.circle.fill",
                label: "Expense",
                amount: viewModel.totalExpense,
                ratio: viewModel.totalExpense / maxAmount,
                color: .red
            )
        }
    }

    private func comparisonRow(
        icon: String, label: String, amount: Double, ratio: Double, color: Color
    ) -> some View {
        VStack(spacing: 6) {
            HStack {
                Image(systemName: icon)
                    .font(.caption)
                    .foregroundStyle(color)
                Text(label)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Spacer()
                Text(CurrencyFormatter.format(amount, currencyCode: currencyCode))
                    .font(.subheadline.weight(.semibold))
                    .fontDesign(.rounded)
                    .foregroundStyle(color)
                    .contentTransition(.numericText(value: amount))
                    .animation(.spring(duration: 0.4), value: amount)
            }

            GeometryReader { geo in
                Capsule()
                    .fill(color.opacity(0.15))
                    .overlay(alignment: .leading) {
                        Capsule()
                            .fill(color.gradient)
                            .frame(width: geo.size.width * max(ratio, 0.02))
                    }
            }
            .frame(height: 8)
            .clipShape(Capsule())
            .animation(.spring(duration: 0.6), value: ratio)
        }
    }

    private func miniStat(title: String, value: String, color: Color) -> some View {
        VStack(spacing: 2) {
            Text(title)
                .font(.caption2)
                .foregroundStyle(.secondary)
            Text(value)
                .font(.caption.weight(.semibold))
                .fontDesign(.rounded)
                .foregroundStyle(color)
                .lineLimit(1)
                .minimumScaleFactor(0.6)
        }
        .frame(maxWidth: .infinity)
    }

    // MARK: - Category Breakdown

    private var categoryBreakdownSection: some View {
        VStack(alignment: .leading, spacing: 14) {
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
                ContentUnavailableView {
                    Label("No Data", systemImage: "chart.pie")
                } description: {
                    Text("No \(viewModel.selectedType.displayName.lowercased()) recorded for this period.")
                }
                .frame(minHeight: 200)
            } else {
                interactiveDonutChart
                    .padding(.vertical, 4)

                Divider()

                categoryList
            }
        }
        .padding(16)
        .background(Color(.secondarySystemGroupedBackground), in: RoundedRectangle(cornerRadius: 20, style: .continuous))
        .animation(.spring(duration: 0.4), value: viewModel.selectedType)
    }

    // MARK: - Interactive Donut Chart

    private var interactiveDonutChart: some View {
        let totalAmount = viewModel.selectedType == .expense
            ? viewModel.totalExpense
            : viewModel.totalIncome
        let selected = viewModel.selectedCategory

        return Chart(viewModel.categoryBreakdown) { item in
            SectorMark(
                angle: .value("Amount", item.amount),
                innerRadius: .ratio(0.58),
                outerRadius: .ratio(item.categoryId == viewModel.selectedCategoryId ? 1.0 : 0.92),
                angularInset: 2
            )
            .foregroundStyle(Color(hex: item.categoryColorHex))
            .cornerRadius(5)
            .opacity(viewModel.selectedCategoryId == nil || item.categoryId == viewModel.selectedCategoryId ? 1 : 0.4)
        }
        .chartAngleSelection(value: $chartAngle)
        .onChange(of: chartAngle) { _, newValue in
            withAnimation(.spring(duration: 0.3)) {
                if let angle = newValue, let cat = viewModel.findCategory(byAngleValue: angle) {
                    viewModel.selectedCategoryId = cat.categoryId == viewModel.selectedCategoryId ? nil : cat.categoryId
                } else {
                    viewModel.selectedCategoryId = nil
                }
            }
        }
        .frame(height: 220)
        .chartLegend(.hidden)
        .overlay {
            VStack(spacing: 3) {
                if let sel = selected {
                    Image(systemName: sel.categoryIcon)
                        .font(.title3)
                        .foregroundStyle(Color(hex: sel.categoryColorHex))
                    Text(sel.categoryName)
                        .font(.caption.weight(.medium))
                        .lineLimit(1)
                    Text(CurrencyFormatter.format(sel.amount, currencyCode: currencyCode))
                        .font(.callout.weight(.bold))
                        .fontDesign(.rounded)
                    Text(String(format: "%.1f%%", sel.percentage))
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                } else {
                    Text(viewModel.selectedType == .expense ? "Total Spent" : "Total Earned")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                    Text(CurrencyFormatter.format(totalAmount, currencyCode: currencyCode))
                        .font(.callout.weight(.bold))
                        .fontDesign(.rounded)
                        .minimumScaleFactor(0.7)
                        .lineLimit(1)
                }
            }
            .padding(12)
            .contentTransition(.numericText())
            .animation(.spring(duration: 0.3), value: viewModel.selectedCategoryId)
        }
        .animation(.spring(duration: 0.4), value: viewModel.selectedCategoryId)
        .animation(.spring(duration: 0.4), value: viewModel.selectedPeriod)
    }

    // MARK: - Category List

    private var categoryList: some View {
        VStack(spacing: 2) {
            ForEach(viewModel.categoryBreakdown) { item in
                NavigationLink {
                    CategoryDetailView(
                        category: item,
                        transactions: viewModel.transactionsForCategory(item.categoryId),
                        periodLabel: viewModel.periodDisplayLabel,
                        currencyCode: currencyCode
                    )
                } label: {
                    CategoryBreakdownRow(
                        item: item,
                        isHighlighted: item.categoryId == viewModel.selectedCategoryId,
                        currencyCode: currencyCode
                    )
                }
                .buttonStyle(.plain)
            }
        }
    }

    // MARK: - Trend Bar Chart

    private var trendChartSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(viewModel.trendSectionTitle)
                .font(.headline)

            if viewModel.trendData.allSatisfy({ $0.income == 0 && $0.expense == 0 }) {
                ContentUnavailableView {
                    Label("No Trend Data", systemImage: "chart.bar")
                } description: {
                    Text("Not enough data to show a trend.")
                }
                .frame(minHeight: 160)
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
                        .cornerRadius(3)

                        BarMark(
                            x: .value("Period", data.label),
                            y: .value("Expense", data.expense),
                            width: .ratio(0.35)
                        )
                        .foregroundStyle(Color.red.gradient)
                        .position(by: .value("Type", "Expense"))
                        .cornerRadius(3)
                    }
                }
                .frame(height: 180)
                .chartLegend(.hidden)
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

                HStack(spacing: 16) {
                    legendDot(color: .green, label: "Income")
                    legendDot(color: .red, label: "Expense")
                }
            }
        }
        .padding(16)
        .background(Color(.secondarySystemGroupedBackground), in: RoundedRectangle(cornerRadius: 20, style: .continuous))
        .animation(.spring(duration: 0.4), value: viewModel.periodOffset)
    }

    private func legendDot(color: Color, label: String) -> some View {
        HStack(spacing: 6) {
            Circle().fill(color.gradient).frame(width: 8, height: 8)
            Text(label).font(.caption2).foregroundStyle(.secondary)
        }
    }

    // MARK: - Balance Trend Card

    private var balanceTrendCard: some View {
        let isPositive = viewModel.balance >= 0
        let accent: Color = isPositive ? .green : .red

        return VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Balance Trend")
                    .font(.headline)
                Spacer()
                Text(formatSigned(viewModel.balance))
                    .font(.subheadline.weight(.bold))
                    .fontDesign(.rounded)
                    .foregroundStyle(accent)
                    .contentTransition(.numericText(value: viewModel.balance))
                    .animation(.spring(duration: 0.4), value: viewModel.balance)
            }

            if viewModel.netCurveData.count < 2 {
                ContentUnavailableView {
                    Label("No Trend Data", systemImage: "chart.xyaxis.line")
                } description: {
                    Text("Not enough data for this period.")
                }
                .frame(minHeight: 120)
            } else {
                cumulativeLineChart(accent: accent)
            }
        }
        .padding(16)
        .background(Color(.secondarySystemGroupedBackground), in: RoundedRectangle(cornerRadius: 20, style: .continuous))
    }

    @ViewBuilder
    private func cumulativeLineChart(accent: Color) -> some View {
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
                    startPoint: .top,
                    endPoint: .bottom
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
            .symbolSize(point.date == viewModel.netCurveData.last?.date ? 30 : 0)
            .foregroundStyle(accent)
        }
        .frame(height: 140)
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
        .animation(.spring(duration: 0.4), value: viewModel.periodOffset)
    }

    // MARK: - Helpers

    private func formatSigned(_ value: Double) -> String {
        let prefix = value > 0 ? "+" : (value < 0 ? "-" : "")
        return "\(prefix)\(CurrencyFormatter.format(abs(value), currencyCode: currencyCode))"
    }
}

// MARK: - Category Breakdown Row

struct CategoryBreakdownRow: View {
    let item: CategorySpending
    let isHighlighted: Bool
    let currencyCode: String
    @State private var animatedPercentage: Double = 0

    var body: some View {
        HStack(spacing: 12) {
            ZStack {
                Circle()
                    .fill(Color(hex: item.categoryColorHex).opacity(isHighlighted ? 0.25 : 0.12))
                    .frame(width: 42, height: 42)
                Image(systemName: item.categoryIcon)
                    .foregroundStyle(Color(hex: item.categoryColorHex))
                    .font(.system(size: 16, weight: .semibold))
            }

            VStack(alignment: .leading, spacing: 5) {
                HStack(spacing: 6) {
                    Text(item.categoryName)
                        .font(.subheadline.weight(.medium))
                    Text("·")
                        .foregroundStyle(.tertiary)
                    Text("\(item.transactionCount) txn\(item.transactionCount == 1 ? "" : "s")")
                        .font(.caption2)
                        .foregroundStyle(.tertiary)
                }

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

            Spacer(minLength: 4)

            VStack(alignment: .trailing, spacing: 2) {
                Text(CurrencyFormatter.format(item.amount, currencyCode: currencyCode))
                    .font(.subheadline.weight(.semibold))
                    .fontDesign(.rounded)
                Text(String(format: "%.1f%%", item.percentage))
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }

            Image(systemName: "chevron.right")
                .font(.caption2.weight(.semibold))
                .foregroundStyle(.tertiary)
        }
        .padding(.vertical, 8)
        .padding(.horizontal, isHighlighted ? 6 : 0)
        .background(
            isHighlighted
                ? Color(hex: item.categoryColorHex).opacity(0.06)
                : Color.clear,
            in: RoundedRectangle(cornerRadius: 10, style: .continuous)
        )
        .animation(.spring(duration: 0.3), value: isHighlighted)
        .onAppear {
            withAnimation(.spring(duration: 0.8, bounce: 0.1).delay(0.1)) {
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
