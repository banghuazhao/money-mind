//
// Created by Banghua Zhao on 20/07/2025
// Copyright Apps Bay Limited. All rights reserved.
//

import SwiftUI
import SQLiteData
import Dependencies

@main
struct MoneyMindApp: App {
    init() {
        CurrencyCatalog.applyLocaleDefaultCurrencyIfNeeded()
        if UserDefaults.standard.object(forKey: "hasCompletedOnboarding") == nil,
           moneyMindDatabaseFileExistedBeforeLaunch() {
            UserDefaults.standard.set(true, forKey: "hasCompletedOnboarding")
        }
        prepareDependencies {
            $0.defaultDatabase = try! appDatabase()
        }
    }

    var body: some Scene {
        WindowGroup {
            AppRootView()
        }
    }
}

private struct AppRootView: View {
    @AppStorage("hasCompletedOnboarding") private var hasCompletedOnboarding = false

    var body: some View {
        Group {
            if hasCompletedOnboarding {
                MainTabView()
            } else {
                OnboardingView {
                    hasCompletedOnboarding = true
                }
            }
        }
    }
}
