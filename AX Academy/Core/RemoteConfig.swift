import Combine
import Foundation

/// Represents dynamic configuration values supplied by a backend.  The
/// configuration may include feature flags, recommendations and update
/// messaging.  The structure is intentionally narrow to limit the type of data
/// stored about a learner.
public struct RemoteConfig: Codable, Equatable {
    public var featureFlags: FeatureFlags?
    public var recommendedNextSteps: [String]
    public var minimumAppVersion: String?

    public init(featureFlags: FeatureFlags? = nil,
                recommendedNextSteps: [String] = [],
                minimumAppVersion: String? = nil) {
        self.featureFlags = featureFlags
        self.recommendedNextSteps = recommendedNextSteps
        self.minimumAppVersion = minimumAppVersion
    }
}

/// Abstraction for fetching and observing remote configuration values.
public protocol RemoteConfigService: AnyObject {
    /// Returns the most recently cached configuration.
    var currentConfig: RemoteConfig { get }

    /// Refreshes configuration from the network.
    func refresh(completion: ((Result<RemoteConfig, Error>) -> Void)?)

    /// Registers an observer that is notified when configuration changes.
    func observe(_ observer: @escaping (RemoteConfig) -> Void)
}

public extension RemoteConfigService {
    func refresh() {
        refresh(completion: nil)
    }
}

/// Protocol for caching configuration and other blobs to disk.  The cache is
/// required for offline support so the app continues to operate even without a
/// network connection.
public protocol OfflineCaching {
    func store<T: Codable>(_ value: T, for key: String)
    func load<T: Codable>(_ type: T.Type, for key: String) -> T?
}

/// A file-based implementation of `OfflineCaching`.  Values are encoded as JSON
/// and stored in the app's cache directory.
public final class FileOfflineCache: OfflineCaching {
    private let directoryURL: URL
    private let encoder = JSONEncoder()
    private let decoder = JSONDecoder()

    public init(directoryURL: URL? = nil) {
        if let directoryURL {
            self.directoryURL = directoryURL
        } else {
            let paths = FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask)
            self.directoryURL = paths[0].appendingPathComponent("OfflineCache", isDirectory: true)
        }
        try? FileManager.default.createDirectory(at: self.directoryURL,
                                                 withIntermediateDirectories: true)
    }

    public func store<T: Codable>(_ value: T, for key: String) {
        let url = directoryURL.appendingPathComponent(key)
        do {
            let data = try encoder.encode(value)
            try data.write(to: url, options: .atomic)
        } catch {
            // The cache is best-effort – failures should be logged but not fatal.
            DependencyContainer.shared.resolve(ErrorLogging.self).log(error: error,
                                                                       context: "Caching \(key)")
        }
    }

    public func load<T: Codable>(_ type: T.Type, for key: String) -> T? {
        let url = directoryURL.appendingPathComponent(key)
        guard let data = try? Data(contentsOf: url) else { return nil }
        do {
            return try decoder.decode(type, from: data)
        } catch {
            DependencyContainer.shared.resolve(ErrorLogging.self).log(error: error,
                                                                       context: "Decoding cache \(key)")
            return nil
        }
    }
}

/// Default remote configuration service.  In production it would perform a
/// network request.  Here it loads bundled JSON asynchronously to demonstrate
/// behaviour while remaining fully offline.  The service publishes updates to
/// observers using Combine.
public final class BundleRemoteConfigService: RemoteConfigService {
    private let cache: OfflineCaching
    private var analytics: AnalyticsLogging
    private var observers: [(RemoteConfig) -> Void] = []
    private let queue = DispatchQueue(label: "RemoteConfig")
    private let resourceName: String

    public private(set) var currentConfig: RemoteConfig {
        didSet {
            cache.store(currentConfig, for: cacheKey)
            observers.forEach { $0(currentConfig) }
        }
    }

    private let cacheKey = "remoteConfig.json"

    public init(resourceName: String = "remote_config",
                cache: OfflineCaching,
                analytics: AnalyticsLogging) {
        self.cache = cache
        self.analytics = analytics
        self.resourceName = resourceName
        if let cached: RemoteConfig = cache.load(RemoteConfig.self, for: cacheKey) {
            self.currentConfig = cached
        } else {
            self.currentConfig = RemoteConfig()
        }
    }

    public func updateAnalyticsLogger(_ analytics: AnalyticsLogging) {
        self.analytics = analytics
    }

    public func refresh(completion: ((Result<RemoteConfig, Error>) -> Void)? = nil) {
        queue.asyncAfter(deadline: .now() + 0.3) { [weak self] in
            guard let self = self else { return }
            let primaryURL = Bundle.main.url(forResource: self.resourceName, withExtension: "json")
            let fallbackURL = Bundle.main.url(forResource: self.resourceName,
                                              withExtension: "json",
                                              subdirectory: "Resources")
            guard let url = primaryURL ?? fallbackURL else {
                self.analytics.log(event: .remoteConfigFetchFailed(reason: "Missing resource"))
                completion?(.failure(NSError(domain: "RemoteConfig", code: 1, userInfo: [NSLocalizedDescriptionKey: "Missing resource"])))
                return
            }
            do {
                let data = try Data(contentsOf: url)
                let config = try JSONDecoder().decode(RemoteConfig.self, from: data)
                self.analytics.log(event: .remoteConfigFetched)
                self.currentConfig = config
                completion?(.success(config))
            } catch {
                self.analytics.log(event: .remoteConfigFetchFailed(reason: error.localizedDescription))
                DependencyContainer.shared.resolve(ErrorLogging.self).log(error: error,
                                                                           context: "RemoteConfig")
                completion?(.failure(error))
            }
        }
    }

    public func observe(_ observer: @escaping (RemoteConfig) -> Void) {
        observers.append(observer)
        observer(currentConfig)
    }
}
