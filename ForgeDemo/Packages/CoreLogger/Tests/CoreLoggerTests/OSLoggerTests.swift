import Testing
import CoreModels
@testable import CoreLogger

@Suite("OSLogger")
struct OSLoggerTests {

    @Test("constructs and logs every level without crashing")
    func logsAllLevels() {
        let logger = OSLogger(subsystem: "com.forge.tests", category: "Unit")
        logger.debug("debug message")
        logger.info("info message")
        logger.warning("warning message")
        logger.error("error message")
    }
}
