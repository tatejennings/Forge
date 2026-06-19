import SwiftUI
import CoreModels
import DesignSystem

public struct SettingsView: View {
    @State private var viewModel = SettingsContainer.shared.settingsViewModel

    public init() {}

    public var body: some View {
        NavigationStack {
            Form {
                Section("Profile") {
                    TextField("Your name", text: $viewModel.displayName)
                        .font(.dsBody)
                        .foregroundStyle(Color.dsInk)
                        .onChange(of: viewModel.displayName) { viewModel.saveSettings() }
                }
                .listRowBackground(Color.dsCard)

                Section("Preferences") {
                    Picker("Sort Order", selection: $viewModel.sortOrder) {
                        ForEach(SortOrder.allCases, id: \.self) { order in
                            Text(order.rawValue).tag(order)
                        }
                    }
                    .onChange(of: viewModel.sortOrder) { viewModel.saveSettings() }
                }
                .listRowBackground(Color.dsCard)

                Section("Advanced") {
                    NavigationLink {
                        FeatureFlagsView()
                    } label: {
                        Label("Feature Flags", systemImage: "flag")
                    }
                }
                .listRowBackground(Color.dsCard)

                Section {
                    Button("Clear Completed Tasks", role: .destructive) {
                        Task { await viewModel.clearCompleted() }
                    }
                    .foregroundStyle(Color.dsDanger)
                    .disabled(viewModel.isClearingCompleted)
                }
                .listRowBackground(Color.dsCard)
            }
            .scrollContentBackground(.hidden)
            .background(Color.dsBackground.ignoresSafeArea())
            .navigationTitle("Settings")
            .onAppear { viewModel.loadSettings() }
        }
        .tint(.dsAccent)
    }
}

#Preview {
    SettingsView()
}
