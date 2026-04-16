import SwiftUI

struct MainTabView: View {
    var body: some View {
        TabView {
            Tab("Transactions", systemImage: "list.bullet.rectangle.portrait") {
                TransactionsView()
            }
            
            Tab("Report", systemImage: "chart.bar.xaxis") {
                ReportView()
            }

            Tab("Budgets", systemImage: "chart.pie.fill") {
                BudgetsView()
            }

            Tab("Goals", systemImage: "target") {
                SavingsGoalsView()
            }

            Tab("Settings", systemImage: "gearshape.fill") {
                SettingsView()
            }
        }
    }
}
