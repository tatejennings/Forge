import SwiftUI
import CoreModels
import DesignSystem

public struct AddTaskSheet: View {
    @State private var viewModel = TaskContainer.shared.addTaskViewModel
    @Environment(\.dismiss) private var dismiss
    @FocusState private var focus: Field?
    var onTaskAdded: () -> Void

    private enum Field { case title, notes }

    public init(onTaskAdded: @escaping () -> Void) {
        self.onTaskAdded = onTaskAdded
    }

    public var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: DSSpacing.xl) {
                    fieldGroup("Title") {
                        TextField("What needs to be done?", text: $viewModel.title)
                            .font(.dsBody)
                            .focused($focus, equals: .title)
                            .submitLabel(.next)
                            .dsFieldBackground(
                                focused: focus == .title,
                                error: viewModel.errorMessage != nil
                            )
                    }

                    fieldGroup("Notes (optional)") {
                        TextField("Add notes…", text: $viewModel.notes, axis: .vertical)
                            .font(.dsBody)
                            .lineLimit(3...6)
                            .focused($focus, equals: .notes)
                            .dsFieldBackground(focused: focus == .notes)
                    }

                    if let error = viewModel.errorMessage {
                        DSInlineError(error)
                    }
                }
                .padding(DSSpacing.lg)
            }
            .background(Color.dsBackground.ignoresSafeArea())
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
                    .fontWeight(.semibold)
                    .disabled(!viewModel.canSubmit)
                }
            }
        }
        .tint(.dsAccent)
    }

    @ViewBuilder
    private func fieldGroup(_ title: String, @ViewBuilder content: () -> some View) -> some View {
        VStack(alignment: .leading, spacing: DSSpacing.sm) {
            Text(title)
                .font(.dsCaption)
                .textCase(.uppercase)
                .tracking(0.4)
                .foregroundStyle(Color.dsInk2)
            content()
        }
    }
}

#Preview {
    AddTaskSheet(onTaskAdded: {})
}
