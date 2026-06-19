import Testing
import CoreModels
@testable import FeatureSettings

// Both suites swap the global `SettingsContainer.shared`, so they must not run
// concurrently. A `.serialized` parent suite serializes all nested suites/tests.
@Suite("FeatureSettings", .serialized)
struct FeatureSettingsTests {

    @Suite("SettingsViewModel")
    struct SettingsViewModelTests {

        @Test("saveSettings updates AppState")
        func saveSettingsUpdatesAppState() {
            let previous = SettingsContainer.shared
            defer { SettingsContainer.shared = previous }
            let container = SettingsContainer()
            SettingsContainer.shared = container

            let mockState = MockAppState()
            let mockService = MockTaskService()
            container.override(\.appState) { mockState as any AppStateProtocol }
            container.override(\.taskService) { mockService as any TaskServiceProtocol }
            container.override(\.logger) { MockLogger() as any LoggerProtocol }

            let vm = SettingsViewModel()
            vm.loadSettings()
            vm.displayName = "Test User"
            vm.sortOrder = .alphabetical
            vm.saveSettings()
            #expect(mockState.settings.displayName == "Test User")
            #expect(mockState.settings.preferredSortOrder == .alphabetical)
        }

        @Test("clearCompleted sets errorMessage on failure")
        @MainActor
        func clearCompletedSetsError() async {
            let previous = SettingsContainer.shared
            defer { SettingsContainer.shared = previous }
            let container = SettingsContainer()
            SettingsContainer.shared = container

            let mockService = MockTaskService(shouldThrow: true)
            let mockState = MockAppState()
            container.override(\.taskService) { mockService as any TaskServiceProtocol }
            container.override(\.appState) { mockState as any AppStateProtocol }
            container.override(\.logger) { MockLogger() as any LoggerProtocol }

            let vm = SettingsViewModel()
            await vm.clearCompleted()
            #expect(vm.errorMessage != nil, "Error should be surfaced when clearCompleted fails")
        }
    }

    @Suite("FeatureFlagsViewModel")
    struct FeatureFlagsViewModelTests {

        private func withMockContainer(_ body: (MockFeatureFlagService) -> Void) {
            let previous = SettingsContainer.shared
            defer { SettingsContainer.shared = previous }
            let container = SettingsContainer()
            SettingsContainer.shared = container

            let flags = MockFeatureFlagService()
            container.override(\.flagService) { flags as any FeatureFlagServiceProtocol }
            container.override(\.logger) { MockLogger() as any LoggerProtocol }

            body(flags)
        }

        @Test("isOn reflects the flag service's defaults")
        func readsDefaults() {
            withMockContainer { _ in
                let vm = FeatureFlagsViewModel()
                for flag in FeatureFlag.allCases {
                    #expect(vm.isOn(flag) == flag.defaultValue)
                }
            }
        }

        @Test("setOn writes through to the flag service")
        func writesThrough() {
            withMockContainer { flags in
                let vm = FeatureFlagsViewModel()
                vm.setOn(.confirmBeforeDelete, true)
                #expect(vm.isOn(.confirmBeforeDelete) == true)
                #expect(flags.isEnabled(.confirmBeforeDelete) == true)

                vm.setOn(.pullToRefresh, false)
                #expect(flags.isEnabled(.pullToRefresh) == false)
            }
        }
    }
}
