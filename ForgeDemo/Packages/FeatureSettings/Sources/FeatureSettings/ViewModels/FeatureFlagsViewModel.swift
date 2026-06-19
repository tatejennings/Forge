import Observation
import CoreModels

/// Backs the Feature Flags subsection of Settings. Reads and writes flags through the
/// injected `flagService` — which the composition root points at the real FeatureFlags
/// module (or a mock in previews/tests). The view model never knows which backend it is.
@Observable
public final class FeatureFlagsViewModel {
    @ObservationIgnored
    @Inject(\.flagService) private var flagService
    @ObservationIgnored
    @Inject(\.logger) private var logger

    public init() {}

    /// All flags, in declaration order, for the list to render.
    public var flags: [FeatureFlag] { FeatureFlag.allCases }

    public func isOn(_ flag: FeatureFlag) -> Bool {
        flagService.isEnabled(flag)
    }

    public func setOn(_ flag: FeatureFlag, _ enabled: Bool) {
        logger.info("Feature flag \(flag.rawValue) set to \(enabled)")
        flagService.setEnabled(flag, enabled)
    }
}
