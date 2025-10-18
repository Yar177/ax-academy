import Combine
import Foundation

/// Orchestrates global application state including consent flows, remote
/// configuration refreshes, update prompts and safe-mode fallbacks when services
/// are unavailable.
final class AppShellViewModel: BaseViewModel {
    struct UpdatePrompt: Identifiable {
        let id = UUID()
        let minimumVersion: String
    }

    @Published private(set) var consentState: ConsentState
    @Published var showConsentSheet: Bool = false
    @Published private(set) var safeModeEnabled: Bool = false
    @Published private(set) var updatePrompt: UpdatePrompt?
    @Published private(set) var featureFlagsSnapshot: FeatureFlags

    private let remoteConfig: RemoteConfigService
    private let featureFlags: FeatureFlagProviding
    private let consentManager: ConsentManaging
    private let updateManager: AppUpdateManaging
    private let analytics: AnalyticsLogging

    private var recommendedSteps: [String] = []

    init(remoteConfig: RemoteConfigService,
         featureFlags: FeatureFlagProviding,
         consentManager: ConsentManaging,
         updateManager: AppUpdateManaging,
         analytics: AnalyticsLogging) {
        self.remoteConfig = remoteConfig
        self.featureFlags = featureFlags
        self.consentManager = consentManager
        self.updateManager = updateManager
        self.analytics = analytics
        self.consentState = consentManager.current
        self.featureFlagsSnapshot = featureFlags.flags
        super.init()

        remoteConfig.observe { [weak self] config in
            guard let self else { return }
            self.recommendedSteps = config.recommendedNextSteps
            self.evaluateUpdatePrompt(minimumVersion: config.minimumAppVersion)
        }

        featureFlags.observe { [weak self] flags in
            DispatchQueue.main.async {
                self?.featureFlagsSnapshot = flags
                self?.evaluateConsentPrompt()
            }
        }
    }

    var caregiverDashboardEnabled: Bool {
        featureFlagsSnapshot.caregiverDashboardEnabled
    }

    var localizedAudioEnabled: Bool {
        featureFlagsSnapshot.localizedAudioEnabled
    }

    func recommendedNextSteps() -> [String] {
        recommendedSteps
    }

    func refreshRemoteConfig() {
        remoteConfig.refresh { [weak self] result in
            DispatchQueue.main.async {
                switch result {
                case .success:
                    self?.safeModeEnabled = false
                    self?.analytics.log(event: .safeModeChanged(isEnabled: false))
                case .failure:
                    self?.safeModeEnabled = true
                    self?.analytics.log(event: .safeModeChanged(isEnabled: true))
                }
            }
        }
    }

    func markSafeModeHandled() {
        if safeModeEnabled {
            safeModeEnabled = false
            analytics.log(event: .safeModeChanged(isEnabled: false))
        }
    }

    func evaluateConsentPrompt() {
        if featureFlagsSnapshot.analyticsEnabled && !consentState.analyticsAllowed {
            showConsentSheet = true
        }
    }

    func updateConsent(analyticsAllowed: Bool, recommendationsAllowed: Bool) {
        consentManager.updateConsent { consent in
            consent.analyticsAllowed = analyticsAllowed
            consent.personalizedRecommendationsAllowed = recommendationsAllowed
        }
        consentState = consentManager.current
        showConsentSheet = false
    }

    private func evaluateUpdatePrompt(minimumVersion: String?) {
        let currentVersion = Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String ?? "1.0.0"
        if updateManager.shouldShowUpdatePrompt(currentVersion: currentVersion, minimumVersion: minimumVersion) {
            updatePrompt = UpdatePrompt(minimumVersion: minimumVersion ?? "")
            analytics.log(event: .updatePromptShown(minimumVersion: minimumVersion ?? ""))
        } else {
            updatePrompt = nil
        }
    }
}
