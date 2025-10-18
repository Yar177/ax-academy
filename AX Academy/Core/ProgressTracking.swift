import Foundation

/// Tracks learner progress for each lesson.  Only aggregated metrics are stored
/// so that personally identifiable information is never written to disk.
public struct LessonProgress: Codable, Equatable, Identifiable {
    public var id: String { lessonID }
    public let lessonID: String
    public var totalQuestions: Int
    public var correctAnswers: Int
    public var attempts: Int
    public var lastUpdated: Date

    public init(lessonID: String,
                totalQuestions: Int,
                correctAnswers: Int = 0,
                attempts: Int = 0,
                lastUpdated: Date = Date()) {
        self.lessonID = lessonID
        self.totalQuestions = totalQuestions
        self.correctAnswers = correctAnswers
        self.attempts = attempts
        self.lastUpdated = lastUpdated
    }

    public var accuracy: Double {
        guard attempts > 0 else { return 0 }
        return Double(correctAnswers) / Double(totalQuestions)
    }
}

public struct GradeProgress: Codable, Equatable {
    public var grade: Grade
    public var lessons: [LessonProgress]

    public init(grade: Grade, lessons: [LessonProgress] = []) {
        self.grade = grade
        self.lessons = lessons
    }

    public var completedLessons: Int {
        lessons.filter { $0.correctAnswers >= $0.totalQuestions }.count
    }

    public var totalLessons: Int { lessons.count }

    public var overallAccuracy: Double {
        let totals = lessons.reduce((correct: 0, total: 0)) { partial, progress in
            (partial.correct + progress.correctAnswers,
             partial.total + progress.totalQuestions)
        }
        guard totals.total > 0 else { return 0 }
        return Double(totals.correct) / Double(totals.total)
    }
}

public protocol ProgressTracking {
    func recordAnswer(for grade: Grade, lessonID: String, totalQuestions: Int, wasCorrect: Bool)
    func progress(for grade: Grade) -> GradeProgress
    func allProgress() -> [GradeProgress]
    func reset()
}

public final class ProgressTracker: ProgressTracking {
    private let cache: OfflineCaching
    private let cacheKey = "progress.json"
    private var storage: [Grade.RawValue: GradeProgress]

    public init(cache: OfflineCaching) {
        self.cache = cache
        if let cached: [Grade.RawValue: GradeProgress] = cache.load([Grade.RawValue: GradeProgress].self, for: cacheKey) {
            self.storage = cached
        } else {
            self.storage = [:]
        }
    }

    public func recordAnswer(for grade: Grade, lessonID: String, totalQuestions: Int, wasCorrect: Bool) {
        var gradeProgress = storage[grade.rawValue] ?? GradeProgress(grade: grade)
        if let index = gradeProgress.lessons.firstIndex(where: { $0.lessonID == lessonID }) {
            var lessonProgress = gradeProgress.lessons[index]
            lessonProgress.attempts += 1
            if wasCorrect {
                lessonProgress.correctAnswers = min(lessonProgress.correctAnswers + 1, lessonProgress.totalQuestions)
            }
            lessonProgress.lastUpdated = Date()
            gradeProgress.lessons[index] = lessonProgress
        } else {
            var lessonProgress = LessonProgress(lessonID: lessonID, totalQuestions: totalQuestions)
            lessonProgress.attempts = 1
            if wasCorrect { lessonProgress.correctAnswers = min(1, totalQuestions) }
            gradeProgress.lessons.append(lessonProgress)
        }
        storage[grade.rawValue] = gradeProgress
        persist()
        NotificationCenter.default.post(name: .progressDidUpdate, object: nil)
    }

    public func progress(for grade: Grade) -> GradeProgress {
        storage[grade.rawValue] ?? GradeProgress(grade: grade)
    }

    public func allProgress() -> [GradeProgress] {
        storage.values.sorted { $0.grade.rawValue < $1.grade.rawValue }
    }

    public func reset() {
        storage = [:]
        persist()
    }

    private func persist() {
        cache.store(storage, for: cacheKey)
    }
}

public extension Notification.Name {
    static let progressDidUpdate = Notification.Name("ProgressDidUpdate")
}
