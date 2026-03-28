import Observation
import Foundation
import CoreModels

@Observable
public final class TaskDetailViewModel {
    @ObservationIgnored
    @Inject(\.taskService) private var taskService

    public private(set) var task: TaskItem
    public var isCompleting: Bool = false
    public var errorMessage: String?

    public init(task: TaskItem) {
        self.task = task
    }

    @MainActor
    public func complete() async -> TaskItem? {
        isCompleting = true
        defer { isCompleting = false }
        do {
            let updated = try await taskService.completeTask(id: task.id)
            task = updated
            return updated
        } catch {
            errorMessage = error.localizedDescription
            return nil
        }
    }
}
