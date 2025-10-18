import Foundation

/// A lightweight analytics logger that keeps events on-device.  It prints
/// anonymised events to the debug console when analytics are enabled via
/// feature flags and consent.  Events are stored in memory allowing them to be
/// exported for auditing if necessary.
public final class PrivacyPreservingAnalyticsLogger: AnalyticsLogging {
    private var events: [AnalyticsEvent] = []
    private let featureFlags: FeatureFlagProviding
    private let consentManager: ConsentManaging

    public init(featureFlags: FeatureFlagProviding, consentManager: ConsentManaging) {
        self.featureFlags = featureFlags
        self.consentManager = consentManager
    }

    public func log(event: AnalyticsEvent) {
        guard consentManager.current.analyticsAllowed,
              featureFlags.flags.analyticsEnabled else { return }
        events.append(event)
        print("[Analytics] \(event)")
    }

    /// Returns a copy of the anonymised event list.  Intended for exporting as
    /// part of privacy reviews.
    public func exportEvents() -> [AnalyticsEvent] {
        events
    }
}
