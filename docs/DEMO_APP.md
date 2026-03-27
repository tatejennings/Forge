# Forge Demo App — Technical Specification

> **App name:** `ForgeDemo`
> A minimal daily task tracker. Simple enough to read in one sitting, complete enough to demonstrate every Forge feature in a realistic context.

---

## 1. Purpose

ForgeDemo exists for one reason: to show what Forge looks like in a real, well-structured iOS app. Every architectural decision in this app is made to demonstrate a Forge feature or a SOLID principle. Nothing is added for its own sake.

A developer reading this codebase should come away understanding:
- How to structure a modular SPM app with Forge
- How each Forge scope (`transient`, `singleton`, `cached`) is applied appropriately
- How preview factories eliminate the need for conditional compilation in views
- How `withOverrides` and `unimplemented` make tests clean and explicit
- How SOLID principles map to real Swift + SwiftUI code

---

## 2. App Concept

ForgeDemo lets users track daily tasks. Tasks can be created, completed, and deleted. The app remembers the user's display name and preferred sort order. A summary badge on the tab bar shows how many tasks remain today.

This is intentionally simple. The complexity lives in the architecture, not the product.

### User-Facing Features

- View a list of today's tasks, filterable by status (all / active / completed)
- Add a new task with a title and optional notes
- Mark a task complete (with satisfying visual feedback)
- Delete a task by swiping
- View a task detail screen
- Settings screen: display name, sort preference, clear completed tasks
- Tab bar badge showing incomplete task count

---

## 3. Forge Feature Coverage Map

Every Forge feature must be demonstrated at least once. This table is the acceptance criteria for the demo app.

| Forge Feature | Demonstrated By |
|---|---|
| `provide(.transient)` | `AddTaskViewModel` — fresh instance every sheet presentation |
| `provide(.singleton)` | `AppStateService`, `SwiftDataStack`, `HTTPClient` — live for app lifetime |
| `provide(.cached)` | `TaskListViewModel` — persists across tab switches, resettable on "clear completed" |
| `preview:` factory | All containers — every dependency that touches network, disk, or state has a mock preview factory |
| `withOverrides` (sync) | `SettingsViewModelTests` |
| `withOverrides` (async) | `TaskListViewModelTests`, `AddTaskViewModelTests`, `RemoteTaskServiceTests` |
| `unimplemented` | `TestTaskContainer`, `TestSettingsContainer` — base test containers with traps |
| Cross-module proxy | `TaskContainer` proxies `taskService` and `appState` from `CoreContainer` |
| Module-local typealias | `FeatureTasks/DI.swift`, `FeatureSettings/DI.swift` |
| Container swap | All test `setUp`/`tearDown` |
| `@Inject` property wrapper | All ViewModels |
| Inline resolution | `ForgeDemoApp.swift` entry point startup |
| `SharedContainer` | `TaskContainer`, `SettingsContainer`, `CoreContainer` |

---

## 4. Module Architecture

### 4.1 Module Graph

```
ForgeDemoApp (app target)
├── imports: FeatureTasks, FeatureSettings, CoreModels, CoreInfrastructure, CoreNetworking
└── CoreContainer — wires all module containers at startup

FeatureTasks (SPM module)
├── imports: CoreModels, Forge
├── TaskContainer + DI.swift
└── Views + ViewModels for task list, detail, add sheet

FeatureSettings (SPM module)
├── imports: CoreModels, Forge
├── SettingsContainer + DI.swift
└── Views + ViewModels for settings

CoreInfrastructure (SPM module)
├── imports: CoreModels, CoreNetworking (NO Forge import)
├── SwiftDataStack
├── TaskRepository (implements TaskRepositoryProtocol)
├── TaskService (implements TaskServiceProtocol) ← orchestrates remote + local
└── AppStateService (implements AppStateProtocol)

CoreNetworking (SPM module)
├── imports: CoreModels (NO Forge import)
├── HTTPClientProtocol + URLSessionHTTPClient
├── TodoDTO (JSONPlaceholder wire format)
├── RemoteTaskServiceProtocol
└── RemoteTaskService (implements RemoteTaskServiceProtocol)

CoreModels (SPM module)
├── NO Forge import
├── Models: Task, TaskStatus, SortOrder, AppSettings
└── Protocols: TaskServiceProtocol, TaskRepositoryProtocol,
              AppStateProtocol, RemoteTaskServiceProtocol, HTTPClientProtocol
```

**Dependency direction:** Feature modules never import infrastructure or networking. `CoreInfrastructure` depends on `CoreNetworking` to hand `RemoteTaskService` to `TaskService`. The app target (`CoreContainer`) is the only composition root that wires everything together.

**Why protocols for `HTTPClient` and `RemoteTaskService` live in `CoreModels`:** Feature modules never touch these protocols directly, but `CoreModels` is the shared protocol home for the entire graph. Keeping them there means `CoreInfrastructure` can depend on them without creating a circular dependency with `CoreNetworking`.

### 4.2 Package.swift Structure

```swift
// ForgeDemo/Packages/MomentumPackages/Package.swift
let package = Package(
    name: "MomentumPackages",
    platforms: [.iOS(.v17)],
    products: [
        .library(name: "CoreModels", targets: ["CoreModels"]),
        .library(name: "CoreNetworking", targets: ["CoreNetworking"]),
        .library(name: "CoreInfrastructure", targets: ["CoreInfrastructure"]),
        .library(name: "FeatureTasks", targets: ["FeatureTasks"]),
        .library(name: "FeatureSettings", targets: ["FeatureSettings"]),
    ],
    dependencies: [
        .package(path: "../../")  // two levels up to Forge's Package.swift at repo root
    ],
    targets: [
        .target(name: "CoreModels", dependencies: []),
        .target(name: "CoreNetworking", dependencies: ["CoreModels"]),
        .target(name: "CoreInfrastructure", dependencies: ["CoreModels", "CoreNetworking"]),
        .target(name: "FeatureTasks", dependencies: ["CoreModels", .product(name: "Forge", package: "Forge")]),
        .target(name: "FeatureSettings", dependencies: ["CoreModels", .product(name: "Forge", package: "Forge")]),
        .testTarget(name: "CoreNetworkingTests", dependencies: ["CoreNetworking", "CoreModels"]),
        .testTarget(name: "FeatureTasksTests", dependencies: ["FeatureTasks", "CoreModels"]),
        .testTarget(name: "FeatureSettingsTests", dependencies: ["FeatureSettings", "CoreModels"]),
    ]
)
```

---

## 5. Data Model (`CoreModels`)

```swift
// Task.swift
public struct Task: Identifiable, Equatable, Sendable {
    public let id: UUID
    public var title: String
    public var notes: String
    public var isCompleted: Bool
    public var createdAt: Date
    public var completedAt: Date?

    public init(
        id: UUID = UUID(),
        title: String,
        notes: String = "",
        isCompleted: Bool = false,
        createdAt: Date = Date()
    )
}

// TaskStatus.swift
public enum TaskStatus: String, CaseIterable, Sendable {
    case all
    case active
    case completed
}

// SortOrder.swift
public enum SortOrder: String, CaseIterable, Sendable {
    case newestFirst
    case oldestFirst
    case alphabetical
}

// AppSettings.swift
public struct AppSettings: Equatable, Sendable {
    public var displayName: String
    public var preferredSortOrder: SortOrder

    public static let `default` = AppSettings(
        displayName: "Friend",
        preferredSortOrder: .newestFirst
    )
}
```

### Protocols

```swift
// TaskRepositoryProtocol.swift
public protocol TaskRepositoryProtocol: Sendable {
    func fetchAll() async throws -> [Task]
    func save(_ task: Task) async throws
    func update(_ task: Task) async throws
    func delete(id: UUID) async throws
    func upsertAll(_ tasks: [Task]) async throws  // batch upsert for remote sync
}

// TaskServiceProtocol.swift
public protocol TaskServiceProtocol: Sendable {
    func loadTasks() async throws -> [Task]           // fetch remote → upsert local → return local
    func refreshTasks() async throws -> [Task]        // explicit pull-to-refresh, same flow
    func addTask(title: String, notes: String) async throws -> Task
    func completeTask(id: UUID) async throws -> Task
    func deleteTask(id: UUID) async throws
}

// RemoteTaskServiceProtocol.swift
public protocol RemoteTaskServiceProtocol: Sendable {
    func fetchTodos() async throws -> [Task]          // maps DTOs → domain Task values
}

// HTTPClientProtocol.swift
public protocol HTTPClientProtocol: Sendable {
    func get<T: Decodable>(_ url: URL) async throws -> T
}

// AppStateProtocol.swift
// Observable — drives reactive UI updates
public protocol AppStateProtocol: AnyObject, Observable {
    var settings: AppSettings { get set }
    var activeFilter: TaskStatus { get set }
    var incompletedTaskCount: Int { get set }
    var isSyncing: Bool { get set }                   // true while remote fetch is in progress
}
```

---

## 6. Networking Layer (`CoreNetworking`)

`CoreNetworking` has no knowledge of SwiftData, containers, or Forge. It is a pure networking module: it knows how to make HTTP requests and map JSON to domain models.

### `HTTPClientProtocol` + `URLSessionHTTPClient`

```swift
// URLSessionHTTPClient.swift
public final class URLSessionHTTPClient: HTTPClientProtocol {
    private let session: URLSession

    public init(session: URLSession = .shared) {
        self.session = session
    }

    public func get<T: Decodable>(_ url: URL) async throws -> T {
        let (data, response) = try await session.data(from: url)
        guard let http = response as? HTTPURLResponse else {
            throw NetworkError.invalidResponse
        }
        guard (200...299).contains(http.statusCode) else {
            throw NetworkError.httpError(statusCode: http.statusCode)
        }
        do {
            return try JSONDecoder().decode(T.self, from: data)
        } catch {
            throw NetworkError.decodingFailed(error)
        }
    }
}

public enum NetworkError: Error, LocalizedError {
    case invalidResponse
    case httpError(statusCode: Int)
    case decodingFailed(Error)

    public var errorDescription: String? {
        switch self {
        case .invalidResponse:
            return "The server returned an invalid response."
        case .httpError(let code):
            return "Server error with status code \(code)."
        case .decodingFailed:
            return "Failed to decode server response."
        }
    }
}
```

### `TodoDTO`

The wire format from JSONPlaceholder. Deliberately separate from the domain `Task` — the DTO knows about JSON, the domain model knows nothing about the network.

```swift
// TodoDTO.swift
public struct TodoDTO: Decodable, Sendable {
    public let id: Int
    public let title: String
    public let completed: Bool
    // userId is present in the API response but intentionally ignored

    /// Maps the wire format to a domain Task.
    /// JSONPlaceholder uses integer IDs — these are converted to deterministic UUIDs
    /// using UUID(uuidString:) with a fixed namespace so the same remote ID always
    /// produces the same local UUID across app launches.
    public func toDomain() -> Task {
        Task(
            id: UUID(remoteID: id),
            title: title,
            isCompleted: completed
        )
    }
}

// UUID+RemoteID.swift
extension UUID {
    /// Generates a deterministic UUID from a JSONPlaceholder integer ID.
    /// Uses a fixed UUID v5-style namespace string so the same integer
    /// always maps to the same UUID. This ensures SwiftData upserts work
    /// correctly across app launches — no duplicate records.
    init(remoteID: Int) {
        let namespace = "6BA7B810-9DAD-11D1-80B4-00C04FD430C8"
        let combined = "\(namespace)-\(remoteID)"
        // Implementation: hash the combined string into UUID bytes
        // Full implementation left to Claude Code — determinism is the requirement
        self = UUID(uuidString: "00000000-0000-0000-0000-\(String(format: "%012d", remoteID))")!
    }
}
```

### `RemoteTaskService`

```swift
// RemoteTaskService.swift
public final class RemoteTaskService: RemoteTaskServiceProtocol {
    private let httpClient: any HTTPClientProtocol
    private let baseURL = URL(string: "https://jsonplaceholder.typicode.com")!

    public init(httpClient: any HTTPClientProtocol) {
        self.httpClient = httpClient
    }

    public func fetchTodos() async throws -> [Task] {
        let dtos: [TodoDTO] = try await httpClient.get(baseURL.appending(path: "todos"))
        return dtos.map { $0.toDomain() }
    }
}
```

---

## 7. Infrastructure Layer (`CoreInfrastructure`)

`CoreInfrastructure` has no knowledge of Forge or containers. It depends on `CoreModels` for protocols and `CoreNetworking` for `RemoteTaskService`.

### SwiftData Stack

```swift
// SwiftDataStack.swift
// Persisted task model (SwiftData requires a class)
@Model
final class TaskRecord {
    var id: UUID
    var title: String
    var notes: String
    var isCompleted: Bool
    var createdAt: Date
    var completedAt: Date?
    // init...
}

public final class SwiftDataStack: Sendable {
    public let container: ModelContainer

    public init() throws {
        let schema = Schema([TaskRecord.self])
        let config = ModelConfiguration(schema: schema, isStoredInMemoryOnly: false)
        self.container = try ModelContainer(for: schema, configurations: config)
    }

    /// In-memory variant used for previews and tests — no file I/O
    public static func inMemory() throws -> SwiftDataStack {
        // Override ModelConfiguration with isStoredInMemoryOnly: true
    }
}
```

### TaskRepository

```swift
// TaskRepository.swift
public final class TaskRepository: TaskRepositoryProtocol {
    private let stack: SwiftDataStack

    public init(stack: SwiftDataStack) { self.stack = stack }

    public func fetchAll() async throws -> [Task] { ... }
    public func save(_ task: Task) async throws { ... }
    public func update(_ task: Task) async throws { ... }
    public func delete(id: UUID) async throws { ... }

    /// Upsert semantics: insert if not present, update if exists (matched by Task.id)
    public func upsertAll(_ tasks: [Task]) async throws { ... }
}
```

### TaskService

`TaskService` is the orchestrator. It coordinates the remote service and local repository, implementing the "remote primary, local cache" strategy. Business logic (validation, error handling) lives here — not in ViewModels.

```swift
// TaskService.swift
public final class TaskService: TaskServiceProtocol {
    private let repository: any TaskRepositoryProtocol
    private let remoteService: any RemoteTaskServiceProtocol

    public init(
        repository: any TaskRepositoryProtocol,
        remoteService: any RemoteTaskServiceProtocol
    ) {
        self.repository = repository
        self.remoteService = remoteService
    }

    /// Primary load: fetch remote → upsert into local → return from local.
    /// If remote fetch fails (offline), falls back to whatever is in local storage.
    public func loadTasks() async throws -> [Task] {
        do {
            let remoteTasks = try await remoteService.fetchTodos()
            try await repository.upsertAll(remoteTasks)
        } catch {
            // Remote unavailable — silently fall back to local
            // Only rethrow if local is also empty (true first-launch offline failure)
        }
        return try await repository.fetchAll()
    }

    /// Explicit refresh — same as loadTasks() but always attempts remote first.
    /// Called on pull-to-refresh. Returns updated local data.
    public func refreshTasks() async throws -> [Task] {
        let remoteTasks = try await remoteService.fetchTodos()  // throws on failure (no silent fallback)
        try await repository.upsertAll(remoteTasks)
        return try await repository.fetchAll()
    }

    /// Local-only write — JSONPlaceholder fakes POST responses but nothing persists server-side
    public func addTask(title: String, notes: String) async throws -> Task {
        guard !title.trimmingCharacters(in: .whitespaces).isEmpty else {
            throw TaskError.emptyTitle
        }
        let task = Task(title: title.trimmingCharacters(in: .whitespaces), notes: notes)
        try await repository.save(task)
        return task
    }

    /// Local-only write
    public func completeTask(id: UUID) async throws -> Task {
        var tasks = try await repository.fetchAll()
        guard let index = tasks.firstIndex(where: { $0.id == id }) else {
            throw TaskError.notFound
        }
        tasks[index].isCompleted = true
        tasks[index].completedAt = Date()
        try await repository.update(tasks[index])
        return tasks[index]
    }

    /// Local-only write
    public func deleteTask(id: UUID) async throws {
        try await repository.delete(id: id)
    }
}

public enum TaskError: Error, LocalizedError {
    case emptyTitle
    case notFound

    public var errorDescription: String? {
        switch self {
        case .emptyTitle: return "Task title cannot be empty."
        case .notFound: return "Task not found."
        }
    }
}
```

### AppStateService

```swift
// AppStateService.swift
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
```

---

## 8. Containers

### 8.1 `CoreContainer` (app target)

Owned by the app target. The only place that imports both infrastructure and networking modules. Wires the full dependency graph.

```swift
// ForgeDemo/CoreContainer.swift
import Forge
import CoreModels
import CoreNetworking
import CoreInfrastructure

public final class CoreContainer: Container, SharedContainer {
    public static var shared = CoreContainer()

    // MARK: - Networking

    public var httpClient: any HTTPClientProtocol {
        provide(.singleton,
                preview: { MockHTTPClient() }
        ) {
            URLSessionHTTPClient()
        }
    }

    public var remoteTaskService: any RemoteTaskServiceProtocol {
        provide(.singleton,
                preview: { MockRemoteTaskService() }
        ) {
            RemoteTaskService(httpClient: self.httpClient)
        }
    }

    // MARK: - Persistence

    public var swiftDataStack: SwiftDataStack {
        provide(.singleton) {
            (try? SwiftDataStack()) ?? { fatalError("SwiftData failed to initialize") }()
        }
    }

    public var taskRepository: any TaskRepositoryProtocol {
        provide(.singleton) { TaskRepository(stack: self.swiftDataStack) }
    }

    // MARK: - Services

    public var taskService: any TaskServiceProtocol {
        provide(.singleton,
                preview: { MockTaskService() }
        ) {
            TaskService(
                repository: self.taskRepository,
                remoteService: self.remoteTaskService
            )
        }
    }

    public var appState: any AppStateProtocol {
        provide(.singleton,
                preview: { MockAppState(displayName: "Preview User") }
        ) {
            AppStateService()
        }
    }
}
```

### 8.2 `TaskContainer` (`FeatureTasks` module)

```swift
// FeatureTasks/Sources/TaskContainer.swift
import Forge
import CoreModels

public final class TaskContainer: Container, SharedContainer {
    public static var shared = TaskContainer()

    // MARK: - Cross-module proxies (sourced from CoreContainer at app level)
    // These are set by the app target at startup — see Section 8.

    public var taskService: any TaskServiceProtocol {
        provide(.singleton,
                preview: { MockTaskService() }
        ) {
            // Fallback — should be overridden by AppContainer at startup.
            // The unimplemented trap makes accidental use loud.
            unimplemented("taskService — did you forget to wire TaskContainer in AppContainer?")
        }
    }

    public var appState: any AppStateProtocol {
        provide(.singleton,
                preview: { MockAppState() }
        ) {
            unimplemented("appState — did you forget to wire TaskContainer in AppContainer?")
        }
    }

    // MARK: - Feature-owned dependencies

    // .cached — TaskListViewModel persists across tab switches.
    // resetCached() is called when the user clears completed tasks.
    public var taskListViewModel: TaskListViewModel {
        provide(.cached,
                preview: { TaskListViewModel() }
        ) {
            TaskListViewModel()
        }
    }

    // .transient — fresh ViewModel every time the Add sheet opens
    public var addTaskViewModel: AddTaskViewModel {
        provide { AddTaskViewModel() }
    }
}
```

**`DI.swift`:**

```swift
// FeatureTasks/Sources/DI.swift
import Forge
typealias Inject<T> = ContainerInject<TaskContainer, T>
```

### 8.3 `SettingsContainer` (`FeatureSettings` module)

```swift
// FeatureSettings/Sources/SettingsContainer.swift
import Forge
import CoreModels

public final class SettingsContainer: Container, SharedContainer {
    public static var shared = SettingsContainer()

    public var appState: any AppStateProtocol {
        provide(.singleton,
                preview: { MockAppState() }
        ) {
            unimplemented("appState — did you forget to wire SettingsContainer in AppContainer?")
        }
    }

    public var taskService: any TaskServiceProtocol {
        provide(.singleton,
                preview: { MockTaskService() }
        ) {
            unimplemented("taskService — did you forget to wire SettingsContainer in AppContainer?")
        }
    }

    public var settingsViewModel: SettingsViewModel {
        provide(.cached) { SettingsViewModel() }
    }
}
```

**`DI.swift`:**

```swift
// FeatureSettings/Sources/DI.swift
import Forge
typealias Inject<T> = ContainerInject<SettingsContainer, T>
```

---

## 9. App Target Wiring (`ForgeDemo`)

The app target is the **composition root** — the only place that knows about both infrastructure and feature modules simultaneously. It wires all containers at launch.

```swift
// ForgeDemoApp.swift
import SwiftUI
import Forge
import FeatureTasks
import FeatureSettings

@main
struct ForgeDemoApp: App {

    init() {
        wireContainers()
    }

    var body: some Scene {
        WindowGroup {
            RootView()
        }
    }
}

// MARK: - Container Wiring (Composition Root)

private func wireContainers() {
    let core = CoreContainer.shared

    // Wire TaskContainer with live dependencies from CoreContainer
    TaskContainer.shared.override("taskService") { core.taskService }
    TaskContainer.shared.override("appState") { core.appState }

    // Wire SettingsContainer with live dependencies from CoreContainer
    SettingsContainer.shared.override("taskService") { core.taskService }
    SettingsContainer.shared.override("appState") { core.appState }
}
```

This pattern makes the dependency graph explicit and readable in one place. Any new module container is wired here.

---

## 10. ViewModels

### `TaskListViewModel`

```swift
// FeatureTasks/Sources/TaskListViewModel.swift
import Observation
import CoreModels

@Observable
public final class TaskListViewModel {
    @Inject(\.taskService) private var taskService
    @Inject(\.appState) private var appState

    public var tasks: [Task] = []
    public var isLoading: Bool = false
    public var errorMessage: String?

    public var filteredTasks: [Task] {
        switch appState.activeFilter {
        case .all: return tasks
        case .active: return tasks.filter { !$0.isCompleted }
        case .completed: return tasks.filter { $0.isCompleted }
        }
    }

    public init() {}

    /// Initial load — fetches remote, upserts local, returns local.
    /// Falls back silently to local if network is unavailable.
    @MainActor
    public func loadTasks() async {
        isLoading = true
        errorMessage = nil
        defer { isLoading = false }
        do {
            tasks = try await taskService.loadTasks()
            syncBadgeCount()
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    /// Pull-to-refresh — always attempts remote, surfaces errors to UI.
    @MainActor
    public func refreshTasks() async {
        appState.isSyncing = true
        errorMessage = nil
        defer { appState.isSyncing = false }
        do {
            tasks = try await taskService.refreshTasks()
            syncBadgeCount()
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    @MainActor
    public func completeTask(id: UUID) async {
        do {
            let updated = try await taskService.completeTask(id: id)
            if let index = tasks.firstIndex(where: { $0.id == updated.id }) {
                tasks[index] = updated
            }
            syncBadgeCount()
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    @MainActor
    public func deleteTask(id: UUID) async {
        do {
            try await taskService.deleteTask(id: id)
            tasks.removeAll { $0.id == id }
            syncBadgeCount()
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    private func syncBadgeCount() {
        appState.incompletedTaskCount = tasks.filter { !$0.isCompleted }.count
    }
}
```

### `AddTaskViewModel`

```swift
// FeatureTasks/Sources/AddTaskViewModel.swift
import Observation
import CoreModels

@Observable
public final class AddTaskViewModel {
    @Inject(\.taskService) private var taskService

    public var title: String = ""
    public var notes: String = ""
    public var isSubmitting: Bool = false
    public var errorMessage: String?

    public var canSubmit: Bool {
        !title.trimmingCharacters(in: .whitespaces).isEmpty && !isSubmitting
    }

    public init() {}

    // Returns the new task on success so the parent view can dismiss and refresh
    @MainActor
    public func submit() async -> Task? {
        guard canSubmit else { return nil }
        isSubmitting = true
        defer { isSubmitting = false }
        do {
            return try await taskService.addTask(title: title, notes: notes)
        } catch {
            errorMessage = error.localizedDescription
            return nil
        }
    }
}
```

### `TaskDetailViewModel`

```swift
// FeatureTasks/Sources/TaskDetailViewModel.swift
import Observation
import CoreModels

@Observable
public final class TaskDetailViewModel {
    @Inject(\.taskService) private var taskService

    public let task: Task
    public var isCompleting: Bool = false
    public var errorMessage: String?

    public init(task: Task) {
        self.task = task
    }

    @MainActor
    public func complete() async -> Task? {
        isCompleting = true
        defer { isCompleting = false }
        do {
            return try await taskService.completeTask(id: task.id)
        } catch {
            errorMessage = error.localizedDescription
            return nil
        }
    }
}
```

### `SettingsViewModel`

```swift
// FeatureSettings/Sources/SettingsViewModel.swift
import Observation
import CoreModels

@Observable
public final class SettingsViewModel {
    @Inject(\.appState) private var appState
    @Inject(\.taskService) private var taskService

    public var displayName: String = ""
    public var sortOrder: SortOrder = .newestFirst
    public var isClearingCompleted: Bool = false

    public init() {}

    public func loadSettings() {
        displayName = appState.settings.displayName
        sortOrder = appState.settings.preferredSortOrder
    }

    public func saveSettings() {
        appState.settings.displayName = displayName
        appState.settings.preferredSortOrder = sortOrder
    }

    @MainActor
    public func clearCompleted() async {
        isClearingCompleted = true
        defer { isClearingCompleted = false }
        do {
            let tasks = try await taskService.loadTasks()
            for task in tasks where task.isCompleted {
                try await taskService.deleteTask(id: task.id)
            }
            // Reset the cached TaskListViewModel so it reloads fresh
            TaskContainer.shared.resetCached()
        } catch { }
    }
}
```

---

## 11. Views

### Navigation Structure

```
RootView (TabView)
├── Tab 1: TasksTab
│   ├── TaskListView (NavigationStack)
│   │   └── TaskDetailView (pushed on row tap)
│   └── AddTaskSheet (sheet, presented from TaskListView)
└── Tab 2: SettingsTab
    └── SettingsView
```

### `TaskListView`

```swift
// FeatureTasks/Sources/Views/TaskListView.swift
import SwiftUI

public struct TaskListView: View {
    @Inject(\.taskListViewModel) private var viewModel
    @Inject(\.appState) private var appState

    @State private var showingAddTask = false

    public init() {}

    public var body: some View {
        NavigationStack {
            Group {
                if viewModel.isLoading {
                    ProgressView("Loading tasks…")
                } else {
                    taskList
                }
            }
            .navigationTitle("ForgeDemo")
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Button {
                        showingAddTask = true
                    } label: {
                        Image(systemName: "plus")
                    }
                }
                ToolbarItem(placement: .secondaryAction) {
                    filterPicker
                }
                // Syncing indicator — visible during pull-to-refresh
                if appState.isSyncing {
                    ToolbarItem(placement: .status) {
                        HStack(spacing: 4) {
                            ProgressView()
                                .controlSize(.small)
                            Text("Syncing…")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }
                }
            }
            .sheet(isPresented: $showingAddTask) {
                AddTaskSheet {
                    Task { await viewModel.loadTasks() }
                }
            }
            .task {
                await viewModel.loadTasks()
            }
            .refreshable {
                // pull-to-refresh — calls refreshTasks() which throws on network failure
                await viewModel.refreshTasks()
            }
            .alert("Error", isPresented: .constant(viewModel.errorMessage != nil)) {
                Button("OK") { viewModel.errorMessage = nil }
            } message: {
                Text(viewModel.errorMessage ?? "")
            }
        }
    }

    private var taskList: some View {
        List {
            if viewModel.filteredTasks.isEmpty {
                ContentUnavailableView(
                    "No Tasks",
                    systemImage: "checkmark.circle",
                    description: Text("Pull down to sync from the server, or tap + to add one.")
                )
                .listRowBackground(Color.clear)
            } else {
                ForEach(viewModel.filteredTasks) { task in
                    NavigationLink(value: task) {
                        TaskRowView(task: task) {
                            Task { await viewModel.completeTask(id: task.id) }
                        }
                    }
                }
                .onDelete { indexSet in
                    let ids = indexSet.map { viewModel.filteredTasks[$0].id }
                    ids.forEach { id in Task { await viewModel.deleteTask(id: id) } }
                }
            }
        }
        .navigationDestination(for: Task.self) { task in
            TaskDetailView(task: task)
        }
    }

    private var filterPicker: some View {
        Picker("Filter", selection: Binding(
            get: { appState.activeFilter },
            set: { appState.activeFilter = $0 }
        )) {
            ForEach(TaskStatus.allCases, id: \.self) { status in
                Text(status.rawValue.capitalized).tag(status)
            }
        }
        .pickerStyle(.menu)
    }
}

// MARK: - Previews

#Preview("With Tasks") {
    TaskListView()
    // TaskContainer uses MockTaskService() and MockAppState() automatically via preview factories
}

#Preview("Empty State") {
    // Override the mock service to return no tasks
    let _ = TaskContainer.shared.withOverrides {
        $0.override("taskService") { MockTaskService(tasks: []) }
    }
    return TaskListView()
}

#Preview("Syncing") {
    let _ = TaskContainer.shared.withOverrides {
        $0.override("appState") { MockAppState(isSyncing: true) }
    }
    return TaskListView()
}
```

### `AddTaskSheet`

```swift
public struct AddTaskSheet: View {
    // .transient scope — fresh ViewModel every presentation
    @Inject(\.addTaskViewModel) private var viewModel

    @Environment(\.dismiss) private var dismiss
    var onTaskAdded: () -> Void

    public var body: some View {
        NavigationStack {
            Form {
                Section("Title") {
                    TextField("What needs to be done?", text: $viewModel.title)
                }
                Section("Notes (optional)") {
                    TextField("Add notes...", text: $viewModel.notes, axis: .vertical)
                        .lineLimit(3...6)
                }
                if let error = viewModel.errorMessage {
                    Section {
                        Text(error).foregroundStyle(.red)
                    }
                }
            }
            .navigationTitle("New Task")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Add") {
                        Task {
                            if await viewModel.submit() != nil {
                                onTaskAdded()
                                dismiss()
                            }
                        }
                    }
                    .disabled(!viewModel.canSubmit)
                }
            }
        }
    }
}

#Preview {
    AddTaskSheet(onTaskAdded: {})
}
```

### `TaskDetailView`

```swift
public struct TaskDetailView: View {
    private let viewModel: TaskDetailViewModel

    public init(task: Task) {
        // TaskDetailViewModel takes the task as a parameter — resolved inline, not via @Inject
        // because it requires a value known at navigation time
        self.viewModel = TaskContainer.shared.taskDetailViewModel(for: task)
    }

    public var body: some View {
        Form {
            Section("Title") {
                Text(viewModel.task.title)
            }
            if !viewModel.task.notes.isEmpty {
                Section("Notes") {
                    Text(viewModel.task.notes)
                }
            }
            Section("Status") {
                if viewModel.task.isCompleted {
                    Label("Completed", systemImage: "checkmark.circle.fill")
                        .foregroundStyle(.green)
                } else {
                    Button("Mark Complete") {
                        Task { await viewModel.complete() }
                    }
                }
            }
        }
        .navigationTitle("Task Detail")
        .navigationBarTitleDisplayMode(.inline)
    }
}

#Preview {
    NavigationStack {
        TaskDetailView(task: Task(title: "Preview Task", notes: "Some notes here"))
    }
}
```

**Note on `TaskDetailViewModel`:** The container should expose a factory method for parameterized ViewModels:

```swift
// In TaskContainer
public func taskDetailViewModel(for task: Task) -> TaskDetailViewModel {
    TaskDetailViewModel(task: task)  // always transient — no provide() needed
}
```

### `SettingsView`

```swift
public struct SettingsView: View {
    @Inject(\.settingsViewModel) private var viewModel

    public init() {}

    public var body: some View {
        NavigationStack {
            Form {
                Section("Profile") {
                    TextField("Your name", text: $viewModel.displayName)
                        .onChange(of: viewModel.displayName) { viewModel.saveSettings() }
                }
                Section("Preferences") {
                    Picker("Sort Order", selection: $viewModel.sortOrder) {
                        ForEach(SortOrder.allCases, id: \.self) { order in
                            Text(order.rawValue).tag(order)
                        }
                    }
                    .onChange(of: viewModel.sortOrder) { viewModel.saveSettings() }
                }
                Section {
                    Button("Clear Completed Tasks", role: .destructive) {
                        Task { await viewModel.clearCompleted() }
                    }
                    .disabled(viewModel.isClearingCompleted)
                }
            }
            .navigationTitle("Settings")
            .onAppear { viewModel.loadSettings() }
        }
    }
}

#Preview {
    SettingsView()
}
```

### `RootView`

```swift
// ForgeDemo/RootView.swift
import SwiftUI
import FeatureTasks
import FeatureSettings

struct RootView: View {
    // Inline resolution — AppState lives in CoreContainer at app level
    private let appState = CoreContainer.shared.appState

    var body: some View {
        TabView {
            Tab("Tasks", systemImage: "checkmark.circle") {
                TaskListView()
            }
            .badge(appState.incompletedTaskCount > 0 ? appState.incompletedTaskCount : nil)

            Tab("Settings", systemImage: "gear") {
                SettingsView()
            }
        }
    }
}
```

---

## 12. Mock Implementations (for previews and tests)

These live in the test targets or in a dedicated `MocksModule` target if shared between test targets.

```swift
// MockHTTPClient.swift
public final class MockHTTPClient: HTTPClientProtocol {
    public var stubbedData: Data
    public var shouldThrow: Bool

    public init(data: Data = Data(), shouldThrow: Bool = false) {
        self.stubbedData = data
        self.shouldThrow = shouldThrow
    }

    public func get<T: Decodable>(_ url: URL) async throws -> T {
        if shouldThrow { throw NetworkError.invalidResponse }
        return try JSONDecoder().decode(T.self, from: stubbedData)
    }
}

// MockRemoteTaskService.swift
public final class MockRemoteTaskService: RemoteTaskServiceProtocol {
    public var stubbedTasks: [Task]
    public var shouldThrow: Bool

    public init(tasks: [Task] = Task.previews, shouldThrow: Bool = false) {
        self.stubbedTasks = tasks
        self.shouldThrow = shouldThrow
    }

    public func fetchTodos() async throws -> [Task] {
        if shouldThrow { throw NetworkError.invalidResponse }
        return stubbedTasks
    }
}

// MockTaskService.swift
public final class MockTaskService: TaskServiceProtocol {
    public var stubbedTasks: [Task]
    public var shouldThrow: Bool
    public private(set) var refreshCallCount = 0

    public init(
        tasks: [Task] = Task.previews,
        shouldThrow: Bool = false
    ) {
        self.stubbedTasks = tasks
        self.shouldThrow = shouldThrow
    }

    public func loadTasks() async throws -> [Task] {
        if shouldThrow { throw TaskError.notFound }
        return stubbedTasks
    }

    public func refreshTasks() async throws -> [Task] {
        refreshCallCount += 1
        if shouldThrow { throw NetworkError.invalidResponse }
        return stubbedTasks
    }

    public func addTask(title: String, notes: String) async throws -> Task {
        let task = Task(title: title, notes: notes)
        stubbedTasks.append(task)
        return task
    }

    public func completeTask(id: UUID) async throws -> Task {
        guard let index = stubbedTasks.firstIndex(where: { $0.id == id }) else {
            throw TaskError.notFound
        }
        stubbedTasks[index].isCompleted = true
        return stubbedTasks[index]
    }

    public func deleteTask(id: UUID) async throws {
        stubbedTasks.removeAll { $0.id == id }
    }
}

// MockAppState.swift
@Observable
public final class MockAppState: AppStateProtocol {
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

// Task+Previews.swift (in CoreModels, #if DEBUG guarded)
extension Task {
    public static let previews: [Task] = [
        Task(title: "Review pull request", notes: "Feature branch for auth flow"),
        Task(title: "Buy groceries", notes: "Milk, eggs, coffee", isCompleted: true),
        Task(title: "Call the dentist", notes: ""),
        Task(title: "Read WWDC session notes", notes: "Focus on Swift concurrency updates"),
    ]
}
```

---

## 13. Testing

### 13.1 Base Test Containers

Every test file that tests a feature ViewModel creates a fresh container in `setUp`. The base pattern uses `unimplemented` traps so accidental live dependency calls are loud failures.

```swift
// FeatureTasksTests/Fixtures/TestTaskContainer.swift
import Forge
import CoreModels
@testable import FeatureTasks

final class TestTaskContainer: TaskContainer {
    override var taskService: any TaskServiceProtocol {
        provide { unimplemented("taskService") }
    }
    override var appState: any AppStateProtocol {
        provide { unimplemented("appState") }
    }
}
```

### 13.2 `TaskListViewModelTests`

```swift
// FeatureTasksTests/TaskListViewModelTests.swift
import XCTest
import CoreModels
@testable import FeatureTasks

final class TaskListViewModelTests: XCTestCase {

    override func setUp() {
        TaskContainer.shared = TestTaskContainer()
    }

    override func tearDown() {
        TaskContainer.shared = TaskContainer()
    }

    func testLoadTasksPopulatesTaskList() async throws {
        let mockTasks = Task.previews
        let mockService = MockTaskService(tasks: mockTasks)
        let mockState = MockAppState()

        try await TaskContainer.shared.withOverrides {
            $0.override("taskService") { mockService }
            $0.override("appState") { mockState }
        } run: {
            let vm = TaskListViewModel()
            await vm.loadTasks()
            XCTAssertEqual(vm.tasks.count, mockTasks.count)
            XCTAssertFalse(vm.isLoading)
            XCTAssertNil(vm.errorMessage)
        }
    }

    func testRefreshTasksUpdatesTaskList() async throws {
        let initial = [Task(title: "Old Task")]
        let refreshed = [Task(title: "New Task"), Task(title: "Another Task")]
        let mockService = MockTaskService(tasks: initial)
        let mockState = MockAppState()

        try await TaskContainer.shared.withOverrides {
            $0.override("taskService") { mockService }
            $0.override("appState") { mockState }
        } run: {
            let vm = TaskListViewModel()
            await vm.loadTasks()
            XCTAssertEqual(vm.tasks.count, 1)

            mockService.stubbedTasks = refreshed
            await vm.refreshTasks()

            XCTAssertEqual(vm.tasks.count, 2)
            XCTAssertEqual(mockService.refreshCallCount, 1)
            XCTAssertFalse(mockState.isSyncing) // restored after refresh
        }
    }

    func testRefreshTasksSetsSyncingStateOnAppState() async throws {
        let mockService = MockTaskService()
        let mockState = MockAppState()

        try await TaskContainer.shared.withOverrides {
            $0.override("taskService") { mockService }
            $0.override("appState") { mockState }
        } run: {
            let vm = TaskListViewModel()
            await vm.refreshTasks()
            XCTAssertFalse(mockState.isSyncing) // false after completion
        }
    }

    func testCompleteTaskUpdatesCount() async throws {
        let tasks = [Task(title: "Test Task")]
        let mockService = MockTaskService(tasks: tasks)
        let mockState = MockAppState(count: 1)

        try await TaskContainer.shared.withOverrides {
            $0.override("taskService") { mockService }
            $0.override("appState") { mockState }
        } run: {
            let vm = TaskListViewModel()
            await vm.loadTasks()
            await vm.completeTask(id: tasks[0].id)
            XCTAssertEqual(mockState.incompletedTaskCount, 0)
        }
    }

    func testLoadTasksHandlesNetworkFailureGracefully() async throws {
        // When remote fails, loadTasks() silently falls back — no error shown
        let mockService = MockTaskService(tasks: Task.previews, shouldThrow: false)
        let mockState = MockAppState()

        try await TaskContainer.shared.withOverrides {
            $0.override("taskService") { mockService }
            $0.override("appState") { mockState }
        } run: {
            let vm = TaskListViewModel()
            await vm.loadTasks()
            XCTAssertNil(vm.errorMessage)
            XCTAssertFalse(vm.tasks.isEmpty)
        }
    }

    func testRefreshTasksSurfacesNetworkError() async throws {
        // refreshTasks() is strict — surfaces errors to the UI
        let mockService = MockTaskService(shouldThrow: true)
        let mockState = MockAppState()

        try await TaskContainer.shared.withOverrides {
            $0.override("taskService") { mockService }
            $0.override("appState") { mockState }
        } run: {
            let vm = TaskListViewModel()
            await vm.refreshTasks()
            XCTAssertNotNil(vm.errorMessage)
        }
    }
}
```

### 13.3 `AddTaskViewModelTests`

```swift
final class AddTaskViewModelTests: XCTestCase {

    override func setUp() { TaskContainer.shared = TestTaskContainer() }
    override func tearDown() { TaskContainer.shared = TaskContainer() }

    func testSubmitWithValidTitleReturnsTask() async throws {
        let mockService = MockTaskService(tasks: [])

        try await TaskContainer.shared.withOverrides {
            $0.override("taskService") { mockService }
        } run: {
            let vm = AddTaskViewModel()
            vm.title = "Write unit tests"
            vm.notes = "Cover all ViewModels"
            let result = await vm.submit()
            XCTAssertNotNil(result)
            XCTAssertEqual(result?.title, "Write unit tests")
        }
    }

    func testSubmitWithEmptyTitleReturnsNil() async throws {
        let mockService = MockTaskService(tasks: [])

        try await TaskContainer.shared.withOverrides {
            $0.override("taskService") { mockService }
        } run: {
            let vm = AddTaskViewModel()
            vm.title = "   " // whitespace only
            let result = await vm.submit()
            XCTAssertNil(result)
        }
    }

    func testCanSubmitIsFalseWhenTitleIsEmpty() {
        let vm = AddTaskViewModel()
        XCTAssertFalse(vm.canSubmit)
        vm.title = "Some task"
        XCTAssertTrue(vm.canSubmit)
    }
}
```

### 13.4 `CoreNetworkingTests`

`CoreNetworking` has no Forge dependency — these tests are pure unit tests with no container involvement.

```swift
// CoreNetworkingTests/RemoteTaskServiceTests.swift
import XCTest
import CoreModels
@testable import CoreNetworking

final class RemoteTaskServiceTests: XCTestCase {

    func testFetchTodosDecodesAndMapsTasks() async throws {
        let json = """
        [
            {"id": 1, "title": "delectus aut autem", "completed": false, "userId": 1},
            {"id": 2, "title": "quis ut nam facilis", "completed": true, "userId": 1}
        ]
        """.data(using: .utf8)!

        let mockClient = MockHTTPClient(data: json)
        let service = RemoteTaskService(httpClient: mockClient)
        let tasks = try await service.fetchTodos()

        XCTAssertEqual(tasks.count, 2)
        XCTAssertEqual(tasks[0].title, "delectus aut autem")
        XCTAssertFalse(tasks[0].isCompleted)
        XCTAssertEqual(tasks[1].title, "quis ut nam facilis")
        XCTAssertTrue(tasks[1].isCompleted)
    }

    func testFetchTodosThrowsOnNetworkFailure() async {
        let mockClient = MockHTTPClient(shouldThrow: true)
        let service = RemoteTaskService(httpClient: mockClient)

        do {
            _ = try await service.fetchTodos()
            XCTFail("Expected error to be thrown")
        } catch {
            XCTAssertTrue(error is NetworkError)
        }
    }

    func testDeterministicUUIDMappingProducesSameUUIDForSameInput() {
        let id1a = UUID(remoteID: 42)
        let id1b = UUID(remoteID: 42)
        XCTAssertEqual(id1a, id1b)
    }

    func testDeterministicUUIDMappingProducesDifferentUUIDsForDifferentInputs() {
        let id1 = UUID(remoteID: 1)
        let id2 = UUID(remoteID: 2)
        XCTAssertNotEqual(id1, id2)
    }

    func testTodoDTOMappingPreservesTitle() throws {
        let json = """
        [{"id": 5, "title": "Buy milk", "completed": false, "userId": 1}]
        """.data(using: .utf8)!

        let dtos = try JSONDecoder().decode([TodoDTO].self, from: json)
        let task = dtos[0].toDomain()

        XCTAssertEqual(task.title, "Buy milk")
        XCTAssertFalse(task.isCompleted)
        XCTAssertEqual(task.id, UUID(remoteID: 5))
    }
}
```

### 13.5 `SettingsViewModelTests`

```swift
final class SettingsViewModelTests: XCTestCase {

    override func setUp() { SettingsContainer.shared = SettingsContainer() }
    override func tearDown() { SettingsContainer.shared = SettingsContainer() }

    func testSaveSettingsUpdatesAppState() throws {
        let mockState = MockAppState()
        let mockService = MockTaskService()

        try SettingsContainer.shared.withOverrides {
            $0.override("appState") { mockState }
            $0.override("taskService") { mockService }
        } run: {
            let vm = SettingsViewModel()
            vm.loadSettings()
            vm.displayName = "Test User"
            vm.sortOrder = .alphabetical
            vm.saveSettings()
            XCTAssertEqual(mockState.settings.displayName, "Test User")
            XCTAssertEqual(mockState.settings.preferredSortOrder, .alphabetical)
        }
    }
}
```

---

## 14. Swift 6 & Concurrency Requirements

- All models in `CoreModels` must conform to `Sendable`
- All service and repository implementations must be `Sendable` (use `final class` or `struct`)
- `SwiftDataStack` accesses `ModelContext` via `@ModelActor` or on the main actor — document the chosen approach
- All ViewModel `@MainActor` annotations must be explicit, not inferred
- ViewModels are `@Observable` (not `ObservableObject`) — requires iOS 17+
- `async throws` is used consistently throughout the service and repository layers — no completion handlers
- `Task { }` in view event handlers is the standard pattern — no Combine

---

## 15. iOS Version & Dependencies

| Requirement | Value |
|---|---|
| iOS | 17.0+ (required for `@Observable`) |
| Swift | 6.0 |
| Xcode | 16.0+ |
| Persistence | SwiftData (no Core Data) |
| Reactive | `@Observable` + `@State` / `@Binding` (no Combine) |
| Navigation | `NavigationStack` with typed navigation values |
| External dependencies | Forge only |

---

## 16. Project File Structure

```
Forge/                                      ← GitHub repo root
├── Package.swift                           ← Forge framework package
├── README.md
├── LICENSE
├── Sources/Forge/                          ← framework source
├── Tests/ForgeTests/                       ← framework tests
└── ForgeDemo/                                ← ForgeDemo app
    ├── ForgeDemo.xcodeproj
    ├── ForgeDemo/                          ← app target source
    │   ├── ForgeDemoApp.swift
    │   ├── RootView.swift
    │   └── CoreContainer.swift
    └── Packages/
        └── MomentumPackages/
            ├── Package.swift               ← path: "../../" references Forge at repo root
            └── Sources/
                ├── CoreModels/
                │   ├── Models/
                │   │   ├── Task.swift
                │   │   ├── TaskStatus.swift
                │   │   ├── SortOrder.swift
                │   │   └── AppSettings.swift
                │   ├── Protocols/
                │   │   ├── TaskRepositoryProtocol.swift
                │   │   ├── TaskServiceProtocol.swift
                │   │   ├── RemoteTaskServiceProtocol.swift
                │   │   ├── HTTPClientProtocol.swift
                │   │   └── AppStateProtocol.swift
                │   └── Extensions/
                │       ├── Task+Previews.swift      (#if DEBUG)
                │       └── UUID+RemoteID.swift
                ├── CoreNetworking/
                │   ├── URLSessionHTTPClient.swift
                │   ├── NetworkError.swift
                │   ├── DTOs/
                │   │   └── TodoDTO.swift
                │   └── RemoteTaskService.swift
                ├── CoreInfrastructure/
                │   ├── SwiftDataStack.swift
                │   ├── TaskRecord.swift             (SwiftData @Model)
                │   ├── TaskRepository.swift
                │   ├── TaskService.swift
                │   └── AppStateService.swift
                ├── FeatureTasks/
                │   ├── DI.swift
                │   ├── TaskContainer.swift
                │   ├── ViewModels/
                │   │   ├── TaskListViewModel.swift
                │   │   ├── AddTaskViewModel.swift
                │   │   └── TaskDetailViewModel.swift
                │   └── Views/
                │       ├── TaskListView.swift
                │       ├── TaskRowView.swift
                │       ├── AddTaskSheet.swift
                │       └── TaskDetailView.swift
                └── FeatureSettings/
                    ├── DI.swift
                    ├── SettingsContainer.swift
                    ├── ViewModels/
                    │   └── SettingsViewModel.swift
                    └── Views/
                        └── SettingsView.swift
```

### Test Targets

Test targets live inside `MomentumPackages` alongside their source targets (standard SPM convention):

```
ForgeDemo/Packages/MomentumPackages/Tests/
├── CoreNetworkingTests/
│   ├── Fixtures/
│   │   └── MockHTTPClient.swift
│   └── RemoteTaskServiceTests.swift
├── FeatureTasksTests/
│   ├── Fixtures/
│   │   ├── TestTaskContainer.swift
│   │   ├── MockTaskService.swift
│   │   ├── MockRemoteTaskService.swift
│   │   └── MockAppState.swift
│   ├── TaskListViewModelTests.swift
│   ├── AddTaskViewModelTests.swift
│   └── TaskDetailViewModelTests.swift
└── FeatureSettingsTests/
    ├── Fixtures/
    │   └── TestSettingsContainer.swift
    └── SettingsViewModelTests.swift
```

---

## 17. What Claude Code Should NOT Do

- Do not use `ObservableObject` — use `@Observable` exclusively
- Do not use Combine — use `async/await` and `@Observable`
- Do not use Core Data — use SwiftData
- Do not use `@StateObject` or `@EnvironmentObject` — use `@Observable` + `@Inject`
- Do not use `URLSession` directly in ViewModels or services — only in `URLSessionHTTPClient`
- Do not add authentication, API keys, or OAuth to the networking layer
- Do not add any third-party dependency beyond Forge
- Do not put business logic in ViewModels — business logic belongs in `TaskService`
- Do not put network mapping logic in `TaskService` — that belongs in `RemoteTaskService` and `TodoDTO`
- Do not import `CoreNetworking` or `CoreInfrastructure` from feature modules — only the app target does this
- Do not access `CoreContainer` directly from feature modules — only the app target does this
- Do not skip previews — every View file must have at least one `#Preview`
- Do not write tests for Views — only ViewModels and networking types are unit tested
- Do not add animations beyond SwiftUI defaults
- Do not add user authentication or accounts
- Do not add push notifications or background refresh