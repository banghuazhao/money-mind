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
            Form {
                Section {
                    Picker("Type", selection: $type) {
                        ForEach(TransactionType.allCases, id: \.self) { t in
                            Label(t.displayName, systemImage: t.systemImage).tag(t)
                        }
                    }
                    .pickerStyle(.segmented)
                    .onChange(of: type) { _, newType in
                        if selectedCategory?.type != newType {
                            selectedCategory = availableCategories.first
                        }
                    }
                }
                .listRowInsets(EdgeInsets(top: 12, leading: 16, bottom: 12, trailing: 16))

                Section("Amount") {
                    HStack {
                        Text(currencyCode)
                            .foregroundStyle(.secondary)
                            .font(.caption)
                            .padding(.trailing, 4)
                        TextField("0.00", text: $amountText)
                            .keyboardType(.decimalPad)
                            .font(.title2.weight(.semibold))
                    }
                }

                Section("Category") {
                    if availableCategories.isEmpty {
                        Text("No categories available. Add one in the Categories tab.")
                            .foregroundStyle(.secondary)
                            .font(.callout)
                    } else {
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 12) {
                                ForEach(availableCategories) { category in
                                    CategoryChip(
                                        category: category,
                                        isSelected: selectedCategory?.id == category.id
                                    ) {
                                        selectedCategory = category
                                    }
                                }
                            }
                            .padding(.vertical, 4)
                        }
                    }
                }

                Section("Details") {
                    TextField("Note (optional)", text: $note)
                    DatePicker("Date", selection: $date, displayedComponents: [.date])
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
            // id: 0 is a placeholder — the DB assigns the real auto-increment id on insert
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

struct CategoryChip: View {
    let category: TransactionCategory
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(spacing: 6) {
                ZStack {
                    Circle()
                        .fill(isSelected ? Color(hex: category.colorHex) : Color(.systemGray5))
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
