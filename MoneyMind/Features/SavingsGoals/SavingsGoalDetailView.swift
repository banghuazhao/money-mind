import SwiftUI
import Charts

struct SavingsGoalDetailView: View {
    let goalId: Int
    @Bindable var viewModel: SavingsGoalsViewModel
    let currencyCode: String

    @State private var isShowingAddContribution = false
    @State private var editingContribution: GoalContribution?
    @State private var contributionToDelete: GoalContribution?
    @State private var showDeleteAlert = false

    private var goal: SavingsGoal? {
        viewModel.goals.first { $0.id == goalId }
    }

    private var progress: GoalProgress? {
        guard let g = goal else { return nil }
        return viewModel.progress(for: g)
    }

    private var contributions: [GoalContribution] {
        viewModel.contributions(for: goalId).sorted { $0.date > $1.date }
    }

    var body: some View {
        Group {
            if let progress {
                ScrollView {
                    VStack(spacing: 16) {
                        heroCard(progress: progress)
                        statusBanner(progress: progress)
                        statsSection(progress: progress)

                        if contributions.count >= 2 {
                            progressChart
                        }

                        contributionsSection
                    }
                    .padding(.horizontal)
                    .padding(.bottom, 24)
                }
                .background(Color(.systemGroupedBackground))
            } else {
                ContentUnavailableView(
                    "Goal Unavailable",
                    systemImage: "target",
                    description: Text("This goal may have been deleted.")
                )
            }
        }
        .navigationTitle(goal?.name ?? "Goal")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button("Add Contribution", systemImage: "plus.circle.fill") {
                    isShowingAddContribution = true
                }
                .font(.title3)
                .symbolRenderingMode(.hierarchical)
            }
        }
        .sheet(isPresented: $isShowingAddContribution) {
            ContributionFormView(currencyCode: currencyCode) { draft in
                viewModel.addContribution(
                    goalId: goalId,
                    amount: draft.amount,
                    date: draft.date,
                    note: draft.note
                )
            }
        }
        .sheet(item: $editingContribution) { contribution in
            ContributionFormView(
                contribution: contribution,
                currencyCode: currencyCode
            ) { draft in
                var updated = contribution
                updated.amount = draft.amount
                updated.date = draft.date
                updated.note = draft.note
                viewModel.updateContribution(updated)
            }
        }
        .alert("Delete Contribution", isPresented: $showDeleteAlert) {
            Button("Delete", role: .destructive) {
                if let c = contributionToDelete {
                    viewModel.deleteContribution(c)
                }
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("Are you sure you want to delete this contribution?")
        }
    }

    // MARK: - Hero

    private func heroCard(progress: GoalProgress) -> some View {
        let color = Color(hex: progress.goal.colorHex)

        return VStack(spacing: 16) {
            GoalRing(
                percentage: progress.percentage,
                color: color,
                size: 170
            ) {
                VStack(spacing: 4) {
                    Image(systemName: progress.isCompleted ? "checkmark.seal.fill" : progress.goal.icon)
                        .font(.system(size: 26, weight: .semibold))
                        .foregroundStyle(color)
                    Text("\(Int(min(progress.percentage, 100)))%")
                        .font(.system(size: 28, weight: .bold, design: .rounded))
                        .foregroundStyle(color)
                }
            }

            VStack(spacing: 4) {
                Text(CurrencyFormatter.format(progress.saved, currencyCode: currencyCode))
                    .font(.system(size: 32, weight: .bold, design: .rounded))
                    .foregroundStyle(.primary)
                Text("of \(CurrencyFormatter.format(progress.target, currencyCode: currencyCode))")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }

            if !progress.goal.note.isEmpty {
                Text(progress.goal.note)
                    .font(.callout)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 8)
            }
        }
        .padding(20)
        .frame(maxWidth: .infinity)
        .background(Color(.secondarySystemGroupedBackground), in: RoundedRectangle(cornerRadius: 24, style: .continuous))
    }

    // MARK: - Status Banner

    private func statusBanner(progress: GoalProgress) -> some View {
        let (title, subtitle, icon, color) = statusBannerContent(progress: progress)

        return HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.title3)
                .foregroundStyle(color)
                .frame(width: 28)

            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.subheadline.weight(.semibold))
                Text(subtitle)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Spacer()
        }
        .padding(14)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(color.opacity(0.10), in: RoundedRectangle(cornerRadius: 14, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .strokeBorder(color.opacity(0.2), lineWidth: 1)
        )
    }

    private func statusBannerContent(progress: GoalProgress) -> (String, String, String, Color) {
        if progress.isCompleted {
            return (
                "Goal Reached!",
                "Congrats — you hit your target. Time to celebrate.",
                "checkmark.seal.fill",
                .green
            )
        }

        switch progress.status {
        case .onTrack:
            if let perDay = progress.requiredPerDay {
                return (
                    "On Track",
                    "Save \(CurrencyFormatter.format(perDay, currencyCode: currencyCode))/day to reach your goal on time.",
                    "checkmark.circle.fill",
                    .green
                )
            }
            return ("On Track", "Keep going — you're building momentum.", "checkmark.circle.fill", .green)
        case .behind:
            if let perDay = progress.requiredPerDay {
                return (
                    "Behind Pace",
                    "You'll need \(CurrencyFormatter.format(perDay, currencyCode: currencyCode))/day to catch up.",
                    "exclamationmark.triangle.fill",
                    .orange
                )
            }
            return (
                "Past Due",
                "Your target date has passed. Extend the date or keep saving.",
                "clock.badge.exclamationmark.fill",
                .orange
            )
        case .noDeadline:
            return (
                "Saving at Your Pace",
                "No deadline set. Add contributions whenever you can.",
                "infinity.circle.fill",
                .blue
            )
        case .completed:
            return ("Goal Reached!", "Congrats — you hit your target.", "checkmark.seal.fill", .green)
        }
    }

    // MARK: - Stats

    private func statsSection(progress: GoalProgress) -> some View {
        let avgContribution: Double = {
            guard progress.contributionCount > 0 else { return 0 }
            return progress.saved / Double(progress.contributionCount)
        }()

        return VStack(alignment: .leading, spacing: 12) {
            Text("Stats")
                .font(.headline)
                .padding(.horizontal, 4)

            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 10) {
                statCell(
                    icon: "flag.checkered",
                    label: "Remaining",
                    value: CurrencyFormatter.format(progress.remaining, currencyCode: currencyCode),
                    tint: .blue
                )

                if let days = progress.daysRemaining {
                    statCell(
                        icon: "calendar",
                        label: days < 0 ? "Past Due" : "Days Left",
                        value: "\(max(days, 0))",
                        tint: days < 0 ? .red : .orange
                    )
                } else {
                    statCell(
                        icon: "calendar.badge.clock",
                        label: "Deadline",
                        value: "None",
                        tint: .secondary
                    )
                }

                if let perMonth = progress.requiredPerMonth, !progress.isCompleted {
                    statCell(
                        icon: "arrow.up.right.circle.fill",
                        label: "Need / month",
                        value: CurrencyFormatter.format(perMonth, currencyCode: currencyCode),
                        tint: .purple
                    )
                } else {
                    statCell(
                        icon: "number.circle.fill",
                        label: "Contributions",
                        value: "\(progress.contributionCount)",
                        tint: .purple
                    )
                }

                statCell(
                    icon: "chart.bar.fill",
                    label: "Avg / deposit",
                    value: CurrencyFormatter.format(avgContribution, currencyCode: currencyCode),
                    tint: .pink
                )
            }
        }
    }

    private func statCell(icon: String, label: String, value: String, tint: Color) -> some View {
        HStack(spacing: 12) {
            ZStack {
                Circle()
                    .fill(tint.opacity(0.15))
                    .frame(width: 34, height: 34)
                Image(systemName: icon)
                    .foregroundStyle(tint)
                    .font(.system(size: 15, weight: .semibold))
            }

            VStack(alignment: .leading, spacing: 1) {
                Text(label)
                    .font(.caption2)
                    .foregroundStyle(.secondary)
                Text(value)
                    .font(.subheadline.weight(.semibold))
                    .fontDesign(.rounded)
                    .lineLimit(1)
                    .minimumScaleFactor(0.7)
            }
            Spacer(minLength: 0)
        }
        .padding(12)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color(.secondarySystemGroupedBackground), in: RoundedRectangle(cornerRadius: 14, style: .continuous))
    }

    // MARK: - Progress Chart

    private var progressChart: some View {
        let sorted = contributions.sorted { $0.date < $1.date }
        var running: Double = 0
        let points: [CumulativePoint] = sorted.map { c in
            running += c.amount
            return CumulativePoint(date: c.date, amount: running)
        }
        let goalColor = goal.map { Color(hex: $0.colorHex) } ?? .accentColor
        let target = goal?.targetAmount ?? 0

        return VStack(alignment: .leading, spacing: 12) {
            Text("Progress Over Time")
                .font(.headline)
                .padding(.horizontal, 4)

            Chart {
                ForEach(points) { p in
                    AreaMark(
                        x: .value("Date", p.date),
                        y: .value("Saved", p.amount)
                    )
                    .foregroundStyle(
                        .linearGradient(
                            colors: [goalColor.opacity(0.35), goalColor.opacity(0.02)],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
                    .interpolationMethod(.monotone)

                    LineMark(
                        x: .value("Date", p.date),
                        y: .value("Saved", p.amount)
                    )
                    .foregroundStyle(goalColor)
                    .interpolationMethod(.monotone)
                    .lineStyle(StrokeStyle(lineWidth: 2.5))
                }

                if target > 0 {
                    RuleMark(y: .value("Target", target))
                        .foregroundStyle(.secondary.opacity(0.4))
                        .lineStyle(StrokeStyle(lineWidth: 1, dash: [4, 3]))
                        .annotation(alignment: .trailing) {
                            Text("Target")
                                .font(.caption2)
                                .foregroundStyle(.secondary)
                                .padding(.horizontal, 6)
                                .padding(.vertical, 2)
                                .background(Color(.secondarySystemGroupedBackground), in: Capsule())
                        }
                }
            }
            .frame(height: 160)
            .chartYAxis {
                AxisMarks(position: .leading) { _ in
                    AxisGridLine().foregroundStyle(Color(.separator).opacity(0.4))
                    AxisValueLabel().font(.caption2)
                }
            }
            .padding(14)
            .background(Color(.secondarySystemGroupedBackground), in: RoundedRectangle(cornerRadius: 18, style: .continuous))
        }
    }

    // MARK: - Contributions

    private var contributionsSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Text("Contributions")
                    .font(.headline)
                Spacer()
                if !contributions.isEmpty {
                    Text("\(contributions.count) total")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
            .padding(.horizontal, 4)

            if contributions.isEmpty {
                VStack(spacing: 10) {
                    Image(systemName: "plus.circle.dashed")
                        .font(.system(size: 32))
                        .foregroundStyle(.secondary)
                    Text("No contributions yet")
                        .font(.subheadline.weight(.medium))
                    Text("Log your first deposit to start tracking progress.")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                    Button {
                        isShowingAddContribution = true
                    } label: {
                        Label("Add Contribution", systemImage: "plus")
                            .font(.subheadline.weight(.semibold))
                            .padding(.horizontal, 16)
                            .padding(.vertical, 10)
                            .background(Color.accentColor, in: Capsule())
                            .foregroundStyle(.white)
                    }
                    .padding(.top, 4)
                }
                .padding(.vertical, 30)
                .frame(maxWidth: .infinity)
                .background(Color(.secondarySystemGroupedBackground), in: RoundedRectangle(cornerRadius: 16, style: .continuous))
            } else {
                VStack(spacing: 0) {
                    ForEach(Array(contributions.enumerated()), id: \.element.id) { index, c in
                        contributionRow(c)
                            .contentShape(Rectangle())
                            .onTapGesture { editingContribution = c }
                            .swipeActions(edge: .trailing, allowsFullSwipe: false) {
                                Button(role: .destructive) {
                                    contributionToDelete = c
                                    showDeleteAlert = true
                                } label: {
                                    Label("Delete", systemImage: "trash")
                                }
                                Button {
                                    editingContribution = c
                                } label: {
                                    Label("Edit", systemImage: "pencil")
                                }
                                .tint(.blue)
                            }

                        if index < contributions.count - 1 {
                            Rectangle()
                                .fill(Color(.separator))
                                .frame(height: 0.5)
                                .padding(.leading, 52)
                        }
                    }
                }
                .background(Color(.secondarySystemGroupedBackground), in: RoundedRectangle(cornerRadius: 16, style: .continuous))
            }
        }
    }

    private func contributionRow(_ c: GoalContribution) -> some View {
        let goalColor = goal.map { Color(hex: $0.colorHex) } ?? .accentColor
        let fmt = DateFormatter()
        fmt.dateStyle = .medium

        return HStack(spacing: 12) {
            ZStack {
                Circle()
                    .fill(goalColor.opacity(0.15))
                    .frame(width: 36, height: 36)
                Image(systemName: "plus")
                    .font(.system(size: 14, weight: .bold))
                    .foregroundStyle(goalColor)
            }

            VStack(alignment: .leading, spacing: 2) {
                Text(c.note.isEmpty ? "Contribution" : c.note)
                    .font(.subheadline.weight(.medium))
                    .lineLimit(1)
                Text(fmt.string(from: c.date))
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Spacer()

            Text("+\(CurrencyFormatter.format(c.amount, currencyCode: currencyCode))")
                .font(.subheadline.weight(.semibold))
                .fontDesign(.rounded)
                .foregroundStyle(.green)
        }
        .padding(.vertical, 10)
        .padding(.horizontal, 14)
    }
}

private struct CumulativePoint: Identifiable {
    let date: Date
    let amount: Double
    var id: Date { date }
}
