import SwiftUI

/// Field chrome for text inputs: page-bg fill, hairline border that becomes a 2pt accent
/// border on focus and a 2pt danger border on error. Radius matches the field token.
///
/// Apply to a `TextField`/`TextEditor`; pass the field's `@FocusState` value and an error
/// flag. An optional message renders beneath in danger Footnote.
public extension View {
    func dsFieldBackground(focused: Bool, error: Bool = false) -> some View {
        self
            .padding(.vertical, DSSpacing.sm + 2)
            .padding(.horizontal, DSSpacing.md)
            .background(Color.dsBackground, in: RoundedRectangle(cornerRadius: DSRadius.field + 2))
            .overlay(
                RoundedRectangle(cornerRadius: DSRadius.field + 2)
                    .strokeBorder(
                        error ? Color.dsDanger : (focused ? Color.dsAccent : Color.dsSeparator),
                        lineWidth: (focused || error) ? 2 : 1
                    )
            )
            .animation(.easeOut(duration: 0.15), value: focused)
            .animation(.easeOut(duration: 0.15), value: error)
    }
}

/// Inline error line: a danger triangle + short message, both in `danger` Footnote.
public struct DSInlineError: View {
    private let message: String
    public init(_ message: String) { self.message = message }

    public var body: some View {
        Label {
            Text(message).font(.dsFootnote)
        } icon: {
            Image(systemName: "exclamationmark.triangle")
        }
        .foregroundStyle(Color.dsDanger)
    }
}
