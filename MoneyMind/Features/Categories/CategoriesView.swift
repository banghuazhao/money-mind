import SwiftUI

struct CategoriesView: View {
    @State private var viewModel = CategoriesViewModel()
    @State private var selectedType: TransactionType = .expense
    @State private var isEditMode = false

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                Picker("Type", selection: $selectedType) {
                    ForEach(TransactionType.allCases, id: \.self) { type in
                        Text(type.displayName).tag(type)
                    }
                }
                .pickerStyle(.segmented)
                .padding(.horizontal)
                .padding(.vertical, 12)
                .onChange(of: selectedType) { _, _ in
                    if isEditMode {
                        withAnimation { isEditMode = false }
                    }
                }

                categoryGrid
            }
            .background(Color(.systemGroupedBackground))
            .navigationTitle("Categories")
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Button {
                        viewModel.isShowingAddSheet = true
                    } label: {
                        Image(systemName: "plus.circle.fill")
                            .font(.title2)
                            .symbolRenderingMode(.hierarchical)
                    }
                }
                ToolbarItem(placement: .topBarLeading) {
                    let filtered = viewModel.categoriesForType(selectedType)
                    if !filtered.isEmpty {
                        Button(isEditMode ? "Done" : "Edit") {
                            withAnimation(.spring(duration: 0.3)) {
                                isEditMode.toggle()
                            }
                        }
                        .fontWeight(isEditMode ? .semibold : .regular)
                    }
                }
            }
            .sheet(isPresented: $viewModel.isShowingAddSheet) {
                CategoryFormView { category in
                    viewModel.addCategory(category)
                }
            }
            .sheet(item: $viewModel.editingCategory) { category in
                CategoryFormView(category: category) { updated in
                    viewModel.updateCategory(updated)
                }
            }
            .alert("Delete Category", isPresented: $viewModel.showDeleteAlert) {
                Button("Delete", role: .destructive) {
                    if let cat = viewModel.categoryToDelete {
                        viewModel.deleteCategory(cat)
                    }
                }
                Button("Cancel", role: .cancel) {}
            } message: {
                Text("Are you sure you want to delete this category? This won't delete existing transactions.")
            }
        }
    }

    // MARK: - Category Grid

    @ViewBuilder
    private var categoryGrid: some View {
        let filtered = viewModel.categoriesForType(selectedType)

        if filtered.isEmpty {
            ContentUnavailableView(
                "No Categories",
                systemImage: "tag.slash",
                description: Text("Add a category to get started.")
            )
        } else {
            ScrollView {
                LazyVGrid(
                    columns: Array(
                        repeating: GridItem(.flexible(), spacing: 12),
                        count: 3
                    ),
                    spacing: 12
                ) {
                    ForEach(filtered) { category in
                        CategoryCard(category: category, isEditMode: isEditMode) {
                            if !isEditMode {
                                viewModel.editingCategory = category
                            }
                        } onDelete: {
                            viewModel.categoryToDelete = category
                            viewModel.showDeleteAlert = true
                        }
                        .contextMenu {
                            Button {
                                viewModel.editingCategory = category
                            } label: {
                                Label("Edit", systemImage: "pencil")
                            }
                            Button(role: .destructive) {
                                viewModel.categoryToDelete = category
                                viewModel.showDeleteAlert = true
                            } label: {
                                Label("Delete", systemImage: "trash")
                            }
                        }
                    }
                }
                .padding()
            }
        }
    }
}

// MARK: - Category Card

struct CategoryCard: View {
    let category: TransactionCategory
    var isEditMode: Bool = false
    let onTap: () -> Void
    var onDelete: (() -> Void)? = nil

    var body: some View {
        Button(action: onTap) {
            VStack(spacing: 10) {
                ZStack {
                    Circle()
                        .fill(Color(hex: category.colorHex).opacity(0.15))
                        .frame(width: 48, height: 48)
                    Image(systemName: category.icon)
                        .foregroundStyle(Color(hex: category.colorHex))
                        .font(.system(size: 20, weight: .semibold))
                }

                Text(category.name)
                    .font(.caption.weight(.medium))
                    .foregroundStyle(.primary)
                    .lineLimit(2)
                    .multilineTextAlignment(.center)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
            .padding(.horizontal, 8)
            .background(
                Color(.secondarySystemGroupedBackground),
                in: RoundedRectangle(cornerRadius: 16, style: .continuous)
            )
            .overlay(alignment: .topLeading) {
                if isEditMode {
                    Button {
                        onDelete?()
                    } label: {
                        Image(systemName: "minus.circle.fill")
                            .foregroundStyle(.red)
                            .font(.system(size: 20))
                            .background(Circle().fill(Color(.secondarySystemGroupedBackground)))
                    }
                    .offset(x: -4, y: -4)
                    .transition(.scale.combined(with: .opacity))
                }
            }
        }
        .buttonStyle(.plain)
        .scaleEffect(isEditMode ? 0.96 : 1.0)
        .animation(.spring(duration: 0.25), value: isEditMode)
    }
}
