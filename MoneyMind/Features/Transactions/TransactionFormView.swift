import SwiftUI

struct TransactionFormView: View {
    let isEditing: Bool
    let categories: [TransactionCategory]
    let goals: [SavingsGoal]
    let goalSaved: (Int) -> Double
    var onSave: (Transaction) -> Void
    var onContribute: ((_ goalId: Int, _ amount: Double, _ date: Date, _ note: String) -> Void)?

    @Environment(\.dismiss) private var dismiss
    @AppStorage("currencyCode") private var currencyCode = "USD"

    @State private var type: TransactionType
    @State private var amountText: String
    @State private var note: String
    @State private var date: Date
    @State private var selectedCategory: TransactionCategory?

    @State private var allocateToGoal: Bool = false
    @State private var selectedGoalId: Int?
    @State private var contributionText: String = ""

    /// When true, `contributionText` is derived from `trackingFraction * income`
    /// and kept in sync as the income changes or fraction buttons are tapped.
    /// Switches to `false` the moment the user manually types into the field.
    @State private var isTrackingIncome: Bool = true
    @State private var trackingFraction: Double = 0.20

    private let original: Transaction?

    init(
        transaction: Transaction? = nil,
        categories: [TransactionCategory],
        goals: [SavingsGoal] = [],
        goalSaved: @escaping (Int) -> Double = { _ in 0 },
        onSave: @escaping (Transaction) -> Void,
        onContribute: ((_ goalId: Int, _ amount: Double, _ date: Date, _ note: String) -> Void)? = nil
    ) {
        self.isEditing = transaction != nil
        self.original = transaction
        self.categories = categories
        self.goals = goals
        self.goalSaved = goalSaved
        self.onSave = onSave
        self.onContribute = onContribute

        _type = State(initialValue: transaction?.type ?? .expense)
        _amountText = State(initialValue: transaction.map { String(format: "%.2f", $0.amount) } ?? "")
        _note = State(initialValue: transaction?.note ?? "")
        _date = State(initialValue: transaction?.date ?? Date())

        let initialType = transaction?.type ?? .expense
        let availableCats = categories.filter { $0.type == initialType }
        if let t = transaction,
           let cat = categories.first(where: { $0.id == t.categoryId }) {
            _selectedCategory = State(initialValue: cat)
        } else {
            _selectedCategory = State(initialValue: availableCats.first)
        }

        _selectedGoalId = State(initialValue: goals.first?.id)
    }

    var availableCategories: [TransactionCategory] {
        categories.filter { $0.type == type }
    }

    var isFormValid: Bool {
        guard let amount = Double(amountText), amount > 0 else { return false }
        return selectedCategory != nil
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    typePicker
                    amountSection
                    categorySection
                    detailsSection
                    if showGoalAllocation {
                        goalAllocationSection
                    }
                }
                .padding()
            }
            .scrollDismissesKeyboard(.interactively)
            .background(Color(.systemGroupedBackground))
            .onChange(of: amountText) { _, _ in
                syncContributionIfTracking()
            }
            .onChange(of: contributionText) { _, newValue in
                guard isTrackingIncome else { return }
                let expected = formattedContribution(fraction: trackingFraction, of: transactionAmount)
                if newValue != expected {
                    isTrackingIncome = false
                }
            }
            .navigationTitle(isEditing ? "Edit Transaction" : "New Transaction")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        save()
                    }
                    .disabled(!isFormValid)
                    .fontWeight(.semibold)
                }
            }
        }
    }

    // MARK: - Type Picker

    private var typePicker: some View {
        HStack(spacing: 0) {
            ForEach(TransactionType.allCases, id: \.self) { t in
                Button {
                    withAnimation(.spring(duration: 0.3)) {
                        type = t
                        if selectedCategory?.type != t {
                            selectedCategory = availableCategories.first
                        }
                    }
                } label: {
                    HStack(spacing: 6) {
                        Image(systemName: t.systemImage)
                            .font(.caption.weight(.semibold))
                        Text(t.displayName)
                            .font(.subheadline.weight(.semibold))
                    }
                    .foregroundStyle(type == t ? .white : .secondary)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
                    .background(
                        type == t
                            ? (t == .expense ? Color.red : Color.green)
                            : Color.clear,
                        in: Capsule()
                    )
                }
                .buttonStyle(.plain)
            }
        }
        .padding(4)
        .background(Color(.systemGray5), in: Capsule())
    }

    // MARK: - Amount

    private var typeColor: Color { type == .expense ? .red : .green }

    private var currencySymbol: String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = currencyCode
        return formatter.currencySymbol
    }

    private var amountSection: some View {
        VStack(spacing: 6) {
            Text(currencyCode)
                .font(.caption.weight(.semibold))
                .foregroundStyle(.tertiary)
                .tracking(1.0)

            HStack(alignment: .firstTextBaseline, spacing: 4) {
                Text(currencySymbol)
                    .font(.system(size: 28, weight: .bold, design: .rounded))
                    .foregroundStyle(typeColor.opacity(0.6))

                TextField("0.00", text: $amountText)
                    .keyboardType(.decimalPad)
                    .font(.system(size: 48, weight: .bold, design: .rounded))
                    .multilineTextAlignment(.leading)
                    .foregroundStyle(typeColor)
                    .minimumScaleFactor(0.5)
                    .fixedSize()
            }
        }
        .padding(.vertical, 20)
        .frame(maxWidth: .infinity)
        .background(
            ZStack {
                Color(.secondarySystemGroupedBackground)
                typeColor.opacity(0.05)
            }
        )
        .clipShape(
            RoundedRectangle(cornerRadius: 20, style: .continuous)
        )
        .animation(.spring(duration: 0.3), value: type)
    }

    // MARK: - Category

    private var categorySection: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("Category")
                .font(.headline)

            if availableCategories.isEmpty {
                Text("No categories available. Add one in the Categories tab.")
                    .foregroundStyle(.secondary)
                    .font(.callout)
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding(.vertical, 12)
            } else {
                LazyVGrid(
                    columns: Array(repeating: GridItem(.flexible(), spacing: 8), count: 4),
                    spacing: 16
                ) {
                    ForEach(availableCategories) { category in
                        CategoryChip(
                            category: category,
                            isSelected: selectedCategory?.id == category.id
                        ) {
                            selectedCategory = category
                        }
                    }
                }
            }
        }
        .padding(16)
        .background(
            Color(.secondarySystemGroupedBackground),
            in: RoundedRectangle(cornerRadius: 20, style: .continuous)
        )
    }

    // MARK: - Details

    private var detailsSection: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("Details")
                .font(.headline)

            VStack(spacing: 12) {
                TextField("Note (optional)", text: $note)
                    .padding(12)
                    .background(
                        Color(.tertiarySystemFill),
                        in: RoundedRectangle(cornerRadius: 12, style: .continuous)
                    )

                HStack {
                    Text("Date & Time")
                    Spacer()
                    DatePicker("", selection: $date, displayedComponents: [.date, .hourAndMinute])
                        .labelsHidden()
                }
                .padding(12)
                .background(
                    Color(.tertiarySystemFill),
                    in: RoundedRectangle(cornerRadius: 12, style: .continuous)
                )
            }
        }
        .padding(16)
        .background(
            Color(.secondarySystemGroupedBackground),
            in: RoundedRectangle(cornerRadius: 20, style: .continuous)
        )
    }

    // MARK: - Goal Allocation

    private var showGoalAllocation: Bool {
        !isEditing && type == .income && !goals.isEmpty && onContribute != nil
    }

    private var selectedGoal: SavingsGoal? {
        goals.first { $0.id == selectedGoalId }
    }

    private var transactionAmount: Double { Double(amountText) ?? 0 }
    private var contributionAmount: Double { Double(contributionText) ?? 0 }

    private var goalAllocationSection: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(spacing: 10) {
                Image(systemName: "target")
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(.indigo)
                Text("Save to Goal")
                    .font(.headline)
                Spacer()
                Toggle("", isOn: $allocateToGoal.animation(.easeInOut(duration: 0.2)))
                    .labelsHidden()
                    .onChange(of: allocateToGoal) { _, enabled in
                        if enabled {
                            isTrackingIncome = true
                            trackingFraction = 0.20
                            syncContributionIfTracking()
                        }
                    }
            }

            if !allocateToGoal {
                Text("Set aside part of this income toward a savings goal.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            } else {
                goalPicker
                contributionAmountField
                quickFractionRow
            }
        }
        .padding(16)
        .background(
            Color(.secondarySystemGroupedBackground),
            in: RoundedRectangle(cornerRadius: 20, style: .continuous)
        )
    }

    private var goalPicker: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 10) {
                ForEach(goals) { goal in
                    goalChip(goal: goal)
                }
            }
        }
    }

    private func goalChip(goal: SavingsGoal) -> some View {
        let isSelected = selectedGoalId == goal.id
        let color = Color(hex: goal.colorHex)
        let saved = goalSaved(goal.id)
        let percent: Double = goal.targetAmount > 0
            ? min(saved / goal.targetAmount * 100, 100)
            : 0

        return Button {
            withAnimation(.spring(duration: 0.25)) {
                selectedGoalId = goal.id
            }
        } label: {
            HStack(spacing: 8) {
                ZStack {
                    Circle()
                        .fill(color.opacity(isSelected ? 0.9 : 0.15))
                        .frame(width: 28, height: 28)
                    Image(systemName: goal.icon)
                        .foregroundStyle(isSelected ? .white : color)
                        .font(.system(size: 12, weight: .semibold))
                }

                VStack(alignment: .leading, spacing: 1) {
                    Text(goal.name)
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(.primary)
                        .lineLimit(1)
                    Text("\(Int(percent))%")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }
            }
            .padding(.horizontal, 10)
            .padding(.vertical, 8)
            .background(
                Color(.tertiarySystemFill),
                in: RoundedRectangle(cornerRadius: 10, style: .continuous)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 10, style: .continuous)
                    .strokeBorder(isSelected ? color : Color.clear, lineWidth: 1.5)
            )
        }
        .buttonStyle(.plain)
    }

    private var contributionAmountField: some View {
        HStack(alignment: .firstTextBaseline, spacing: 6) {
            Text(currencySymbol)
                .font(.system(size: 20, weight: .bold, design: .rounded))
                .foregroundStyle(.secondary)
            TextField("0.00", text: $contributionText)
                .keyboardType(.decimalPad)
                .font(.system(size: 28, weight: .bold, design: .rounded))
                .foregroundStyle(.indigo)
                .minimumScaleFactor(0.5)
                .fixedSize()

            Spacer()

            if transactionAmount > 0 && contributionAmount > 0 {
                let pct = Int(min(contributionAmount / transactionAmount * 100, 999))
                Text("\(pct)% of income")
                    .font(.caption2)
                    .foregroundStyle(contributionAmount > transactionAmount ? .orange : .secondary)
            }
        }
        .padding(12)
        .background(
            Color(.tertiarySystemFill),
            in: RoundedRectangle(cornerRadius: 12, style: .continuous)
        )
    }

    private var quickFractionRow: some View {
        HStack(spacing: 8) {
            ForEach(Self.quickFractions, id: \.percent) { option in
                let fraction = Double(option.percent) / 100.0
                let isActive = isTrackingIncome && abs(trackingFraction - fraction) < 0.0001

                Button {
                    isTrackingIncome = true
                    trackingFraction = fraction
                    syncContributionIfTracking()
                } label: {
                    Text(option.label)
                        .font(.caption.weight(.semibold))
                        .fontDesign(.rounded)
                        .foregroundStyle(isActive ? .white : .primary)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 8)
                        .background(
                            isActive ? Color.indigo : Color(.tertiarySystemFill),
                            in: Capsule()
                        )
                }
                .buttonStyle(.plain)
                .animation(.spring(duration: 0.2), value: isActive)
            }
        }
    }

    private static let quickFractions: [(percent: Int, label: String)] = [
        (10, "10%"),
        (25, "25%"),
        (50, "50%"),
        (100, "All"),
    ]

    private func syncContributionIfTracking() {
        guard isTrackingIncome else { return }
        contributionText = formattedContribution(fraction: trackingFraction, of: transactionAmount)
    }

    private func formattedContribution(fraction: Double, of income: Double) -> String {
        String(format: "%.2f", max(0, income * fraction))
    }

    // MARK: - Save

    private func save() {
        guard let amount = Double(amountText), let category = selectedCategory else { return }
        let now = Date()
        let transaction: Transaction
        if let existing = original {
            transaction = Transaction(
                id: existing.id,
                amount: amount,
                note: note.trimmingCharacters(in: .whitespaces),
                date: date,
                type: type,
                categoryId: category.id,
                categoryName: category.name,
                categoryIcon: category.icon,
                categoryColorHex: category.colorHex,
                createdAt: existing.createdAt
            )
        } else {
            transaction = Transaction(
                id: 0,
                amount: amount,
                note: note.trimmingCharacters(in: .whitespaces),
                date: date,
                type: type,
                categoryId: category.id,
                categoryName: category.name,
                categoryIcon: category.icon,
                categoryColorHex: category.colorHex,
                createdAt: now
            )
        }
        onSave(transaction)

        if showGoalAllocation,
           allocateToGoal,
           let goalId = selectedGoalId,
           contributionAmount > 0,
           let onContribute {
            onContribute(
                goalId,
                contributionAmount,
                date,
                "From \(category.name)"
            )
        }

        dismiss()
    }
}

// MARK: - Category Chip

struct CategoryChip: View {
    let category: TransactionCategory
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(spacing: 8) {
                ZStack {
                    Circle()
                        .fill(
                            isSelected
                                ? Color(hex: category.colorHex)
                                : Color(hex: category.colorHex).opacity(0.12)
                        )
                        .frame(width: 48, height: 48)
                    Image(systemName: category.icon)
                        .foregroundStyle(isSelected ? .white : Color(hex: category.colorHex))
                        .font(.system(size: 20, weight: .semibold))
                }

                Text(category.name)
                    .font(.caption2)
                    .fontWeight(isSelected ? .semibold : .regular)
                    .foregroundStyle(isSelected ? Color(hex: category.colorHex) : .secondary)
                    .lineLimit(2)
                    .multilineTextAlignment(.center)
                    .frame(width: 60)
            }
        }
        .buttonStyle(.plain)
        .animation(.spring(duration: 0.2), value: isSelected)
    }
}
