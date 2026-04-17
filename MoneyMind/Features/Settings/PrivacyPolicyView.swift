import SwiftUI

/// In-app privacy summary for App Store alignment. Host a full policy URL on your site when ready.
struct PrivacyPolicyView: View {
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    Text("MoneyMind keeps your finances on your iPhone or iPad. This summary describes how the app handles data today.")
                        .font(.body)
                        .foregroundStyle(.secondary)

                    policySection(
                        title: "Data stays local",
                        body: "Transactions, categories, budgets, goals, and settings are stored in a database on your device (Application Support). We do not operate accounts in the app and do not send your financial entries to our servers."
                    )

                    policySection(
                        title: "No third-party analytics in this build",
                        body: "This version does not embed advertising SDKs or third-party analytics. If that changes in a future update, we will update this screen and the App Store privacy details before release."
                    )

                    policySection(
                        title: "Export",
                        body: "You can export your data as CSV from Settings. Only you choose where that file is sent or saved (e.g. Files, Mail, AirDrop)."
                    )

                    policySection(
                        title: "App Store & Apple",
                        body: "Apple may collect crash diagnostics and usage metrics according to your device settings. That is governed by Apple’s privacy policy, not by MoneyMind’s database."
                    )

                    policySection(
                        title: "Contact",
                        body: "For privacy questions or data requests, contact the developer email listed on the App Store listing for MoneyMind."
                    )

                    Text("For the legal privacy policy document, publish a page on your website and add a link here when available.")
                        .font(.caption)
                        .foregroundStyle(.tertiary)
                }
                .padding(20)
                .frame(maxWidth: .infinity, alignment: .leading)
            }
            .background(Color(.systemGroupedBackground))
            .navigationTitle("Privacy")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") { dismiss() }
                        .fontWeight(.semibold)
                }
            }
        }
    }

    private func policySection(title: String, body: String) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.headline)
            Text(body)
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(16)
        .background(Color(.secondarySystemGroupedBackground), in: RoundedRectangle(cornerRadius: 16, style: .continuous))
    }
}
