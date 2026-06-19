#if DEBUG
import Observation

/// In-memory feature-flag service for previews and tests. Starts from each flag's
/// `defaultValue` unless seeded with overrides.
@Observable
public final class MockFeatureFlagService: FeatureFlagServiceProtocol, @unchecked Sendable {
    private var overrides: [FeatureFlag: Bool]

    public init(overrides: [FeatureFlag: Bool] = [:]) {
        self.overrides = overrides
    }

    public func isEnabled(_ flag: FeatureFlag) -> Bool {
        overrides[flag] ?? flag.defaultValue
    }

    public func setEnabled(_ flag: FeatureFlag, _ enabled: Bool) {
        overrides[flag] = enabled
    }

    public func refresh() async {}
}
#endif
