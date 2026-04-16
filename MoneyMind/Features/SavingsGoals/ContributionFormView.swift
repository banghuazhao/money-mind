import SwiftUI

struct ContributionDraft {
    var amount: Double
    var date: Date
    var note: String
}

struct ContributionFormView: View {
    let isEditing: Bool
    let currencyCode: String
    var onSave: (ContributionDraft) -> Void

    @Environment(\.dismiss) private var dismiss

    @State private var amountText: String
    @State private var date: Date
    @State private var note: String

    init(
        contribution: GoalContribution? = nil,
        currencyCode: String,
        onSave: @escaping (ContributionDraft) -> Void
    ) {
        self.isEditing = contribution != nil
        self.currencyCode = currencyCode
        self.onSave = onSave
        if let amount = contribution?.amount {
            _amountText = State(initialValue: String(format: "%.2f", amount))
        } else {
            _amountText = State(initialValue: "")
        }
        _date = State(initialValue: contribution?.date ?? Date())
        _note = State(initialValue: contribution?.note ?? "")
    }

    private var isValid: Bool {
        (Double(amountText) ?? 0) > 0
    }

    private var currencySymbol: String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = currencyCode
        return formatter.currencySymbol
    }

    private static let quickAmounts: [Double] = [10, 25, 50, 100, 200, 500]

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 16) {
                    amountSection
                    quickAmountsSection
                    detailsSection
                }
                .padding(.horizontal)
                .padding(.vertical, 16)
            }
            .background(Color(.systemGroupedBackground))
            .navigationTitle(isEditing ? "Edit Contribution" : "Add Contribution")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") { save() }
                        .disabled(!isValid)
                        .fontWeight(.semibold)
                }
            }
        }
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
                    .foregroundStyle(Color.green.opacity(0.6))

                TextField("0.00", text: $amountText)
                    .keyboardType(.decimalPad)
                    .font(.system(size: 48, weight: .bold, design: .rounded))
                    .multilineTextAlignment(.leading)
                    .foregroundStyle(.green)
                    .minimumScaleFactor(0.5)
                    .fixedSize()
            }
        }
        .padding(.vertical, 20)
        .frame(maxWidth: .infinity)
        .background(
            ZStack {
                Color(.secondarySystemGroupedBackground)
                Color.green.opacity(0.05)
            }
        )
        .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
    }

    private var quickAmountsSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Quick amounts")
                .font(.caption)
                .foregroundStyle(.secondary)
                .padding(.horizontal, 4)

            LazyVGrid(
                columns: Array(repeating: GridItem(.flexible(), spacing: 8), count: 3),
                spacing: 8
            ) {
                ForEach(Self.quickAmounts, id: \.self) { amount in
                    Button {
                        amountText = String(format: "%.2f", amount)
                    } label: {
                        Text(CurrencyFormatter.format(amount, currencyCode: currencyCode))
                            .font(.subheadline.weight(.semibold))
                            .fontDesign(.rounded)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 10)
                            .background(
                                Color(.tertiarySystemFill),
                                in: RoundedRectangle(cornerRadius: 12, style: .continuous)
                            )
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }

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
        .background(Color(.secondarySystemGroupedBackground), in: RoundedRectangle(cornerRadius: 20, style: .continuous))
    }

    private func save() {
        guard let amount = Double(amountText), amount > 0 else { return }
        onSave(ContributionDraft(
            amount: amount,
            date: date,
            note: note.trimmingCharacters(in: .whitespaces)
        ))
        dismiss()
    }
}
