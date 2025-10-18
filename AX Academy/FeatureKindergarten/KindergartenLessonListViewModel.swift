import Foundation
import Combine

/// View model for the root kindergarten view displaying a list of lessons.  It
/// loads lesson completion status from persistence and logs screen
/// presentations【8868879203866†L39-L60】.  When a lesson is tapped a
/// `LessonSessionViewModel` will be created by the view.
final class KindergartenLessonListViewModel: BaseViewModel {
    @Published var lessons: [Lesson]
    let grade: Grade

    // expose dependencies internally so the view can construct session view models
    let analytics: AnalyticsLogging
    let persistence: Persistence
    let progressTracker: ProgressTracking

    init(grade: Grade,
         lessons: [Lesson],
         analytics: AnalyticsLogging,
         persistence: Persistence,
         progressTracker: ProgressTracking) {
        self.grade = grade
        self.lessons = lessons
        self.analytics = analytics
        self.persistence = persistence
        self.progressTracker = progressTracker
        super.init()

        analytics.log(event: .screenPresented(name: "\(grade.displayName) Lesson List"))
    }

    /// Returns whether the lesson has been completed.  Completion flags are
    /// stored in persistence using a composite key.
    func isLessonCompleted(_ lesson: Lesson) -> Bool {
        let key = completionKey(for: lesson)
        return persistence.bool(forKey: key) ?? false
    }

    /// Marks the given lesson as completed in persistence.
    func markLessonCompleted(_ lesson: Lesson) {
        let key = completionKey(for: lesson)
        persistence.set(true, forKey: key)
    }

    private func completionKey(for lesson: Lesson) -> String {
        return "\(grade.rawValue).lessonCompleted.\(lesson.id)"
    }
}
