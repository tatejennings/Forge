import Foundation
import Testing
import CoreModels
@testable import FeatureFlags

@Suite("UserDefaultsFeatureFlagService")
struct UserDefaultsFeatureFlagServiceTests {

    /// Each test gets an isolated UserDefaults suite so it never touches real app state.
    private func makeService() -> (UserDefaultsFeatureFlagService, UserDefaults) {
        let suiteName = "FeatureFlagsTests.\(UUID().uuidString)"
        let defaults = UserDefaults(suiteName: suiteName)!
        return (UserDefaultsFeatureFlagService(defaults: defaults), defaults)
    }

    @Test("unset flags fall back to their default value")
    func defaultsWhenUnset() {
        let (service, _) = makeService()
        for flag in FeatureFlag.allCases {
            #expect(service.isEnabled(flag) == flag.defaultValue)
        }
    }

    @Test("setEnabled persists and overrides the default")
    func persistsOverride() {
        let (service, defaults) = makeService()
        let flag = FeatureFlag.confirmBeforeDelete   // default: false
        service.setEnabled(flag, true)
        #expect(service.isEnabled(flag) == true)

        // A fresh service over the same store reads the persisted value.
        let reloaded = UserDefaultsFeatureFlagService(defaults: defaults)
        #expect(reloaded.isEnabled(flag) == true)
    }

    @Test("flags can be turned off below their default")
    func overrideToFalse() {
        let (service, _) = makeService()
        let flag = FeatureFlag.pullToRefresh   // default: true
        service.setEnabled(flag, false)
        #expect(service.isEnabled(flag) == false)
    }
}
