import Foundation

/// A protocol for retrieving curriculum content.  Conforming types return
/// lessons for a given grade.  In production this could load from JSON or a
/// network service; here we define a static provider for demonstration.
public protocol ContentProviding {
    /// Returns all lessons available for the specified grade.
    func lessons(for grade: Grade) -> [Lesson]
}

/// A simple content provider that returns static lessons defined in code.
/// Lessons are based on typical kindergarten and first grade curriculum
/// topics【124221548192575†L245-L269】【8868879203866†L39-L124】.  New subjects can be added by
/// extending the `Grade` enumeration and adding corresponding cases here.
public final class StaticContentProvider: ContentProviding {
    public init() {}

    public func lessons(for grade: Grade) -> [Lesson] {
        switch grade {
        case .kindergarten:
            return kindergartenLessons
        case .grade1:
            return grade1Lessons
        }
    }

    // MARK: - Sample Lessons

    private var kindergartenLessons: [Lesson] {
        return [
            Lesson(
                id: "kg_counting",
                title: "Counting to Five",
                description: "Let's practice counting and recognising numbers up to five.",
                questions: [
                    Question(prompt: "What number comes after 4?", choices: ["3", "5", "6"], correctIndex: 1),
                    Question(prompt: "How many balloons? 🎈🎈🎈", choices: ["3", "4", "5"], correctIndex: 0),
                    Question(prompt: "Which set has more? 🍎🍎 or 🍎🍎🍎", choices: ["Two apples", "Three apples", "They are the same"], correctIndex: 1)
                ]
            ),
            Lesson(
                id: "kg_shapes",
                title: "Shapes",
                description: "Identify common shapes.",
                questions: [
                    Question(prompt: "Which shape has three sides?", choices: ["Triangle", "Square", "Circle"], correctIndex: 0),
                    Question(prompt: "Which shape is round?", choices: ["Triangle", "Square", "Circle"], correctIndex: 2),
                    Question(prompt: "Which shape has four equal sides?", choices: ["Triangle", "Square", "Rectangle"], correctIndex: 1)
                ]
            ),
            Lesson(
                id: "kg_arithmetic",
                title: "Adding and Subtracting",
                description: "Simple addition and subtraction within ten.",
                questions: [
                    Question(prompt: "3 + 2 = ?", choices: ["4", "5", "6"], correctIndex: 1),
                    Question(prompt: "5 - 1 = ?", choices: ["3", "4", "5"], correctIndex: 1),
                    Question(prompt: "2 + 4 = ?", choices: ["6", "7", "8"], correctIndex: 0)
                ]
            )
        ]
    }

    private var grade1Lessons: [Lesson] {
        return [
            Lesson(
                id: "g1_addSubWithin20",
                title: "Addition and Subtraction Facts",
                description: "Practice addition and subtraction facts up to 20【8868879203866†L39-L60】.",
                questions: [
                    Question(prompt: "9 + 8 = ?", choices: ["15", "16", "17"], correctIndex: 2),
                    Question(prompt: "14 - 5 = ?", choices: ["8", "9", "10"], correctIndex: 1),
                    Question(prompt: "10 + 7 = ?", choices: ["16", "17", "18"], correctIndex: 1)
                ]
            ),
            Lesson(
                id: "g1_inverse",
                title: "Inverse Operations",
                description: "See how addition and subtraction are related【8868879203866†L54-L61】.",
                questions: [
                    Question(prompt: "Which subtraction matches 5 + 2 = 7?", choices: ["7 - 2 = 5", "7 - 5 = 1", "5 - 2 = 3"], correctIndex: 0),
                    Question(prompt: "Which addition matches 9 - 4 = 5?", choices: ["5 + 4 = 9", "4 + 5 = 8", "9 + 4 = 5"], correctIndex: 0),
                    Question(prompt: "Which equation shows subtraction as the inverse of addition?", choices: ["6 + 3 = 9", "9 - 3 = 6", "8 + 1 = 9"], correctIndex: 1)
                ]
            ),
            Lesson(
                id: "g1_counting120",
                title: "Counting & Writing Numbers",
                description: "Count and write numbers up to 120【8868879203866†L68-L78】.",
                questions: [
                    Question(prompt: "What number comes after 119?", choices: ["110", "120", "121"], correctIndex: 1),
                    Question(prompt: "How is 'one hundred and twelve' written?", choices: ["112", "120", "102"], correctIndex: 0),
                    Question(prompt: "How many tens are in 76?", choices: ["7", "6", "76"], correctIndex: 0)
                ]
            ),
            Lesson(
                id: "g1_addWithin100",
                title: "Adding Within 100",
                description: "Add numbers within 100 using place value strategies【8868879203866†L80-L94】.",
                questions: [
                    Question(prompt: "25 + 30 = ?", choices: ["55", "65", "45"], correctIndex: 0),
                    Question(prompt: "45 + 10 = ?", choices: ["35", "55", "65"], correctIndex: 1),
                    Question(prompt: "63 + 20 = ?", choices: ["73", "83", "93"], correctIndex: 1)
                ]
            ),
            Lesson(
                id: "g1_time",
                title: "Telling Time",
                description: "Learn to tell time to the hour and half hour【8868879203866†L107-L117】.",
                questions: [
                    Question(prompt: "If the big hand is on 12 and the small hand is on 3, what time is it?", choices: ["3:00", "6:00", "12:30"], correctIndex: 0),
                    Question(prompt: "If the big hand is on 6 and the small hand is on 4, what time is it?", choices: ["4:00", "4:30", "5:30"], correctIndex: 1),
                    Question(prompt: "If the big hand is on 12 and the small hand is on 7, what time is it?", choices: ["7:00", "7:30", "12:30"], correctIndex: 0)
                ]
            ),
            Lesson(
                id: "g1_fractions",
                title: "Basic Fractions",
                description: "Understand equal shares and simple fractions【8868879203866†L119-L124】.",
                questions: [
                    Question(prompt: "Which fraction represents one half?", choices: ["1/2", "1/3", "1/4"], correctIndex: 0),
                    Question(prompt: "Divide 8 apples equally among 4 friends. How many apples does each friend get?", choices: ["2", "4", "8"], correctIndex: 0),
                    Question(prompt: "What is one quarter of 12?", choices: ["3", "4", "6"], correctIndex: 0)
                ]
            )
        ]
    }
}