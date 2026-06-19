import Forge
import CoreModels

// Per-module Forge container (Modular path). CoreLogger is a provider module: it owns the
// logging implementation and exposes it for the composition root to wire into feature
// modules. No local `Inject` typealias — it injects nothing from itself.
public final class LoggerContainer: Container, SharedContainer, @unchecked Sendable {
    nonisolated(unsafe) public static var shared = LoggerContainer()

    /// The app-wide logger. Swap `OSLogger()` for any other `LoggerProtocol` (a file
    /// logger, a remote sink) here and every call site follows automatically.
    public var logger: any LoggerProtocol {
        provide(.singleton) {
            OSLogger()
        } preview: {
            MockLogger()
        }
    }
}
