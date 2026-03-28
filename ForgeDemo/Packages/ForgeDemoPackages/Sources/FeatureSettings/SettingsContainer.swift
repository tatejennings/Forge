import Forge
import CoreModels

public final class SettingsContainer: Container, SharedContainer, @unchecked Sendable {
    nonisolated(unsafe) public static var shared = SettingsContainer()

    /// Override this with a real implementation from the app target's CoreContainer.
    public var appState: any AppStateProtocol {
        provide(.singleton, preview: { MockAppState() }) {
            MockAppState()
        }
    }

    /// Override this with a real implementation from the app target's CoreContainer.
    public var taskService: any TaskServiceProtocol {
        provide(.singleton, preview: { MockTaskService() }) {
            MockTaskService()
        }
    }

    public var settingsViewModel: SettingsViewModel {
        provide(.cached) { SettingsViewModel() }
    }
}
