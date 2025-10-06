import Foundation

/// A protocol for persisting lightweight user data such as lesson progress
/// and settings.  By abstracting persistence behind a protocol the app can
/// switch between different storage backends (UserDefaults, CoreData, file
/// based, etc.) without changing the calling code.  For this app a simple
/// key–value store suffices.
public protocol Persistence {
    /// Saves a boolean value for a given key.
    func set(_ value: Bool, forKey key: String)
    /// Reads a boolean value for a given key.  Returns nil if the value has
    /// not been set.
    func bool(forKey key: String) -> Bool?
}

/// A default implementation of `Persistence` backed by `UserDefaults`.  This
/// class observes the `UserDefaults` suite associated with the app.
public final class UserDefaultsPersistence: Persistence {
    private let defaults: UserDefaults

    /// Creates a persistence store backed by the supplied user defaults.  The
    /// default argument uses `.standard` which reads and writes from the
    /// shared defaults database.  You can inject a custom instance for
    /// testing.
    public init(userDefaults: UserDefaults = .standard) {
        self.defaults = userDefaults
    }

    public func set(_ value: Bool, forKey key: String) {
        defaults.set(value, forKey: key)
    }

    public func bool(forKey key: String) -> Bool? {
        return defaults.object(forKey: key) as? Bool
    }
}