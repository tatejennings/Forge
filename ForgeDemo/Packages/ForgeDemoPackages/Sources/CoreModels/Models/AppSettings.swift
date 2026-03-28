public struct AppSettings: Equatable, Sendable {
    public var displayName: String
    public var preferredSortOrder: SortOrder

    public init(displayName: String, preferredSortOrder: SortOrder) {
        self.displayName = displayName
        self.preferredSortOrder = preferredSortOrder
    }

    public static let `default` = AppSettings(
        displayName: "Friend",
        preferredSortOrder: .newestFirst
    )
}
