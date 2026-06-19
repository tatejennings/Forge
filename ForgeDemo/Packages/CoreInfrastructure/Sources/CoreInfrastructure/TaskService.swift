import Foundation
import CoreModels

public final class TaskService: TaskServiceProtocol, Sendable {
    private let repository: any TaskRepositoryProtocol
    private let remoteService: any RemoteTaskServiceProtocol
    private let logger: any LoggerProtocol

    public init(
        repository: any TaskRepositoryProtocol,
        remoteService: any RemoteTaskServiceProtocol,
        logger: any LoggerProtocol
    ) {
        self.repository = repository
        self.remoteService = remoteService
        self.logger = logger
    }

    public func loadTasks() async throws -> [TaskItem] {
        do {
            let remoteTasks = try await remoteService.fetchTodos()
            try await repository.upsertAll(remoteTasks)
        } catch {
            logger.warning("Remote fetch failed, falling back to local store: \(error.localizedDescription)")
        }
        let tasks = try await repository.fetchAll()
        logger.info("Loaded \(tasks.count) tasks")
        return tasks
    }

    public func refreshTasks() async throws -> [TaskItem] {
        logger.debug("Refreshing tasks from remote")
        let remoteTasks = try await remoteService.fetchTodos()
        try await repository.upsertAll(remoteTasks)
        let tasks = try await repository.fetchAll()
        logger.info("Refreshed \(tasks.count) tasks")
        return tasks
    }

    public func addTask(title: String, notes: String) async throws -> TaskItem {
        guard !title.trimmingCharacters(in: .whitespaces).isEmpty else {
            logger.error("Rejected addTask with empty title")
            throw TaskError.emptyTitle
        }
        let task = TaskItem(title: title.trimmingCharacters(in: .whitespaces), notes: notes)
        try await repository.save(task)
        logger.info("Added task \(task.id)")
        return task
    }

    public func toggleTask(id: UUID) async throws -> TaskItem {
        var tasks = try await repository.fetchAll()
        guard let index = tasks.firstIndex(where: { $0.id == id }) else {
            logger.error("toggleTask: task \(id) not found")
            throw TaskError.notFound
        }
        tasks[index].isCompleted.toggle()
        tasks[index].completedAt = tasks[index].isCompleted ? Date() : nil
        try await repository.update(tasks[index])
        logger.info("Toggled task \(id) -> completed: \(tasks[index].isCompleted)")
        return tasks[index]
    }

    public func deleteTask(id: UUID) async throws {
        try await repository.delete(id: id)
        logger.info("Deleted task \(id)")
    }
}
