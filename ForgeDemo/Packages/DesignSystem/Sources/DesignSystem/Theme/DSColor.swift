import SwiftUI

/// ForgeDemo color tokens ("Calm Focus" palette). Backed by an Asset Catalog with
/// Any/Dark appearances, so each color resolves automatically for the active
/// `colorScheme` — no manual light/dark branching needed at call sites.
///
/// Accent rule: teal means *state or action only* (a completed task, a primary button,
/// the active tab). Never decorative.
public extension Color {
    /// App background (grouped). `#FAF9F6` / `#15171A`.
    static let dsBackground = Color("bg", bundle: .module)
    /// Grouped surface / row. `#FFFFFF` / `#1E2125`.
    static let dsCard = Color("card", bundle: .module)
    /// Primary text. `#1C1C1E` / `#ECECEA`.
    static let dsInk = Color("ink", bundle: .module)
    /// Secondary text. `#6E6E73` / `#9A9AA1`.
    static let dsInk2 = Color("ink2", bundle: .module)
    /// Tertiary / placeholder. `#AEAEB2` / `#67676E`.
    static let dsInk3 = Color("ink3", bundle: .module)
    /// Accent + success/completion (teal). `#1E6F69` / `#56AFA6`.
    static let dsAccent = Color("accent", bundle: .module)
    /// Accent tint for fills (teal @ 12% / 18%).
    static let dsAccentSoft = Color("accentSoft", bundle: .module)
    /// Destructive. `#C8483B` / `#FF6F62`.
    static let dsDanger = Color("danger", bundle: .module)
    /// Hairline separator (black @ 13% / white @ 32%).
    static let dsSeparator = Color("separator", bundle: .module)
}
