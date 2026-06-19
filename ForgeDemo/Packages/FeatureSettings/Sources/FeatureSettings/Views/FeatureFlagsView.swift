import SwiftUI
import CoreModels

/// The Feature Flags subsection of Settings — a toggle per `FeatureFlag`. Reached via a
/// `NavigationLink` from `SettingsView`.
public struct FeatureFlagsView: View {
    @State private var viewModel = SettingsContainer.shared.featureFlagsViewModel

    public init() {}

    public var body: some View {
        Form {
            Section {
                ForEach(viewModel.flags, id: \.self) { flag in
                    Toggle(isOn: Binding(
                        get: { viewModel.isOn(flag) },
                        set: { viewModel.setOn(flag, $0) }
                    )) {
                        VStack(alignment: .leading, spacing: 2) {
                            Text(flag.title)
                            Text(flag.summary)
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }
                }
            } footer: {
                Text("Flags are stored locally. Swap the FeatureFlagContainer backend to drive them from a remote service like LaunchDarkly.")
            }
        }
        .navigationTitle("Feature Flags")
    }
}

#Preview {
    NavigationStack {
        FeatureFlagsView()
    }
}
