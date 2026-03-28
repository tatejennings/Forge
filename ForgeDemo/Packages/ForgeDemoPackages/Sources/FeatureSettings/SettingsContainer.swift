import Forge
import CoreModels

typealias Inject<T> = ContainerInject<SettingsContainer, T>

public final class SettingsContainer: Container, SharedContainer, @unchecked Sendable {
    nonisolated(unsafe) public static var shared = SettingsContainer()

    /// Override this with a real implementation from the app target's CoreContainer.
    public var appState: any AppStateProtocol {
        provide(.singleton, preview: { MockAppState() }) {
            #if DEBUG
            print("[Forge] ⚠️ appState resolved without override — using mock fallback")
            #endif
            return MockAppState()
        }
    }

    /// Override this with a real implementation from the app target's CoreContainer.
    public var taskService: any TaskServiceProtocol {
        provide(.singleton, preview: { MockTaskService() }) {
            #if DEBUG
            print("[Forge] ⚠️ taskService resolved without override — using mock fallback")
            #endif
            return MockTaskService()
        }
    }

    public var settingsViewModel: SettingsViewModel {
        provide(.cached) { SettingsViewModel() }
    }
}
