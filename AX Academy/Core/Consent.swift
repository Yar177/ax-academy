import Foundation

/// Represents the consent status for a learner.  Separate flags are maintained
/// for analytics and for communications so the caregiver can choose what is
/// shared.
public struct ConsentState: Codable, Equatable {
    public var analyticsAllowed: Bool
    public var personalizedRecommendationsAllowed: Bool
    public var lastUpdated: Date

    public init(analyticsAllowed: Bool = false,
                personalizedRecommendationsAllowed: Bool = false,
                lastUpdated: Date = Date()) {
        self.analyticsAllowed = analyticsAllowed
        self.personalizedRecommendationsAllowed = personalizedRecommendationsAllowed
        self.lastUpdated = lastUpdated
    }
}

/// Abstraction for managing parental consent records.  Persistent storage is
/// required for compliance logging.
public protocol ConsentManaging {
    var current: ConsentState { get }
    func updateConsent(_ updateBlock: (inout ConsentState) -> Void)
}

/// Default implementation backed by offline cache to avoid storing sensitive
/// data in third-party services.
public final class ConsentManager: ConsentManaging {
    private let cache: OfflineCaching
    private let cacheKey = "consent.json"
    private var analytics: AnalyticsLogging

    public private(set) var current: ConsentState {
        didSet {
            cache.store(current, for: cacheKey)
            analytics.log(event: .consentUpdated)
        }
    }

    public init(cache: OfflineCaching, analytics: AnalyticsLogging) {
        if let cached: ConsentState = cache.load(ConsentState.self, for: cacheKey) {
            self.current = cached
        } else {
            self.current = ConsentState()
        }
        self.cache = cache
        self.analytics = analytics
    }

    public func updateConsent(_ updateBlock: (inout ConsentState) -> Void) {
        var copy = current
        updateBlock(&copy)
        copy.lastUpdated = Date()
        current = copy
    }

    public func updateAnalyticsLogger(_ analytics: AnalyticsLogging) {
        self.analytics = analytics
    }
}
