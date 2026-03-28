import Testing
import CoreModels
@testable import FeatureSettings

@Suite("SettingsViewModel", .serialized)
struct SettingsViewModelTests {

    @Test("saveSettings updates AppState")
    func saveSettingsUpdatesAppState() {
        let container = SettingsContainer()
        SettingsContainer.shared = container

        let mockState = MockAppState()
        let mockService = MockTaskService()
        container.override("appState") { mockState as any AppStateProtocol }
        container.override("taskService") { mockService as any TaskServiceProtocol }

        let vm = SettingsViewModel()
        vm.loadSettings()
        vm.displayName = "Test User"
        vm.sortOrder = .alphabetical
        vm.saveSettings()
        #expect(mockState.settings.displayName == "Test User")
        #expect(mockState.settings.preferredSortOrder == .alphabetical)
    }
}
