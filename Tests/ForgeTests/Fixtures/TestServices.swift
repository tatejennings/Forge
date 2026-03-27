import Foundation

// MARK: - Protocols

protocol ServiceProtocol: Sendable {
    var id: String { get }
}

// MARK: - Implementations

final class SimpleService: ServiceProtocol, @unchecked Sendable {
    let id: String

    init(id: String = UUID().uuidString) {
        self.id = id
    }
}

final class CountingService: @unchecked Sendable {
    static let counter = Counter()
    let instanceNumber: Int

    init() {
        self.instanceNumber = CountingService.counter.increment()
    }
}

/// Thread-safe collector for gathering IDs from concurrent operations.
final class IDCollector: @unchecked Sendable {
    private var ids: [String] = []
    private let lock = NSLock()

    func append(_ id: String) {
        lock.lock()
        defer { lock.unlock() }
        ids.append(id)
    }

    var uniqueIDs: Set<String> {
        lock.lock()
        defer { lock.unlock() }
        return Set(ids)
    }
}

/// Thread-safe counter for verifying instance creation counts.
final class Counter: @unchecked Sendable {
    private var _value = 0
    private let lock = NSLock()

    func increment() -> Int {
        lock.lock()
        defer { lock.unlock() }
        _value += 1
        return _value
    }

    func reset() {
        lock.lock()
        defer { lock.unlock() }
        _value = 0
    }

    var value: Int {
        lock.lock()
        defer { lock.unlock() }
        return _value
    }
}
