import SwiftUI

struct TransactionFormView: View {
    let isEditing: Bool
    let categories: [TransactionCategory]
    var onSave: (Transaction) -> Void

    @Environment(\.dismiss) private var dismiss
    @AppStorage("currencyCode") private var currencyCode = "USD"

    @State private var type: TransactionType
    @State private var amountText: String
    @State private var note: String
    @State private var date: Date
    @State private var selectedCategory: TransactionCategory?

    private let original: Transaction?

    init(
        transaction: Transaction? = nil,
        categories: [TransactionCategory],
        onSave: @escaping (Transaction) -> Void
    ) {
        self.isEditing = transaction != nil
        self.original = transaction
        self.categories = categories
        self.onSave = onSave

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
                }
                .padding()
            }
            .scrollDismissesKeyboard(.interactively)
            .background(Color(.systemGroupedBackground))
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

    private var amountSection: some View {
        VStack(spacing: 8) {
            Text(currencyCode)
                .font(.subheadline.weight(.medium))
                .foregroundStyle(.secondary)

            TextField("0.00", text: $amountText)
                .keyboardType(.decimalPad)
                .font(.system(size: 48, weight: .bold, design: .rounded))
                .multilineTextAlignment(.center)
                .foregroundStyle(type == .expense ? .red : .green)
                .minimumScaleFactor(0.5)
        }
        .padding(.vertical, 20)
        .frame(maxWidth: .infinity)
        .background(
            Color(.secondarySystemGroupedBackground),
            in: RoundedRectangle(cornerRadius: 20, style: .continuous)
        )
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
                    Text("Date")
                    Spacer()
                    DatePicker("", selection: $date, displayedComponents: [.date])
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
