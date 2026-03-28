import SwiftUI
import CoreModels

public struct TaskDetailView: View {
    @State private var viewModel: TaskDetailViewModel

    public init(task: TaskItem) {
        self._viewModel = State(initialValue: TaskContainer.shared.taskDetailViewModel(for: task))
    }

    public var body: some View {
        Form {
            Section("Title") {
                Text(viewModel.task.title)
            }
            if !viewModel.task.notes.isEmpty {
                Section("Notes") {
                    Text(viewModel.task.notes)
                }
            }
            Section("Status") {
                if viewModel.task.isCompleted {
                    Label("Completed", systemImage: "checkmark.circle.fill")
                        .foregroundStyle(.green)
                } else {
                    Button("Mark Complete") {
                        Task { await viewModel.complete() }
                    }
                }
            }
        }
        .navigationTitle("Task Detail")
        #if os(iOS)
        .navigationBarTitleDisplayMode(.inline)
        #endif
    }
}

#Preview {
    NavigationStack {
        TaskDetailView(task: TaskItem(title: "Preview Task", notes: "Some notes here"))
    }
}
