import SwiftUI

/// Typography tokens mapped to the native iOS Dynamic Type ramp, so text scales with the
/// user's settings automatically. Regular/Medium do the everyday work; **Semibold is
/// reserved for titles**. Use these instead of fixed point sizes for body copy.
public extension Font {
    /// 34/41 · Semibold.
    static let dsLargeTitle = Font.system(.largeTitle, weight: .semibold)
    /// 28/34 · Semibold.
    static let dsTitle = Font.system(.title, weight: .semibold)
    /// 17/22 · Semibold.
    static let dsHeadline = Font.system(.headline)
    /// 17/22 · Regular.
    static let dsBody = Font.system(.body)
    /// 15/20 · Regular.
    static let dsSubheadline = Font.system(.subheadline)
    /// 13/18 · Regular.
    static let dsFootnote = Font.system(.footnote)
    /// 12/16 · Regular. For section headers, pair with `.textCase(.uppercase)` + tracking.
    static let dsCaption = Font.system(.caption)
}
