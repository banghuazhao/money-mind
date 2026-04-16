import SwiftUI

struct MainTabView: View {
    var body: some View {
        TabView {
            Tab("Transactions", systemImage: "list.bullet.rectangle.portrait") {
                TransactionsView()
            }

            Tab("Report", systemImage: "chart.pie.fill") {
                ReportView()
            }

            Tab("Settings", systemImage: "gearshape.fill") {
                SettingsView()
            }
        }
    }
}
