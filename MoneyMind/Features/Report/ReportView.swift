import SwiftUI
import Charts

struct ReportView: View {
    @State private var viewModel = ReportViewModel()
    @AppStorage("currencyCode") private var currencyCode = "USD"

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 16) {
                    periodSelector
                    compactSummaryCard
                    compactCategorySection
                    compactTrendSection
                    compactBalanceTrendCard
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

    // MARK: - Compact Summary Card

    private var compactSummaryCard: some View {
        let isPositive = viewModel.balance >= 0

        return VStack(spacing: 14) {
            sectionHeader(title: "Summary") {
                ReportSummaryDetailView(viewModel: viewModel, currencyCode: currencyCode)
            }

            VStack(spacing: 4) {
                Text(formatSigned(viewModel.balance))
                    .font(.system(size: 28, weight: .bold, design: .rounded))
                    .foregroundStyle(isPositive ? .green : .red)
                    .contentTransition(.numericText(value: viewModel.balance))
                    .animation(.spring(duration: 0.4), value: viewModel.balance)
                Text("Net Balance")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            .frame(maxWidth: .infinity)

            Rectangle().fill(Color(.separator)).frame(height: 0.5)

            HStack(spacing: 0) {
                incomeExpenseColumn(
                    title: "Income",
                    amount: viewModel.totalIncome,
                    icon: "arrow.down.circle.fill",
                    color: .green
                )
                Rectangle().fill(Color(.separator)).frame(width: 0.5, height: 44)
                incomeExpenseColumn(
                    title: "Expense",
                    amount: viewModel.totalExpense,
                    icon: "arrow.up.circle.fill",
                    color: .red
                )
            }
        }
        .padding(16)
        .background(Color(.secondarySystemGroupedBackground), in: RoundedRectangle(cornerRadius: 20, style: .continuous))
    }

    // MARK: - Compact Category Section

    private var compactCategorySection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                NavigationLink {
                    CategoryBreakdownDetailView(viewModel: viewModel, currencyCode: currencyCode)
                } label: {
                    HStack(spacing: 4) {
                        Text("By Category")
                            .font(.headline)
                            .foregroundStyle(.primary)
                        Image(systemName: "chevron.right")
                            .font(.caption.weight(.semibold))
                            .foregroundStyle(.tertiary)
                    }
                }
                .buttonStyle(.plain)

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
                    .frame(maxWidth: .infinity, minHeight: 60, alignment: .center)
            } else {
                compactDonutRow

                Divider()

                ForEach(viewModel.categoryBreakdown.prefix(3)) { item in
                    compactCategoryRow(item)
                }

                if viewModel.categoryBreakdown.count > 3 {
                    NavigationLink {
                        CategoryBreakdownDetailView(viewModel: viewModel, currencyCode: currencyCode)
                    } label: {
                        HStack {
                            Text("See all \(viewModel.categoryBreakdown.count) categories")
                                .font(.subheadline)
                            Spacer()
                            Image(systemName: "chevron.right")
                                .font(.caption.weight(.semibold))
                                .foregroundStyle(.secondary)
                        }
                        .padding(.top, 2)
                    }
                    .buttonStyle(.plain)
                }
            }
        }
        .padding(16)
        .background(Color(.secondarySystemGroupedBackground), in: RoundedRectangle(cornerRadius: 20, style: .continuous))
        .animation(.spring(duration: 0.4), value: viewModel.selectedType)
    }

    private var compactDonutRow: some View {
        let totalAmount = viewModel.selectedType == .expense ? viewModel.totalExpense : viewModel.totalIncome

        return HStack(alignment: .center, spacing: 16) {
            Chart(viewModel.categoryBreakdown) { item in
                SectorMark(
                    angle: .value("Amount", item.amount),
                    innerRadius: .ratio(0.55),
                    angularInset: 1.5
                )
                .foregroundStyle(Color(hex: item.categoryColorHex))
                .cornerRadius(3)
            }
            .frame(width: 110, height: 110)
            .chartLegend(.hidden)
            .overlay {
                VStack(spacing: 1) {
                    Text(viewModel.selectedType == .expense ? "Spent" : "Earned")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                    Text(CurrencyFormatter.format(totalAmount, currencyCode: currencyCode))
                        .font(.caption.weight(.bold))
                        .fontDesign(.rounded)
                        .minimumScaleFactor(0.6)
                        .lineLimit(1)
                }
                .padding(6)
            }
            .animation(.spring(duration: 0.4), value: viewModel.selectedPeriod)

            VStack(alignment: .leading, spacing: 6) {
                ForEach(viewModel.categoryBreakdown.prefix(5)) { item in
                    HStack(spacing: 6) {
                        Circle()
                            .fill(Color(hex: item.categoryColorHex))
                            .frame(width: 7, height: 7)
                        Text(item.categoryName)
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                            .lineLimit(1)
                        Spacer(minLength: 4)
                        Text(String(format: "%.0f%%", item.percentage))
                            .font(.caption2.weight(.semibold))
                    }
                }
                if viewModel.categoryBreakdown.count > 5 {
                    Text("+\(viewModel.categoryBreakdown.count - 5) more")
                        .font(.caption2)
                        .foregroundStyle(.tertiary)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
    }

    private func compactCategoryRow(_ item: CategorySpending) -> some View {
        HStack(spacing: 10) {
            ZStack {
                Circle()
                    .fill(Color(hex: item.categoryColorHex).opacity(0.12))
                    .frame(width: 32, height: 32)
                Image(systemName: item.categoryIcon)
                    .foregroundStyle(Color(hex: item.categoryColorHex))
                    .font(.system(size: 13, weight: .semibold))
            }

            Text(item.categoryName)
                .font(.subheadline)

            Spacer()

            VStack(alignment: .trailing, spacing: 1) {
                Text(CurrencyFormatter.format(item.amount, currencyCode: currencyCode))
                    .font(.subheadline.weight(.semibold))
                    .fontDesign(.rounded)
                Text(String(format: "%.1f%%", item.percentage))
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }
        }
        .padding(.vertical, 3)
    }

    // MARK: - Compact Trend Section

    private var compactTrendSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            sectionHeader(title: viewModel.trendSectionTitle) {
                TrendDetailView(viewModel: viewModel, currencyCode: currencyCode)
            }

            if viewModel.trendData.allSatisfy({ $0.income == 0 && $0.expense == 0 }) {
                Text("Not enough data for this period.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity, minHeight: 60, alignment: .center)
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
                .frame(height: 110)
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
                .animation(.spring(duration: 0.4), value: viewModel.periodOffset)

                HStack(spacing: 16) {
                    legendDot(color: .green, label: "Income")
                    legendDot(color: .red, label: "Expense")
                }
            }
        }
        .padding(16)
        .background(Color(.secondarySystemGroupedBackground), in: RoundedRectangle(cornerRadius: 20, style: .continuous))
    }

    // MARK: - Compact Balance Trend Card

    private var compactBalanceTrendCard: some View {
        let accent: Color = viewModel.balance >= 0 ? .green : .red

        return VStack(alignment: .leading, spacing: 10) {
            sectionHeader(title: "Balance Trend") {
                BalanceTrendDetailView(viewModel: viewModel, currencyCode: currencyCode)
            }

            if viewModel.netCurveData.count < 2 {
                Text("Not enough data for this period.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity, minHeight: 60, alignment: .center)
            } else {
                compactLineChart(accent: accent)
            }
        }
        .padding(16)
        .background(Color(.secondarySystemGroupedBackground), in: RoundedRectangle(cornerRadius: 20, style: .continuous))
    }

    @ViewBuilder
    private func compactLineChart(accent: Color) -> some View {
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
                    colors: [accent.opacity(0.22), accent.opacity(0.02)],
                    startPoint: .top, endPoint: .bottom
                )
            )
            .interpolationMethod(.monotone)

            LineMark(
                x: .value("Date", point.date, unit: unit),
                y: .value("Net", point.cumulativeNet)
            )
            .foregroundStyle(accent)
            .lineStyle(StrokeStyle(lineWidth: 2))
            .interpolationMethod(.monotone)
        }
        .frame(height: 100)
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

    // MARK: - Shared Helpers

    @ViewBuilder
    private func sectionHeader<Destination: View>(
        title: String,
        @ViewBuilder destination: () -> Destination
    ) -> some View {
        NavigationLink(destination: destination()) {
            HStack {
                Text(title)
                    .font(.headline)
                    .foregroundStyle(.primary)
                Spacer()
                Image(systemName: "chevron.right")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.tertiary)
            }
        }
        .buttonStyle(.plain)
    }

    private func incomeExpenseColumn(title: String, amount: Double, icon: String, color: Color) -> some View {
        HStack(spacing: 10) {
            Image(systemName: icon)
                .foregroundStyle(color)
                .font(.system(size: 22))
                .frame(width: 26)

            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Text(CurrencyFormatter.format(amount, currencyCode: currencyCode))
                    .font(.subheadline.weight(.semibold))
                    .fontDesign(.rounded)
                    .foregroundStyle(color)
                    .contentTransition(.numericText(value: amount))
                    .animation(.spring(duration: 0.4), value: amount)
                    .lineLimit(1)
                    .minimumScaleFactor(0.7)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal, 8)
    }

    private func legendDot(color: Color, label: String) -> some View {
        HStack(spacing: 6) {
            Circle().fill(color.gradient).frame(width: 8, height: 8)
            Text(label).font(.caption2).foregroundStyle(.secondary)
        }
    }

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
            isHighlighted ? Color(hex: item.categoryColorHex).opacity(0.06) : Color.clear,
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
