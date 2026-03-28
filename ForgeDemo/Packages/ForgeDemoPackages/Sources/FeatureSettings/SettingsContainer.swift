import Forge
import CoreModels

public final class SettingsContainer: Container, SharedContainer, @unchecked Sendable {
    nonisolated(unsafe) public static var shared = SettingsContainer()

    /// Override this with a real implementation from the app target's CoreContainer.
    public var appState: any AppStateProtocol {
        provide(.singleton, preview: { MockAppState() as any AppStateProtocol }) {
            #if DEBUG
            print("[Forge] ⚠️ appState resolved without override — using mock fallback")
            #endif
            return MockAppState() as any AppStateProtocol
        }
    }

    /// Override this with a real implementation from the app target's CoreContainer.
    public var taskService: any TaskServiceProtocol {
        provide(.singleton, preview: { MockTaskService() as any TaskServiceProtocol }) {
            #if DEBUG
            print("[Forge] ⚠️ taskService resolved without override — using mock fallback")
            #endif
            return MockTaskService() as any TaskServiceProtocol
        }
    }

    public var settingsViewModel: SettingsViewModel {
        provide(.cached) { SettingsViewModel() }
    }
}
