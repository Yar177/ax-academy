//
//  AX_AcademyApp.swift
//  AX Academy
//
//  Created by Hoshiar Sher on 10/5/25.
//

import SwiftUI

@main
struct AX_AcademyApp: App {
    
    init() {
        setupDependencies()
    }
    
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
    }
    
    /// Registers all app dependencies in the DependencyContainer
    private func setupDependencies() {
        let container = DependencyContainer.shared

        // Register content provider
        container.register(ContentProviding.self) {
            StaticContentProvider()
        }

        // Shared cache ensures offline behaviour across services
        let cache = FileOfflineCache()
        container.register(OfflineCaching.self) { cache }

        // Base analytics logger used until consent-gated logger replaces it
        let fallbackAnalytics = NoopAnalyticsLogger()

        // Remote configuration informs feature flags and messaging
        let remoteConfig = BundleRemoteConfigService(cache: cache,
                                                     analytics: fallbackAnalytics)
        container.register(RemoteConfigService.self) { remoteConfig }

        // Feature flags respond to remote configuration updates
        let featureFlags = DefaultFeatureFlagProvider(remoteConfig: remoteConfig, cache: cache)
        container.register(FeatureFlagProviding.self) { featureFlags }

        // Consent manager persists parental decisions
        let consentManager = ConsentManager(cache: cache, analytics: fallbackAnalytics)
        container.register(ConsentManaging.self) { consentManager }

        // Replace analytics logger with privacy-preserving implementation that
        // honours feature flags and consent states
        let analyticsLogger = PrivacyPreservingAnalyticsLogger(featureFlags: featureFlags,
                                                               consentManager: consentManager)
        container.register(AnalyticsLogging.self) { analyticsLogger }

        remoteConfig.updateAnalyticsLogger(analyticsLogger)
        consentManager.updateAnalyticsLogger(analyticsLogger)

        // Progress tracking supports caregiver dashboards
        let progressTracker = ProgressTracker(cache: cache)
        container.register(ProgressTracking.self) { progressTracker }

        // App update checks use lightweight semantic version comparison
        container.register(AppUpdateManaging.self) { AppUpdateManager() }

        // Audio scaffolds prepared for future voiceovers
        container.register(AudioScaffoldRepository.self) { AudioScaffoldRepository() }

        // Refresh remote configuration at launch to update flags and prompts
        remoteConfig.refresh()
    }
}
