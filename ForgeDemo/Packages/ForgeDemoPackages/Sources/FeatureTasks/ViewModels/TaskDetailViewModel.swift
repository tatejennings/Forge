import Observation
import Foundation
import CoreModels

@Observable
public final class TaskDetailViewModel {
    @ObservationIgnored
    @Inject(\.taskService) private var taskService

    public private(set) var task: TaskItem
    public var isToggling: Bool = false
    public var errorMessage: String?

    public init(task: TaskItem) {
        self.task = task
    }

    @MainActor
    public func toggle() async -> TaskItem? {
        isToggling = true
        defer { isToggling = false }
        do {
            let updated = try await taskService.toggleTask(id: task.id)
            task = updated
            return updated
        } catch {
            errorMessage = error.localizedDescription
            return nil
        }
    }
}
