import Observation
import CoreModels

@Observable
public final class AppStateService: AppStateProtocol {
    public var settings: AppSettings
    public var activeFilter: TaskStatus
    public var incompletedTaskCount: Int
    public var isSyncing: Bool

    public init(settings: AppSettings = .default) {
        self.settings = settings
        self.activeFilter = .all
        self.incompletedTaskCount = 0
        self.isSyncing = false
    }
}
