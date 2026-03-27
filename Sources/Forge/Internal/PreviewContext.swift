import Foundation

/// Detects whether the current process is running inside an Xcode preview.
enum PreviewContext {

    /// Internal override for testing preview behavior without requiring an actual
    /// Xcode Preview environment. Set to `true` or `false` in tests; leave `nil`
    /// for production behavior.
    nonisolated(unsafe) static var _isPreviewOverride: Bool?

    /// Returns `true` when running inside an Xcode preview.
    static var isPreview: Bool {
        if let override = _isPreviewOverride {
            return override
        }
        return ProcessInfo.processInfo.environment["XCODE_RUNNING_FOR_PREVIEWS"] == "1"
    }
}
