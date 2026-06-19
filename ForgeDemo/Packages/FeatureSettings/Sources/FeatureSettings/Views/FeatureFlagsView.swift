import SwiftUI
import CoreModels
import DesignSystem

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
                        VStack(alignment: .leading, spacing: DSSpacing.xs / 2) {
                            Text(flag.title)
                                .font(.dsBody)
                                .foregroundStyle(Color.dsInk)
                            Text(flag.summary)
                                .font(.dsFootnote)
                                .foregroundStyle(Color.dsInk2)
                        }
                    }
                }
            } footer: {
                Text("Flags are stored locally. Swap the FeatureFlagContainer backend to drive them from a remote service like LaunchDarkly.")
                    .font(.dsFootnote)
                    .foregroundStyle(Color.dsInk2)
            }
            .listRowBackground(Color.dsCard)
        }
        .scrollContentBackground(.hidden)
        .background(Color.dsBackground.ignoresSafeArea())
        .navigationTitle("Feature Flags")
        .tint(.dsAccent)
    }
}

#Preview {
    NavigationStack {
        FeatureFlagsView()
    }
}
