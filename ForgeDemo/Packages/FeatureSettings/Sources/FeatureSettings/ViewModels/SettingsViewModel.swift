import Observation
import CoreModels

@Observable
public final class SettingsViewModel {
    @ObservationIgnored
    @Inject(\.appState) private var appState
    @ObservationIgnored
    @Inject(\.taskService) private var taskService
    @ObservationIgnored
    @Inject(\.logger) private var logger

    public var displayName: String = ""
    public var sortOrder: SortOrder = .newestFirst
    public var isClearingCompleted: Bool = false
    public var errorMessage: String?

    /// Called after clearing completed tasks so the app target can reset caches.
    public var onCompletedCleared: (() -> Void)?

    public init() {}

    public func loadSettings() {
        displayName = appState.settings.displayName
        sortOrder = appState.settings.preferredSortOrder
    }

    public func saveSettings() {
        appState.settings.displayName = displayName
        appState.settings.preferredSortOrder = sortOrder
    }

    @MainActor
    public func clearCompleted() async {
        isClearingCompleted = true
        defer { isClearingCompleted = false }
        do {
            let tasks = try await taskService.loadTasks()
            let completed = tasks.filter(\.isCompleted)
            for task in completed {
                try await taskService.deleteTask(id: task.id)
            }
            logger.info("Cleared \(completed.count) completed tasks")
            onCompletedCleared?()
        } catch {
            logger.error("clearCompleted failed: \(error.localizedDescription)")
            errorMessage = error.localizedDescription
        }
    }
}
