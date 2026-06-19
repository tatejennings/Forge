import SwiftUI
import CoreModels

public struct TaskDetailView: View {
    let task: TaskItem
    var onTaskUpdated: ((TaskItem) -> Void)?

    @State private var currentTask: TaskItem
    @State private var isToggling = false
    @State private var errorMessage: String?

    private var taskService: any TaskServiceProtocol {
        TaskContainer.shared.taskService
    }

    public init(task: TaskItem, onTaskUpdated: ((TaskItem) -> Void)? = nil) {
        self.task = task
        self.onTaskUpdated = onTaskUpdated
        self._currentTask = State(initialValue: task)
    }

    public var body: some View {
        Form {
            Section("Title") {
                Text(currentTask.title)
            }
            if !currentTask.notes.isEmpty {
                Section("Notes") {
                    Text(currentTask.notes)
                }
            }
            Section("Status") {
                Button {
                    Task { await toggle() }
                } label: {
                    Label(
                        currentTask.isCompleted ? "Completed" : "Not Completed",
                        systemImage: currentTask.isCompleted ? "checkmark.circle.fill" : "circle"
                    )
                    .foregroundStyle(currentTask.isCompleted ? .green : .primary)
                }
                .disabled(isToggling)
            }
            if let error = errorMessage {
                Section {
                    Text(error).foregroundStyle(.red)
                }
            }
        }
        .navigationTitle("Task Detail")
        #if os(iOS)
        .navigationBarTitleDisplayMode(.inline)
        #endif
    }

    @MainActor
    private func toggle() async {
        isToggling = true
        defer { isToggling = false }
        do {
            let updated = try await taskService.toggleTask(id: currentTask.id)
            currentTask = updated
            onTaskUpdated?(updated)
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}

#Preview {
    NavigationStack {
        TaskDetailView(task: TaskItem(title: "Preview Task", notes: "Some notes here"))
    }
}
