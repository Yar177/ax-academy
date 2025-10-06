import Foundation

/// A mock analytics logger used in unit tests.  It records events to an
/// internal array which can be inspected by tests to verify correct
/// behaviour.  Tests can also clear the recorded events between test cases.
public final class MockAnalyticsLogger: AnalyticsLogging {
    public private(set) var events: [AnalyticsEvent] = []
    public init() {}
    public func log(event: AnalyticsEvent) {
        events.append(event)
    }
    /// Resets the recorded events.
    public func reset() {
        events.removeAll()
    }
}

/// A mock persistence store backed by an in‑memory dictionary.  This is
/// useful for testing view models without writing to UserDefaults.
public final class MockPersistence: Persistence {
    private var store: [String: Bool] = [:]
    public init() {}
    public func set(_ value: Bool, forKey key: String) {
        store[key] = value
    }
    public func bool(forKey key: String) -> Bool? {
        return store[key]
    }
}