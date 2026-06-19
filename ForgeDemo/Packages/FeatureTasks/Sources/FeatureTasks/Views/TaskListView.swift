import SwiftUI
import CoreModels
import DesignSystem

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
                        filterMenu
                    }
                    ToolbarItem(placement: .primaryAction) {
                        Button {
                            showingAddTask = true
                        } label: {
                            DSIconCircleLabel(systemName: "plus")
                        }
                        .accessibilityLabel("Add task")
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
        .tint(.dsAccent)
    }

    // Pull-to-refresh is gated behind the `.pullToRefresh` flag, so the gesture disappears
    // entirely when the flag is off (rather than just no-op'ing).
    @ViewBuilder
    private var content: some View {
        if flags.isEnabled(.pullToRefresh) {
            stateContent.refreshable { await viewModel.refreshTasks() }
        } else {
            stateContent
        }
    }

    @ViewBuilder
    private var stateContent: some View {
        if viewModel.isLoading {
            loadingView
        } else {
            taskList
                // Error state: list dims behind the system "Error" alert.
                .opacity(viewModel.errorMessage != nil ? 0.45 : 1)
        }
    }

    private var loadingView: some View {
        VStack(spacing: DSSpacing.md) {
            ProgressView()
                .tint(.dsAccent)
            Text("Loading tasks…")
                .font(.dsSubheadline)
                .foregroundStyle(Color.dsInk2)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.dsBackground.ignoresSafeArea())
    }

    private var taskList: some View {
        let list = List {
            if viewModel.filteredTasks.isEmpty {
                DSEmptyState(
                    title: "No Tasks",
                    message: "Pull down to sync from the server, or tap + to add one."
                )
                .padding(.top, DSSpacing.xxl)
                .listRowBackground(Color.clear)
                .listRowSeparator(.hidden)
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
                    .listRowBackground(Color.dsCard)
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
        .scrollContentBackground(.hidden)
        .background(Color.dsBackground.ignoresSafeArea())
        #if os(iOS)
        return list.listStyle(.insetGrouped)
        #else
        return list
        #endif
    }

    private var filterMenu: some View {
        Menu {
            Picker("Filter", selection: Binding(
                get: { appState.activeFilter },
                set: { appState.activeFilter = $0 }
            )) {
                ForEach(TaskStatus.allCases, id: \.self) { status in
                    Text(status.rawValue.capitalized).tag(status)
                }
            }
        } label: {
            Image(systemName: "line.3.horizontal.decrease.circle")
        }
        .accessibilityLabel("Filter tasks")
    }
}

#Preview("With Tasks") {
    TaskListView()
}
