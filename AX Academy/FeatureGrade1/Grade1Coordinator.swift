import SwiftUI

/// Coordinator for the Grade 1 feature.  Builds the navigation hierarchy
/// and injects dependencies into view models.
public final class Grade1Coordinator: Coordinator {
    private let contentProvider: ContentProviding
    private let analytics: AnalyticsLogging
    private let persistence: Persistence
    private let progressTracker: ProgressTracking

    public init(contentProvider: ContentProviding,
                analytics: AnalyticsLogging,
                persistence: Persistence,
                progressTracker: ProgressTracking) {
        self.contentProvider = contentProvider
        self.analytics = analytics
        self.persistence = persistence
        self.progressTracker = progressTracker
    }

    public func start() -> some View {
        let lessons = contentProvider.lessons(for: .grade1)
        let rootVM = Grade1LessonListViewModel(grade: .grade1,
                                         lessons: lessons,
                                         analytics: analytics,
                                         persistence: persistence,
                                         progressTracker: progressTracker)
        return Grade1RootView(viewModel: rootVM)
    }
}
