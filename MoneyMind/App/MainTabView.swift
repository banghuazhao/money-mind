import SwiftUI

struct MainTabView: View {
    var body: some View {
        TabView {
            Tab("Transactions", systemImage: "list.bullet.rectangle.portrait") {
                TransactionsView()
            }

            Tab("Budgets", systemImage: "chart.pie.fill") {
                BudgetsView()
            }

            Tab("Report", systemImage: "chart.bar.xaxis") {
                ReportView()
            }

            Tab("Settings", systemImage: "gearshape.fill") {
                SettingsView()
            }
        }
    }
}
