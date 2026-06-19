import Foundation

public enum NetworkError: Error, LocalizedError {
    case invalidResponse
    case httpError(statusCode: Int)
    case decodingFailed(Error)

    public var errorDescription: String? {
        switch self {
        case .invalidResponse:
            return "The server returned an invalid response."
        case .httpError(let code):
            return "Server error with status code \(code)."
        case .decodingFailed:
            return "Failed to decode server response."
        }
    }
}
