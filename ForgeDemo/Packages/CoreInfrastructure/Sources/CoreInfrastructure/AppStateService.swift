import Observation
import CoreModels

@Observable
public final class AppStateService: AppStateProtocol {
    public var settings: AppSettings {
        didSet { logger.debug("Settings changed: \(settings.displayName), sort: \(settings.preferredSortOrder.rawValue)") }
    }
    public var activeFilter: TaskStatus
    public var incompletedTaskCount: Int
    public var isSyncing: Bool

    @ObservationIgnored
    private let logger: any LoggerProtocol

    public init(settings: AppSettings = .default, logger: any LoggerProtocol) {
        self.settings = settings
        self.activeFilter = .all
        self.incompletedTaskCount = 0
        self.isSyncing = false
        self.logger = logger
        logger.info("AppState initialized for \(settings.displayName)")
    }
}
