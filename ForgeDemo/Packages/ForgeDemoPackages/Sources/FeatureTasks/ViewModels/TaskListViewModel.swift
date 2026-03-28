import Observation
import Foundation
import CoreModels

@Observable
public final class TaskListViewModel {
    @ObservationIgnored
    @Inject(\.taskService) private var taskService
    @ObservationIgnored
    @Inject(\.appState) private var appState

    public var tasks: [TaskItem] = []
    public var isLoading: Bool = false
    public var errorMessage: String?

    public var filteredTasks: [TaskItem] {
        switch appState.activeFilter {
        case .all: return tasks
        case .active: return tasks.filter { !$0.isCompleted }
        case .completed: return tasks.filter { $0.isCompleted }
        }
    }

    public init() {}

    @MainActor
    public func loadTasks() async {
        isLoading = true
        errorMessage = nil
        defer { isLoading = false }
        do {
            tasks = try await taskService.loadTasks()
            syncBadgeCount()
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    @MainActor
    public func refreshTasks() async {
        appState.isSyncing = true
        errorMessage = nil
        defer { appState.isSyncing = false }
        do {
            tasks = try await taskService.refreshTasks()
            syncBadgeCount()
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    @MainActor
    public func completeTask(id: UUID) async {
        do {
            let updated = try await taskService.completeTask(id: id)
            if let index = tasks.firstIndex(where: { $0.id == updated.id }) {
                tasks[index] = updated
            }
            syncBadgeCount()
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    @MainActor
    public func deleteTask(id: UUID) async {
        do {
            try await taskService.deleteTask(id: id)
            tasks.removeAll { $0.id == id }
            syncBadgeCount()
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    private func syncBadgeCount() {
        appState.incompletedTaskCount = tasks.filter { !$0.isCompleted }.count
    }
}
