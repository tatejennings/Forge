import Foundation

public protocol TaskServiceProtocol: Sendable {
    func loadTasks() async throws -> [TaskItem]
    func refreshTasks() async throws -> [TaskItem]
    func addTask(title: String, notes: String) async throws -> TaskItem
    func toggleTask(id: UUID) async throws -> TaskItem
    func deleteTask(id: UUID) async throws
}
