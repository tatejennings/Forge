import Foundation

public enum TaskError: Error, LocalizedError {
    case emptyTitle
    case notFound

    public var errorDescription: String? {
        switch self {
        case .emptyTitle: return "Task title cannot be empty."
        case .notFound: return "Task not found."
        }
    }
}
