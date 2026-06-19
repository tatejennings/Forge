import Foundation

public protocol TaskRepositoryProtocol: Sendable {
    func fetchAll() async throws -> [TaskItem]
    func save(_ task: TaskItem) async throws
    func update(_ task: TaskItem) async throws
    func delete(id: UUID) async throws
    func upsertAll(_ tasks: [TaskItem]) async throws
}
