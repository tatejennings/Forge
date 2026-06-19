import Forge
import CoreModels

// Per-module Forge container (Modular path). FeatureFlags is a provider module: it owns
// the flag-service implementation and exposes it for the composition root to wire into the
// feature modules. No local `Inject` typealias — it injects nothing from itself.
public final class FeatureFlagContainer: Container, SharedContainer, @unchecked Sendable {
    nonisolated(unsafe) public static var shared = FeatureFlagContainer()

    /// The app's feature-flag source.
    ///
    /// The demo ships a local `UserDefaults` backend. To move to a remote provider
    /// (e.g. LaunchDarkly), you change ONLY this one factory — no view, view model, or
    /// other module changes, because everything depends on `FeatureFlagServiceProtocol`,
    /// not the concrete type:
    ///
    ///     public var flagService: any FeatureFlagServiceProtocol {
    ///         provide(.singleton) {
    ///             LaunchDarklyFeatureFlagService(mobileKey: "<your-mobile-key>")
    ///         } preview: {
    ///             MockFeatureFlagService()
    ///         }
    ///     }
    ///
    /// See `LaunchDarklyFeatureFlagService.swift.example` for a reference adapter.
    public var flagService: any FeatureFlagServiceProtocol {
        provide(.singleton) {
            UserDefaultsFeatureFlagService()
        } preview: {
            MockFeatureFlagService()
        }
    }
}
