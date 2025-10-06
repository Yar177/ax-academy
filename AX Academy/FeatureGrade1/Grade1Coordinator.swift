import SwiftUI
import Core
import ContentModel
import DesignSystem

/// Coordinator for the Grade 1 feature.  Builds the navigation hierarchy
/// and injects dependencies into view models.
public final class Grade1Coordinator: Coordinator {
    private let contentProvider: ContentProviding
    private let analytics: AnalyticsLogging
    private let persistence: Persistence

    public init(contentProvider: ContentProviding,
                analytics: AnalyticsLogging,
                persistence: Persistence) {
        self.contentProvider = contentProvider
        self.analytics = analytics
        self.persistence = persistence
    }

    public func start() -> some View {
        let lessons = contentProvider.lessons(for: .grade1)
        let rootVM = LessonListViewModel(grade: .grade1,
                                         lessons: lessons,
                                         analytics: analytics,
                                         persistence: persistence)
        return Grade1RootView(viewModel: rootVM)
    }
}