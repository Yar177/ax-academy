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

    public init(id: String, title: String, description: String, questions: [Question]) {
        self.id = id
        self.title = title
        self.description = description
        self.questions = questions
    }
}
