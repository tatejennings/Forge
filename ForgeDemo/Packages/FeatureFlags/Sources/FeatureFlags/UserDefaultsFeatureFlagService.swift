import Foundation
import Observation
import CoreModels

/// Local, persistent feature-flag backend. Each flag is stored under its `rawValue` in
/// `UserDefaults`; an unset flag falls back to `FeatureFlag.defaultValue`.
///
/// Named for its backend on purpose — it's one of several interchangeable
/// `FeatureFlagServiceProtocol` implementations (see
/// `LaunchDarklyFeatureFlagService.swift.example`). Swapping backends is a one-line change
/// in `FeatureFlagContainer`.
@Observable
public final class UserDefaultsFeatureFlagService: FeatureFlagServiceProtocol, @unchecked Sendable {
    @ObservationIgnored
    private let defaults: UserDefaults

    // The real state lives in `UserDefaults`, so this counter is the observed property that
    // drives `@Observable`: reads touch it, writes bump it, and SwiftUI re-renders.
    private var version = 0

    public init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
    }

    private func key(for flag: FeatureFlag) -> String { "featureFlag.\(flag.rawValue)" }

    public func isEnabled(_ flag: FeatureFlag) -> Bool {
        _ = version
        guard defaults.object(forKey: key(for: flag)) != nil else { return flag.defaultValue }
        return defaults.bool(forKey: key(for: flag))
    }

    public func setEnabled(_ flag: FeatureFlag, _ enabled: Bool) {
        defaults.set(enabled, forKey: key(for: flag))
        version &+= 1
    }

    /// No-op: local values are always current. A remote backend would fetch here.
    public func refresh() async {}
}
