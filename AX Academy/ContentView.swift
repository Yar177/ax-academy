//
//  ContentView.swift
//  AX Academy
//
//  Created by Hoshiar Sher on 10/5/25.
//

import SwiftUI

struct ContentView: View {
    @State private var selectedGrade: Grade?
    @StateObject private var shellViewModel: AppShellViewModel
    private let dashboardViewModel: CaregiverDashboardViewModel
    private let fallbackRecommendations: [String]

    init(viewModel: AppShellViewModel? = nil) {
        let container = DependencyContainer.shared
        let remoteConfig = container.resolve(RemoteConfigService.self)
        let featureFlags = container.resolve(FeatureFlagProviding.self)
        let consentManager = container.resolve(ConsentManaging.self)
        let updateManager = container.resolve(AppUpdateManaging.self)
        let analytics = container.resolve(AnalyticsLogging.self)
        if let viewModel {
            _shellViewModel = StateObject(wrappedValue: viewModel)
        } else {
            _shellViewModel = StateObject(wrappedValue: AppShellViewModel(remoteConfig: remoteConfig,
                                                                          featureFlags: featureFlags,
                                                                          consentManager: consentManager,
                                                                          updateManager: updateManager,
                                                                          analytics: analytics))
        }

        self.dashboardViewModel = CaregiverDashboardViewModel(progressTracker: container.resolve(ProgressTracking.self),
                                                              remoteConfig: remoteConfig,
                                                              analytics: analytics,
                                                              consentManager: consentManager)

        self.fallbackRecommendations = [
            L10n.string("fallback_recommendation_read"),
            L10n.string("fallback_recommendation_play"),
            L10n.string("fallback_recommendation_everyday")
        ]
    }

    var body: some View {
        TabView {
            studentHome
                .tabItem {
                    Label(L10n.text("tab_student"), systemImage: "book.fill")
                }

            if shellViewModel.caregiverDashboardEnabled {
                NavigationStack {
                    CaregiverDashboardView(viewModel: dashboardViewModel,
                                            safeModeEnabled: shellViewModel.safeModeEnabled,
                                            recommendedFallback: fallbackRecommendations)
                }
                .tabItem {
                    Label(L10n.text("tab_caregiver"), systemImage: "person.2.fill")
                }
            }
        }
        .task {
            shellViewModel.refreshRemoteConfig()
            shellViewModel.evaluateConsentPrompt()
        }
        .sheet(isPresented: $shellViewModel.showConsentSheet) {
            ConsentFormView(viewModel: shellViewModel)
        }
        .alert(item: $shellViewModel.updatePrompt) { prompt in
            Alert(title: Text(L10n.text("update_required_title")),
                  message: Text(String(format: L10n.string("update_required_message"), prompt.minimumVersion)),
                  dismissButton: .default(Text(L10n.text("update_required_ok"))))
        }
    }

    private var studentHome: some View {
        NavigationStack {
            VStack(spacing: 40) {
                VStack(spacing: 16) {
                    Image(systemName: "graduationcap.fill")
                        .font(.system(size: 60))
                        .foregroundStyle(.blue)

                    Text(L10n.text("app_title"))
                        .font(.largeTitle)
                        .fontWeight(.bold)

                    Text(L10n.text("welcome_subtitle"))
                        .font(.title3)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                }
                .padding(.top, 40)

                VStack(spacing: 20) {
                    ForEach(Grade.allCases, id: \.self) { grade in
                        GradeSelectionCard(grade: grade) {
                            selectedGrade = grade
                        }
                    }
                }
                .padding(.horizontal, 20)

                Spacer()
            }
            .navigationTitle(L10n.text("welcome_title"))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        shellViewModel.showConsentSheet = true
                    } label: {
                        Label(L10n.text("consent_toolbar_button"), systemImage: "hand.raised")
                    }
                    .accessibilityIdentifier("consentButton")
                }
            }
            .fullScreenCover(item: $selectedGrade) { grade in
                gradeView(for: grade)
            }
        }
    }
    
    @ViewBuilder
    private func gradeView(for grade: Grade) -> some View {
        let container = DependencyContainer.shared
        let contentProvider = container.resolve(ContentProviding.self)
        let analytics = container.resolve(AnalyticsLogging.self)
        let persistence = container.resolve(Persistence.self)
        let progressTracker = container.resolve(ProgressTracking.self)

        switch grade {
        case .kindergarten:
            let coordinator = KindergartenCoordinator(
                contentProvider: contentProvider,
                analytics: analytics,
                persistence: persistence,
                progressTracker: progressTracker
            )
            coordinator.start()
                .onAppear {
                    analytics.log(event: .screenPresented(name: "Kindergarten"))
                }

        case .grade1:
            let coordinator = Grade1Coordinator(
                contentProvider: contentProvider,
                analytics: analytics,
                persistence: persistence,
                progressTracker: progressTracker
            )
            coordinator.start()
                .onAppear {
                    analytics.log(event: .screenPresented(name: "Grade1"))
                }
        }
    }
}

struct GradeSelectionCard: View {
    let grade: Grade
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack {
                VStack(alignment: .leading, spacing: 8) {
                    Text(grade.displayName)
                        .font(.title2)
                        .fontWeight(.semibold)
                        .foregroundStyle(.primary)

                    Text(L10n.text("grade_card_cta"))
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
                
                Spacer()
                
                Image(systemName: "arrow.right.circle.fill")
                    .font(.title2)
                    .foregroundStyle(.blue)
            }
            .padding(20)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(.background)
                    .shadow(color: .black.opacity(0.1), radius: 8, x: 0, y: 4)
            )
        }
        .buttonStyle(.plain)
    }
}

#Preview {
    ContentView()
}
