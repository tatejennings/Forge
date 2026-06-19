import SwiftUI
import Forge
import CoreModels
import CoreInfrastructure
import FeatureTasks
import FeatureSettings

struct RootView: View {
    private let appState = InfrastructureContainer.shared.appState

    var body: some View {
        TabView {
            Tab("Tasks", systemImage: "checkmark.circle") {
                TaskListView()
            }
            .badge(appState.incompletedTaskCount > 0 ? appState.incompletedTaskCount : 0)

            Tab("Settings", systemImage: "gear") {
                SettingsView()
            }
        }
    }
}

#Preview {
    RootView()
}
