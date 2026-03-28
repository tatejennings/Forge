import SwiftUI
import CoreModels
import FeatureTasks
import FeatureSettings

struct RootView: View {
    private let appState = CoreContainer.shared.appState

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
