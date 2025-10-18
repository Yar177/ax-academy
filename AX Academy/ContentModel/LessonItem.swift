import Foundation

/// Represents a single assessment or practice item within a lesson. Items can
/// reference multimedia assets for manipulatives or worked examples and include
/// localized hints and scaffolds for adaptive support.
public struct LessonItem: Identifiable, Codable, Hashable {
    public enum Kind: String, Codable, Hashable { case multipleChoice, multiSelect, openResponse, sequencing }

    public struct Choice: Identifiable, Codable, Hashable {
        public var id: String
        private var textValue: LocalizedText
        public var isCorrect: Bool

        public init(id: String, text: LocalizedText, isCorrect: Bool) {
            self.id = id
            self.textValue = text
            self.isCorrect = isCorrect
        }

        public var text: String { textValue.resolve() }

        private enum CodingKeys: String, CodingKey {
            case id
            case textValue = "text"
            case isCorrect
        }
    }

    public var id: String
    public var kind: Kind
    private var promptText: LocalizedText
    public var choices: [Choice]?
    private var hintTexts: [LocalizedText]
    private var scaffoldTexts: [LocalizedText]
    public var assetIDs: [String]
    public var standardIDs: [String]
    public var difficulty: Lesson.Difficulty?

    public init(id: String,
                kind: Kind,
                prompt: LocalizedText,
                choices: [Choice]?,
                hints: [LocalizedText],
                scaffolds: [LocalizedText],
                assetIDs: [String],
                standardIDs: [String],
                difficulty: Lesson.Difficulty?) {
        self.id = id
        self.kind = kind
        self.promptText = prompt
        self.choices = choices
        self.hintTexts = hints
        self.scaffoldTexts = scaffolds
        self.assetIDs = assetIDs
        self.standardIDs = standardIDs
        self.difficulty = difficulty
    }

    public var prompt: String { promptText.resolve() }
    public var hints: [String] { hintTexts.map { $0.resolve() } }
    public var scaffolds: [String] { scaffoldTexts.map { $0.resolve() } }

    /// Returns whether the choice at the provided index is correct. For items
    /// that do not support auto-grading the method returns `false`.
    public func isCorrectChoice(at index: Int) -> Bool {
        guard let choices, index >= 0, index < choices.count else { return false }
        return choices[index].isCorrect
    }

    private enum CodingKeys: String, CodingKey {
        case id
        case kind
        case promptText = "prompt"
        case choices
        case hintTexts = "hints"
        case scaffoldTexts = "scaffolds"
        case assetIDs
        case standardIDs
        case difficulty
    }
}
