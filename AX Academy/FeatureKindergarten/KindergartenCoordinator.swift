import SwiftUI

/// The coordinator responsible for the Kindergarten feature.  It builds a
/// navigation tree for kindergarten lessons and injects dependencies into
/// views and view models.  Coordinators should be lightweight and defer
/// heavy work to view models.
public final class KindergartenCoordinator: Coordinator {
    private let contentProvider: ContentProviding
    private let analytics: AnalyticsLogging
    private let persistence: Persistence
    private let progressTracker: ProgressTracking

    /// Initializes the coordinator with required dependencies.  These are
    /// typically resolved from the `DependencyContainer` at the call site.
    public init(contentProvider: ContentProviding,
                analytics: AnalyticsLogging,
                persistence: Persistence,
                progressTracker: ProgressTracking) {
        self.contentProvider = contentProvider
        self.analytics = analytics
        self.persistence = persistence
        self.progressTracker = progressTracker
    }

    /// Constructs the root view for the Kindergarten feature.  The root
    /// contains a list of available lessons.  Selecting a lesson pushes a
    /// quiz view onto the navigation stack.
    public func start() -> some View {
        let lessons = contentProvider.lessons(for: .kindergarten)
        let rootViewModel = KindergartenLessonListViewModel(grade: .kindergarten,
                                                lessons: lessons,
                                                analytics: analytics,
                                                persistence: persistence,
                                                progressTracker: progressTracker)
        return KindergartenRootView(viewModel: rootViewModel)
    }
}
