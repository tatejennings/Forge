import SwiftUI

/// A task row: completion toggle + title (+ optional 1-line note). The trailing chevron is
/// supplied by the enclosing `NavigationLink`, per native list convention.
///
/// Takes primitives, not a domain model, so DesignSystem stays decoupled from CoreModels.
public struct DSTaskRow: View {
    private let title: String
    private let note: String?
    private let isComplete: Bool
    private let showNote: Bool
    private let onToggle: () -> Void

    public init(
        title: String,
        note: String? = nil,
        isComplete: Bool,
        showNote: Bool = true,
        onToggle: @escaping () -> Void
    ) {
        self.title = title
        self.note = note
        self.isComplete = isComplete
        self.showNote = showNote
        self.onToggle = onToggle
    }

    public var body: some View {
        HStack(spacing: DSSpacing.md) {
            CompletionToggle(isComplete: isComplete, action: onToggle)

            VStack(alignment: .leading, spacing: DSSpacing.xs / 2) {
                Text(title)
                    .font(.dsBody)
                    .foregroundStyle(isComplete ? Color.dsInk2 : Color.dsInk)
                    .strikethrough(isComplete, color: Color.dsInk2)

                if showNote, let note, !note.isEmpty {
                    Text(note)
                        .font(.dsFootnote)
                        .foregroundStyle(Color.dsInk2)
                        .opacity(isComplete ? 0.6 : 1)
                        .lineLimit(1)
                }
            }
            Spacer(minLength: 0)
        }
        .padding(.vertical, DSSpacing.xs / 2)
        .animation(.easeOut(duration: 0.25), value: isComplete)
    }
}
