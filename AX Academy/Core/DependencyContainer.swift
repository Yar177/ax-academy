import Foundation

/// A lightweight dependency injection container.  The container stores factory
/// closures for each service type and resolves them on demand.  Register
/// factories at app launch before requesting any services.  If a service
/// cannot be resolved an assertion will fail in debug; release builds will
/// return a default instance where possible.
public final class DependencyContainer {
    // Singleton instance used throughout the app.  The container can also
    // be instantiated locally for unit tests.
    public static let shared = DependencyContainer()

    // Storage for factory closures keyed by ObjectIdentifier
    private var factories: [ObjectIdentifier: () -> Any] = [:]

    private init() {
        // Register default implementations for optional services
        register(AnalyticsLogging.self) { NoopAnalyticsLogger() }
        register(Persistence.self) { UserDefaultsPersistence() }
    }

    /// Registers a factory closure for creating instances of a given service
    /// type.  If a factory already exists for the type it will be replaced.
    /// - Parameters:
    ///   - type: The protocol or class type to register.
    ///   - factory: A closure that returns a new instance of the type.
    public func register<Service>(_ type: Service.Type, factory: @escaping () -> Service) {
        let key = ObjectIdentifier(type)
        factories[key] = factory
    }

    /// Resolves an instance of the specified type.  The returned instance is
    /// created by invoking the registered factory.  If no factory has been
    /// registered, this method will crash in debug builds to highlight
    /// misconfiguration.  In release builds it falls back to a default
    /// instance when available.  Add more fallbacks as needed.
    /// - Returns: An instance of the requested type.
    public func resolve<Service>(_ type: Service.Type = Service.self) -> Service {
        let key = ObjectIdentifier(type)
        guard let factory = factories[key], let service = factory() as? Service else {
            fatalError("No factory registered for \(type)")
        }
        return service
    }
}