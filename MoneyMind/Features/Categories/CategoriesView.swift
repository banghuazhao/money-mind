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

                categoryList
            }
            .navigationTitle("Categories")
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Button("Add Category", systemImage: "plus") {
                        viewModel.isShowingAddSheet = true
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

    private var categoryList: some View {
        let filtered = viewModel.categoriesForType(selectedType)

        return Group {
            if filtered.isEmpty {
                ContentUnavailableView(
                    "No Categories",
                    systemImage: "tag.slash",
                    description: Text("Add a category to get started.")
                )
            } else {
                List {
                    ForEach(filtered) { category in
                        CategoryRow(category: category)
                            .contentShape(Rectangle())
                            .onTapGesture {
                                viewModel.editingCategory = category
                            }
                            .swipeActions(edge: .trailing, allowsFullSwipe: false) {
                                Button(role: .destructive) {
                                    viewModel.categoryToDelete = category
                                    viewModel.showDeleteAlert = true
                                } label: {
                                    Label("Delete", systemImage: "trash")
                                }

                                Button {
                                    viewModel.editingCategory = category
                                } label: {
                                    Label("Edit", systemImage: "pencil")
                                }
                                .tint(.blue)
                            }
                    }
                }
                .listStyle(.plain)
            }
        }
    }
}

struct CategoryRow: View {
    let category: TransactionCategory

    var body: some View {
        HStack(spacing: 14) {
            ZStack {
                Circle()
                    .fill(Color(hex: category.colorHex))
                    .frame(width: 44, height: 44)
                Image(systemName: category.icon)
                    .foregroundStyle(.white)
                    .font(.system(size: 18, weight: .semibold))
            }

            Text(category.name)
                .font(.body)
                .fontWeight(.medium)

            Spacer()

            Image(systemName: "chevron.right")
                .foregroundStyle(.tertiary)
                .font(.caption)
        }
        .padding(.vertical, 4)
    }
}
