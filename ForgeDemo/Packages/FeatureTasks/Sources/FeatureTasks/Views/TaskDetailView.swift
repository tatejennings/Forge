import SwiftUI
import CoreModels
import DesignSystem

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
                    .font(.dsBody)
                    .foregroundStyle(Color.dsInk)
            }
            .listRowBackground(Color.dsCard)

            if !currentTask.notes.isEmpty {
                Section("Notes") {
                    Text(currentTask.notes)
                        .font(.dsBody)
                        .foregroundStyle(Color.dsInk2)
                }
                .listRowBackground(Color.dsCard)
            }

            Section("Status") {
                Button {
                    Task { await toggle() }
                } label: {
                    HStack(spacing: DSSpacing.md) {
                        Image(systemName: currentTask.isCompleted ? "checkmark.circle.fill" : "circle")
                            .foregroundStyle(currentTask.isCompleted ? Color.dsAccent : Color.dsInk3)
                        Text(currentTask.isCompleted ? "Completed" : "Not Completed")
                            .font(.dsBody)
                            .foregroundStyle(currentTask.isCompleted ? Color.dsAccent : Color.dsInk)
                        Spacer()
                    }
                    .contentShape(Rectangle())
                }
                .disabled(isToggling)
            }
            .listRowBackground(Color.dsCard)

            if let error = errorMessage {
                Section {
                    DSInlineError(error)
                }
                .listRowBackground(Color.dsCard)
            }
        }
        .scrollContentBackground(.hidden)
        .background(Color.dsBackground.ignoresSafeArea())
        .navigationTitle("Task Detail")
        #if os(iOS)
        .navigationBarTitleDisplayMode(.inline)
        #endif
        .tint(.dsAccent)
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
