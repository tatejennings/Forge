import Foundation
import SwiftData
import CoreModels

/// All methods are `@MainActor` because SwiftData `ModelContext` requires actor isolation.
public final class TaskRepository: TaskRepositoryProtocol {
    private let stack: SwiftDataStack

    public init(stack: SwiftDataStack) {
        self.stack = stack
    }

    @MainActor
    public func fetchAll() async throws -> [TaskItem] {
        let context = ModelContext(stack.container)
        let descriptor = FetchDescriptor<TaskRecord>(sortBy: [SortDescriptor(\.createdAt, order: .reverse)])
        let records = try context.fetch(descriptor)
        return records.map { $0.toTaskItem() }
    }

    @MainActor
    public func save(_ task: TaskItem) async throws {
        let context = ModelContext(stack.container)
        let record = TaskRecord(
            id: task.id,
            title: task.title,
            notes: task.notes,
            isCompleted: task.isCompleted,
            createdAt: task.createdAt,
            completedAt: task.completedAt
        )
        context.insert(record)
        try context.save()
    }

    @MainActor
    public func update(_ task: TaskItem) async throws {
        let context = ModelContext(stack.container)
        let id = task.id
        let descriptor = FetchDescriptor<TaskRecord>(predicate: #Predicate { $0.id == id })
        guard let record = try context.fetch(descriptor).first else { return }
        record.title = task.title
        record.notes = task.notes
        record.isCompleted = task.isCompleted
        record.completedAt = task.completedAt
        try context.save()
    }

    @MainActor
    public func delete(id: UUID) async throws {
        let context = ModelContext(stack.container)
        let descriptor = FetchDescriptor<TaskRecord>(predicate: #Predicate { $0.id == id })
        guard let record = try context.fetch(descriptor).first else { return }
        context.delete(record)
        try context.save()
    }

    @MainActor
    public func upsertAll(_ tasks: [TaskItem]) async throws {
        let context = ModelContext(stack.container)
        for task in tasks {
            let id = task.id
            let descriptor = FetchDescriptor<TaskRecord>(predicate: #Predicate { $0.id == id })
            if let existing = try context.fetch(descriptor).first {
                existing.title = task.title
                existing.notes = task.notes
                existing.isCompleted = task.isCompleted
                existing.completedAt = task.completedAt
            } else {
                let record = TaskRecord(
                    id: task.id,
                    title: task.title,
                    notes: task.notes,
                    isCompleted: task.isCompleted,
                    createdAt: task.createdAt,
                    completedAt: task.completedAt
                )
                context.insert(record)
            }
        }
        try context.save()
    }
}

extension TaskRecord {
    func toTaskItem() -> TaskItem {
        TaskItem(
            id: id,
            title: title,
            notes: notes,
            isCompleted: isCompleted,
            createdAt: createdAt,
            completedAt: completedAt
        )
    }
}
