import SwiftUI

struct TransactionsView: View {
    @State private var viewModel = TransactionsViewModel()
    @AppStorage("currencyCode") private var currencyCode = "USD"

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                balanceHeader
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

    // MARK: - Balance Header

    private var balanceHeader: some View {
        VStack(spacing: 16) {
            VStack(spacing: 4) {
                Text("Balance")
                    .font(.subheadline)
                    .foregroundStyle(.white.opacity(0.7))
                Text(CurrencyFormatter.format(
                    viewModel.totalIncome - viewModel.totalExpense,
                    currencyCode: currencyCode
                ))
                .font(.system(size: 34, weight: .bold, design: .rounded))
                .foregroundStyle(.white)
                .contentTransition(.numericText())
            }

            HStack(spacing: 0) {
                HStack(spacing: 8) {
                    Image(systemName: "arrow.down.circle.fill")
                        .font(.title3)
                        .foregroundStyle(.green)
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Income")
                            .font(.caption)
                            .foregroundStyle(.white.opacity(0.6))
                        Text(CurrencyFormatter.format(viewModel.totalIncome, currencyCode: currencyCode))
                            .font(.subheadline.weight(.semibold))
                            .foregroundStyle(.white)
                            .lineLimit(1)
                            .minimumScaleFactor(0.7)
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)

                Rectangle()
                    .fill(.white.opacity(0.2))
                    .frame(width: 1, height: 36)

                HStack(spacing: 8) {
                    Image(systemName: "arrow.up.circle.fill")
                        .font(.title3)
                        .foregroundStyle(Color(hex: "#FF6B6B"))
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Expense")
                            .font(.caption)
                            .foregroundStyle(.white.opacity(0.6))
                        Text(CurrencyFormatter.format(viewModel.totalExpense, currencyCode: currencyCode))
                            .font(.subheadline.weight(.semibold))
                            .foregroundStyle(.white)
                            .lineLimit(1)
                            .minimumScaleFactor(0.7)
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.leading, 16)
            }
        }
        .padding(20)
        .background(
            LinearGradient(
                colors: [Color(hex: "#1A1A2E"), Color(hex: "#16213E"), Color(hex: "#0F3460")],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        )
        .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
    }

    // MARK: - Filters

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

    // MARK: - Transaction List

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
                    Section {
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
                    } header: {
                        HStack {
                            Text(date)
                            Spacer()
                            let net = dayNet(for: transactions)
                            Text(dayNetFormatted(net))
                                .foregroundStyle(net >= 0 ? .green : .red)
                        }
                    }
                }
            }
            .listStyle(.insetGrouped)
        }
    }

    // MARK: - Helpers

    private func dayNet(for transactions: [Transaction]) -> Double {
        transactions.reduce(0) { $0 + ($1.type == .income ? $1.amount : -$1.amount) }
    }

    private func dayNetFormatted(_ net: Double) -> String {
        let prefix = net >= 0 ? "+" : "-"
        return "\(prefix)\(CurrencyFormatter.format(abs(net), currencyCode: currencyCode))"
    }
}

// MARK: - Filter Chip

struct FilterChip: View {
    let title: String
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.subheadline.weight(isSelected ? .semibold : .regular))
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
                .background(
                    isSelected ? Color.accentColor : Color(.systemGray5),
                    in: Capsule()
                )
                .foregroundStyle(isSelected ? .white : .primary)
        }
        .buttonStyle(.plain)
        .animation(.spring(duration: 0.25), value: isSelected)
    }
}

// MARK: - Transaction Row

struct TransactionRow: View {
    let transaction: Transaction
    let currencyCode: String

    private var categoryColor: Color {
        Color(hex: transaction.categoryColorHex)
    }

    var body: some View {
        HStack(spacing: 12) {
            ZStack {
                Circle()
                    .fill(categoryColor.opacity(0.12))
                    .frame(width: 46, height: 46)
                Image(systemName: transaction.categoryIcon)
                    .foregroundStyle(categoryColor)
                    .font(.system(size: 18, weight: .semibold))
            }

            VStack(alignment: .leading, spacing: 3) {
                Text(transaction.categoryName)
                    .font(.body.weight(.medium))
                if !transaction.note.isEmpty {
                    Text(transaction.note)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                }
            }

            Spacer()

            VStack(alignment: .trailing, spacing: 3) {
                Text(formattedAmount)
                    .font(.body.weight(.semibold))
                    .fontDesign(.rounded)
                    .foregroundStyle(transaction.type == .expense ? .red : .green)
                Text(transaction.date, style: .time)
                    .font(.caption2)
                    .foregroundStyle(.tertiary)
            }
        }
        .padding(.vertical, 4)
    }

    private var formattedAmount: String {
        let prefix = transaction.type == .expense ? "-" : "+"
        return "\(prefix)\(CurrencyFormatter.format(transaction.amount, currencyCode: currencyCode))"
    }
}
