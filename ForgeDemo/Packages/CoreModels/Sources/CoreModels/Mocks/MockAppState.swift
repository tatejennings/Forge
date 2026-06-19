#if DEBUG
import Observation

@Observable
public final class MockAppState: AppStateProtocol, @unchecked Sendable {
    public var settings: AppSettings
    public var activeFilter: TaskStatus
    public var incompletedTaskCount: Int
    public var isSyncing: Bool

    public init(
        displayName: String = "Preview User",
        filter: TaskStatus = .all,
        count: Int = 3,
        isSyncing: Bool = false
    ) {
        self.settings = AppSettings(displayName: displayName, preferredSortOrder: .newestFirst)
        self.activeFilter = filter
        self.incompletedTaskCount = count
        self.isSyncing = isSyncing
    }
}
#endif
