import SwiftUI
import FeatureTasks
import FeatureSettings

@main
struct ForgeDemoApp: App {

    init() {
        wireContainers()
    }

    var body: some Scene {
        WindowGroup {
            RootView()
        }
    }
}

// MARK: - Container Wiring (Composition Root)

private func wireContainers() {
    assert(Thread.isMainThread, "wireContainers must be called from the main thread")
    let core = CoreContainer.shared

    // Wire TaskContainer with live dependencies from CoreContainer
    TaskContainer.shared.override("taskService") { core.taskService }
    TaskContainer.shared.override("appState") { core.appState }

    // Wire SettingsContainer with live dependencies from CoreContainer
    SettingsContainer.shared.override("taskService") { core.taskService }
    SettingsContainer.shared.override("appState") { core.appState }

}
