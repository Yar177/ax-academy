import Foundation
import Combine
import Core
import ContentModel

/// View model for the grade 1 lesson list.  Maintains completion state in
/// persistence and logs screen presentations【8868879203866†L39-L60】.
final class LessonListViewModel: BaseViewModel {
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