import Foundation

/// Describes feature flags used throughout the app.  Feature flags allow new
/// functionality to be rolled out gradually and, when combined with remote
/// configuration, enable quick mitigation if issues arise.  All feature flag
/// values default to a conservative setting that is safe for children.
public struct FeatureFlags: Codable, Equatable {
    /// When true the caregiver dashboard is presented to adults in the app.
    public var caregiverDashboardEnabled: Bool
    /// When true analytics events are collected for behaviour insight.  This
    /// should only be enabled when the appropriate parental consent has been
    /// granted.
    public var analyticsEnabled: Bool
    /// Enables remote configuration refreshes.  When disabled the app relies on
    /// cached values to avoid unnecessary network calls.
    public var remoteConfigEnabled: Bool
    /// Enables proactive update messaging when a new build is available.
    public var updateMessagingEnabled: Bool
    /// Enables audio scaffolds per locale.
    public var localizedAudioEnabled: Bool

    public init(caregiverDashboardEnabled: Bool = true,
                analyticsEnabled: Bool = false,
                remoteConfigEnabled: Bool = true,
                updateMessagingEnabled: Bool = true,
                localizedAudioEnabled: Bool = true) {
        self.caregiverDashboardEnabled = caregiverDashboardEnabled
        self.analyticsEnabled = analyticsEnabled
        self.remoteConfigEnabled = remoteConfigEnabled
        self.updateMessagingEnabled = updateMessagingEnabled
        self.localizedAudioEnabled = localizedAudioEnabled
    }
}

/// A protocol for resolving feature flags.  The provider may read values from
/// remote configuration, experiments or local overrides.  By depending on this
/// protocol view models can respond to flag changes without coupling to the
/// concrete data source.
public protocol FeatureFlagProviding {
    /// Returns the current feature flag configuration.
    var flags: FeatureFlags { get }

    /// Registers a callback to be invoked when feature flags change.  The
    /// default implementation is optional for providers that do not support
    /// live updates.
    func observe(_ observer: @escaping (FeatureFlags) -> Void)
}

public extension FeatureFlagProviding {
    func observe(_ observer: @escaping (FeatureFlags) -> Void) {
        observer(flags)
    }
}

/// A simple in-memory feature flag provider backed by remote configuration and
/// optional persisted overrides.  The provider broadcasts updates to its
/// observers using a lightweight observer list.
public final class DefaultFeatureFlagProvider: FeatureFlagProviding {
    private let remoteConfig: RemoteConfigService
    private let cache: OfflineCaching
    private let cacheKey = "featureFlags.json"
    private var observers: [(FeatureFlags) -> Void] = []

    public private(set) var flags: FeatureFlags {
        didSet {
            observers.forEach { $0(flags) }
            persist(flags)
        }
    }

    public init(remoteConfig: RemoteConfigService, cache: OfflineCaching) {
        self.remoteConfig = remoteConfig
        self.cache = cache
        if let cached: FeatureFlags = cache.load(FeatureFlags.self, for: cacheKey) {
            self.flags = cached
        } else {
            self.flags = FeatureFlags()
        }

        remoteConfig.observe { [weak self] config in
            guard let self = self else { return }
            if let flags = config.featureFlags {
                self.flags = flags
            }
        }
    }

    public func observe(_ observer: @escaping (FeatureFlags) -> Void) {
        observers.append(observer)
        observer(flags)
    }

    private func persist(_ flags: FeatureFlags) {
        cache.store(flags, for: cacheKey)
    }
}
