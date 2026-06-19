import SwiftUI
import CoreModels

public struct SettingsView: View {
    @State private var viewModel = SettingsContainer.shared.settingsViewModel

    public init() {}

    public var body: some View {
        NavigationStack {
            Form {
                Section("Profile") {
                    TextField("Your name", text: $viewModel.displayName)
                        .onChange(of: viewModel.displayName) { viewModel.saveSettings() }
                }
                Section("Preferences") {
                    Picker("Sort Order", selection: $viewModel.sortOrder) {
                        ForEach(SortOrder.allCases, id: \.self) { order in
                            Text(order.rawValue).tag(order)
                        }
                    }
                    .onChange(of: viewModel.sortOrder) { viewModel.saveSettings() }
                }
                Section {
                    Button("Clear Completed Tasks", role: .destructive) {
                        Task { await viewModel.clearCompleted() }
                    }
                    .disabled(viewModel.isClearingCompleted)
                }
            }
            .navigationTitle("Settings")
            .onAppear { viewModel.loadSettings() }
        }
    }
}

#Preview {
    SettingsView()
}
