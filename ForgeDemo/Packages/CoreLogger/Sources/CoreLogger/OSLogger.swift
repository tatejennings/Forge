import Foundation
import OSLog
import CoreModels

/// `LoggerProtocol` backed by Apple's unified logging system (`os.Logger`). Messages show
/// up in Console.app and the Xcode debug console, filterable by `subsystem`/`category`.
public final class OSLogger: LoggerProtocol {
    private let logger: Logger

    public init(
        subsystem: String = Bundle.main.bundleIdentifier ?? "com.forge.ForgeDemo",
        category: String = "App"
    ) {
        self.logger = Logger(subsystem: subsystem, category: category)
    }

    public func log(_ level: LogLevel, _ message: String) {
        // Map our level onto an OSLogType. `.info`/`.debug` are not persisted by default;
        // `.warning` uses `.error` and `.error` uses `.fault` so they survive to Console.
        switch level {
        case .debug:   logger.debug("\(message, privacy: .public)")
        case .info:    logger.info("\(message, privacy: .public)")
        case .warning: logger.error("\(message, privacy: .public)")
        case .error:   logger.fault("\(message, privacy: .public)")
        }
    }
}
