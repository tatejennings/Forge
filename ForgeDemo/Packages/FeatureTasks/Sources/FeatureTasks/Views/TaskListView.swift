import SwiftUI
import CoreModels

public struct TaskListView: View {
    @State private var viewModel = TaskContainer.shared.taskListViewModel
    @State private var appState = TaskContainer.shared.appState
    @State private var flags = TaskContainer.shared.flagService

    @State private var showingAddTask = false
    /// Tasks awaiting delete confirmation (only used when `.confirmBeforeDelete` is on).
    @State private var pendingDeleteIDs: [UUID] = []

    public init() {}

    public var body: some View {
        NavigationStack {
            content
                .navigationTitle("ForgeDemo")
                .toolbar {
                    ToolbarItem(placement: .primaryAction) {
                        Button {
                            showingAddTask = true
                        } label: {
                            Image(systemName: "plus")
                        }
                    }
                    ToolbarItem(placement: .secondaryAction) {
                        filterPicker
                    }
                }
                .sheet(isPresented: $showingAddTask) {
                    AddTaskSheet {
                        Task { await viewModel.loadTasks() }
                    }
                }
                .task {
                    guard viewModel.tasks.isEmpty else { return }
                    await viewModel.loadTasks()
                }
                .confirmationDialog(
                    "Delete \(pendingDeleteIDs.count > 1 ? "Tasks" : "Task")?",
                    isPresented: Binding(
                        get: { !pendingDeleteIDs.isEmpty },
                        set: { if !$0 { pendingDeleteIDs = [] } }
                    ),
                    titleVisibility: .visible
                ) {
                    Button("Delete", role: .destructive) {
                        let ids = pendingDeleteIDs
                        pendingDeleteIDs = []
                        for id in ids { Task { await viewModel.deleteTask(id: id) } }
                    }
                    Button("Cancel", role: .cancel) { pendingDeleteIDs = [] }
                }
                .alert("Error", isPresented: .constant(viewModel.errorMessage != nil)) {
                    Button("OK") { viewModel.errorMessage = nil }
                } message: {
                    Text(viewModel.errorMessage ?? "")
                }
        }
    }

    // Pull-to-refresh is gated behind the `.pullToRefresh` flag, so the gesture disappears
    // entirely when the flag is off (rather than just no-op'ing).
    @ViewBuilder
    private var content: some View {
        if flags.isEnabled(.pullToRefresh) {
            mainContent.refreshable { await viewModel.refreshTasks() }
        } else {
            mainContent
        }
    }

    @ViewBuilder
    private var mainContent: some View {
        if viewModel.isLoading {
            ProgressView("Loading tasks…")
        } else {
            taskList
        }
    }

    private var taskList: some View {
        List {
            if viewModel.filteredTasks.isEmpty {
                ContentUnavailableView(
                    "No Tasks",
                    systemImage: "checkmark.circle",
                    description: Text("Pull down to sync from the server, or tap + to add one.")
                )
                .listRowBackground(Color.clear)
            } else {
                ForEach(viewModel.filteredTasks) { task in
                    NavigationLink {
                        TaskDetailView(task: task) { updated in
                            viewModel.updateTask(updated)
                        }
                    } label: {
                        TaskRowView(task: task, showNotes: flags.isEnabled(.showNotesInList)) {
                            Task { await viewModel.toggleTask(id: task.id) }
                        }
                    }
                }
                .onDelete { indexSet in
                    let ids = indexSet.map { viewModel.filteredTasks[$0].id }
                    if flags.isEnabled(.confirmBeforeDelete) {
                        pendingDeleteIDs = ids
                    } else {
                        for id in ids {
                            Task { await viewModel.deleteTask(id: id) }
                        }
                    }
                }
            }
        }
    }

    private var filterPicker: some View {
        Picker("Filter", selection: Binding(
            get: { appState.activeFilter },
            set: { appState.activeFilter = $0 }
        )) {
            ForEach(TaskStatus.allCases, id: \.self) { status in
                Text(status.rawValue.capitalized).tag(status)
            }
        }
        .pickerStyle(.menu)
    }
}

#Preview("With Tasks") {
    TaskListView()
}
