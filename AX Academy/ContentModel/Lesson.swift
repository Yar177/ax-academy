import Foundation

/// A badge represents a collectible reward earned by completing a learning
/// playlist.  Badges surface on the kindergarten home screen and are persisted
/// so learners can celebrate their progress over multiple sessions.
public struct BadgeReward: Identifiable, Codable, Hashable {
    public var id: String
    public var title: String
    public var detail: String
    public var imageName: String

    public init(id: String, title: String, detail: String, imageName: String) {
        self.id = id
        self.title = title
        self.detail = detail
        self.imageName = imageName
    }
}

/// Lesson playlists string related lessons into a purposeful path such as
/// "Counting Adventure" or "Shape Safari".  Each playlist may award a badge
/// once all lessons are mastered.
public struct LessonPlaylist: Identifiable, Codable, Hashable {
    public var id: String
    public var title: String
    public var description: String
    public var sequence: Int
    public var badge: BadgeReward?

    public init(id: String,
                title: String,
                description: String,
                sequence: Int,
                badge: BadgeReward? = nil) {
        self.id = id
        self.title = title
        self.description = description
        self.sequence = sequence
        self.badge = badge
    }

    /// A lightweight default playlist used when no explicit playlist metadata
    /// is provided.  This keeps backward compatibility with legacy lessons.
    public static let `default` = LessonPlaylist(id: "playlist.default",
                                                title: "Core Skills",
                                                description: "Foundational activities",
                                                sequence: 0,
                                                badge: nil)
}

/// The lesson topic drives the kindergarten home layout (topic carousels) and
/// unlocks contextual hints within a session.
public enum LessonTopic: String, Codable, CaseIterable, Hashable {
    case counting
    case numeralWriting
    case ordinalReasoning
    case operations
    case shapes
    case measurement
    case money
    case general

    public var displayName: String {
        switch self {
        case .counting: return "Counting"
        case .numeralWriting: return "Numeral Writing"
        case .ordinalReasoning: return "Ordinal Reasoning"
        case .operations: return "Operations"
        case .shapes: return "Shapes"
        case .measurement: return "Measurement"
        case .money: return "Money"
        case .general: return "Math Skills"
        }
    }

    public var symbolName: String {
        switch self {
        case .counting: return "123.rectangle"
        case .numeralWriting: return "pencil"
        case .ordinalReasoning: return "list.number"
        case .operations: return "plus.forwardslash.minus"
        case .shapes: return "square.on.circle"
        case .measurement: return "ruler"
        case .money: return "dollarsign.circle"
        case .general: return "sparkles"
        }
    }
}

/// Metadata describing formative assessments within a lesson.
public struct LessonAssessment: Codable, Hashable {
    public enum Kind: String, Codable, Hashable {
        case quickCheck
        case exitTicket
    }

    public var kind: Kind
    /// The mastery threshold represented as a 0...1 value.
    public var masteryThreshold: Double
    /// Teacher-facing summary of the assessment's focus.
    public var instructions: String

    public init(kind: Kind, masteryThreshold: Double, instructions: String) {
        self.kind = kind
        self.masteryThreshold = masteryThreshold
        self.instructions = instructions
    }
}

/// A lesson groups a set of questions under a title and provides brief
/// instructions.  Lessons correspond loosely to curriculum units such as
/// counting or addition.  They have stable identifiers for analytics and
/// persistence.  Metadata describes the playlist, badge and assessment context
/// so the kindergarten home can construct journey maps driven by content.
public struct Lesson: Identifiable, Codable, Hashable {
    public var id: String
    public var title: String
    public var description: String
    public var questions: [Question]
    public var topic: LessonTopic
    public var playlist: LessonPlaylist
    /// Order of the lesson inside its playlist for timeline presentation.
    public var playlistPosition: Int
    /// Optional badge awarded immediately after completing the lesson.
    public var badge: BadgeReward?
    /// Optional formative assessment metadata (quick checks, exit tickets).
    public var assessment: LessonAssessment?

    public init(id: String,
                title: String,
                description: String,
                questions: [Question],
                topic: LessonTopic = .general,
                playlist: LessonPlaylist = .default,
                playlistPosition: Int = 0,
                badge: BadgeReward? = nil,
                assessment: LessonAssessment? = nil) {
        self.id = id
        self.title = title
        self.description = description
        self.questions = questions
        self.topic = topic
        self.playlist = playlist
        self.playlistPosition = playlistPosition
        self.badge = badge
        self.assessment = assessment
    }

    /// Convenience flag used when building formative assessment UI.
    public var isAssessment: Bool {
        return assessment != nil
    }
}
