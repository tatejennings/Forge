import Foundation
import SwiftData

@Model
final class TaskRecord {
    @Attribute(.unique) var id: UUID
    var title: String
    var notes: String
    var isCompleted: Bool
    var createdAt: Date
    var completedAt: Date?

    init(
        id: UUID,
        title: String,
        notes: String = "",
        isCompleted: Bool = false,
        createdAt: Date = Date(),
        completedAt: Date? = nil
    ) {
        self.id = id
        self.title = title
        self.notes = notes
        self.isCompleted = isCompleted
        self.createdAt = createdAt
        self.completedAt = completedAt
    }
}
