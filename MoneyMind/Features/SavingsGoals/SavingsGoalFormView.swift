import SwiftUI

struct SavingsGoalDraft {
    var name: String
    var icon: String
    var colorHex: String
    var targetAmount: Double
    var targetDate: Date?
    var note: String
}

struct SavingsGoalFormView: View {
    let isEditing: Bool
    let currencyCode: String
    var onSave: (SavingsGoalDraft) -> Void

    @Environment(\.dismiss) private var dismiss

    @State private var name: String
    @State private var icon: String
    @State private var selectedColorHex: String
    @State private var amountText: String
    @State private var hasDeadline: Bool
    @State private var targetDate: Date
    @State private var note: String
    @State private var showIconPicker = false

    private let original: SavingsGoal?

    static let presetColors: [String] = [
        "#3B82F6", "#10B981", "#F59E0B", "#EF4444", "#8B5CF6",
        "#EC4899", "#06B6D4", "#D97706", "#059669", "#7C3AED",
        "#EAB308", "#BE185D"
    ]

    static let presetIcons: [String] = [
        "target", "flag.fill", "star.fill", "trophy.fill", "gift.fill",
        "airplane", "house.fill", "car.fill", "graduationcap.fill",
        "heart.fill", "cross.case.fill", "laptopcomputer", "camera.fill",
        "gamecontroller.fill", "pawprint.fill", "figure.and.child.holdinghands",
        "dumbbell.fill", "sparkles", "cart.fill", "creditcard.fill",
        "banknote.fill", "bag.fill", "building.2.fill", "building.columns.fill",
    ]

    init(
        goal: SavingsGoal? = nil,
        currencyCode: String,
        onSave: @escaping (SavingsGoalDraft) -> Void
    ) {
        self.isEditing = goal != nil
        self.original = goal
        self.currencyCode = currencyCode
        self.onSave = onSave
        _name = State(initialValue: goal?.name ?? "")
        _icon = State(initialValue: goal?.icon ?? "target")
        _selectedColorHex = State(initialValue: goal?.colorHex ?? "#3B82F6")
        if let amount = goal?.targetAmount {
            _amountText = State(initialValue: String(format: "%.2f", amount))
        } else {
            _amountText = State(initialValue: "")
        }
        _hasDeadline = State(initialValue: goal?.targetDate != nil)
        _targetDate = State(
            initialValue: goal?.targetDate ?? Calendar.current.date(
                byAdding: .month, value: 6, to: Date()
            ) ?? Date()
        )
        _note = State(initialValue: goal?.note ?? "")
    }

    private var isValid: Bool {
        !name.trimmingCharacters(in: .whitespaces).isEmpty
            && (Double(amountText) ?? 0) > 0
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
                    headerCard
                    amountSection
                    appearanceSection
                    deadlineSection
                    noteSection
                }
                .padding(.horizontal)
                .padding(.vertical, 16)
            }
            .background(Color(.systemGroupedBackground))
            .navigationTitle(isEditing ? "Edit Goal" : "New Goal")
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
            .sheet(isPresented: $showIconPicker) {
                GoalIconPickerView(
                    selectedIcon: $icon,
                    selectedColor: Color(hex: selectedColorHex),
                    icons: Self.presetIcons
                )
            }
        }
    }

    // MARK: - Sections

    private var headerCard: some View {
        VStack(spacing: 14) {
            Button {
                showIconPicker = true
            } label: {
                let selectedColor = Color(hex: selectedColorHex)
                ZStack {
                    Circle()
                        .fill(selectedColor.gradient)
                        .frame(width: 84, height: 84)
                        .shadow(color: selectedColor.opacity(0.35), radius: 12, y: 6)
                    Image(systemName: icon)
                        .foregroundStyle(.white)
                        .font(.system(size: 36, weight: .semibold))
                }
            }
            .buttonStyle(.plain)

            TextField("Goal name (e.g. Vacation)", text: $name)
                .font(.headline)
                .multilineTextAlignment(.center)
                .padding(.vertical, 10)
                .padding(.horizontal, 14)
                .background(
                    Color(.tertiarySystemFill),
                    in: RoundedRectangle(cornerRadius: 12, style: .continuous)
                )
        }
        .padding(16)
        .frame(maxWidth: .infinity)
        .background(Color(.secondarySystemGroupedBackground), in: RoundedRectangle(cornerRadius: 20, style: .continuous))
    }

    private var amountSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Target Amount")
                .font(.headline)

            HStack(alignment: .firstTextBaseline, spacing: 6) {
                Text(currencySymbol)
                    .font(.system(size: 28, weight: .bold, design: .rounded))
                    .foregroundStyle(.secondary)
                TextField("0.00", text: $amountText)
                    .keyboardType(.decimalPad)
                    .font(.system(size: 42, weight: .bold, design: .rounded))
                    .minimumScaleFactor(0.5)
            }
            .padding(.vertical, 10)
            .padding(.horizontal, 14)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(
                Color(.tertiarySystemFill),
                in: RoundedRectangle(cornerRadius: 14, style: .continuous)
            )
        }
        .padding(16)
        .background(Color(.secondarySystemGroupedBackground), in: RoundedRectangle(cornerRadius: 20, style: .continuous))
    }

    private var appearanceSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Color")
                .font(.headline)

            LazyVGrid(
                columns: Array(repeating: GridItem(.flexible(), spacing: 8), count: 6),
                spacing: 10
            ) {
                ForEach(Self.presetColors, id: \.self) { hex in
                    let isSelected = hex.lowercased() == selectedColorHex.lowercased()
                    Button {
                        withAnimation(.spring(duration: 0.25)) {
                            selectedColorHex = hex
                        }
                    } label: {
                        ZStack {
                            Circle()
                                .fill(Color(hex: hex))
                                .frame(width: 38, height: 38)
                            if isSelected {
                                Circle()
                                    .strokeBorder(Color.primary.opacity(0.6), lineWidth: 2)
                                    .frame(width: 44, height: 44)
                                Image(systemName: "checkmark")
                                    .font(.caption.weight(.bold))
                                    .foregroundStyle(.white)
                            }
                        }
                    }
                    .buttonStyle(.plain)
                }
            }
        }
        .padding(16)
        .background(Color(.secondarySystemGroupedBackground), in: RoundedRectangle(cornerRadius: 20, style: .continuous))
    }

    private var deadlineSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Target Date")
                    .font(.headline)
                Spacer()
                Toggle("", isOn: $hasDeadline.animation(.easeInOut(duration: 0.2)))
                    .labelsHidden()
            }

            if hasDeadline {
                DatePicker(
                    "",
                    selection: $targetDate,
                    in: Date()...,
                    displayedComponents: .date
                )
                .labelsHidden()
                .datePickerStyle(.graphical)
            } else {
                Text("No deadline — save at your own pace.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .padding(16)
        .background(Color(.secondarySystemGroupedBackground), in: RoundedRectangle(cornerRadius: 20, style: .continuous))
    }

    private var noteSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Note")
                .font(.headline)

            TextField("Why this goal matters (optional)", text: $note, axis: .vertical)
                .lineLimit(3, reservesSpace: true)
                .padding(12)
                .background(
                    Color(.tertiarySystemFill),
                    in: RoundedRectangle(cornerRadius: 12, style: .continuous)
                )
        }
        .padding(16)
        .background(Color(.secondarySystemGroupedBackground), in: RoundedRectangle(cornerRadius: 20, style: .continuous))
    }

    // MARK: - Save

    private func save() {
        guard let amount = Double(amountText), amount > 0 else { return }
        let draft = SavingsGoalDraft(
            name: name.trimmingCharacters(in: .whitespaces),
            icon: icon,
            colorHex: selectedColorHex,
            targetAmount: amount,
            targetDate: hasDeadline ? targetDate : nil,
            note: note.trimmingCharacters(in: .whitespaces)
        )
        onSave(draft)
        dismiss()
    }
}

// MARK: - Icon Picker

struct GoalIconPickerView: View {
    @Binding var selectedIcon: String
    let selectedColor: Color
    let icons: [String]

    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            ScrollView {
                LazyVGrid(
                    columns: Array(repeating: GridItem(.flexible(), spacing: 12), count: 5),
                    spacing: 16
                ) {
                    ForEach(icons, id: \.self) { icon in
                        Button {
                            selectedIcon = icon
                            dismiss()
                        } label: {
                            ZStack {
                                Circle()
                                    .fill(selectedIcon == icon ? selectedColor : Color(.systemGray5))
                                    .frame(width: 52, height: 52)
                                Image(systemName: icon)
                                    .foregroundStyle(selectedIcon == icon ? .white : .secondary)
                                    .font(.system(size: 22))
                            }
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding()
            }
            .navigationTitle("Choose Icon")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
            }
        }
    }
}
