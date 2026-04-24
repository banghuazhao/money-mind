//
// Created by Banghua Zhao on 21/04/2026
// Copyright Apps Bay Limited. All rights reserved.
//

import Foundation

enum AdConfiguration {
    /// AdMob **banner** unit (not the app ID from Info.plist). Replace for release builds.
    /// Google test banner — safe for DEBUG; use your real unit ID from AdMob for App Store builds.
    static let bannerAdUnitID = Bundle.main.object(forInfoDictionaryKey: "bannerViewAdUnitID") as? String ?? ""
}
