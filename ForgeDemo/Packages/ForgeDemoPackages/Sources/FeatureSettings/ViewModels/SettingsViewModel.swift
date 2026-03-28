import Observation
import CoreModels

@Observable
public final class SettingsViewModel {
    @ObservationIgnored
    @Inject(\.appState) private var appState
    @ObservationIgnored
    @Inject(\.taskService) private var taskService

    public var displayName: String = ""
    public var sortOrder: SortOrder = .newestFirst
    public var isClearingCompleted: Bool = false

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
            for task in tasks where task.isCompleted {
                try await taskService.deleteTask(id: task.id)
            }
            onCompletedCleared?()
        } catch { }
    }
}
