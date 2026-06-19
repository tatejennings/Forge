import Foundation

extension UUID {
    /// Generates a deterministic UUID from a JSONPlaceholder integer ID.
    ///
    /// Uses a zero-padded format so the same integer always maps to the same UUID.
    /// This ensures SwiftData upserts work correctly across app launches.
    public init(remoteID: Int) {
        self = UUID(uuidString: "00000000-0000-0000-0000-\(String(format: "%012d", remoteID))")!
    }
}
