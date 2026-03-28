import SwiftUI
import CoreModels

public struct TaskListView: View {
    @State private var viewModel = TaskContainer.shared.taskListViewModel
    @State private var appState = TaskContainer.shared.appState

    @State private var showingAddTask = false

    public init() {}

    public var body: some View {
        NavigationStack {
            Group {
                if viewModel.isLoading {
                    ProgressView("Loading tasks…")
                } else {
                    taskList
                }
            }
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
                await viewModel.loadTasks()
            }
            .refreshable {
                await viewModel.refreshTasks()
            }
            .alert("Error", isPresented: .constant(viewModel.errorMessage != nil)) {
                Button("OK") { viewModel.errorMessage = nil }
            } message: {
                Text(viewModel.errorMessage ?? "")
            }
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
                    NavigationLink(value: task) {
                        TaskRowView(task: task) {
                            Task { await viewModel.toggleTask(id: task.id) }
                        }
                    }
                }
                .onDelete { indexSet in
                    let ids = indexSet.map { viewModel.filteredTasks[$0].id }
                    for id in ids {
                        Task { await viewModel.deleteTask(id: id) }
                    }
                }
            }
        }
        .navigationDestination(for: TaskItem.self) { task in
            TaskDetailView(task: task)
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
