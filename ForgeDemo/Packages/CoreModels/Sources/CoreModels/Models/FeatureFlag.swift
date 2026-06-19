/// The catalog of feature flags. This enum is the single source of truth — adding a
/// case automatically surfaces a new toggle in the Settings → Feature Flags screen and a
/// new key in whatever `FeatureFlagServiceProtocol` backend is wired in.
public enum FeatureFlag: String, CaseIterable, Sendable {
    case confirmBeforeDelete
    case showNotesInList
    case pullToRefresh

    /// Title shown for the flag's toggle.
    public var title: String {
        switch self {
        case .confirmBeforeDelete: return "Confirm Before Delete"
        case .showNotesInList:     return "Show Notes in List"
        case .pullToRefresh:       return "Pull to Refresh"
        }
    }

    /// Caption explaining what the flag does, shown beneath the toggle.
    public var summary: String {
        switch self {
        case .confirmBeforeDelete: return "Ask for confirmation before deleting a task."
        case .showNotesInList:     return "Display each task's notes beneath its title in the list."
        case .pullToRefresh:       return "Enable the pull-to-refresh gesture to sync tasks."
        }
    }

    /// Value used when the backend has no stored value for this flag.
    public var defaultValue: Bool {
        switch self {
        case .confirmBeforeDelete: return false
        case .showNotesInList:     return true
        case .pullToRefresh:       return true
        }
    }
}
