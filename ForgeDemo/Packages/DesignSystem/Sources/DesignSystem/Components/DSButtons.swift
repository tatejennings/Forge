import SwiftUI

/// Primary action button: filled teal, white Semibold label, radius 12. One per screen.
/// Pressed ≈ slight dim + 0.98 scale; disabled ≈ 38% opacity.
public struct DSPrimaryButtonStyle: ButtonStyle {
    @Environment(\.isEnabled) private var isEnabled
    public init() {}

    public func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.system(.body, weight: .semibold))
            .foregroundStyle(.white)
            .padding(.vertical, DSSpacing.md)
            .padding(.horizontal, DSSpacing.xl - 2)
            .frame(maxWidth: .infinity)
            .background(Color.dsAccent, in: RoundedRectangle(cornerRadius: DSRadius.button))
            .brightness(configuration.isPressed ? -0.06 : 0)
            .scaleEffect(configuration.isPressed ? 0.98 : 1)
            .opacity(isEnabled ? 1 : 0.38)
            .animation(.easeOut(duration: 0.12), value: configuration.isPressed)
            .contentShape(RoundedRectangle(cornerRadius: DSRadius.button))
    }
}

public extension ButtonStyle where Self == DSPrimaryButtonStyle {
    static var dsPrimary: DSPrimaryButtonStyle { DSPrimaryButtonStyle() }
}

/// An icon-only button label with the optional `accentSoft` circle behind it (e.g. the
/// toolbar `+`). Pairs a 44pt tap target with the accent tint.
public struct DSIconCircleLabel: View {
    private let systemName: String
    public init(systemName: String) { self.systemName = systemName }

    public var body: some View {
        Image(systemName: systemName)
            .font(.system(size: 17, weight: .semibold))
            .foregroundStyle(Color.dsAccent)
            .frame(width: 32, height: 32)
            .background(Color.dsAccentSoft, in: Circle())
            .frame(width: DSSpacing.minTapTarget, height: DSSpacing.minTapTarget)
            .contentShape(Rectangle())
    }
}
