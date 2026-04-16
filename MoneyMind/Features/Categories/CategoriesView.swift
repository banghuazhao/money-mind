import SwiftUI

struct CategoriesView: View {
    @State private var viewModel = CategoriesViewModel()
    @State private var selectedType: TransactionType = .expense

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
                        CategoryCard(category: category)
                            .onTapGesture {
                                viewModel.editingCategory = category
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

    var body: some View {
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
    }
}
