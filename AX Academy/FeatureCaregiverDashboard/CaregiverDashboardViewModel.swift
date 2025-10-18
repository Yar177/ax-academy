import Combine
import Foundation

struct MasteryBadge: Identifiable, Hashable {
    let id = UUID()
    let titleKey: String
    let detailKey: String
}

final class CaregiverDashboardViewModel: BaseViewModel {
    @Published private(set) var gradeSummaries: [GradeProgress] = []
    @Published private(set) var badges: [MasteryBadge] = []
    @Published private(set) var recommendedSteps: [String] = []

    private let progressTracker: ProgressTracking
    private let remoteConfig: RemoteConfigService
    private let analytics: AnalyticsLogging
    private let consentManager: ConsentManaging

    init(progressTracker: ProgressTracking,
         remoteConfig: RemoteConfigService,
         analytics: AnalyticsLogging,
         consentManager: ConsentManaging) {
        self.progressTracker = progressTracker
        self.remoteConfig = remoteConfig
        self.analytics = analytics
        self.consentManager = consentManager
        super.init()
        refresh()
        remoteConfig.observe { [weak self] config in
            DispatchQueue.main.async {
                self?.recommendedSteps = config.recommendedNextSteps
            }
        }

        NotificationCenter.default.publisher(for: .progressDidUpdate)
            .receive(on: DispatchQueue.main)
            .sink { [weak self] _ in
                self?.refresh()
            }
            .store(in: &cancellables)
    }

    func refresh() {
        let progress = progressTracker.allProgress()
        DispatchQueue.main.async {
            self.gradeSummaries = progress
            self.badges = self.generateBadges(from: progress)
        }
    }

    func recordView() {
        analytics.log(event: .caregiverDashboardViewed)
    }

    func shareSummaryText() -> String {
        let sanitized = gradeSummaries.map { summary in
            let accuracy = Int(summary.overallAccuracy * 100)
            return "\(summary.grade.displayName): \(summary.completedLessons)/\(summary.totalLessons) lessons, \(accuracy)% accuracy"
        }.joined(separator: "\n")
        return String(format: L10n.string("dashboard_share_template"), sanitized)
    }

    func canShare() -> Bool {
        consentManager.current.personalizedRecommendationsAllowed
    }

    func recordShare() {
        analytics.log(event: .caregiverSummaryShared)
    }

    private func generateBadges(from progress: [GradeProgress]) -> [MasteryBadge] {
        var badges: [MasteryBadge] = []
        for summary in progress {
            if summary.overallAccuracy >= 0.9 {
                badges.append(MasteryBadge(titleKey: "badge_accuracy_ace",
                                           detailKey: "badge_accuracy_ace_detail"))
            }
            if summary.completedLessons >= summary.totalLessons && summary.totalLessons > 0 {
                badges.append(MasteryBadge(titleKey: "badge_completion_champion",
                                           detailKey: "badge_completion_champion_detail"))
            }
        }
        if badges.isEmpty {
            badges.append(MasteryBadge(titleKey: "badge_keep_going",
                                       detailKey: "badge_keep_going_detail"))
        }
        return Array(Set(badges)).sorted { $0.titleKey < $1.titleKey }
    }
}
