import Foundation

/// Describes the interaction style used to answer a question.  Multiple
/// choice remains the default, but Grade 1 introduces richer modalities like
/// base‑ten block matching or data interpretation.
public enum QuestionInteraction: String, Codable, Hashable {
    case multipleChoice
    case baseTenBlocks
    case wordProblem
    case fractions
    case timeMatching
    case moneyCounting
    case dataAnalysis
}

/// Represents a step in a multi-part question.  Each step behaves like a
/// small multiple-choice prompt.  Steps allow us to scaffold multi-step word
/// problems while reusing the core interaction pattern.
public struct QuestionStep: Identifiable, Codable, Hashable {
    public var id: UUID
    public var prompt: String
    public var choices: [String]
    public var correctIndex: Int
    public var hint: String?

    public init(id: UUID = UUID(),
                prompt: String,
                choices: [String],
                correctIndex: Int,
                hint: String? = nil) {
        self.id = id
        self.prompt = prompt
        self.choices = choices
        self.correctIndex = correctIndex
        self.hint = hint
    }

    func isCorrectChoice(at index: Int) -> Bool {
        index == correctIndex
    }
}

/// A single question which may be answered directly or through a sequence of
/// guided steps.  The `choices` array should contain at least two options.  For
/// multi-step questions, the `steps` array stores each scaffolded prompt.  The
/// default `interaction` is `.multipleChoice` so existing Kindergarten content
/// continues to work without modification.
public struct Question: Identifiable, Codable, Hashable {
    public var id: UUID
    public var prompt: String
    public var choices: [String]
    public var correctIndex: Int
    public var interaction: QuestionInteraction
    public var steps: [QuestionStep]
    public var hint: String?

    public init(id: UUID = UUID(),
                prompt: String,
                choices: [String],
                correctIndex: Int,
                interaction: QuestionInteraction = .multipleChoice,
                steps: [QuestionStep] = [],
                hint: String? = nil) {
        self.id = id
        self.prompt = prompt
        self.choices = choices
        self.correctIndex = correctIndex
        self.interaction = interaction
        self.steps = steps
        self.hint = hint
    }

    /// Returns whether the choice at the given index is correct.  When the
    /// question contains multi-step scaffolding this method evaluates the
    /// active step; otherwise it falls back to the primary `correctIndex`.
    public func isCorrectChoice(at index: Int, step stepIndex: Int? = nil) -> Bool {
        if let stepIndex = stepIndex, stepIndex < steps.count {
            return steps[stepIndex].isCorrectChoice(at: index)
        }
        return index == correctIndex
    }

    /// Compatibility helper used by existing callers that do not provide a
    /// step index.
    public func isCorrectChoice(at index: Int) -> Bool {
        isCorrectChoice(at: index, step: nil)
    }
}
