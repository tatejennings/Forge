#if DEBUG
import Foundation

public final class MockHTTPClient: HTTPClientProtocol, @unchecked Sendable {
    public var stubbedData: Data
    public var shouldThrow: Bool

    public init(data: Data = Data(), shouldThrow: Bool = false) {
        self.stubbedData = data
        self.shouldThrow = shouldThrow
    }

    public func get<T: Decodable & Sendable>(_ url: URL) async throws -> T {
        if shouldThrow { throw MockError.forced }
        return try JSONDecoder().decode(T.self, from: stubbedData)
    }
}
#endif
