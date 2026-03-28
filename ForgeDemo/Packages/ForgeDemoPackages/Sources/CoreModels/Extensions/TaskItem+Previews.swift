#if DEBUG
extension TaskItem {
    public static let previews: [TaskItem] = [
        TaskItem(title: "Review pull request", notes: "Feature branch for auth flow"),
        TaskItem(title: "Buy groceries", notes: "Milk, eggs, coffee", isCompleted: true),
        TaskItem(title: "Call the dentist", notes: ""),
        TaskItem(title: "Read WWDC session notes", notes: "Focus on Swift concurrency updates"),
    ]
}
#endif
