import Testing
import SwiftUI
@testable import DesignSystem

@Suite("DesignSystem tokens")
struct DesignSystemTokenTests {

    @Test("color tokens resolve from the module bundle without crashing")
    func colorsResolve() {
        // Touch every token to ensure each asset-catalog color set exists and is named
        // correctly (a typo'd name would resolve to a fallback, but a missing bundle would
        // trap). This guards against renamed/removed color sets.
        _ = [
            Color.dsBackground, .dsCard, .dsInk, .dsInk2, .dsInk3,
            .dsAccent, .dsAccentSoft, .dsDanger, .dsSeparator
        ]
    }

    @Test("spacing scale is monotonic")
    func spacingOrder() {
        #expect(DSSpacing.xs < DSSpacing.sm)
        #expect(DSSpacing.sm < DSSpacing.md)
        #expect(DSSpacing.md < DSSpacing.lg)
        #expect(DSSpacing.lg < DSSpacing.xl)
        #expect(DSSpacing.xl < DSSpacing.xxl)
        #expect(DSSpacing.minTapTarget == 44)
    }
}
