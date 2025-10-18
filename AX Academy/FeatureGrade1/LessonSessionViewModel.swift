import Foundation
import Combine

/// View model that manages a single Grade 1 lesson session.  It iterates
/// through questions, evaluates answers and signals completion.  Analytics
/// events are logged when the lesson starts and completes, and when each
/// question is answered.
final class Grade1LessonSessionViewModel: BaseViewModel {
    let lesson: Lesson
    @Published private(set) var currentIndex: Int = 0
    @Published private(set) var isFinished: Bool = false
    @Published private(set) var lastAnswerCorrect: Bool? = nil

    private let grade: Grade
    private let analytics: AnalyticsLogging
    private let persistence: Persistence
    private let markLessonCompleted: (Lesson) -> Void
    private let progressTracker: ProgressTracking

    init(grade: Grade,
         lesson: Lesson,
         analytics: AnalyticsLogging,
         persistence: Persistence,
         progressTracker: ProgressTracking,
         markLessonCompleted: @escaping (Lesson) -> Void) {
        self.grade = grade
        self.lesson = lesson
        self.analytics = analytics
        self.persistence = persistence
        self.markLessonCompleted = markLessonCompleted
        self.progressTracker = progressTracker
        super.init()
        analytics.log(event: .lessonStarted(grade: grade.rawValue, lessonID: lesson.id))
    }

    var currentQuestion: Question? {
        guard currentIndex < lesson.questions.count else { return nil }
        return lesson.questions[currentIndex]
    }

    func answer(choiceAt index: Int) {
        guard let question = currentQuestion else { return }
        let correct = question.isCorrectChoice(at: index)
        lastAnswerCorrect = correct
        analytics.log(event: .questionAnswered(correct: correct))
        progressTracker.recordAnswer(for: grade,
                                     lessonID: lesson.id,
                                     totalQuestions: lesson.questions.count,
                                     wasCorrect: correct)
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) { [weak self] in
            self?.advance()
        }
    }

    private func advance() {
        lastAnswerCorrect = nil
        let next = currentIndex + 1
        if next < lesson.questions.count {
            currentIndex = next
        } else {
            finishLesson()
        }
    }
    private func finishLesson() {
        isFinished = true
        markLessonCompleted(lesson)
        analytics.log(event: .lessonCompleted(grade: grade.rawValue, lessonID: lesson.id))
    }
}
