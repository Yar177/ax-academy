import Foundation

/// A lesson groups a set of questions under a title and provides brief
/// instructions.  Lessons correspond loosely to curriculum units such as
/// counting or addition.  They have stable identifiers for analytics and
/// persistence.  In the future we can add metadata like duration or
/// dependencies between lessons.
public struct Lesson: Identifiable, Codable, Hashable {
    public var id: String
    public var title: String
    public var description: String
    public var questions: [Question]
    public var mode: LessonMode
    public var unlockRequirement: UnlockRequirement
    public var challengeSets: [ChallengeSet]
    public var remediation: [RemediationLink]

    public init(id: String,
                title: String,
                description: String,
                questions: [Question],
                mode: LessonMode = .foundational,
                unlockRequirement: UnlockRequirement = .always,
                challengeSets: [ChallengeSet] = [],
                remediation: [RemediationLink] = []) {
        self.id = id
        self.title = title
        self.description = description
        self.questions = questions
        self.mode = mode
        self.unlockRequirement = unlockRequirement
        self.challengeSets = challengeSets
        self.remediation = remediation
    }
}

/// Describes the presentation style and objective of a lesson.  This powers
/// the Grade 1 unit map and allows the UI to surface the correct interaction
/// pattern.
public enum LessonMode: String, Codable, Hashable {
    case foundational
    case placeValue
    case wordProblems
    case fractions
    case time
    case money
    case data
}

/// Controls how and when a lesson becomes available.  Some lessons unlock
/// after demonstrating Kindergarten mastery, others require completing a prior
/// Grade 1 milestone, and diagnostic placement can be used as an override.
public struct UnlockRequirement: Codable, Hashable {
    public enum Kind: String, Codable {
        case always
        case kindergartenMastery
        case diagnostic
        case unitCompleted
    }

    public var kind: Kind
    public var value: String?

    public static let always = UnlockRequirement(kind: .always)

    public init(kind: Kind, value: String? = nil) {
        self.kind = kind
        self.value = value
    }
}

/// A set of challenge questions that unlock when a learner demonstrates
/// mastery within the core lesson flow.  The `threshold` represents how many
/// core questions must be answered correctly to surface the challenge path.
public struct ChallengeSet: Codable, Hashable {
    public var id: String
    public var title: String
    public var questions: [Question]
    public var threshold: Int

    public init(id: String, title: String, questions: [Question], threshold: Int) {
        self.id = id
        self.title = title
        self.questions = questions
        self.threshold = threshold
    }
}

/// Links a Grade 1 misconception to prerequisite Kindergarten material.  The
/// UI presents these links when remediation loops are triggered so learners can
/// review the recommended Kindergarten lesson.
public struct RemediationLink: Codable, Hashable {
    public var kindergartenLessonID: String
    public var message: String
    public var questionIDs: [UUID]

    public init(kindergartenLessonID: String,
                message: String,
                questionIDs: [UUID] = []) {
        self.kindergartenLessonID = kindergartenLessonID
        self.message = message
        self.questionIDs = questionIDs
    }
}
