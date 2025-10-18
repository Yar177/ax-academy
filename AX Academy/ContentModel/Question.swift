import Foundation

/// Supported strategies for scaffolding a question.  Strategies map to the
/// adaptive hints surfaced inside a lesson session.
public enum QuestionStrategy: String, Codable, Hashable {
    case visual
    case tactile
    case verbal
}

/// A single multiple choice question.  Each question has a unique identifier
/// so progress can be recorded.  The `choices` array should contain at least
/// two elements.  The `correctIndex` references the position within the
/// `choices` array that holds the correct answer.  Questions now include
/// optional voice prompts and hint strings so kindergarten lessons can provide
/// touch/voice guidance with adaptive scaffolds.
public struct Question: Identifiable, Codable, Hashable {
    public var id: UUID
    public var prompt: String
    public var choices: [String]
    public var correctIndex: Int
    /// Optional narration that is spoken by the lesson session when the
    /// question is presented.
    public var voicePrompt: String?
    /// Ordered hints that gradually reveal more support.  The session shows
    /// the next hint after each incorrect attempt or when the learner taps the
    /// hint button.
    public var hints: [String]
    /// Describes the touch interaction or manipulative to focus on (e.g. "tap
    /// the group with more objects").  Displayed alongside hints to support
    /// tactile learners.
    public var tactileGuidance: String?
    /// The dominant strategy used by the question.  Helps the view model select
    /// an appropriate hint tone.
    public var strategy: QuestionStrategy

    public init(id: UUID = UUID(),
                prompt: String,
                choices: [String],
                correctIndex: Int,
                voicePrompt: String? = nil,
                hints: [String] = [],
                tactileGuidance: String? = nil,
                strategy: QuestionStrategy = .visual) {
        self.id = id
        self.prompt = prompt
        self.choices = choices
        self.correctIndex = correctIndex
        self.voicePrompt = voicePrompt
        self.hints = hints
        self.tactileGuidance = tactileGuidance
        self.strategy = strategy
    }

    /// Returns whether the choice at the given index is correct.
    public func isCorrectChoice(at index: Int) -> Bool {
        return index == correctIndex
    }
}
