import SwiftUI

struct TransactionsView: View {
    @State private var viewModel = TransactionsViewModel()
    @AppStorage("currencyCode") private var currencyCode = "USD"

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                balanceCard
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
                    Button("Add Transaction", systemImage: "plus.circle.fill") {
                        viewModel.isShowingAddSheet = true
                    }
                    .font(.title2)
                    .symbolRenderingMode(.hierarchical)
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

    // MARK: - Balance Card

    private var balanceCard: some View {
        let net = viewModel.totalIncome - viewModel.totalExpense
        let netColor: Color = net > 0 ? .green : (net < 0 ? .red : .primary)

        return VStack(spacing: 14) {
            VStack(spacing: 4) {
                Text("Net Balance")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.secondary)
                    .textCase(.uppercase)
                    .tracking(0.8)

                Text(netFormatted(net))
                    .font(.system(size: 36, weight: .bold, design: .rounded))
                    .foregroundStyle(netColor)
                    .contentTransition(.numericText(value: net))
                    .animation(.spring(duration: 0.4), value: net)
            }

            Rectangle()
                .fill(Color(.separator))
                .frame(height: 0.5)

            HStack(spacing: 0) {
                incomeExpenseColumn(
                    title: "Income",
                    amount: viewModel.totalIncome,
                    icon: "arrow.down.circle.fill",
                    color: .green
                )

                Rectangle()
                    .fill(Color(.separator))
                    .frame(width: 0.5, height: 44)

                incomeExpenseColumn(
                    title: "Expense",
                    amount: viewModel.totalExpense,
                    icon: "arrow.up.circle.fill",
                    color: .red
                )
            }
        }
        .padding(18)
        .background(
            Color(.secondarySystemGroupedBackground),
            in: RoundedRectangle(cornerRadius: 20, style: .continuous)
        )
    }

    private func incomeExpenseColumn(
        title: String,
        amount: Double,
        icon: String,
        color: Color
    ) -> some View {
        HStack(spacing: 10) {
            Image(systemName: icon)
                .foregroundStyle(color)
                .font(.system(size: 24))
                .frame(width: 28)

            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Text(CurrencyFormatter.format(amount, currencyCode: currencyCode))
                    .font(.subheadline.weight(.semibold))
                    .fontDesign(.rounded)
                    .foregroundStyle(color)
                    .lineLimit(1)
                    .minimumScaleFactor(0.7)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal, 6)
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
                        sectionHeader(date: date, transactions: transactions)
                    }
                }
            }
            .listStyle(.insetGrouped)
        }
    }

    // MARK: - Section Header

    private func sectionHeader(date: String, transactions: [Transaction]) -> some View {
        let net = dayNet(for: transactions)
        return HStack {
            Text(relativeDate(from: date))
                .font(.footnote.weight(.semibold))
                .foregroundStyle(.secondary)
            Spacer()
            Text(dayNetFormatted(net))
                .font(.footnote.weight(.medium))
                .foregroundStyle(net >= 0 ? .green : .red)
        }
        .textCase(nil)
    }

    // MARK: - Helpers

    private func dayNet(for transactions: [Transaction]) -> Double {
        transactions.reduce(0) { $0 + ($1.type == .income ? $1.amount : -$1.amount) }
    }

    private func dayNetFormatted(_ net: Double) -> String {
        let prefix = net >= 0 ? "+" : "-"
        return "\(prefix)\(CurrencyFormatter.format(abs(net), currencyCode: currencyCode))"
    }

    private func netFormatted(_ net: Double) -> String {
        let prefix = net > 0 ? "+" : (net < 0 ? "-" : "")
        return "\(prefix)\(CurrencyFormatter.format(abs(net), currencyCode: currencyCode))"
    }

    private func relativeDate(from rawDate: String) -> String {
        let parser = DateFormatter()
        parser.dateStyle = .medium
        parser.timeStyle = .none
        guard let date = parser.date(from: rawDate) else { return rawDate }

        let calendar = Calendar.current
        if calendar.isDateInToday(date) { return "Today" }
        if calendar.isDateInYesterday(date) { return "Yesterday" }

        let display = DateFormatter()
        let thisYear = calendar.component(.year, from: Date())
        let dateYear = calendar.component(.year, from: date)
        display.dateFormat = thisYear == dateYear ? "EEE, MMM d" : "EEE, MMM d, yyyy"
        return display.string(from: date)
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
        HStack(spacing: 14) {
            ZStack {
                Circle()
                    .fill(categoryColor.opacity(0.15))
                    .frame(width: 48, height: 48)
                Image(systemName: transaction.categoryIcon)
                    .foregroundStyle(categoryColor)
                    .font(.system(size: 19, weight: .semibold))
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
