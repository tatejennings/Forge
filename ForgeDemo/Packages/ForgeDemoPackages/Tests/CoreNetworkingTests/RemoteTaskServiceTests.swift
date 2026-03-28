import Testing
import Foundation
import CoreModels
@testable import CoreNetworking

@Suite("RemoteTaskService")
struct RemoteTaskServiceTests {

    @Test("Decodes and maps tasks from JSON")
    func decodesAndMapsTasks() async throws {
        let json = """
        [
            {"id": 1, "title": "delectus aut autem", "completed": false, "userId": 1},
            {"id": 2, "title": "quis ut nam facilis", "completed": true, "userId": 1}
        ]
        """.data(using: .utf8)!

        let client = TestHTTPClient(data: json)
        let service = RemoteTaskService(httpClient: client)
        let tasks = try await service.fetchTodos()

        #expect(tasks.count == 2)
        #expect(tasks[0].title == "delectus aut autem")
        #expect(tasks[0].isCompleted == false)
        #expect(tasks[1].title == "quis ut nam facilis")
        #expect(tasks[1].isCompleted == true)
    }

    @Test("Throws on network failure")
    func throwsOnNetworkFailure() async {
        let client = TestHTTPClient(shouldThrow: true)
        let service = RemoteTaskService(httpClient: client)

        do {
            _ = try await service.fetchTodos()
            #expect(Bool(false), "Expected error to be thrown")
        } catch {
            #expect(error is TestNetworkError)
        }
    }

    @Test("Deterministic UUID produces same UUID for same input")
    func deterministicUUID() {
        let id1 = UUID(remoteID: 42)
        let id2 = UUID(remoteID: 42)
        #expect(id1 == id2)
    }

    @Test("Deterministic UUID produces different UUIDs for different inputs")
    func differentUUIDs() {
        let id1 = UUID(remoteID: 1)
        let id2 = UUID(remoteID: 2)
        #expect(id1 != id2)
    }

    @Test("TodoDTO maps title and completion status correctly")
    func dtoMapping() throws {
        let json = """
        [{"id": 5, "title": "Buy milk", "completed": false, "userId": 1}]
        """.data(using: .utf8)!

        let dtos = try JSONDecoder().decode([TodoDTO].self, from: json)
        let task = dtos[0].toDomain()

        #expect(task.title == "Buy milk")
        #expect(task.isCompleted == false)
        #expect(task.id == UUID(remoteID: 5))
    }
}
