#if DEBUG
import Foundation

public final class MockTaskService: TaskServiceProtocol, @unchecked Sendable {
    public var stubbedTasks: [TaskItem]
    public var shouldThrow: Bool
    public private(set) var refreshCallCount = 0

    public init(tasks: [TaskItem] = TaskItem.previews, shouldThrow: Bool = false) {
        self.stubbedTasks = tasks
        self.shouldThrow = shouldThrow
    }

    public func loadTasks() async throws -> [TaskItem] {
        if shouldThrow { throw MockError.forced }
        return stubbedTasks
    }

    public func refreshTasks() async throws -> [TaskItem] {
        refreshCallCount += 1
        if shouldThrow { throw MockError.forced }
        return stubbedTasks
    }

    public func addTask(title: String, notes: String) async throws -> TaskItem {
        if shouldThrow { throw MockError.forced }
        let task = TaskItem(title: title, notes: notes)
        stubbedTasks.append(task)
        return task
    }

    public func toggleTask(id: UUID) async throws -> TaskItem {
        guard let index = stubbedTasks.firstIndex(where: { $0.id == id }) else {
            throw MockError.notFound
        }
        stubbedTasks[index].isCompleted.toggle()
        stubbedTasks[index].completedAt = stubbedTasks[index].isCompleted ? Date() : nil
        return stubbedTasks[index]
    }

    public func deleteTask(id: UUID) async throws {
        stubbedTasks.removeAll { $0.id == id }
    }
}

public enum MockError: Error, LocalizedError {
    case forced
    case notFound

    public var errorDescription: String? {
        switch self {
        case .forced: return "Mock error"
        case .notFound: return "Not found"
        }
    }
}
#endif
