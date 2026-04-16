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
        prepareDependencies {
            $0.defaultDatabase = try! appDatabase()
        }
    }

    var body: some Scene {
        WindowGroup {
            MainTabView()
        }
    }
}
