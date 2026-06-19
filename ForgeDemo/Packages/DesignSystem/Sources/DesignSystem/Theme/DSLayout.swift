import CoreGraphics

/// Spacing scale. `4 (xs) · 8 (sm) · 12 (md) · 16 (lg, screen gutter) · 24 (xl) · 32 (2xl)`.
public enum DSSpacing {
    public static let xs: CGFloat = 4
    public static let sm: CGFloat = 8
    public static let md: CGFloat = 12
    /// Screen gutter.
    public static let lg: CGFloat = 16
    public static let xl: CGFloat = 24
    public static let xxl: CGFloat = 32
    /// Minimum tap target for all controls.
    public static let minTapTarget: CGFloat = 44
}

/// Corner radii. `8` fields · `12` buttons · `14` cards/grouped sections · capsule for pills.
public enum DSRadius {
    public static let field: CGFloat = 8
    public static let button: CGFloat = 12
    public static let card: CGFloat = 14
}
