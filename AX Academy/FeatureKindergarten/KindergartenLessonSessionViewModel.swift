import Foundation
import Combine
import AVFoundation

/// View model that manages a single lesson session.  It iterates through
/// questions, evaluates answers and signals completion.  Analytics events are
/// logged when the lesson starts and completes, and when each question is
/// answered【8868879203866†L39-L60】.  Adaptive hints, voice guidance and formative
/// assessment logic are implemented here so the SwiftUI view stays declarative.
final class KindergartenLessonSessionViewModel: BaseViewModel {
    struct ProgressMetrics: Equatable {
        var answered: Int
        var correct: Int
        var total: Int

        var progressText: String {
            return "\(answered) / \(total)"
        }

        var score: Double {
            guard total > 0 else { return 0 }
            return Double(correct) / Double(total)
        }
    }

    struct AssessmentResult: Equatable {
        let kind: LessonAssessment.Kind
        let score: Double
        let passed: Bool
    }

    struct CompletionContext {
        let lesson: Lesson
        let passedAssessment: Bool
    }

    /// The lesson being presented.
    let lesson: Lesson
    /// The zero‑based index of the current question.
    @Published private(set) var currentIndex: Int = 0
    /// Whether the lesson has been completed.
    @Published private(set) var isFinished: Bool = false
    /// Indicates whether the last answer was correct.  When nil no answer
    /// has been submitted for the current question.
    @Published private(set) var lastAnswerCorrect: Bool? = nil
    /// The latest hint being displayed to the learner (if any).
    @Published private(set) var currentHint: String?
    /// Aggregated progress metrics used by the UI.
    @Published private(set) var progress: ProgressMetrics
    /// True when the completion view should play a mastery celebration.
    @Published private(set) var shouldCelebrateMastery: Bool = false
    /// Result of a formative assessment if the lesson includes one.
    @Published private(set) var assessmentResult: AssessmentResult?

    private let analytics: AnalyticsLogging
    private let persistence: Persistence
    private let grade: Grade
    private let completionHandler: (CompletionContext) -> Void
    private let speechSynthesizer = AVSpeechSynthesizer()

    private var requestedHintCount: Int = 0
    private var hasBegun = false

    init(grade: Grade,
         lesson: Lesson,
         analytics: AnalyticsLogging,
         persistence: Persistence,
         markLessonCompleted: @escaping (CompletionContext) -> Void) {
        self.grade = grade
        self.lesson = lesson
        self.analytics = analytics
        self.persistence = persistence
        self.completionHandler = markLessonCompleted
        self.progress = ProgressMetrics(answered: 0, correct: 0, total: lesson.questions.count)
        super.init()
        analytics.log(event: .lessonStarted(grade: grade.rawValue, lessonID: lesson.id))
        if let assessment = lesson.assessment {
            analytics.log(event: .assessmentPresented(kind: assessment.kind.rawValue, lessonID: lesson.id))
        }
    }

    /// Returns the current question.  If the lesson has finished this
    /// returns nil.
    var currentQuestion: Question? {
        guard currentIndex < lesson.questions.count else { return nil }
        return lesson.questions[currentIndex]
    }

    /// Whether the current lesson is a formative assessment.
    var assessmentKind: LessonAssessment.Kind? {
        lesson.assessment?.kind
    }

    /// Begins the session, triggering the initial voice prompt.
    func beginSession() {
        guard !hasBegun else { return }
        hasBegun = true
        speakCurrentPrompt()
    }

    /// Replays the voice prompt for the current question.
    func replayVoicePrompt() {
        speakCurrentPrompt()
    }

    /// Handles a user answer.  Evaluates correctness and advances to the
    /// next question or marks the lesson finished.  Correctness is
    /// published so the view can provide feedback.
    func answer(choiceAt index: Int) {
        guard let question = currentQuestion else { return }
        let isCorrect = question.isCorrectChoice(at: index)
        lastAnswerCorrect = isCorrect
        analytics.log(event: .questionAnswered(correct: isCorrect))

        if isCorrect {
            requestedHintCount = 0
            currentHint = nil
            recordCorrectAnswer(for: question)
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.45) { [weak self] in
                self?.advance()
            }
        } else {
            provideAdaptiveHint(for: question, escalate: true)
        }
    }

    /// Allows the learner to manually request the next hint.
    func requestHint() {
        guard let question = currentQuestion else { return }
        provideAdaptiveHint(for: question, escalate: false)
    }

    // MARK: - Private helpers

    private func advance() {
        lastAnswerCorrect = nil
        requestedHintCount = 0
        currentHint = nil
        let nextIndex = currentIndex + 1
        if nextIndex < lesson.questions.count {
            currentIndex = nextIndex
            speakCurrentPrompt()
        } else {
            finishLesson()
        }
    }

    private func recordCorrectAnswer(for question: Question) {
        progress.answered += 1
        progress.correct += 1
        persistence.set(true, forKey: progressKey(for: question))
    }

    private func provideAdaptiveHint(for question: Question, escalate: Bool) {
        guard !question.hints.isEmpty else { return }
        if escalate {
            requestedHintCount = min(requestedHintCount + 1, question.hints.count)
        } else {
            requestedHintCount = min(requestedHintCount + 1, question.hints.count)
        }
        let index = max(0, requestedHintCount - 1)
        if index < question.hints.count {
            currentHint = question.hints[index]
            analytics.log(event: .hintShown(lessonID: lesson.id, questionID: question.id, hintIndex: index))
        }
    }

    private func finishLesson() {
        isFinished = true
        speechSynthesizer.stopSpeaking(at: .immediate)

        var passed = true
        if let assessment = lesson.assessment {
            let score = progress.score
            passed = score >= assessment.masteryThreshold
            assessmentResult = AssessmentResult(kind: assessment.kind, score: score, passed: passed)
            analytics.log(event: .assessmentCompleted(kind: assessment.kind.rawValue,
                                                      lessonID: lesson.id,
                                                      passed: passed))
        }

        shouldCelebrateMastery = passed
        completionHandler(CompletionContext(lesson: lesson, passedAssessment: passed))
        analytics.log(event: .lessonCompleted(grade: grade.rawValue, lessonID: lesson.id))
    }

    private func speakCurrentPrompt() {
        guard let question = currentQuestion else { return }
        let prompt = question.voicePrompt ?? question.prompt
        speak(text: prompt)
    }

    private func speak(text: String) {
        speechSynthesizer.stopSpeaking(at: .immediate)
        let utterance = AVSpeechUtterance(string: text)
        utterance.voice = AVSpeechSynthesisVoice(language: "en-US")
        utterance.rate = AVSpeechUtteranceDefaultSpeechRate * 0.9
        speechSynthesizer.speak(utterance)
    }

    private func progressKey(for question: Question) -> String {
        return "\(grade.rawValue).lesson.\(lesson.id).question.\(question.id).correct"
    }
}
