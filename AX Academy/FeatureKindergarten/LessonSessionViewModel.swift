import Foundation
import Combine
import Core
import ContentModel

/// View model that manages a single lesson session.  It iterates through
/// questions, evaluates answers and signals completion.  Analytics events are
/// logged when the lesson starts and completes, and when each question is
/// answered【8868879203866†L39-L60】.
final class LessonSessionViewModel: BaseViewModel {
    /// The lesson being presented.
    let lesson: Lesson
    /// The zero‑based index of the current question.
    @Published private(set) var currentIndex: Int = 0
    /// Whether the lesson has been completed.
    @Published private(set) var isFinished: Bool = false
    /// Indicates whether the last answer was correct.  When nil no answer
    /// has been submitted for the current question.
    @Published private(set) var lastAnswerCorrect: Bool? = nil

    private let analytics: AnalyticsLogging
    private let persistence: Persistence
    private let grade: Grade
    private let markLessonCompleted: (Lesson) -> Void

    init(grade: Grade,
         lesson: Lesson,
         analytics: AnalyticsLogging,
         persistence: Persistence,
         markLessonCompleted: @escaping (Lesson) -> Void) {
        self.grade = grade
        self.lesson = lesson
        self.analytics = analytics
        self.persistence = persistence
        self.markLessonCompleted = markLessonCompleted
        super.init()
        analytics.log(event: .lessonStarted(grade: grade.rawValue, lessonID: lesson.id))
    }

    /// Returns the current question.  If the lesson has finished this
    /// returns nil.
    var currentQuestion: Question? {
        guard currentIndex < lesson.questions.count else { return nil }
        return lesson.questions[currentIndex]
    }

    /// Handles a user answer.  Evaluates correctness and advances to the
    /// next question or marks the lesson finished.  Correctness is
    /// published so the view can provide feedback.
    func answer(choiceAt index: Int) {
        guard let question = currentQuestion else { return }
        let isCorrect = question.isCorrectChoice(at: index)
        lastAnswerCorrect = isCorrect
        analytics.log(event: .questionAnswered(correct: isCorrect))

        // Advance to next question after a short delay to allow for
        // feedback animations.  Use DispatchQueue to simulate asynchronous
        // behaviour; in the real app this might be triggered by the view.
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) { [weak self] in
            guard let self = self else { return }
            self.advance()
        }
    }

    private func advance() {
        // Reset answer state
        lastAnswerCorrect = nil
        let nextIndex = currentIndex + 1
        if nextIndex < lesson.questions.count {
            currentIndex = nextIndex
        } else {
            finishLesson()
        }
    }

    private func finishLesson() {
        isFinished = true
        // Persist completion
        markLessonCompleted(lesson)
        analytics.log(event: .lessonCompleted(grade: grade.rawValue, lessonID: lesson.id))
    }
}