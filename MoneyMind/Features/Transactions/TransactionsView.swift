import SwiftUI

struct TransactionsView: View {
    @State private var viewModel = TransactionsViewModel()
    @AppStorage("currencyCode") private var currencyCode = "USD"

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                summaryHeader
                    .padding(.horizontal)
                    .padding(.top, 8)
                    .padding(.bottom, 12)

                filterPicker
                    .padding(.horizontal)
                    .padding(.bottom, 8)

                transactionList
            }
            .background(Color(.systemGroupedBackground))
            .navigationTitle("Transactions")
            .navigationBarTitleDisplayMode(.large)
            .searchable(text: $viewModel.searchText, prompt: "Search transactions")
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Button("Add Transaction", systemImage: "plus") {
                        viewModel.isShowingAddSheet = true
                    }
                }
            }
            .sheet(isPresented: $viewModel.isShowingAddSheet) {
                TransactionFormView(categories: viewModel.categories) { transaction in
                    viewModel.addTransaction(transaction)
                }
            }
            .sheet(item: $viewModel.editingTransaction) { transaction in
                TransactionFormView(transaction: transaction, categories: viewModel.categories) { updated in
                    viewModel.updateTransaction(updated)
                }
            }
            .alert("Delete Transaction", isPresented: $viewModel.showDeleteAlert) {
                Button("Delete", role: .destructive) {
                    if let t = viewModel.transactionToDelete {
                        viewModel.deleteTransaction(t)
                    }
                }
                Button("Cancel", role: .cancel) {}
            } message: {
                Text("Are you sure you want to delete this transaction?")
            }
        }
    }

    private var summaryHeader: some View {
        HStack(spacing: 12) {
            SummaryCard(
                title: "Income",
                amount: viewModel.totalIncome,
                currencyCode: currencyCode,
                color: .green,
                icon: "arrow.down.circle.fill"
            )

            SummaryCard(
                title: "Expense",
                amount: viewModel.totalExpense,
                currencyCode: currencyCode,
                color: .red,
                icon: "arrow.up.circle.fill"
            )
        }
    }

    private var filterPicker: some View {
        HStack(spacing: 8) {
            FilterChip(title: "All", isSelected: viewModel.filterType == nil) {
                viewModel.filterType = nil
            }
            FilterChip(title: "Income", isSelected: viewModel.filterType == .income) {
                viewModel.filterType = .income
            }
            FilterChip(title: "Expense", isSelected: viewModel.filterType == .expense) {
                viewModel.filterType = .expense
            }
            Spacer()
        }
    }

    @ViewBuilder
    private var transactionList: some View {
        if viewModel.filteredTransactions.isEmpty {
            ContentUnavailableView(
                viewModel.searchText.isEmpty ? "No Transactions" : "No Results",
                systemImage: viewModel.searchText.isEmpty ? "tray" : "magnifyingglass",
                description: Text(
                    viewModel.searchText.isEmpty
                        ? "Tap + to add your first transaction."
                        : "Try a different search."
                )
            )
        } else {
            List {
                ForEach(viewModel.groupedTransactions, id: \.0) { date, transactions in
                    Section(date) {
                        ForEach(transactions) { transaction in
                            TransactionRow(
                                transaction: transaction,
                                currencyCode: currencyCode
                            )
                            .contentShape(Rectangle())
                            .onTapGesture {
                                viewModel.editingTransaction = transaction
                            }
                            .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                                Button(role: .destructive) {
                                    viewModel.transactionToDelete = transaction
                                    viewModel.showDeleteAlert = true
                                } label: {
                                    Label("Delete", systemImage: "trash")
                                }

                                Button {
                                    viewModel.editingTransaction = transaction
                                } label: {
                                    Label("Edit", systemImage: "pencil")
                                }
                                .tint(.blue)
                            }
                        }
                    }
                }
            }
            .listStyle(.insetGrouped)
        }
    }
}

struct SummaryCard: View {
    let title: String
    let amount: Double
    let currencyCode: String
    let color: Color
    let icon: String

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack(spacing: 6) {
                Image(systemName: icon)
                    .foregroundStyle(color)
                    .font(.subheadline)
                Text(title)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
            Text(CurrencyFormatter.format(amount, currencyCode: currencyCode))
                .font(.title3.weight(.bold))
                .foregroundStyle(color)
                .lineLimit(1)
                .minimumScaleFactor(0.7)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(14)
        .background(color.opacity(0.1), in: RoundedRectangle(cornerRadius: 12))
    }
}

struct FilterChip: View {
    let title: String
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.subheadline)
                .fontWeight(isSelected ? .semibold : .regular)
                .padding(.horizontal, 14)
                .padding(.vertical, 7)
                .background(
                    isSelected ? Color.accentColor : Color(.systemGray5),
                    in: Capsule()
                )
                .foregroundStyle(isSelected ? .white : .primary)
        }
        .buttonStyle(.plain)
        .animation(.spring(duration: 0.2), value: isSelected)
    }
}

struct TransactionRow: View {
    let transaction: Transaction
    let currencyCode: String

    var body: some View {
        HStack(spacing: 12) {
            ZStack {
                Circle()
                    .fill(Color(hex: transaction.categoryColorHex).opacity(0.15))
                    .frame(width: 44, height: 44)
                Image(systemName: transaction.categoryIcon)
                    .foregroundStyle(Color(hex: transaction.categoryColorHex))
                    .font(.system(size: 18, weight: .semibold))
            }

            VStack(alignment: .leading, spacing: 3) {
                Text(transaction.categoryName)
                    .font(.body)
                    .fontWeight(.medium)
                if !transaction.note.isEmpty {
                    Text(transaction.note)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                }
            }

            Spacer()

            VStack(alignment: .trailing, spacing: 3) {
                Text("\(transaction.type == .expense ? "-" : "+")\(CurrencyFormatter.format(transaction.amount, currencyCode: currencyCode))")
                    .font(.body.weight(.semibold))
                    .foregroundStyle(transaction.type == .expense ? .red : .green)
                Text(transaction.date, style: .time)
                    .font(.caption2)
                    .foregroundStyle(.tertiary)
            }
        }
        .padding(.vertical, 4)
    }
}
