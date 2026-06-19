import Foundation
import CoreModels

public final class RemoteTaskService: RemoteTaskServiceProtocol, Sendable {
    private let httpClient: any HTTPClientProtocol
    private let baseURL = URL(string: "https://jsonplaceholder.typicode.com")!

    public init(httpClient: any HTTPClientProtocol) {
        self.httpClient = httpClient
    }

    public func fetchTodos() async throws -> [TaskItem] {
        let dtos: [TodoDTO] = try await httpClient.get(baseURL.appending(path: "todos"))
        return dtos.map { $0.toDomain() }
    }
}
