import Foundation
import CoreModels

final class TestHTTPClient: HTTPClientProtocol, @unchecked Sendable {
    var stubbedData: Data
    var shouldThrow: Bool

    init(data: Data = Data(), shouldThrow: Bool = false) {
        self.stubbedData = data
        self.shouldThrow = shouldThrow
    }

    func get<T: Decodable & Sendable>(_ url: URL) async throws -> T {
        if shouldThrow { throw TestNetworkError.forced }
        return try JSONDecoder().decode(T.self, from: stubbedData)
    }
}

enum TestNetworkError: Error {
    case forced
}
