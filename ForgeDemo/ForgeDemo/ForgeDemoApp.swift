import SwiftUI
import Forge

@main
struct ForgeDemoApp: App {

    init() {
        AppContainer.wireContainers()
    }

    var body: some Scene {
        WindowGroup {
            RootView()
        }
    }
}
