import SwiftUI
import Charts

struct CategoryBreakdownDetailView: View {
    @Bindable var viewModel: ReportViewModel
    let currencyCode: String

    @State private var chartAngle: Double?

    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                typePicker
                    .padding(.horizontal)

                if viewModel.categoryBreakdown.isEmpty {
                    ContentUnavailableView {
                        Label("No Data", systemImage: "chart.pie")
                    } description: {
                        Text("No \(viewModel.selectedType.displayName.lowercased()) recorded for this period.")
                    }
                    .frame(minHeight: 300)
                } else {
                    interactiveDonutSection
                        .padding(.horizontal)

                    categoryListSection
                        .padding(.horizontal)
                }
            }
            .padding(.vertical, 16)
            .padding(.bottom, 24)
        }
        .background(Color(.systemGroupedBackground))
        .navigationTitle("By Category")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                ShareLink(item: exportText) {
                    Image(systemName: "square.and.arrow.up")
                }
            }
        }
        .animation(.spring(duration: 0.4), value: viewModel.selectedType)
    }

    // MARK: - Type Picker

    private var typePicker: some View {
        Picker("Type", selection: $viewModel.selectedType) {
            ForEach(TransactionType.allCases, id: \.self) { type in
                Text(type.displayName).tag(type)
            }
        }
        .pickerStyle(.segmented)
    }

    // MARK: - Interactive Donut

    private var interactiveDonutSection: some View {
        let totalAmount = viewModel.selectedType == .expense ? viewModel.totalExpense : viewModel.totalIncome
        let selected = viewModel.selectedCategory

        return VStack(spacing: 0) {
            Chart(viewModel.categoryBreakdown) { item in
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
            .frame(height: 240)
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

            if selected != nil {
                Button("Clear Selection") {
                    withAnimation(.spring(duration: 0.3)) {
                        viewModel.selectedCategoryId = nil
                        chartAngle = nil
                    }
                }
                .font(.caption)
                .foregroundStyle(.secondary)
                .padding(.top, 8)
            }
        }
        .padding(16)
        .background(Color(.secondarySystemGroupedBackground), in: RoundedRectangle(cornerRadius: 20, style: .continuous))
    }

    // MARK: - Category List

    private var categoryListSection: some View {
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
        .padding(16)
        .background(Color(.secondarySystemGroupedBackground), in: RoundedRectangle(cornerRadius: 20, style: .continuous))
    }

    // MARK: - Export

    private var exportText: String {
        let typeLabel = viewModel.selectedType.displayName
        let totalAmount = viewModel.selectedType == .expense ? viewModel.totalExpense : viewModel.totalIncome
        var lines: [String] = []
        lines.append("MoneyMind — \(typeLabel) by Category")
        lines.append("Period: \(viewModel.periodDisplayLabel)")
        lines.append(String(repeating: "─", count: 40))

        for (index, item) in viewModel.categoryBreakdown.enumerated() {
            let rank = String(format: "%2d.", index + 1)
            let name = item.categoryName.padding(toLength: 20, withPad: " ", startingAt: 0)
            let amount = CurrencyFormatter.format(item.amount, currencyCode: currencyCode)
            let pct = String(format: "(%.1f%%)", item.percentage)
            lines.append("\(rank) \(name) \(amount)  \(pct)")
        }

        lines.append(String(repeating: "─", count: 40))
        lines.append("Total: \(CurrencyFormatter.format(totalAmount, currencyCode: currencyCode))")
        return lines.joined(separator: "\n")
    }
}
