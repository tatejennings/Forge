import Foundation

public protocol HTTPClientProtocol: Sendable {
    func get<T: Decodable & Sendable>(_ url: URL) async throws -> T
}
