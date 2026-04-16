import SwiftUI

/// Lightweight sheet for contributing to a savings goal directly from an
/// income transaction. Pre-fills amount/date/note from the source transaction
/// and lets the user pick which goal to contribute to.
///
/// Contributions created here remain logically independent from the source
/// transaction — the source transaction is unchanged, and nothing about the
/// transaction's appearance on the books is modified.
struct QuickContributeSheet: View {
    let sourceTransaction: Transaction
    let goals: [SavingsGoal]
    let goalProgress: (SavingsGoal) -> (saved: Double, target: Double)
    let currencyCode: String
    var onSave: (_ goalId: Int, _ amount: Double, _ date: Date, _ note: String) -> Void

    @Environment(\.dismiss) private var dismiss

    @State private var selectedGoalId: Int?
    @State private var amountText: String
    @State private var note: String

    init(
        sourceTransaction: Transaction,
        goals: [SavingsGoal],
        goalProgress: @escaping (SavingsGoal) -> (saved: Double, target: Double),
        currencyCode: String,
        onSave: @escaping (_ goalId: Int, _ amount: Double, _ date: Date, _ note: String) -> Void
    ) {
        self.sourceTransaction = sourceTransaction
        self.goals = goals
        self.goalProgress = goalProgress
        self.currencyCode = currencyCode
        self.onSave = onSave
        _selectedGoalId = State(initialValue: goals.first?.id)
        _amountText = State(initialValue: String(format: "%.2f", sourceTransaction.amount))
        _note = State(initialValue: "From \(sourceTransaction.categoryName)")
    }

    private var isValid: Bool {
        selectedGoalId != nil && (Double(amountText) ?? 0) > 0
    }

    private var currencySymbol: String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = currencyCode
        return formatter.currencySymbol
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 16) {
                    sourceCard
                    goalPickerSection
                    amountSection
                    noteSection
                }
                .padding(.horizontal)
                .padding(.vertical, 16)
            }
            .background(Color(.systemGroupedBackground))
            .navigationTitle("Save to Goal")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Contribute") { save() }
                        .disabled(!isValid)
                        .fontWeight(.semibold)
                }
            }
        }
    }

    // MARK: - Source Card

    private var sourceCard: some View {
        let color = Color(hex: sourceTransaction.categoryColorHex)

        return HStack(spacing: 14) {
            ZStack {
                Circle()
                    .fill(color.opacity(0.15))
                    .frame(width: 44, height: 44)
                Image(systemName: sourceTransaction.categoryIcon)
                    .foregroundStyle(color)
                    .font(.system(size: 18, weight: .semibold))
            }

            VStack(alignment: .leading, spacing: 2) {
                Text("From Income")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Text(sourceTransaction.categoryName)
                    .font(.subheadline.weight(.semibold))
            }

            Spacer()

            Text("+\(CurrencyFormatter.format(sourceTransaction.amount, currencyCode: currencyCode))")
                .font(.subheadline.weight(.bold))
                .fontDesign(.rounded)
                .foregroundStyle(.green)
        }
        .padding(14)
        .background(Color(.secondarySystemGroupedBackground), in: RoundedRectangle(cornerRadius: 16, style: .continuous))
    }

    // MARK: - Goal Picker

    private var goalPickerSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Contribute to")
                .font(.headline)
                .padding(.horizontal, 4)

            VStack(spacing: 8) {
                ForEach(goals) { goal in
                    goalRow(goal: goal)
                }
            }
        }
    }

    private func goalRow(goal: SavingsGoal) -> some View {
        let isSelected = selectedGoalId == goal.id
        let color = Color(hex: goal.colorHex)
        let progress = goalProgress(goal)
        let percent: Double = progress.target > 0
            ? min(progress.saved / progress.target * 100, 100)
            : 0

        return Button {
            withAnimation(.spring(duration: 0.25)) {
                selectedGoalId = goal.id
            }
        } label: {
            HStack(spacing: 12) {
                ZStack {
                    Circle()
                        .fill(color.opacity(0.15))
                        .frame(width: 40, height: 40)
                    Image(systemName: goal.icon)
                        .foregroundStyle(color)
                        .font(.system(size: 16, weight: .semibold))
                }

                VStack(alignment: .leading, spacing: 4) {
                    Text(goal.name)
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(.primary)

                    HStack(spacing: 6) {
                        Text("\(Int(percent))%")
                            .font(.caption2.weight(.semibold))
                            .foregroundStyle(color)
                        Text("·")
                            .foregroundStyle(.tertiary)
                        Text("\(CurrencyFormatter.format(progress.saved, currencyCode: currencyCode)) / \(CurrencyFormatter.format(progress.target, currencyCode: currencyCode))")
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                            .lineLimit(1)
                    }
                }

                Spacer(minLength: 0)

                ZStack {
                    Circle()
                        .strokeBorder(
                            isSelected ? color : Color(.systemGray4),
                            lineWidth: isSelected ? 6 : 1.5
                        )
                        .frame(width: 22, height: 22)
                }
            }
            .padding(12)
            .background(
                Color(.secondarySystemGroupedBackground),
                in: RoundedRectangle(cornerRadius: 14, style: .continuous)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .strokeBorder(isSelected ? color : Color.clear, lineWidth: 1.5)
            )
        }
        .buttonStyle(.plain)
    }

    // MARK: - Amount

    private var amountSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Amount")
                .font(.headline)
                .padding(.horizontal, 4)

            HStack(alignment: .firstTextBaseline, spacing: 6) {
                Text(currencySymbol)
                    .font(.system(size: 24, weight: .bold, design: .rounded))
                    .foregroundStyle(Color.green.opacity(0.6))
                TextField("0.00", text: $amountText)
                    .keyboardType(.decimalPad)
                    .font(.system(size: 36, weight: .bold, design: .rounded))
                    .foregroundStyle(.green)
                    .minimumScaleFactor(0.5)
                    .fixedSize()

                Spacer()

                if let amount = Double(amountText), amount < sourceTransaction.amount, sourceTransaction.amount > 0 {
                    let percent = Int(amount / sourceTransaction.amount * 100)
                    Text("\(percent)% of income")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }
            }
            .padding(14)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(
                Color(.secondarySystemGroupedBackground),
                in: RoundedRectangle(cornerRadius: 14, style: .continuous)
            )

            HStack(spacing: 8) {
                ForEach(Self.quickFractions, id: \.percent) { option in
                    Button {
                        let fraction = Double(option.percent) / 100.0
                        let value = sourceTransaction.amount * fraction
                        amountText = String(format: "%.2f", value)
                    } label: {
                        Text(option.label)
                            .font(.caption.weight(.semibold))
                            .fontDesign(.rounded)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 8)
                            .background(
                                Color(.tertiarySystemFill),
                                in: Capsule()
                            )
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }

    private static let quickFractions: [(percent: Int, label: String)] = [
        (10, "10%"),
        (25, "25%"),
        (50, "50%"),
        (100, "All"),
    ]

    // MARK: - Note

    private var noteSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Note")
                .font(.headline)
                .padding(.horizontal, 4)

            TextField("Optional note", text: $note)
                .padding(14)
                .background(
                    Color(.secondarySystemGroupedBackground),
                    in: RoundedRectangle(cornerRadius: 14, style: .continuous)
                )
        }
    }

    // MARK: - Save

    private func save() {
        guard
            let goalId = selectedGoalId,
            let amount = Double(amountText),
            amount > 0
        else { return }

        onSave(
            goalId,
            amount,
            sourceTransaction.date,
            note.trimmingCharacters(in: .whitespaces)
        )
        dismiss()
    }
}
