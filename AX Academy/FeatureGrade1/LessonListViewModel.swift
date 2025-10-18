import Foundation
import Combine

/// View model for the Grade 1 navigation experience.  It organises lessons
/// into curriculum units, enforces unlock criteria based on Kindergarten
/// mastery or diagnostic placement, and surfaces goal-tracking data for the
/// progress dashboard.
final class Grade1LessonListViewModel: BaseViewModel {
    struct UnitPresentation: Identifiable {
        let id: String
        let mode: LessonMode
        let title: String
        let description: String
        let iconName: String
        let lessons: [Lesson]
        let isUnlocked: Bool
        let unlockDescription: String
        let progress: Double
        let completedLessons: Int

        var isCompleted: Bool {
            !lessons.isEmpty && completedLessons == lessons.count
        }
    }

    struct GoalProgressSnapshot {
        let progress: Double
        let completedLessons: Int
        let totalLessons: Int
        let nextMilestoneTitle: String?
        let kindergartenMastered: Bool
        let diagnosticPassed: Bool

        var shouldShowDiagnosticPrompt: Bool {
            !kindergartenMastered && !diagnosticPassed
        }
    }

    @Published private(set) var lessons: [Lesson]
    @Published private(set) var unitMap: [UnitPresentation] = []
    @Published private(set) var goalProgress: GoalProgressSnapshot

    let grade: Grade
    let analytics: AnalyticsLogging
    let persistence: Persistence
    let kindergartenLessons: [Lesson]

    private let diagnosticKey = "grade1.diagnostic.passed"
    private var unlockedUnitIDs: Set<String> = []
    private var lastProgressTuple: (completed: Int, total: Int)? = nil

    init(grade: Grade,
         lessons: [Lesson],
         kindergartenLessons: [Lesson],
         analytics: AnalyticsLogging,
         persistence: Persistence) {
        self.grade = grade
        self.lessons = lessons
        self.kindergartenLessons = kindergartenLessons
        self.analytics = analytics
        self.persistence = persistence
        self.goalProgress = GoalProgressSnapshot(progress: 0, completedLessons: 0, totalLessons: lessons.count, nextMilestoneTitle: lessons.first?.title, kindergartenMastered: false, diagnosticPassed: persistence.bool(forKey: diagnosticKey) ?? false)
        super.init()
        analytics.log(event: .screenPresented(name: "\(grade.displayName) Lesson Map"))
        refreshSnapshot()
    }

    func isLessonCompleted(_ lesson: Lesson) -> Bool {
        persistence.bool(forKey: completionKey(for: lesson)) ?? false
    }

    func markLessonCompleted(_ lesson: Lesson) {
        persistence.set(true, forKey: completionKey(for: lesson))
        refreshSnapshot()
    }

    func completeDiagnosticPlacement() {
        persistence.set(true, forKey: diagnosticKey)
        analytics.log(event: .diagnosticCompleted(grade: grade.rawValue))
        refreshSnapshot()
    }

    func diagnosticPassed() -> Bool {
        persistence.bool(forKey: diagnosticKey) ?? false
    }

    func kindergartenMastered() -> Bool {
        kindergartenLessons.allSatisfy { lesson in
            let key = "\(Grade.kindergarten.rawValue).lessonCompleted.\(lesson.id)"
            return persistence.bool(forKey: key) ?? false
        }
    }

    private func refreshSnapshot() {
        let kgMastered = kindergartenMastered()
        let diagnostic = diagnosticPassed()

        let orderedModes: [LessonMode] = [.placeValue, .wordProblems, .fractions, .time, .money, .data]
        var updatedUnits: [UnitPresentation] = []

        for mode in orderedModes {
            let unitLessons = lessons.filter { $0.mode == mode }
            guard let firstLesson = unitLessons.first else { continue }
            let completedCount = unitLessons.filter { isLessonCompleted($0) }.count
            let progress = unitLessons.isEmpty ? 0 : Double(completedCount) / Double(unitLessons.count)
            let requirement = firstLesson.unlockRequirement
            let unlocked = isRequirementSatisfied(requirement, kindergartenMastered: kgMastered, diagnosticPassed: diagnostic)
            let unlockDescription = requirementDescription(requirement, kindergartenMastered: kgMastered, diagnosticPassed: diagnostic)
            let unit = UnitPresentation(
                id: mode.rawValue,
                mode: mode,
                title: unitTitle(for: mode, default: firstLesson.title),
                description: firstLesson.description,
                iconName: iconName(for: mode),
                lessons: unitLessons,
                isUnlocked: unlocked,
                unlockDescription: unlockDescription,
                progress: progress,
                completedLessons: completedCount
            )
            updatedUnits.append(unit)
        }

        let newlyUnlocked = Set(updatedUnits.filter { $0.isUnlocked }.map { $0.id })
        let newUnlocks = newlyUnlocked.subtracting(unlockedUnitIDs)
        newUnlocks.forEach { id in
            analytics.log(event: .gradeUnitUnlocked(grade: grade.rawValue, unitID: id))
        }
        unlockedUnitIDs = newlyUnlocked
        unitMap = updatedUnits

        let completedLessons = lessons.filter { isLessonCompleted($0) }.count
        let totalLessons = lessons.count
        let progress = totalLessons == 0 ? 0 : Double(completedLessons) / Double(totalLessons)
        let nextMilestone = updatedUnits.first(where: { !$0.isCompleted })?.title
        goalProgress = GoalProgressSnapshot(progress: progress,
                                            completedLessons: completedLessons,
                                            totalLessons: totalLessons,
                                            nextMilestoneTitle: nextMilestone,
                                            kindergartenMastered: kgMastered,
                                            diagnosticPassed: diagnostic)

        let tuple = (completed: completedLessons, total: totalLessons)
        if lastProgressTuple != tuple {
            analytics.log(event: .gradeGoalProgressUpdated(grade: grade.rawValue,
                                                           completedLessons: completedLessons,
                                                           totalLessons: totalLessons))
            lastProgressTuple = tuple
        }
    }

    private func requirementDescription(_ requirement: UnlockRequirement,
                                         kindergartenMastered: Bool,
                                         diagnosticPassed: Bool) -> String {
        switch requirement.kind {
        case .always:
            return "Start learning!"
        case .kindergartenMastery:
            if kindergartenMastered || diagnosticPassed { return "Unlocked by mastery" }
            return "Complete Kindergarten lessons or pass the placement check."
        case .diagnostic:
            if diagnosticPassed { return "Placement passed" }
            return "Pass the placement check to unlock."
        case .unitCompleted:
            guard let lessonID = requirement.value,
                  let title = lessons.first(where: { $0.id == lessonID })?.title else {
                return "Complete the previous unit."
            }
            return "Finish \(title) to unlock."
        }
    }

    private func isRequirementSatisfied(_ requirement: UnlockRequirement,
                                        kindergartenMastered: Bool,
                                        diagnosticPassed: Bool) -> Bool {
        switch requirement.kind {
        case .always:
            return true
        case .kindergartenMastery:
            return kindergartenMastered || diagnosticPassed
        case .diagnostic:
            return diagnosticPassed
        case .unitCompleted:
            guard let lessonID = requirement.value else { return true }
            return persistence.bool(forKey: completionKey(forLessonID: lessonID)) ?? false
        }
    }

    private func unitTitle(for mode: LessonMode, default fallback: String) -> String {
        switch mode {
        case .placeValue:
            return "Place Value Quest"
        case .wordProblems:
            return "Word Problem Workshop"
        case .fractions:
            return "Fraction Fair"
        case .time:
            return "Time Tellers"
        case .money:
            return "Money Mastery"
        case .data:
            return "Data Detectives"
        case .foundational:
            return fallback
        }
    }

    private func iconName(for mode: LessonMode) -> String {
        switch mode {
        case .placeValue:
            return "square.grid.3x3.fill"
        case .wordProblems:
            return "book.closed.fill"
        case .fractions:
            return "circle.lefthalf.fill"
        case .time:
            return "clock.fill"
        case .money:
            return "dollarsign.circle.fill"
        case .data:
            return "chart.bar.fill"
        case .foundational:
            return "star.fill"
        }
    }

    private func completionKey(for lesson: Lesson) -> String {
        "\(grade.rawValue).lessonCompleted.\(lesson.id)"
    }

    private func completionKey(forLessonID id: String) -> String {
        "\(grade.rawValue).lessonCompleted.\(id)"
    }
}
