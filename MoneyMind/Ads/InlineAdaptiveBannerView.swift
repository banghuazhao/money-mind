//
// Created by Banghua Zhao on 21/04/2026
// Copyright Apps Bay Limited. All rights reserved.
//

import GoogleMobileAds
import SwiftUI
import UIKit

/// Inline banner that scrolls with parent content.
/// Uses **inline adaptive** with the **full measured row width** and a `maxHeight` cap (compact vertically without a narrower-than-slot ad width).
///
/// Width comes from **SwiftUI layout** (not `UIScreen`) so the requested ad width matches the padded content area — avoids clipping AdChoices / creatives.
/// Do **not** set `clipsToBounds` on `BannerView` or use a frame **narrower** than `adSize.size` (both crop the privacy icon).
struct InlineAdaptiveBannerView: View {
    let adUnitID: String

    /// Caps vertical size (~56–60pt typical); nudge to 56…65 to taste.
    private let maxBannerHeight: CGFloat = 60

    /// Measured width of this row inside `ScrollView` (updates from `GeometryReader`).
    @State private var slotWidth: CGFloat = Self.initialSlotWidthEstimate()

    private var bannerSlotWidth: CGFloat {
        max(1, slotWidth)
    }

    private var adSize: AdSize {
        inlineAdaptiveBanner(width: bannerSlotWidth, maxHeight: maxBannerHeight)
    }

    var body: some View {
        AdaptiveBannerRepresentable(adUnitID: adUnitID, adSize: adSize)
            .frame(width: adSize.size.width, height: adSize.size.height)
            .frame(maxWidth: .infinity, alignment: .center)
            .background {
                GeometryReader { geo in
                    Color.clear
                        .onAppear { syncSlotWidth(geo.size.width) }
                        .onChange(of: geo.size.width) { _, new in
                            syncSlotWidth(new)
                        }
                }
            }
            .padding(.top, 28)
    }

    private func syncSlotWidth(_ width: CGFloat) {
        guard width.isFinite, width > 1 else { return }
        guard abs(width - slotWidth) > 0.5 else { return }
        slotWidth = width
    }

    private static func initialSlotWidthEstimate() -> CGFloat {
        guard let scene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
              let window = scene.windows.first(where: \.isKeyWindow) else {
            return max(1, UIScreen.main.bounds.width - 32)
        }
        let inset = window.safeAreaInsets.left + window.safeAreaInsets.right
        return max(1, window.bounds.width - inset - 32)
    }
}

// MARK: - UIKit bridge

private struct AdaptiveBannerRepresentable: UIViewRepresentable {
    let adUnitID: String
    let adSize: AdSize

    func makeCoordinator() -> Coordinator {
        Coordinator()
    }

    func makeUIView(context: Context) -> BannerView {
        let banner = BannerView(adSize: adSize)
        banner.adUnitID = adUnitID
        banner.delegate = context.coordinator
        banner.rootViewController = Self.rootViewController()
        banner.load(Request())
        return banner
    }

    func updateUIView(_ banner: BannerView, context: Context) {
        if !banner.adSize.size.equalTo(adSize.size) {
            banner.adSize = adSize
            banner.load(Request())
        }
        if banner.rootViewController == nil {
            banner.rootViewController = Self.rootViewController()
        }
    }

    private static func rootViewController() -> UIViewController? {
        guard let scene = UIApplication.shared.connectedScenes.first as? UIWindowScene else {
            return nil
        }
        return scene.windows.first { $0.isKeyWindow }?.rootViewController
    }

    final class Coordinator: NSObject, BannerViewDelegate {}
}
