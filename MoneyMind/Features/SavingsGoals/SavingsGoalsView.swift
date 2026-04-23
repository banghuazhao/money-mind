import SwiftUI

struct SavingsGoalsView: View {
    @State private var viewModel = SavingsGoalsViewModel()
    @AppStorage("currencyCode") private var currencyCode = "USD"

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 16) {
                    if viewModel.goals.isEmpty {
                        emptyState
                    } else {
                        overallSummaryCard
                        savingsRateCard
                        goalListSection
                    }

                    InlineAdaptiveBannerView(adUnitID: AdConfiguration.bannerAdUnitID)
                }
                .padding(.horizontal)
                .padding(.top, 4)
                .padding(.bottom, 24)
            }
            .background(Color(.systemGroupedBackground))
            .navigationTitle("Goals")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Button("New Goal", systemImage: "plus.circle.fill") {
                        viewModel.isShowingAddGoalSheet = true
                    }
                    .font(.title2)
                    .symbolRenderingMode(.hierarchical)
                }
            }
            .sheet(isPresented: $viewModel.isShowingAddGoalSheet) {
                SavingsGoalFormView(currencyCode: currencyCode) { draft in
                    viewModel.addGoal(
                        name: draft.name,
                        icon: draft.icon,
                        colorHex: draft.colorHex,
                        targetAmount: draft.targetAmount,
                        targetDate: draft.targetDate,
                        note: draft.note
                    )
                }
            }
            .sheet(item: $viewModel.editingGoal) { goal in
                SavingsGoalFormView(goal: goal, currencyCode: currencyCode) { draft in
                    var updated = goal
                    updated.name = draft.name
                    updated.icon = draft.icon
                    updated.colorHex = draft.colorHex
                    updated.targetAmount = draft.targetAmount
                    updated.targetDate = draft.targetDate
                    updated.note = draft.note
                    viewModel.updateGoal(updated)
                }
            }
            .alert("Delete Goal", isPresented: $viewModel.showDeleteAlert) {
                Button("Delete", role: .destructive) {
                    if let g = viewModel.goalToDelete {
                        viewModel.deleteGoal(g)
                    }
                }
                Button("Cancel", role: .cancel) {}
            } message: {
                Text("This will also remove all contributions logged for this goal.")
            }
        }
    }

    // MARK: - Empty State

    private var emptyState: some View {
        VStack(spacing: 20) {
            ZStack {
                Circle()
                    .fill(Color.accentColor.opacity(0.12))
                    .frame(width: 96, height: 96)
                Image(systemName: "target")
                    .font(.system(size: 42))
            }

            VStack(spacing: 6) {
                Text("No Goals Yet")
                    .font(.title3.weight(.semibold))
                Text("Save for what matters—vacations, emergencies, a new laptop. Track progress and stay motivated.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 32)
            }

            Button {
                viewModel.isShowingAddGoalSheet = true
            } label: {
                Label("Create Your First Goal", systemImage: "plus")
                    .font(.subheadline.weight(.semibold))
                    .padding(.horizontal, 20)
                    .padding(.vertical, 12)
                    .background(Color.accentColor, in: Capsule())
                    .foregroundStyle(.white)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 60)
    }

    // MARK: - Overall Summary

    private var overallSummaryCard: some View {
        VStack(spacing: 18) {
            HStack(alignment: .top, spacing: 20) {
                GoalRing(
                    percentage: viewModel.overallPercentage,
                    color: .accentColor,
                    size: 130
                ) {
                    VStack(spacing: 2) {
                        Text("\(Int(viewModel.overallPercentage))%")
                            .font(.system(size: 24, weight: .bold, design: .rounded))
                            .foregroundStyle(Color.accentColor)
                            .contentTransition(.numericText(value: viewModel.overallPercentage))
                            .animation(.spring(duration: 0.5), value: viewModel.overallPercentage)
                        Text("saved")
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                    }
                }

                VStack(alignment: .leading, spacing: 10) {
                    summaryRow(label: "Saved", amount: viewModel.totalSaved, color: .green)
                    summaryRow(label: "Target", amount: viewModel.totalTarget, color: .primary)
                    Rectangle().fill(Color(.separator)).frame(height: 0.5)
                    summaryRow(
                        label: "To Go",
                        amount: max(0, viewModel.totalTarget - viewModel.totalSaved),
                        color: .secondary
                    )
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }

            if viewModel.goals.count > 1 {
                Rectangle().fill(Color(.separator)).frame(height: 0.5)

                HStack(spacing: 16) {
                    infoPill(
                        icon: "flag.fill",
                        label: "Active",
                        value: "\(viewModel.activeGoalsCount)"
                    )
                    infoPill(
                        icon: "checkmark.seal.fill",
                        label: "Completed",
                        value: "\(viewModel.completedGoalsCount)"
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

    // MARK: - Savings Rate

    private var savingsRateCard: some View {
        let rate = viewModel.savingsRatePercent
        let income = viewModel.monthlyIncome
        let saved = viewModel.monthlyContributions
        let accent = rateAccent(for: rate)

        return VStack(alignment: .leading, spacing: 14) {
            HStack(alignment: .firstTextBaseline) {
                Label("Savings Rate", systemImage: "chart.line.uptrend.xyaxis")
                    .font(.subheadline.weight(.semibold))
                Spacer()
                Text(viewModel.currentMonthLabel)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            HStack(alignment: .firstTextBaseline, spacing: 14) {
                if let rate {
                    Text("\(Int(rate))%")
                        .font(.system(size: 32, weight: .bold, design: .rounded))
                        .foregroundStyle(accent)
                        .contentTransition(.numericText(value: rate))
                        .animation(.spring(duration: 0.4), value: rate)
                } else {
                    Text("—")
                        .font(.system(size: 32, weight: .bold, design: .rounded))
                        .foregroundStyle(.secondary)
                }

                VStack(alignment: .leading, spacing: 2) {
                    Text(rateHeadline(saved: saved, income: income))
                        .font(.caption.weight(.medium))
                    Text(rateSubtitle(rate: rate, saved: saved, income: income))
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }

                Spacer(minLength: 0)
            }

            if rate != nil {
                GeometryReader { geo in
                    ZStack(alignment: .leading) {
                        Capsule()
                            .fill(Color(.systemGray5))
                        Capsule()
                            .fill(accent.gradient)
                            .frame(width: progressWidth(rate: rate, total: geo.size.width))
                    }
                }
                .frame(height: 6)
                .clipShape(Capsule())
            }
        }
        .padding(16)
        .background(Color(.secondarySystemGroupedBackground), in: RoundedRectangle(cornerRadius: 20, style: .continuous))
    }

    private func rateAccent(for rate: Double?) -> Color {
        guard let rate else { return .secondary }
        if rate >= 20 { return .green }
        if rate >= 10 { return Color(hex: "#10B981") }
        if rate > 0 { return .orange }
        return .secondary
    }

    private func rateHeadline(saved: Double, income: Double) -> String {
        let savedStr = CurrencyFormatter.format(saved, currencyCode: currencyCode)
        if income > 0 {
            let incomeStr = CurrencyFormatter.format(income, currencyCode: currencyCode)
            return "\(savedStr) saved of \(incomeStr) income"
        }
        if saved > 0 {
            return "\(savedStr) contributed"
        }
        return "Nothing saved yet"
    }

    private func rateSubtitle(rate: Double?, saved: Double, income: Double) -> String {
        if income == 0 {
            return "Log income this month to compute your rate"
        }
        guard let rate else { return "" }
        if rate >= 20 { return "Excellent — you're building serious momentum." }
        if rate >= 10 { return "On a healthy track. Keep it up." }
        if rate > 0 { return "A start. Try to hit 10% or more." }
        return "Start a contribution to boost your rate."
    }

    private func progressWidth(rate: Double?, total: CGFloat) -> CGFloat {
        guard let rate else { return 0 }
        let clamped = max(0, min(rate, 100))
        return total * CGFloat(clamped / 100)
    }

    // MARK: - Goal List

    private var goalListSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Your Goals")
                .font(.headline)
                .padding(.horizontal, 4)

            VStack(spacing: 10) {
                ForEach(viewModel.goalProgress) { progress in
                    NavigationLink {
                        SavingsGoalDetailView(
                            goalId: progress.goal.id,
                            viewModel: viewModel,
                            currencyCode: currencyCode
                        )
                    } label: {
                        GoalCard(progress: progress, currencyCode: currencyCode)
                    }
                    .buttonStyle(.plain)
                    .swipeActions(edge: .trailing, allowsFullSwipe: false) {
                        Button(role: .destructive) {
                            viewModel.goalToDelete = progress.goal
                            viewModel.showDeleteAlert = true
                        } label: {
                            Label("Delete", systemImage: "trash")
                        }

                        Button {
                            viewModel.editingGoal = progress.goal
                        } label: {
                            Label("Edit", systemImage: "pencil")
                        }
                        .tint(.blue)
                    }
                    .contextMenu {
                        Button("Edit", systemImage: "pencil") {
                            viewModel.editingGoal = progress.goal
                        }
                        Button("Delete", systemImage: "trash", role: .destructive) {
                            viewModel.goalToDelete = progress.goal
                            viewModel.showDeleteAlert = true
                        }
                    }
                }
            }
        }
    }
}

// MARK: - Goal Card

struct GoalCard: View {
    let progress: GoalProgress
    let currencyCode: String

    @State private var animatedPercentage: Double = 0

    private var goalColor: Color { Color(hex: progress.goal.colorHex) }

    private var statusColor: Color {
        switch progress.status {
        case .completed: return .green
        case .onTrack, .noDeadline: return goalColor
        case .behind: return .orange
        }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 12) {
                ZStack {
                    Circle()
                        .fill(goalColor.opacity(0.15))
                        .frame(width: 44, height: 44)
                    Image(systemName: progress.isCompleted ? "checkmark" : progress.goal.icon)
                        .font(.system(size: 17, weight: .semibold))
                        .foregroundStyle(goalColor)
                }

                VStack(alignment: .leading, spacing: 2) {
                    HStack(spacing: 6) {
                        Text(progress.goal.name)
                            .font(.subheadline.weight(.semibold))
                            .lineLimit(1)

                        if progress.isCompleted {
                            Image(systemName: "checkmark.seal.fill")
                                .font(.caption2)
                                .foregroundStyle(.green)
                        }
                    }
                    Text("\(CurrencyFormatter.format(progress.saved, currencyCode: currencyCode)) of \(CurrencyFormatter.format(progress.target, currencyCode: currencyCode))")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                }

                Spacer()

                VStack(alignment: .trailing, spacing: 2) {
                    Text("\(Int(min(progress.percentage, 100)))%")
                        .font(.subheadline.weight(.bold))
                        .fontDesign(.rounded)
                        .foregroundStyle(statusColor)

                    if let label = trailingDetail {
                        Text(label)
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
                animatedPercentage = min(progress.percentage, 100)
            }
        }
        .onChange(of: progress.percentage) { _, newValue in
            withAnimation(.spring(duration: 0.5)) {
                animatedPercentage = min(newValue, 100)
            }
        }
    }

    private var trailingDetail: String? {
        if progress.isCompleted { return "Reached!" }
        if let days = progress.daysRemaining {
            if days < 0 { return "Past due" }
            if days == 0 { return "Due today" }
            return "\(days)d left"
        }
        return nil
    }
}

// MARK: - Goal Ring

struct GoalRing<Content: View>: View {
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
