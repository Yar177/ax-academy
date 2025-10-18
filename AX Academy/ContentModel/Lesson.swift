import Foundation

/// A lesson represents an instructional experience for a single skill or small
/// cluster of skills. Lessons are authored in three variants—practice,
/// challenge, and remediation—and always include objectives, scaffolds, and a
/// mastery rule for analytics.
public struct Lesson: Identifiable, Codable, Hashable {
    public enum Variant: String, Codable, CaseIterable, Hashable { case practice, challenge, remediation }
    public enum Difficulty: String, Codable, CaseIterable, Hashable { case emerging, developing, secure, extending }

    public struct MasteryRule: Codable, Hashable {
        public var scoreThreshold: Double
        public var consecutiveCorrect: Int?
        public var minimumItems: Int
        public var notes: String?
    }

    public var id: String
    public var grade: Grade
    public var strandID: String
    public var skillIDs: [String]
    public var variant: Variant
    public var estimatedDurationMinutes: Int
    private var titleText: LocalizedText
    private var summaryText: LocalizedText
    private var objectivesTexts: [LocalizedText]
    public var difficulty: Difficulty
    public var items: [LessonItem]
    private var hintTexts: [LocalizedText]
    private var scaffoldTexts: [LocalizedText]
    public var masteryRule: MasteryRule
    public var assetIDs: [String]

    public init(id: String,
                grade: Grade,
                strandID: String,
                skillIDs: [String],
                variant: Variant,
                estimatedDurationMinutes: Int,
                title: LocalizedText,
                summary: LocalizedText,
                objectives: [LocalizedText],
                difficulty: Difficulty,
                items: [LessonItem],
                hints: [LocalizedText],
                scaffolds: [LocalizedText],
                masteryRule: MasteryRule,
                assetIDs: [String]) {
        self.id = id
        self.grade = grade
        self.strandID = strandID
        self.skillIDs = skillIDs
        self.variant = variant
        self.estimatedDurationMinutes = estimatedDurationMinutes
        self.titleText = title
        self.summaryText = summary
        self.objectivesTexts = objectives
        self.difficulty = difficulty
        self.items = items
        self.hintTexts = hints
        self.scaffoldTexts = scaffolds
        self.masteryRule = masteryRule
        self.assetIDs = assetIDs
    }

    public var title: String { titleText.resolve() }
    public var description: String { summaryText.resolve() }
    public var objectives: [String] { objectivesTexts.map { $0.resolve() } }
    public var hints: [String] { hintTexts.map { $0.resolve() } }
    public var scaffolds: [String] { scaffoldTexts.map { $0.resolve() } }

    /// Backwards compatibility for older code that references `questions`.
    public var questions: [LessonItem] { items }

    private enum CodingKeys: String, CodingKey {
        case id
        case grade
        case strandID
        case skillIDs
        case variant
        case estimatedDurationMinutes
        case titleText = "title"
        case summaryText = "summary"
        case objectivesTexts = "objectives"
        case difficulty
        case items
        case hintTexts = "hints"
        case scaffoldTexts = "scaffolds"
        case masteryRule
        case assetIDs
    }
}
