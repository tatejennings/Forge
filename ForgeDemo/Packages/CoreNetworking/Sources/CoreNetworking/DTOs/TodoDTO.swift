import Foundation
import CoreModels

public struct TodoDTO: Decodable, Sendable {
    public let id: Int
    public let title: String
    public let completed: Bool

    public func toDomain() -> TaskItem {
        TaskItem(
            id: UUID(remoteID: id),
            title: title,
            isCompleted: completed
        )
    }
}
