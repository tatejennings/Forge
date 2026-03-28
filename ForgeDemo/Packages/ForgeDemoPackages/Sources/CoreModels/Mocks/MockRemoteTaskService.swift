#if DEBUG
public final class MockRemoteTaskService: RemoteTaskServiceProtocol, @unchecked Sendable {
    public var stubbedTasks: [TaskItem]
    public var shouldThrow: Bool

    public init(tasks: [TaskItem] = TaskItem.previews, shouldThrow: Bool = false) {
        self.stubbedTasks = tasks
        self.shouldThrow = shouldThrow
    }

    public func fetchTodos() async throws -> [TaskItem] {
        if shouldThrow { throw MockError.forced }
        return stubbedTasks
    }
}
#endif
