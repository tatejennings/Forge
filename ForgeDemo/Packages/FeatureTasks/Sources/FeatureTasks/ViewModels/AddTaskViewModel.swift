import Observation
import Foundation
import CoreModels

@Observable
public final class AddTaskViewModel {
    @ObservationIgnored
    @Inject(\.taskService) private var taskService
    @ObservationIgnored
    @Inject(\.logger) private var logger

    public var title: String = ""
    public var notes: String = ""
    public var isSubmitting: Bool = false
    public var errorMessage: String?

    public var canSubmit: Bool {
        !title.trimmingCharacters(in: .whitespaces).isEmpty && !isSubmitting
    }

    public init() {}

    @MainActor
    public func submit() async -> TaskItem? {
        guard canSubmit else { return nil }
        isSubmitting = true
        defer { isSubmitting = false }
        do {
            let task = try await taskService.addTask(title: title, notes: notes)
            logger.info("Submitted new task \(task.id)")
            return task
        } catch {
            logger.error("addTask failed: \(error.localizedDescription)")
            errorMessage = error.localizedDescription
            return nil
        }
    }
}
