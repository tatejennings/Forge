import SwiftUI

/// Empty-state block: an `accentSoft` circle holding a glyph, a short title, and a helper
/// line. Used for the Tasks list when there's nothing to show.
public struct DSEmptyState: View {
    private let systemImage: String
    private let title: String
    private let message: String

    public init(systemImage: String = "checklist", title: String, message: String) {
        self.systemImage = systemImage
        self.title = title
        self.message = message
    }

    public var body: some View {
        VStack(spacing: DSSpacing.lg) {
            Image(systemName: systemImage)
                .font(.system(size: 30, weight: .regular))
                .foregroundStyle(Color.dsAccent)
                .frame(width: 76, height: 76)
                .background(Color.dsAccentSoft, in: Circle())

            VStack(spacing: DSSpacing.xs) {
                Text(title)
                    .font(.system(.title3, weight: .semibold))
                    .foregroundStyle(Color.dsInk)
                Text(message)
                    .font(.dsSubheadline)
                    .foregroundStyle(Color.dsInk2)
                    .multilineTextAlignment(.center)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(DSSpacing.xl)
    }
}
