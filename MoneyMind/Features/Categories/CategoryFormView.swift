import SwiftUI

struct CategoryFormView: View {
    let isEditing: Bool
    var onSave: (TransactionCategory) -> Void

    @Environment(\.dismiss) private var dismiss

    @State private var name: String
    @State private var icon: String
    @State private var selectedColor: Color
    @State private var type: TransactionType
    @State private var showIconPicker = false

    private let original: TransactionCategory?

    init(category: TransactionCategory? = nil, onSave: @escaping (TransactionCategory) -> Void) {
        self.isEditing = category != nil
        self.original = category
        self.onSave = onSave
        _name = State(initialValue: category?.name ?? "")
        _icon = State(initialValue: category?.icon ?? "tag.fill")
        _selectedColor = State(initialValue: Color(hex: category?.colorHex ?? "#45B7D1"))
        _type = State(initialValue: category?.type ?? .expense)
    }

    var isFormValid: Bool {
        !name.trimmingCharacters(in: .whitespaces).isEmpty
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("Details") {
                    TextField("Category Name", text: $name)

                    Picker("Type", selection: $type) {
                        ForEach(TransactionType.allCases, id: \.self) { t in
                            Text(t.displayName).tag(t)
                        }
                    }
                    .pickerStyle(.segmented)
                }

                Section("Appearance") {
                    Button {
                        showIconPicker = true
                    } label: {
                        HStack {
                            Text("Icon")
                                .foregroundStyle(.primary)
                            Spacer()
                            ZStack {
                                Circle()
                                    .fill(selectedColor)
                                    .frame(width: 36, height: 36)
                                Image(systemName: icon)
                                    .foregroundStyle(.white)
                                    .font(.system(size: 16, weight: .semibold))
                            }
                            Image(systemName: "chevron.right")
                                .foregroundStyle(.tertiary)
                                .font(.caption)
                        }
                    }

                    ColorPicker("Color", selection: $selectedColor, supportsOpacity: false)
                }
            }
            .navigationTitle(isEditing ? "Edit Category" : "New Category")
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
            .sheet(isPresented: $showIconPicker) {
                IconPickerView(selectedIcon: $icon, selectedColor: selectedColor)
            }
        }
    }

    private func save() {
        let now = Date()
        let category: TransactionCategory
        if let existing = original {
            category = TransactionCategory(
                id: existing.id,
                name: name.trimmingCharacters(in: .whitespaces),
                icon: icon,
                colorHex: selectedColor.hexString,
                type: type,
                createdAt: existing.createdAt
            )
        } else {
            // id: 0 is a placeholder — the DB assigns the real auto-increment id on insert
            category = TransactionCategory(
                id: 0,
                name: name.trimmingCharacters(in: .whitespaces),
                icon: icon,
                colorHex: selectedColor.hexString,
                type: type,
                createdAt: now
            )
        }
        onSave(category)
        dismiss()
    }
}

struct IconPickerView: View {
    @Binding var selectedIcon: String
    let selectedColor: Color
    @Environment(\.dismiss) private var dismiss

    let icons: [String] = [
        "fork.knife", "car.fill", "bag.fill", "tv.fill", "heart.fill",
        "bolt.fill", "house.fill", "book.fill", "ellipsis.circle.fill",
        "banknote.fill", "laptopcomputer", "chart.line.uptrend.xyaxis",
        "gift.fill", "plus.circle.fill", "airplane", "tram.fill",
        "bus.fill", "bicycle", "cart.fill", "creditcard.fill",
        "gamecontroller.fill", "music.note", "film.fill", "camera.fill",
        "pills.fill", "stethoscope", "figure.walk", "dumbbell.fill",
        "leaf.fill", "pawprint.fill", "phone.fill", "wifi", "tag.fill",
        "star.fill", "flame.fill", "drop.fill", "umbrella.fill",
        "wrench.and.screwdriver.fill", "paintbrush.fill", "scissors",
        "graduationcap.fill", "building.2.fill", "building.columns.fill",
    ]

    let columns = Array(repeating: GridItem(.flexible(), spacing: 12), count: 5)

    var body: some View {
        NavigationStack {
            ScrollView {
                LazyVGrid(columns: columns, spacing: 16) {
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
