import SwiftUI
import CoreModels

public struct AddTaskSheet: View {
    @State private var viewModel = TaskContainer.shared.addTaskViewModel
    @Environment(\.dismiss) private var dismiss
    var onTaskAdded: () -> Void

    public init(onTaskAdded: @escaping () -> Void) {
        self.onTaskAdded = onTaskAdded
    }

    public var body: some View {
        NavigationStack {
            Form {
                Section("Title") {
                    TextField("What needs to be done?", text: $viewModel.title)
                }
                Section("Notes (optional)") {
                    TextField("Add notes...", text: $viewModel.notes, axis: .vertical)
                        .lineLimit(3...6)
                }
                if let error = viewModel.errorMessage {
                    Section {
                        Text(error).foregroundStyle(.red)
                    }
                }
            }
            .navigationTitle("New Task")
            #if os(iOS)
            .navigationBarTitleDisplayMode(.inline)
            #endif
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Add") {
                        Task {
                            if await viewModel.submit() != nil {
                                onTaskAdded()
                                dismiss()
                            }
                        }
                    }
                    .disabled(!viewModel.canSubmit)
                }
            }
        }
    }
}

#Preview {
    AddTaskSheet(onTaskAdded: {})
}
