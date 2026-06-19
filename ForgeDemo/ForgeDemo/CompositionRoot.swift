//
//  CompositionRoot.swift
//
//  The app target's composition root for this MODULAR Forge app. Its only job is to
//  wire each feature module's `unimplemented()` proxies to the real implementations
//  owned by the Core module containers — called once from `ForgeDemoApp.init()`.
//
//  Note what is NOT here: this app target registers no dependencies of its own.
//  Every concrete service lives in the module that owns it (CoreNetworking's
//  `NetworkingContainer`, CoreInfrastructure's `InfrastructureContainer`), so this
//  file never extends `AppContainer`. In a Modular app `AppContainer` is optional —
//  add it only if the app target itself owns dependencies (see the placeholder below).
//

import Forge
import CoreInfrastructure
import CoreLogger
import FeatureFlags
import FeatureTasks
import FeatureSettings

// MARK: - Target-level services (none in this demo)
//
// If the app target itself owns dependencies that live in no feature module
// (an app-level coordinator, a root view model), register them on AppContainer here
// and inject them with the framework's built-in `@Inject(\.x)`:
//
//   extension AppContainer {
//       var someAppService: any SomeProtocol {
//           provide(.singleton) { SomeService() }
//       }
//   }

// MARK: - Composition root — wire feature proxies once, at launch

func wireContainers() {
    let infra = InfrastructureContainer.shared

    // Resolve the real services once, then hand the instances to the @Sendable
    // override closures.
    let taskService = infra.taskService
    let appState = infra.appState
    let logger = LoggerContainer.shared.logger
    let flagService = FeatureFlagContainer.shared.flagService

    // Point each feature container's `unimplemented()` proxy at the real service.
    TaskContainer.shared.override(\.taskService) { taskService }
    TaskContainer.shared.override(\.appState)    { appState }
    TaskContainer.shared.override(\.logger)      { logger }
    TaskContainer.shared.override(\.flagService) { flagService }

    SettingsContainer.shared.override(\.taskService) { taskService }
    SettingsContainer.shared.override(\.appState)    { appState }
    SettingsContainer.shared.override(\.logger)      { logger }
    SettingsContainer.shared.override(\.flagService) { flagService }
}
