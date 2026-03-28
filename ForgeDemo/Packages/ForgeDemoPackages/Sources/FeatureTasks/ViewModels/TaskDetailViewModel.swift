import Observation
import Foundation
import CoreModels

@Observable
public final class TaskDetailViewModel {
    @ObservationIgnored
    @Inject(\.taskService) private var taskService

    public let task: TaskItem
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
            return try await taskService.completeTask(id: task.id)
        } catch {
            errorMessage = error.localizedDescription
            return nil
        }
    }
}
