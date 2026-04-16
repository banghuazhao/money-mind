import SwiftUI

struct BudgetFormView: View {
    let isEditing: Bool
    let availableCategories: [TransactionCategory]
    let currencyCode: String
    var onSave: (_ categoryId: Int, _ amount: Double) -> Void

    @Environment(\.dismiss) private var dismiss

    @State private var amountText: String
    @State private var selectedCategory: TransactionCategory?

    init(
        budget: Budget? = nil,
        availableCategories: [TransactionCategory],
        currencyCode: String,
        onSave: @escaping (Int, Double) -> Void
    ) {
        self.isEditing = budget != nil
        self.availableCategories = availableCategories
        self.currencyCode = currencyCode
        self.onSave = onSave

        _amountText = State(initialValue: budget.map { String(format: "%.2f", $0.amount) } ?? "")

        if let b = budget,
           let cat = availableCategories.first(where: { $0.id == b.categoryId }) {
            _selectedCategory = State(initialValue: cat)
        } else {
            _selectedCategory = State(initialValue: availableCategories.first)
        }
    }

    var isFormValid: Bool {
        guard let amount = Double(amountText), amount > 0 else { return false }
        return selectedCategory != nil
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    amountSection
                    categorySection
                    tipSection
                }
                .padding()
            }
            .scrollDismissesKeyboard(.interactively)
            .background(Color(.systemGroupedBackground))
            .navigationTitle(isEditing ? "Edit Budget" : "New Budget")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") { save() }
                        .disabled(!isFormValid)
                        .fontWeight(.semibold)
                }
            }
        }
    }

    // MARK: - Amount Section

    private var amountSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Monthly Limit")
                .font(.caption)
                .foregroundStyle(.secondary)
                .padding(.leading, 4)

            HStack(spacing: 10) {
                Text(currencySymbol)
                    .font(.system(size: 34, weight: .bold, design: .rounded))
                    .foregroundStyle(.secondary)

                TextField("0.00", text: $amountText)
                    .font(.system(size: 34, weight: .bold, design: .rounded))
                    .keyboardType(.decimalPad)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 14)
            .background(
                Color(.secondarySystemGroupedBackground),
                in: RoundedRectangle(cornerRadius: 14, style: .continuous)
            )
        }
    }

    // MARK: - Category Section

    @ViewBuilder
    private var categorySection: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Category")
                .font(.caption)
                .foregroundStyle(.secondary)
                .padding(.leading, 4)

            if availableCategories.isEmpty {
                Text("All expense categories already have budgets.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(16)
                    .background(
                        Color(.secondarySystemGroupedBackground),
                        in: RoundedRectangle(cornerRadius: 14, style: .continuous)
                    )
            } else {
                LazyVGrid(columns: [GridItem(.adaptive(minimum: 100), spacing: 10)], spacing: 10) {
                    ForEach(availableCategories) { category in
                        BudgetCategoryChip(
                            category: category,
                            isSelected: selectedCategory?.id == category.id
                        ) {
                            withAnimation(.spring(duration: 0.25)) {
                                selectedCategory = category
                            }
                        }
                    }
                }
            }
        }
    }

    // MARK: - Tip Section

    private var tipSection: some View {
        HStack(alignment: .top, spacing: 10) {
            Image(systemName: "lightbulb.fill")
                .foregroundStyle(.yellow)
                .font(.subheadline)

            Text("This budget applies every month. You'll see a warning when spending reaches 80%, and an alert when you go over.")
                .font(.caption)
                .foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(14)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            Color.yellow.opacity(0.08),
            in: RoundedRectangle(cornerRadius: 12, style: .continuous)
        )
    }

    // MARK: - Helpers

    private var currencySymbol: String {
        let fmt = NumberFormatter()
        fmt.numberStyle = .currency
        fmt.currencyCode = currencyCode
        return fmt.currencySymbol ?? "$"
    }

    private func save() {
        guard let amount = Double(amountText), amount > 0,
              let category = selectedCategory else { return }
        onSave(category.id, amount)
        dismiss()
    }
}

// MARK: - Budget Category Chip

private struct BudgetCategoryChip: View {
    let category: TransactionCategory
    let isSelected: Bool
    let action: () -> Void

    private var color: Color { Color(hex: category.colorHex) }

    var body: some View {
        Button(action: action) {
            HStack(spacing: 8) {
                Image(systemName: category.icon)
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(isSelected ? .white : color)
                    .frame(width: 22)

                Text(category.name)
                    .font(.caption.weight(isSelected ? .semibold : .regular))
                    .foregroundStyle(isSelected ? .white : .primary)
                    .lineLimit(1)
                    .minimumScaleFactor(0.7)
            }
            .frame(maxWidth: .infinity, minHeight: 36)
            .padding(.horizontal, 10)
            .background(
                isSelected ? color : Color(.secondarySystemGroupedBackground),
                in: RoundedRectangle(cornerRadius: 10, style: .continuous)
            )
        }
        .buttonStyle(.plain)
    }
}
