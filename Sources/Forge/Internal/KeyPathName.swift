// IMPLEMENTATION NOTE:
// This function relies on Swift's KeyPath string interpolation format, which produces
// either the bare property name ("authService") or a dotted path ("container.authService").
// This format has been consistent across Swift 5.10 through 6.2.
//
// This is NOT a documented language guarantee. If Swift ever changes this format:
// 1. The function will return nil
// 2. assertionFailure will fire at the call site in debug builds
// 3. The fix is to update the parsing logic to match the new format
// 4. If the format becomes unpredictable, revert to string-based public API
//
// CI must run KeyPath name extraction tests across all supported Swift versions
// before every release.

/// Extracts the leaf property name from a KeyPath using its string interpolation.
///
/// Swift KeyPath string interpolation produces either the bare property name
/// (e.g. `"authService"`) or a dotted path (e.g. `"container.authService"`).
/// This function takes the last component in both cases.
///
/// - Parameter keyPath: The KeyPath to extract the property name from.
/// - Returns: The property name, or `nil` if extraction fails.
internal func propertyName<Root, Value>(from keyPath: KeyPath<Root, Value>) -> String? {
    let description = "\(keyPath)"
    let components = description.components(separatedBy: ".")
    let name = components.last?.trimmingCharacters(in: .whitespaces) ?? ""
    return name.isEmpty ? nil : name
}
