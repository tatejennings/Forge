//
//  AppContainer+DI.swift
//
//  MODULAR composition root.
//
//  ForgeDemo is a multi-module SPM app using Forge's *Modular* path. This file is
//  the app target's composition root: it registers the app's live implementations
//  on `AppContainer`, then `wireContainers()` injects them into the per-module
//  feature containers (`TaskContainer`, `SettingsContainer`) that declare those
//  dependencies as `unimplemented()` proxies.
//
//  This `AppContainer` extension looks like Forge's Simple path, but it is NOT —
//  the `wireContainers()` step and the per-module containers it wires are what make
//  this Modular. A Simple (single-target) app would have no feature containers, no
//  `unimplemented()` proxies, and no `wireContainers()`. See ForgeDemo/README.md.
//

import Forge
import CoreModels
import CoreNetworking
import CoreInfrastructure
import FeatureTasks
import FeatureSettings

// MARK: - App Dependencies

extension AppContainer {

    // MARK: Networking

    var httpClient: any HTTPClientProtocol {
        provide(.singleton) {
            URLSessionHTTPClient()
        } preview: {
            MockHTTPClient()
        }
    }

    var remoteTaskService: any RemoteTaskServiceProtocol {
        provide(.singleton) {
            RemoteTaskService(httpClient: self.httpClient)
        } preview: {
            MockRemoteTaskService()
        }
    }

    // MARK: Persistence

    var swiftDataStack: SwiftDataStack {
        provide(.singleton) {
            (try? SwiftDataStack()) ?? { fatalError("SwiftData failed to initialize") }()
        }
    }

    var taskRepository: any TaskRepositoryProtocol {
        provide(.singleton) { TaskRepository(stack: self.swiftDataStack) }
    }

    // MARK: Services

    var taskService: any TaskServiceProtocol {
        provide(.singleton) {
            TaskService(
                repository: self.taskRepository,
                remoteService: self.remoteTaskService
            )
        } preview: {
            MockTaskService()
        }
    }

    var appState: any AppStateProtocol {
        provide(.singleton) {
            AppStateService()
        } preview: {
            MockAppState(displayName: "Preview User")
        }
    }

    // MARK: Composition Root

    static func wireContainers() {
        let app = AppContainer.shared

        // Resolve once eagerly, then hand the instances to the @Sendable closures
        let taskService = app.taskService
        let appState = app.appState

        // Wire TaskContainer with live dependencies from AppContainer
        TaskContainer.shared.override(\.taskService) { taskService }
        TaskContainer.shared.override(\.appState) { appState }

        // Wire SettingsContainer with live dependencies from AppContainer
        SettingsContainer.shared.override(\.taskService) { taskService }
        SettingsContainer.shared.override(\.appState) { appState }
    }
}
