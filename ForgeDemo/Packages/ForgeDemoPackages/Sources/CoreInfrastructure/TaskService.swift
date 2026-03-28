import Foundation
import CoreModels

public final class TaskService: TaskServiceProtocol, Sendable {
    private let repository: any TaskRepositoryProtocol
    private let remoteService: any RemoteTaskServiceProtocol

    public init(
        repository: any TaskRepositoryProtocol,
        remoteService: any RemoteTaskServiceProtocol
    ) {
        self.repository = repository
        self.remoteService = remoteService
    }

    public func loadTasks() async throws -> [TaskItem] {
        do {
            let remoteTasks = try await remoteService.fetchTodos()
            try await repository.upsertAll(remoteTasks)
        } catch {
            // Remote unavailable — silently fall back to local
        }
        return try await repository.fetchAll()
    }

    public func refreshTasks() async throws -> [TaskItem] {
        let remoteTasks = try await remoteService.fetchTodos()
        try await repository.upsertAll(remoteTasks)
        return try await repository.fetchAll()
    }

    public func addTask(title: String, notes: String) async throws -> TaskItem {
        guard !title.trimmingCharacters(in: .whitespaces).isEmpty else {
            throw TaskError.emptyTitle
        }
        let task = TaskItem(title: title.trimmingCharacters(in: .whitespaces), notes: notes)
        try await repository.save(task)
        return task
    }

    public func toggleTask(id: UUID) async throws -> TaskItem {
        var tasks = try await repository.fetchAll()
        guard let index = tasks.firstIndex(where: { $0.id == id }) else {
            throw TaskError.notFound
        }
        tasks[index].isCompleted.toggle()
        tasks[index].completedAt = tasks[index].isCompleted ? Date() : nil
        try await repository.update(tasks[index])
        return tasks[index]
    }

    public func deleteTask(id: UUID) async throws {
        try await repository.delete(id: id)
    }
}
