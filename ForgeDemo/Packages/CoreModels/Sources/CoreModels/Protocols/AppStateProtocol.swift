import Observation

public protocol AppStateProtocol: AnyObject, Observable {
    var settings: AppSettings { get set }
    var activeFilter: TaskStatus { get set }
    var incompletedTaskCount: Int { get set }
    var isSyncing: Bool { get set }
}
