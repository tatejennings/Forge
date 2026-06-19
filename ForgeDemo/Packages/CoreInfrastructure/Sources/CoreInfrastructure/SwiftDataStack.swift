import Foundation
import SwiftData

public final class SwiftDataStack: Sendable {
    public let container: ModelContainer

    public init() throws {
        let schema = Schema([TaskRecord.self])
        let config = ModelConfiguration(schema: schema, isStoredInMemoryOnly: false)
        self.container = try ModelContainer(for: schema, configurations: config)
    }

    private init(inMemory: Bool) throws {
        let schema = Schema([TaskRecord.self])
        let config = ModelConfiguration(schema: schema, isStoredInMemoryOnly: true)
        self.container = try ModelContainer(for: schema, configurations: config)
    }

    public static func inMemory() throws -> SwiftDataStack {
        try SwiftDataStack(inMemory: true)
    }
}
