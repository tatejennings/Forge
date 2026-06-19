// Per-module Forge container (Modular path). The local `Inject` typealias resolves
// from this container; cross-module dependencies are declared as `unimplemented()`
// proxies and wired by the app target's composition root (see ForgeDemo's
// AppContainer+DI.swift). A Simple app would not have this file.

import Forge
import CoreModels

typealias Inject<T> = ContainerInject<SettingsContainer, T>

public final class SettingsContainer: Container, SharedContainer, @unchecked Sendable {
    nonisolated(unsafe) public static var shared = SettingsContainer()

    /// Override this with a real implementation from the app target's AppContainer.
    public var appState: any AppStateProtocol {
        provide(.singleton) {
            unimplemented("appState")
        } preview: {
            MockAppState()
        }
    }

    /// Override this with a real implementation from the app target's AppContainer.
    public var taskService: any TaskServiceProtocol {
        provide(.singleton) {
            unimplemented("taskService")
        } preview: {
            MockTaskService()
        }
    }

    public var settingsViewModel: SettingsViewModel {
        provide(.cached) { SettingsViewModel() }
    }
}
