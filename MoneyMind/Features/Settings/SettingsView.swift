import SwiftUI

struct SettingsView: View {
    @State private var viewModel = SettingsViewModel()
    @AppStorage("currencyCode") private var currencyCode = "USD"
    @State private var showCurrencyPicker = false

    var body: some View {
        NavigationStack {
            List {
                Section {
                    Button {
                        showCurrencyPicker = true
                    } label: {
                        HStack {
                            Label("Currency", systemImage: "dollarsign.circle.fill")
                                .foregroundStyle(.primary)
                            Spacer()
                            Text(currencyCode)
                                .foregroundStyle(.secondary)
                            Image(systemName: "chevron.right")
                                .foregroundStyle(.tertiary)
                                .font(.caption)
                        }
                    }
                } header: {
                    Text("Preferences")
                }

                Section {
                    HStack {
                        Label("Version", systemImage: "info.circle.fill")
                        Spacer()
                        Text("1.0.0")
                            .foregroundStyle(.secondary)
                    }
                } header: {
                    Text("About")
                }
            }
            .navigationTitle("Settings")
            .sheet(isPresented: $showCurrencyPicker) {
                CurrencyPickerView(
                    selectedCode: $currencyCode,
                    availableCurrencies: viewModel.availableCurrencies
                )
            }
        }
    }
}

struct CurrencyPickerView: View {
    @Binding var selectedCode: String
    let availableCurrencies: [(code: String, name: String, symbol: String)]
    @Environment(\.dismiss) private var dismiss
    @State private var searchText = ""

    var filteredCurrencies: [(code: String, name: String, symbol: String)] {
        if searchText.isEmpty { return availableCurrencies }
        return availableCurrencies.filter {
            $0.code.localizedCaseInsensitiveContains(searchText) ||
            $0.name.localizedCaseInsensitiveContains(searchText)
        }
    }

    var body: some View {
        NavigationStack {
            List(filteredCurrencies, id: \.code) { currency in
                Button {
                    selectedCode = currency.code
                    dismiss()
                } label: {
                    HStack {
                        VStack(alignment: .leading, spacing: 2) {
                            Text(currency.name)
                                .foregroundStyle(.primary)
                            Text(currency.code)
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                        Spacer()
                        Text(currency.symbol)
                            .foregroundStyle(.secondary)
                        if selectedCode == currency.code {
                            Image(systemName: "checkmark")
                                .foregroundStyle(.tint)
                                .fontWeight(.semibold)
                        }
                    }
                }
            }
            .searchable(text: $searchText, prompt: "Search currency")
            .navigationTitle("Select Currency")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
            }
        }
    }
}
