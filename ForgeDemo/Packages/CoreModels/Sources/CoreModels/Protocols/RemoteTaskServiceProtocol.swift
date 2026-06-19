public protocol RemoteTaskServiceProtocol: Sendable {
    func fetchTodos() async throws -> [TaskItem]
}
