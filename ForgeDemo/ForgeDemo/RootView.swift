import SwiftUI
import Forge
import CoreModels
import CoreInfrastructure
import DesignSystem
import FeatureTasks
import FeatureSettings

struct RootView: View {
    private let appState = InfrastructureContainer.shared.appState

    var body: some View {
        TabView {
            Tab("Tasks", systemImage: "checklist") {
                TaskListView()
            }
            .badge(appState.incompletedTaskCount > 0 ? appState.incompletedTaskCount : 0)

            Tab("Settings", systemImage: "gearshape") {
                SettingsView()
            }
        }
        // Accent means state/action only — here, the active tab.
        .tint(.dsAccent)
    }
}

#Preview {
    RootView()
}
