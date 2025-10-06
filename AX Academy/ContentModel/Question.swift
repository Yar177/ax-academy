import Foundation

/// A single multiple choice question.  Each question has a unique identifier
/// so progress can be recorded.  The `choices` array should contain at least
/// two elements.  The `correctIndex` references the position within the
/// `choices` array that holds the correct answer.
public struct Question: Identifiable, Codable, Hashable {
    public var id: UUID
    public var prompt: String
    public var choices: [String]
    public var correctIndex: Int

    public init(id: UUID = UUID(), prompt: String, choices: [String], correctIndex: Int) {
        self.id = id
        self.prompt = prompt
        self.choices = choices
        self.correctIndex = correctIndex
    }

    /// Returns whether the choice at the given index is correct.
    public func isCorrectChoice(at index: Int) -> Bool {
        return index == correctIndex
    }
}
