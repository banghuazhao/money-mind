import SwiftUI

struct SettingsView: View {
    @State private var viewModel = SettingsViewModel()
    @AppStorage("currencyCode") private var currencyCode = "USD"
    @State private var showCurrencyPicker = false
    @State private var showCategories = false

    private var appVersion: String {
        Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0"
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    headerCard

                    sectionLabel("Preferences")
                    preferencesCard

                    sectionLabel("Data")
                    dataCard

                    sectionLabel("About")
                    aboutCard

                    footerNote
                }
                .padding(.horizontal)
                .padding(.top, 4)
                .padding(.bottom, 28)
            }
            .background(Color(.systemGroupedBackground))
            .navigationTitle("Settings")
            .navigationBarTitleDisplayMode(.large)
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

    // MARK: - Header

    private var headerCard: some View {
        HStack(alignment: .center, spacing: 16) {
            ZStack {
                Circle()
                    .fill(
                        LinearGradient(
                            colors: [Color(hex: "#1A1A2E"), Color(hex: "#0F3460")],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 64, height: 64)
                Image(systemName: "brain.head.profile")
                    .font(.system(size: 28, weight: .semibold))
                    .foregroundStyle(.white)
            }

            VStack(alignment: .leading, spacing: 4) {
                Text("MoneyMind")
                    .font(.title3.weight(.bold))
                Text("Budget tracker — track spending and save more.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding(16)
        .background(Color(.secondarySystemGroupedBackground), in: RoundedRectangle(cornerRadius: 20, style: .continuous))
    }

    // MARK: - Sections

    private func sectionLabel(_ title: String) -> some View {
        Text(title.uppercased())
            .font(.caption.weight(.semibold))
            .foregroundStyle(.secondary)
            .tracking(0.6)
            .padding(.horizontal, 4)
    }

    private var preferencesCard: some View {
        VStack(spacing: 0) {
            SettingsRowButton(
                title: "Currency",
                subtitle: viewModel.currencySubtitle(for: currencyCode),
                trailing: currencyCode,
                icon: "dollarsign.circle.fill",
                iconTint: .green
            ) {
                showCurrencyPicker = true
            }
        }
        .background(Color(.secondarySystemGroupedBackground), in: RoundedRectangle(cornerRadius: 20, style: .continuous))
    }

    private var dataCard: some View {
        VStack(spacing: 0) {
            SettingsRowButton(
                title: "Categories",
                subtitle: "Income and expense labels for transactions",
                trailing: nil,
                icon: "tag.fill",
                iconTint: .blue
            ) {
                showCategories = true
            }
        }
        .background(Color(.secondarySystemGroupedBackground), in: RoundedRectangle(cornerRadius: 20, style: .continuous))
    }

    private var aboutCard: some View {
        VStack(spacing: 0) {
            SettingsInfoRow(
                title: "Version",
                value: appVersion,
                icon: "info.circle.fill",
                iconTint: .purple
            )
        }
        .background(Color(.secondarySystemGroupedBackground), in: RoundedRectangle(cornerRadius: 20, style: .continuous))
    }

    private var rowDivider: some View {
        Rectangle()
            .fill(Color(.separator).opacity(0.35))
            .frame(height: 0.5)
            .padding(.leading, 56)
    }

    private var footerNote: some View {
        Text("Numbers stay on your device. Change currency anytime — existing amounts are not converted.")
            .font(.caption2)
            .foregroundStyle(.tertiary)
            .multilineTextAlignment(.center)
            .frame(maxWidth: .infinity)
            .padding(.horizontal, 8)
            .padding(.top, 4)
    }
}

// MARK: - Row Components

private struct SettingsRowButton: View {
    let title: String
    let subtitle: String?
    let trailing: String?
    let icon: String
    let iconTint: Color
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 14) {
                ZStack {
                    RoundedRectangle(cornerRadius: 10, style: .continuous)
                        .fill(iconTint.opacity(0.15))
                        .frame(width: 40, height: 40)
                    Image(systemName: icon)
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundStyle(iconTint)
                }

                VStack(alignment: .leading, spacing: 2) {
                    Text(title)
                        .font(.body.weight(.semibold))
                        .foregroundStyle(.primary)
                    if let subtitle, !subtitle.isEmpty {
                        Text(subtitle)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                            .lineLimit(2)
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)

                if let trailing {
                    Text(trailing)
                        .font(.subheadline.weight(.semibold))
                        .fontDesign(.rounded)
                        .foregroundStyle(.secondary)
                }

                Image(systemName: "chevron.right")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.tertiary)
            }
            .padding(14)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }
}

private struct SettingsInfoRow: View {
    let title: String
    let value: String
    let icon: String
    let iconTint: Color

    var body: some View {
        HStack(spacing: 14) {
            ZStack {
                RoundedRectangle(cornerRadius: 10, style: .continuous)
                    .fill(iconTint.opacity(0.15))
                    .frame(width: 40, height: 40)
                Image(systemName: icon)
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundStyle(iconTint)
            }

            Text(title)
                .font(.body.weight(.medium))
                .foregroundStyle(.primary)

            Spacer()

            Text(value)
                .font(.subheadline.weight(.semibold))
                .fontDesign(.rounded)
                .foregroundStyle(.secondary)
        }
        .padding(14)
    }
}

// MARK: - Currency Picker

struct CurrencyPickerView: View {
    @Binding var selectedCode: String
    let availableCurrencies: [(code: String, name: String, symbol: String)]
    @Environment(\.dismiss) private var dismiss
    @State private var searchText = ""

    private var filteredCurrencies: [(code: String, name: String, symbol: String)] {
        if searchText.isEmpty { return availableCurrencies }
        return availableCurrencies.filter {
            $0.code.localizedCaseInsensitiveContains(searchText) ||
            $0.name.localizedCaseInsensitiveContains(searchText) ||
            $0.symbol.localizedCaseInsensitiveContains(searchText)
        }
    }

    var body: some View {
        NavigationStack {
            Group {
                if filteredCurrencies.isEmpty {
                    ContentUnavailableView.search(text: searchText)
                } else {
                    List {
                        ForEach(filteredCurrencies, id: \.code) { currency in
                            Button {
                                selectedCode = currency.code
                                dismiss()
                            } label: {
                                HStack(spacing: 14) {
                                    ZStack {
                                        RoundedRectangle(cornerRadius: 10, style: .continuous)
                                            .fill(Color.accentColor.opacity(0.12))
                                            .frame(width: 40, height: 40)
                                        Text(currency.symbol)
                                            .font(.subheadline.weight(.semibold))
                                            .foregroundStyle(.primary)
                                            .lineLimit(1)
                                            .minimumScaleFactor(0.5)
                                            .frame(width: 36)
                                    }

                                    VStack(alignment: .leading, spacing: 2) {
                                        Text(currency.name)
                                            .font(.body.weight(.medium))
                                            .foregroundStyle(.primary)
                                        Text(currency.code)
                                            .font(.caption)
                                            .foregroundStyle(.secondary)
                                    }

                                    Spacer(minLength: 8)

                                    if selectedCode == currency.code {
                                        Image(systemName: "checkmark.circle.fill")
                                            .foregroundStyle(.green)
                                            .font(.title3)
                                            .symbolRenderingMode(.hierarchical)
                                    }
                                }
                                .padding(.vertical, 4)
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    .listStyle(.insetGrouped)
                }
            }
            .background(Color(.systemGroupedBackground))
            .searchable(text: $searchText, prompt: "Search by name, code, or symbol")
            .navigationTitle("Currency")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
            }
        }
    }
}
