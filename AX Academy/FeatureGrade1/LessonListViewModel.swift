import Foundation
import Combine

/// View model for the root Grade 1 view displaying a list of lessons.  It
/// loads lesson completion status from persistence and logs screen
/// presentations.  When a lesson is tapped a LessonSessionViewModel will be
/// created by the view.
final class Grade1LessonListViewModel: BaseViewModel {
    @Published var lessons: [Lesson]
    let grade: Grade
    let analytics: AnalyticsLogging
    let persistence: Persistence

    init(grade: Grade,
         lessons: [Lesson],
         analytics: AnalyticsLogging,
         persistence: Persistence) {
        self.grade = grade
        self.lessons = lessons
        self.analytics = analytics
        self.persistence = persistence
        super.init()
        analytics.log(event: .screenPresented(name: "\(grade.displayName) Lesson List"))
    }

    func isLessonCompleted(_ lesson: Lesson) -> Bool {
        persistence.bool(forKey: completionKey(for: lesson)) ?? false
    }
    func markLessonCompleted(_ lesson: Lesson) {
        persistence.set(true, forKey: completionKey(for: lesson))
    }
    private func completionKey(for lesson: Lesson) -> String {
        "\(grade.rawValue).lessonCompleted.\(lesson.id)"
    }
}
