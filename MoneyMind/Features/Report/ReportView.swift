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

                    monthlyBarChartSection

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

    private var periodPicker: some View {
        Picker("Period", selection: $viewModel.selectedPeriod) {
            ForEach(ReportPeriod.allCases, id: \.self) { period in
                Text(period.rawValue).tag(period)
            }
        }
        .pickerStyle(.segmented)
        .padding(.top, 4)
    }

    private var balanceSummarySection: some View {
        VStack(spacing: 12) {
            HStack {
                Text("Overview")
                    .font(.headline)
                    .fontWeight(.semibold)
                Spacer()
            }

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
            }

            MetricCard(
                title: "Balance",
                value: CurrencyFormatter.format(viewModel.balance, currencyCode: currencyCode),
                color: viewModel.balance >= 0 ? .blue : .orange,
                icon: "equal.circle.fill",
                fullWidth: true
            )
        }
    }

    private var monthlyBarChartSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("6-Month Overview")
                .font(.headline)
                .fontWeight(.semibold)

            Chart {
                ForEach(viewModel.monthlyData) { data in
                    BarMark(
                        x: .value("Month", data.month),
                        y: .value("Income", data.income),
                        width: .ratio(0.4)
                    )
                    .foregroundStyle(Color.green.gradient)
                    .position(by: .value("Type", "Income"))

                    BarMark(
                        x: .value("Month", data.month),
                        y: .value("Expense", data.expense),
                        width: .ratio(0.4)
                    )
                    .foregroundStyle(Color.red.gradient)
                    .position(by: .value("Type", "Expense"))
                }
            }
            .frame(height: 200)
            .chartLegend(.hidden)

            HStack(spacing: 16) {
                HStack(spacing: 6) {
                    Circle().fill(Color.green).frame(width: 10, height: 10)
                    Text("Income").font(.caption).foregroundStyle(.secondary)
                }
                HStack(spacing: 6) {
                    Circle().fill(Color.red).frame(width: 10, height: 10)
                    Text("Expense").font(.caption).foregroundStyle(.secondary)
                }
            }
        }
        .padding(16)
        .background(Color(.secondarySystemGroupedBackground), in: RoundedRectangle(cornerRadius: 16))
    }

    private var categoryBreakdownSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("By Category")
                    .font(.headline)
                    .fontWeight(.semibold)
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

                ForEach(viewModel.categoryBreakdown) { item in
                    CategoryBreakdownRow(
                        item: item,
                        currencyCode: currencyCode
                    )
                }
            }
        }
        .padding(16)
        .background(Color(.secondarySystemGroupedBackground), in: RoundedRectangle(cornerRadius: 16))
    }

    private var donutChartSection: some View {
        let totalAmount = viewModel.selectedType == .expense ? viewModel.totalExpense : viewModel.totalIncome
        return Chart(viewModel.categoryBreakdown) { item in
            SectorMark(
                angle: .value("Amount", item.amount),
                innerRadius: .ratio(0.55),
                angularInset: 2
            )
            .foregroundStyle(Color(hex: item.categoryColorHex))
            .cornerRadius(4)
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
                    .minimumScaleFactor(0.7)
                    .lineLimit(1)
            }
            .padding(8)
        }
    }
}

struct MetricCard: View {
    let title: String
    let value: String
    let color: Color
    let icon: String
    var fullWidth: Bool = false

    var body: some View {
        HStack(spacing: 10) {
            Image(systemName: icon)
                .foregroundStyle(color)
                .font(.title3)

            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Text(value)
                    .font(.subheadline.weight(.bold))
                    .foregroundStyle(color)
                    .lineLimit(1)
                    .minimumScaleFactor(0.7)
            }
            if fullWidth { Spacer() }
        }
        .frame(maxWidth: fullWidth ? .infinity : nil, alignment: .leading)
        .padding(14)
        .background(color.opacity(0.1), in: RoundedRectangle(cornerRadius: 12))
        .frame(maxWidth: fullWidth ? .infinity : .infinity)
    }
}

struct CategoryBreakdownRow: View {
    let item: CategorySpending
    let currencyCode: String

    var body: some View {
        HStack(spacing: 12) {
            ZStack {
                Circle()
                    .fill(Color(hex: item.categoryColorHex).opacity(0.15))
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
                            .frame(height: 5)
                        Capsule()
                            .fill(Color(hex: item.categoryColorHex))
                            .frame(width: geo.size.width * item.percentage / 100, height: 5)
                    }
                }
                .frame(height: 5)
            }

            Spacer()

            VStack(alignment: .trailing, spacing: 2) {
                Text(CurrencyFormatter.format(item.amount, currencyCode: currencyCode))
                    .font(.subheadline.weight(.semibold))
                Text(String(format: "%.1f%%", item.percentage))
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }
        }
        .padding(.vertical, 4)
    }
}
