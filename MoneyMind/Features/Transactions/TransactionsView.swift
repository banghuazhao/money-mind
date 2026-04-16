import SwiftUI

struct TransactionsView: View {
    @State private var viewModel = TransactionsViewModel()
    @AppStorage("currencyCode") private var currencyCode = "USD"
    
    var body: some View {
        NavigationStack {
            List {
                Group {
                    periodPicker
                        .padding(.top, 8)
                        .padding(.bottom, 10)
                    
                    balanceCard
                        .padding(.bottom, 12)
                    
                    filterPicker
                        .padding(.bottom, 8)
                }
                .listRowInsets(EdgeInsets())
                .listRowBackground(Color.clear)
                .listRowSeparator(.hidden)
                
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
            .alert("No Goals Yet", isPresented: $viewModel.showNoGoalsAlert) {
                Button("OK", role: .cancel) {}
            } message: {
                Text("Create a savings goal in the Goals tab to start allocating income towards it.")
            }
            .sheet(item: $viewModel.contributeSourceTransaction) { source in
                QuickContributeSheet(
                    sourceTransaction: source,
                    goals: viewModel.goals,
                    goalProgress: { goal in
                        (
                            saved: viewModel.savedAmount(for: goal.id),
                            target: goal.targetAmount
                        )
                    },
                    currencyCode: currencyCode
                ) { goalId, amount, date, note in
                    viewModel.addContribution(
                        goalId: goalId,
                        amount: amount,
                        date: date,
                        note: note
                    )
                }
            }
        }
    }
    
    // MARK: - Period Picker
    
    private var periodPicker: some View {
        Picker("Period", selection: $viewModel.selectedPeriod) {
            ForEach(TransactionPeriod.allCases, id: \.self) { period in
                Text(period.rawValue).tag(period)
            }
        }
        .pickerStyle(.segmented)
        .animation(.spring(duration: 0.25), value: viewModel.selectedPeriod)
    }
    
    // MARK: - Balance Card

    private var balanceCard: some View {
        let (label, amount, color) = balanceCardContent
        return VStack(spacing: 4) {
            Text(label)
                .font(.caption)
                .foregroundStyle(.secondary)
            Text(formattedCardAmount(amount, type: viewModel.filterType))
                .font(.system(size: 36, weight: .bold, design: .rounded))
                .foregroundStyle(color)
                .contentTransition(.numericText(value: amount))
                .animation(.spring(duration: 0.4), value: amount)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 20)
        .background(
            Color(.secondarySystemGroupedBackground),
            in: RoundedRectangle(cornerRadius: 20, style: .continuous)
        )
        .animation(.spring(duration: 0.3), value: viewModel.filterType)
    }

    private var balanceCardContent: (label: String, amount: Double, color: Color) {
        switch viewModel.filterType {
        case .income:
            return ("Income", viewModel.totalIncome, .green)
        case .expense:
            return ("Expense", viewModel.totalExpense, .red)
        case nil:
            let net = viewModel.totalIncome - viewModel.totalExpense
            let color: Color = net > 0 ? .green : (net < 0 ? .red : .primary)
            return ("Net Balance", net, color)
        }
    }

    private func formattedCardAmount(_ amount: Double, type: TransactionType?) -> String {
        switch type {
        case .income:
            return "+\(CurrencyFormatter.format(amount, currencyCode: currencyCode))"
        case .expense:
            return "-\(CurrencyFormatter.format(amount, currencyCode: currencyCode))"
        case nil:
            return netFormatted(amount)
        }
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
                emptyTitle,
                systemImage: viewModel.searchText.isEmpty ? "tray" : "magnifyingglass",
                description: Text(
                    viewModel.searchText.isEmpty
                    ? "Tap + to add your first transaction."
                    : "Try a different search."
                )
            )
            .listRowInsets(EdgeInsets())
            .listRowBackground(Color.clear)
            .listRowSeparator(.hidden)
        } else {
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
                        .swipeActions(edge: .leading, allowsFullSwipe: false) {
                            if transaction.type == .income {
                                Button {
                                    viewModel.requestContribution(for: transaction)
                                } label: {
                                    Label("Save to Goal", systemImage: "target")
                                }
                                .tint(.indigo)
                            }
                        }
                        .contextMenu {
                            if transaction.type == .income {
                                Button {
                                    viewModel.requestContribution(for: transaction)
                                } label: {
                                    Label("Save to Goal", systemImage: "target")
                                }
                            }
                            Button {
                                viewModel.editingTransaction = transaction
                            } label: {
                                Label("Edit", systemImage: "pencil")
                            }
                            Button(role: .destructive) {
                                viewModel.transactionToDelete = transaction
                                viewModel.showDeleteAlert = true
                            } label: {
                                Label("Delete", systemImage: "trash")
                            }
                        }
                    }
                } header: {
                    sectionHeader(date: date, transactions: transactions)
                }
            }
            .listStyle(.insetGrouped)
            .animation(.spring(duration: 0.3), value: viewModel.selectedPeriod)
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
    
    private var emptyTitle: String {
        guard viewModel.searchText.isEmpty else { return "No Results" }
        switch viewModel.selectedPeriod {
        case .week: return "No Transactions This Week"
        case .month: return "No Transactions This Month"
        case .year: return "No Transactions This Year"
        case .all: return "No Transactions"
        }
    }
    
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
