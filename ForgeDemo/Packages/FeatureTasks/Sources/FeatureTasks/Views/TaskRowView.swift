import SwiftUI
import CoreModels
import DesignSystem

/// Thin adapter from the domain `TaskItem` to the design system's `DSTaskRow`
/// (which takes primitives so DesignSystem stays decoupled from CoreModels).
struct TaskRowView: View {
    let task: TaskItem
    /// Driven by the `.showNotesInList` feature flag.
    var showNotes: Bool = true
    var onToggle: () -> Void

    var body: some View {
        DSTaskRow(
            title: task.title,
            note: task.notes,
            isComplete: task.isCompleted,
            showNote: showNotes,
            onToggle: onToggle
        )
    }
}
