import Foundation
import Combine

/// View model that manages a single Grade 1 lesson session.  It supports
/// adaptive difficulty by unlocking challenge sets and provides remediation
/// loops that reference prerequisite Kindergarten content when learners need
/// extra support.
final class Grade1LessonSessionViewModel: BaseViewModel {
    struct RemediationState: Identifiable {
        let id = UUID()
        let link: Lesson.RemediationLink
        let lesson: Lesson?
    }

    private enum Phase {
        case core
        case challenge(Lesson.ChallengeSet)
    }

    let lesson: Lesson
    @Published private(set) var currentIndex: Int = 0
    @Published private(set) var currentStepIndex: Int = 0
    @Published private(set) var isFinished: Bool = false
    @Published private(set) var lastAnswerCorrect: Bool? = nil
    @Published private(set) var remediationState: RemediationState? = nil
    @Published private(set) var isInChallengeMode: Bool = false
    @Published private(set) var completedQuestions: Int = 0

    private let grade: Grade
    private let analytics: AnalyticsLogging
    private let markLessonCompleted: (Lesson) -> Void
    private let kindergartenLessons: [Lesson]

    private let coreQuestions: [Question]
    private var remainingChallengeSets: [Lesson.ChallengeSet]
    private var currentPhase: Phase = .core
    private let remediationLinks: [Lesson.RemediationLink]
    private var correctCoreAnswers: Int = 0

    init(grade: Grade,
         lesson: Lesson,
         kindergartenLessons: [Lesson],
         analytics: AnalyticsLogging,
         markLessonCompleted: @escaping (Lesson) -> Void) {
        self.grade = grade
        self.lesson = lesson
        self.kindergartenLessons = kindergartenLessons
        self.analytics = analytics
        self.markLessonCompleted = markLessonCompleted
        self.coreQuestions = lesson.questions
        self.remainingChallengeSets = lesson.challengeSets
        self.remediationLinks = lesson.remediation
        super.init()
        analytics.log(event: .lessonStarted(grade: grade.rawValue, lessonID: lesson.id))
    }

    var currentQuestion: Question? {
        guard currentIndex < currentQuestions.count else { return nil }
        return currentQuestions[currentIndex]
    }

    var currentStep: QuestionStep? {
        guard let question = currentQuestion, !question.steps.isEmpty else { return nil }
        return question.steps[currentStepIndex]
    }

    var currentChoices: [String] {
        if let step = currentStep { return step.choices }
        return currentQuestion?.choices ?? []
    }

    var currentPrompt: String {
        if let step = currentStep { return step.prompt }
        return currentQuestion?.prompt ?? ""
    }

    var currentHint: String? {
        if let step = currentStep, !step.hint?.isEmpty ?? false { return step.hint }
        return currentQuestion?.hint
    }

    var totalCoreQuestions: Int { coreQuestions.count }

    var totalChallengeQuestions: Int {
        switch currentPhase {
        case .core:
            return 0
        case .challenge(let set):
            return set.questions.count
        }
    }

    func answer(choiceAt index: Int) {
        guard let question = currentQuestion else { return }
        let stepIndex = question.steps.isEmpty ? nil : currentStepIndex
        let correct = question.isCorrectChoice(at: index, step: stepIndex)
        lastAnswerCorrect = correct
        analytics.log(event: .questionAnswered(correct: correct))

        if correct {
            remediationState = nil
            if let stepIndex {
                if stepIndex < question.steps.count - 1 {
                    currentStepIndex += 1
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) { [weak self] in
                        self?.lastAnswerCorrect = nil
                    }
                    return
                }
                currentStepIndex = 0
            }

            if case .core = currentPhase { correctCoreAnswers += 1 }
            completedQuestions += 1
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) { [weak self] in
                self?.advance()
            }
        } else {
            presentRemediation(for: question)
        }
    }

    func acknowledgeRemediation() {
        if let remediationState {
            analytics.log(event: .remediationAcknowledged(grade: grade.rawValue,
                                                          kindergartenLessonID: remediationState.link.kindergartenLessonID,
                                                          lessonID: lesson.id))
        }
        remediationState = nil
        lastAnswerCorrect = nil
    }

    private var currentQuestions: [Question] {
        switch currentPhase {
        case .core:
            return coreQuestions
        case .challenge(let set):
            return set.questions
        }
    }

    private func advance() {
        lastAnswerCorrect = nil
        let next = currentIndex + 1
        if next < currentQuestions.count {
            currentIndex = next
            currentStepIndex = 0
        } else if isInChallengeMode {
            finishLesson()
        } else if let challenge = nextChallengeSet() {
            startChallenge(with: challenge)
        } else {
            finishLesson()
        }
    }

    private func nextChallengeSet() -> Lesson.ChallengeSet? {
        remainingChallengeSets.first(where: { correctCoreAnswers >= $0.threshold })
    }

    private func startChallenge(with set: Lesson.ChallengeSet) {
        currentPhase = .challenge(set)
        isInChallengeMode = true
        currentIndex = 0
        currentStepIndex = 0
        remainingChallengeSets.removeAll(where: { $0.id == set.id })
        analytics.log(event: .challengeSetPresented(grade: grade.rawValue,
                                                    lessonID: lesson.id,
                                                    challengeID: set.id))
    }

    private func presentRemediation(for question: Question) {
        guard remediationState == nil else { return }
        if let link = remediationLinks.first(where: { $0.questionIDs.isEmpty || $0.questionIDs.contains(question.id) }) {
            let lesson = kindergartenLessons.first(where: { $0.id == link.kindergartenLessonID })
            remediationState = RemediationState(link: link, lesson: lesson)
            analytics.log(event: .remediationSuggested(grade: grade.rawValue,
                                                       kindergartenLessonID: link.kindergartenLessonID,
                                                       lessonID: self.lesson.id))
        }
    }

    private func finishLesson() {
        isFinished = true
        markLessonCompleted(lesson)
        analytics.log(event: .lessonCompleted(grade: grade.rawValue, lessonID: lesson.id))
    }
}
