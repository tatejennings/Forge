import Observation

/// Read/write access to feature flags. `Observable` (like `AppStateProtocol`) so SwiftUI
/// re-renders when a flag changes — a toggle flipped in Settings instantly affects the
/// Tasks screen.
///
/// Everything in the app depends on this protocol, never a concrete type, so the backend
/// can move from local `UserDefaults` to a remote provider (LaunchDarkly, Firebase Remote
/// Config) by changing only the `FeatureFlagContainer` factory.
public protocol FeatureFlagServiceProtocol: AnyObject, Observable {
    func isEnabled(_ flag: FeatureFlag) -> Bool
    func setEnabled(_ flag: FeatureFlag, _ enabled: Bool)

    /// No-op for local backends; a remote provider fetches the latest flag values.
    /// Present from the start so adopting a remote backend won't break this protocol.
    func refresh() async
}
