import SwiftUI

struct BudgetsView: View {
    @State private var viewModel = BudgetsViewModel()
    @AppStorage("currencyCode") private var currencyCode = "USD"

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 16) {
                    monthNavigationBar

                    if viewModel.budgets.isEmpty {
                        emptyState
                    } else {
                        if viewModel.isCurrentMonth && viewModel.hasActiveAlerts {
                            alertBanner
                        }
                        overallSummaryCard
                        budgetListSection
                    }

                    InlineAdaptiveBannerView(adUnitID: AdConfiguration.bannerAdUnitID)
                }
                .padding(.horizontal)
                .padding(.bottom, 24)
            }
            .background(Color(.systemGroupedBackground))
            .navigationTitle("Budgets")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Button("Add Budget", systemImage: "plus.circle.fill") {
                        viewModel.isShowingAddSheet = true
                    }
                    .font(.title2)
                    .symbolRenderingMode(.hierarchical)
                    .disabled(viewModel.unbudgetedExpenseCategories.isEmpty)
                }
            }
            .sheet(isPresented: $viewModel.isShowingAddSheet) {
                BudgetFormView(
                    availableCategories: viewModel.unbudgetedExpenseCategories,
                    currencyCode: currencyCode
                ) { categoryId, amount in
                    viewModel.addBudget(categoryId: categoryId, amount: amount)
                }
            }
            .sheet(item: $viewModel.editingBudget) { budget in
                let current = viewModel.category(id: budget.categoryId)
                let candidates = viewModel.unbudgetedExpenseCategories + [current].compactMap { $0 }
                BudgetFormView(
                    budget: budget,
                    availableCategories: candidates.sorted { $0.name < $1.name },
                    currencyCode: currencyCode
                ) { categoryId, amount in
                    var updated = budget
                    updated.categoryId = categoryId
                    updated.amount = amount
                    viewModel.updateBudget(updated)
                }
            }
            .alert("Delete Budget", isPresented: $viewModel.showDeleteAlert) {
                Button("Delete", role: .destructive) {
                    if let b = viewModel.budgetToDelete {
                        viewModel.deleteBudget(b)
                    }
                }
                Button("Cancel", role: .cancel) {}
            } message: {
                Text("Are you sure you want to delete this budget?")
            }
            .sensoryFeedback(.impact(flexibility: .soft), trigger: viewModel.monthOffset)
        }
    }

    // MARK: - Month Navigation

    private var monthNavigationBar: some View {
        HStack {
            Button {
                withAnimation(.spring(duration: 0.35)) { viewModel.previousMonth() }
            } label: {
                Image(systemName: "chevron.left")
                    .font(.body.weight(.semibold))
                    .frame(width: 36, height: 36)
                    .contentShape(Rectangle())
            }

            Spacer()

            Text(viewModel.monthDisplayLabel)
                .font(.subheadline.weight(.semibold))
                .contentTransition(.numericText())
                .animation(.spring(duration: 0.3), value: viewModel.monthOffset)

            Spacer()

            Button {
                withAnimation(.spring(duration: 0.35)) { viewModel.nextMonth() }
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
        .padding(.top, 4)
    }

    // MARK: - Alert Banner

    private var alertBanner: some View {
        let overspent = viewModel.overspentBudgets
        let warnings = viewModel.warningBudgets
        let isCritical = !overspent.isEmpty
        let accent: Color = isCritical ? .red : .orange
        let icon = isCritical ? "exclamationmark.octagon.fill" : "exclamationmark.triangle.fill"

        return VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: 10) {
                Image(systemName: icon)
                    .font(.title3)
                    .foregroundStyle(accent)
                    .symbolEffect(.pulse, options: .repeat(.periodic(delay: 2)))

                VStack(alignment: .leading, spacing: 2) {
                    Text(bannerTitle(overspent: overspent.count, warnings: warnings.count))
                        .font(.subheadline.weight(.semibold))
                    Text(bannerSubtitle(overspent: overspent, warnings: warnings))
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .lineLimit(2)
                }

                Spacer()
            }

            if overspent.count + warnings.count <= 3 {
                VStack(spacing: 6) {
                    ForEach(overspent.prefix(3)) { bp in
                        alertItem(progress: bp, color: .red)
                    }
                    ForEach(warnings.prefix(max(0, 3 - overspent.count))) { bp in
                        alertItem(progress: bp, color: .orange)
                    }
                }
            }
        }
        .padding(14)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(accent.opacity(0.10), in: RoundedRectangle(cornerRadius: 16, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .strokeBorder(accent.opacity(0.25), lineWidth: 1)
        )
        .sensoryFeedback(.warning, trigger: overspent.count)
    }

    private func alertItem(progress: BudgetProgress, color: Color) -> some View {
        HStack(spacing: 8) {
            Image(systemName: progress.category?.icon ?? "questionmark.circle")
                .font(.caption)
                .foregroundStyle(color)
                .frame(width: 18)

            Text(progress.category?.name ?? "Unknown")
                .font(.caption.weight(.medium))

            Spacer(minLength: 4)

            Text(progress.status == .overspent
                 ? "Over by \(CurrencyFormatter.format(progress.overspent, currencyCode: currencyCode))"
                 : "\(Int(progress.percentage))% used")
                .font(.caption2.weight(.semibold))
                .foregroundStyle(color)
        }
    }

    private func bannerTitle(overspent: Int, warnings: Int) -> String {
        if overspent > 0 && warnings > 0 {
            return "\(overspent) over limit · \(warnings) nearing limit"
        } else if overspent > 0 {
            return overspent == 1 ? "1 budget over limit" : "\(overspent) budgets over limit"
        } else {
            return warnings == 1 ? "1 budget nearing limit" : "\(warnings) budgets nearing limit"
        }
    }

    private func bannerSubtitle(overspent: [BudgetProgress], warnings: [BudgetProgress]) -> String {
        if !overspent.isEmpty {
            return "Consider reviewing your spending in these categories."
        }
        return "You've used 80% or more of these budgets."
    }

    // MARK: - Empty State

    private var emptyState: some View {
        VStack(spacing: 20) {
            ZStack {
                Circle()
                    .fill(Color.accentColor.opacity(0.12))
                    .frame(width: 96, height: 96)
                Image(systemName: "chart.pie.fill")
                    .font(.system(size: 42))
//                    .foregroundStyle(.accentColor)
            }

            VStack(spacing: 6) {
                Text("No Budgets Yet")
                    .font(.title3.weight(.semibold))
                Text("Set monthly spending limits for your expense categories to stay on track.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 32)
            }

            Button {
                viewModel.isShowingAddSheet = true
            } label: {
                Label("Create Your First Budget", systemImage: "plus")
                    .font(.subheadline.weight(.semibold))
                    .padding(.horizontal, 20)
                    .padding(.vertical, 12)
                    .background(Color.accentColor, in: Capsule())
                    .foregroundStyle(.white)
            }
            .disabled(viewModel.unbudgetedExpenseCategories.isEmpty)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 60)
    }

    // MARK: - Overall Summary

    private var overallSummaryCard: some View {
        let statusColor = color(for: viewModel.overallStatus)

        return VStack(spacing: 18) {
            HStack(alignment: .top, spacing: 20) {
                BudgetRing(
                    percentage: viewModel.overallPercentage,
                    color: statusColor,
                    size: 130
                ) {
                    VStack(spacing: 2) {
                        Text("\(Int(viewModel.overallPercentage))%")
                            .font(.system(size: 24, weight: .bold, design: .rounded))
                            .foregroundStyle(statusColor)
                            .contentTransition(.numericText(value: viewModel.overallPercentage))
                            .animation(.spring(duration: 0.5), value: viewModel.overallPercentage)
                        Text("used")
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                    }
                }

                VStack(alignment: .leading, spacing: 10) {
                    summaryRow(label: "Budget", amount: viewModel.totalBudgeted, color: .primary)
                    summaryRow(label: "Spent", amount: viewModel.totalSpent, color: statusColor)
                    Rectangle().fill(Color(.separator)).frame(height: 0.5)
                    summaryRow(
                        label: viewModel.totalSpent > viewModel.totalBudgeted ? "Over" : "Left",
                        amount: viewModel.totalSpent > viewModel.totalBudgeted
                            ? viewModel.totalSpent - viewModel.totalBudgeted
                            : viewModel.totalRemaining,
                        color: viewModel.totalSpent > viewModel.totalBudgeted ? .red : .green
                    )
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }

            if viewModel.isCurrentMonth && viewModel.daysRemainingInMonth > 0 && viewModel.totalRemaining > 0 {
                Rectangle().fill(Color(.separator)).frame(height: 0.5)

                HStack(spacing: 16) {
                    infoPill(
                        icon: "calendar",
                        label: "Days Left",
                        value: "\(viewModel.daysRemainingInMonth)"
                    )
                    infoPill(
                        icon: "dollarsign.circle",
                        label: "Daily Remaining",
                        value: CurrencyFormatter.format(viewModel.dailyRemainingBudget, currencyCode: currencyCode)
                    )
                }
            }
        }
        .padding(16)
        .background(Color(.secondarySystemGroupedBackground), in: RoundedRectangle(cornerRadius: 20, style: .continuous))
    }

    private func summaryRow(label: String, amount: Double, color: Color) -> some View {
        HStack {
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
    }

    private func infoPill(icon: String, label: String, value: String) -> some View {
        HStack(spacing: 8) {
            Image(systemName: icon)
                .font(.caption)
                .foregroundStyle(.secondary)
            VStack(alignment: .leading, spacing: 1) {
                Text(label)
                    .font(.caption2)
                    .foregroundStyle(.secondary)
                Text(value)
                    .font(.subheadline.weight(.semibold))
                    .fontDesign(.rounded)
            }
            Spacer()
        }
    }

    // MARK: - Budget List

    private var budgetListSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Categories")
                .font(.headline)
                .padding(.horizontal, 4)

            VStack(spacing: 10) {
                ForEach(viewModel.budgetProgress) { progress in
                    NavigationLink {
                        BudgetDetailView(
                            progress: progress,
                            transactions: viewModel.transactions(for: progress.budget.categoryId),
                            monthLabel: viewModel.monthDisplayLabel,
                            daysRemaining: viewModel.daysRemainingInMonth,
                            isCurrentMonth: viewModel.isCurrentMonth,
                            currencyCode: currencyCode
                        )
                    } label: {
                        BudgetCard(progress: progress, currencyCode: currencyCode)
                    }
                    .buttonStyle(.plain)
                    .swipeActions(edge: .trailing, allowsFullSwipe: false) {
                        Button(role: .destructive) {
                            viewModel.budgetToDelete = progress.budget
                            viewModel.showDeleteAlert = true
                        } label: {
                            Label("Delete", systemImage: "trash")
                        }

                        Button {
                            viewModel.editingBudget = progress.budget
                        } label: {
                            Label("Edit", systemImage: "pencil")
                        }
                        .tint(.blue)
                    }
                    .contextMenu {
                        Button("Edit", systemImage: "pencil") {
                            viewModel.editingBudget = progress.budget
                        }
                        Button("Delete", systemImage: "trash", role: .destructive) {
                            viewModel.budgetToDelete = progress.budget
                            viewModel.showDeleteAlert = true
                        }
                    }
                }
            }
        }
    }
}

// MARK: - Budget Card

struct BudgetCard: View {
    let progress: BudgetProgress
    let currencyCode: String
    @State private var animatedPercentage: Double = 0

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

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 12) {
                ZStack {
                    Circle()
                        .fill(categoryColor.opacity(0.15))
                        .frame(width: 40, height: 40)
                    Image(systemName: progress.category?.icon ?? "questionmark.circle")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundStyle(categoryColor)
                }

                VStack(alignment: .leading, spacing: 2) {
                    Text(progress.category?.name ?? "Unknown")
                        .font(.subheadline.weight(.semibold))
                    Text("\(CurrencyFormatter.format(progress.spent, currencyCode: currencyCode)) of \(CurrencyFormatter.format(progress.amount, currencyCode: currencyCode))")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                Spacer()

                VStack(alignment: .trailing, spacing: 2) {
                    Text("\(Int(progress.percentage))%")
                        .font(.subheadline.weight(.bold))
                        .fontDesign(.rounded)
                        .foregroundStyle(statusColor)
                    if progress.status == .overspent {
                        Text("Over by \(CurrencyFormatter.format(progress.overspent, currencyCode: currencyCode))")
                            .font(.caption2)
                            .foregroundStyle(.red)
                    } else {
                        Text("\(CurrencyFormatter.format(progress.remaining, currencyCode: currencyCode)) left")
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                    }
                }
            }

            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    Capsule()
                        .fill(Color(.systemGray5))

                    Capsule()
                        .fill(statusColor.gradient)
                        .frame(width: min(geo.size.width, geo.size.width * animatedPercentage / 100))
                }
            }
            .frame(height: 8)
            .clipShape(Capsule())
        }
        .padding(14)
        .background(Color(.secondarySystemGroupedBackground), in: RoundedRectangle(cornerRadius: 16, style: .continuous))
        .onAppear {
            withAnimation(.spring(duration: 0.8, bounce: 0.1).delay(0.1)) {
                animatedPercentage = progress.percentage
            }
        }
        .onChange(of: progress.percentage) { _, newValue in
            withAnimation(.spring(duration: 0.5)) {
                animatedPercentage = newValue
            }
        }
    }
}

// MARK: - Budget Ring

struct BudgetRing<Content: View>: View {
    let percentage: Double
    let color: Color
    let size: CGFloat
    @ViewBuilder var content: Content

    @State private var animatedPercentage: Double = 0

    private var clampedPercentage: Double { min(percentage, 100) }

    var body: some View {
        ZStack {
            Circle()
                .stroke(Color(.systemGray5), lineWidth: 12)

            Circle()
                .trim(from: 0, to: CGFloat(min(animatedPercentage, 100) / 100))
                .stroke(
                    color.gradient,
                    style: StrokeStyle(lineWidth: 12, lineCap: .round)
                )
                .rotationEffect(.degrees(-90))

            content
        }
        .frame(width: size, height: size)
        .onAppear {
            withAnimation(.spring(duration: 0.9, bounce: 0.1).delay(0.1)) {
                animatedPercentage = clampedPercentage
            }
        }
        .onChange(of: percentage) { _, _ in
            withAnimation(.spring(duration: 0.5)) {
                animatedPercentage = clampedPercentage
            }
        }
    }
}

// MARK: - Helpers

private func color(for status: BudgetStatus) -> Color {
    switch status {
    case .healthy: return .green
    case .warning: return .orange
    case .overspent: return .red
    }
}
