import SwiftUI

struct SettingsView: View {
    @State private var viewModel = SettingsViewModel()
    @AppStorage("currencyCode") private var currencyCode = "USD"
    @State private var showCurrencyPicker = false
    @State private var showCategories = false

    var body: some View {
        NavigationStack {
            List {
                brandingSection
                preferencesSection
                organizationSection
                aboutSection
            }
            .navigationTitle("Settings")
            .sheet(isPresented: $showCurrencyPicker) {
                CurrencyPickerView(
                    selectedCode: $currencyCode,
                    availableCurrencies: viewModel.availableCurrencies
                )
            }
            .sheet(isPresented: $showCategories) {
                CategoriesView()
            }
        }
    }

    // MARK: - Branding

    private var brandingSection: some View {
        Section {
            VStack(spacing: 12) {
                ZStack {
                    Circle()
                        .fill(
                            LinearGradient(
                                colors: [Color(hex: "#1A1A2E"), Color(hex: "#0F3460")],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 72, height: 72)
                    Image(systemName: "banknote.fill")
                        .font(.system(size: 28))
                        .foregroundStyle(.white)
                }
                Text("MoneyMind")
                    .font(.title3.weight(.bold))
                Text("Track smarter, spend wiser")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 8)
            .listRowBackground(Color.clear)
            .listRowSeparator(.hidden)
        }
    }

    // MARK: - Preferences

    private var preferencesSection: some View {
        Section("Preferences") {
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
        }
    }

    // MARK: - Organization

    private var organizationSection: some View {
        Section("Organization") {
            Button {
                showCategories = true
            } label: {
                HStack {
                    Label("Categories", systemImage: "tag.fill")
                        .foregroundStyle(.primary)
                    Spacer()
                    Image(systemName: "chevron.right")
                        .foregroundStyle(.tertiary)
                        .font(.caption)
                }
            }
        }
    }

    // MARK: - About

    private var aboutSection: some View {
        Section("About") {
            HStack {
                Label("Version", systemImage: "info.circle.fill")
                Spacer()
                Text("1.0.0")
                    .foregroundStyle(.secondary)
            }
        }
    }
}

// MARK: - Currency Picker

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
