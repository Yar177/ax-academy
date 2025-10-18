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
                id: "g1_placeValue_blocks",
                title: "Place Value & Base-Ten Blocks",
                description: "Build two-digit numbers using tens and ones blocks.",
                questions: [
                    Question(
                        prompt: "Which blocks make the number 34?",
                        choices: [
                            "3 tens and 4 ones",
                            "4 tens and 3 ones",
                            "34 ones"
                        ],
                        correctIndex: 0,
                        interaction: .baseTenBlocks,
                        hint: "Count groups of ten first."
                    ),
                    Question(
                        prompt: "You see 5 tens and 2 ones. What number is shown?",
                        choices: ["52", "25", "7"],
                        correctIndex: 0,
                        interaction: .baseTenBlocks
                    ),
                    Question(
                        prompt: "Choose the blocks that show 48.",
                        choices: [
                            "4 tens and 8 ones",
                            "8 tens and 4 ones",
                            "40 ones and 8 tens"
                        ],
                        correctIndex: 0,
                        interaction: .baseTenBlocks
                    )
                ],
                mode: .placeValue,
                unlockRequirement: UnlockRequirement(kind: .kindergartenMastery),
                challengeSets: [
                    ChallengeSet(
                        id: "g1_placeValue_challenge",
                        title: "Expanded Form Challenge",
                        questions: [
                            Question(
                                prompt: "Which number matches 6 tens and 7 ones?",
                                choices: ["76", "67", "607"],
                                correctIndex: 1,
                                interaction: .baseTenBlocks
                            ),
                            Question(
                                prompt: "Select the blocks for 90.",
                                choices: ["9 tens", "9 ones", "90 ones"],
                                correctIndex: 0,
                                interaction: .baseTenBlocks
                            )
                        ],
                        threshold: 3
                    )
                ],
                remediation: [
                    RemediationLink(
                        kindergartenLessonID: "kg_counting",
                        message: "Review counting sets to strengthen place value understanding."
                    )
                ]
            ),
            Lesson(
                id: "g1_wordProblems_multiStep",
                title: "Multi-Step Word Problems",
                description: "Solve word problems by working through each step.",
                questions: [
                    Question(
                        prompt: "Mia has 6 stickers. She buys 4 more and gives 3 to a friend. How many stickers does she have now?",
                        choices: ["7", "9", "13"],
                        correctIndex: 0,
                        interaction: .wordProblem,
                        steps: [
                            QuestionStep(prompt: "Start with 6 stickers and add 4. What do you get?", choices: ["9", "10", "12"], correctIndex: 1, hint: "6 + 4"),
                            QuestionStep(prompt: "Now subtract the 3 she gave away.", choices: ["7", "9", "11"], correctIndex: 0, hint: "10 - 3")
                        ]
                    ),
                    Question(
                        prompt: "A class reads 8 pages on Monday and 7 pages on Tuesday. They need to read 5 more pages to finish the book. How many pages are in the book?",
                        choices: ["15", "20", "25"],
                        correctIndex: 1,
                        interaction: .wordProblem,
                        steps: [
                            QuestionStep(prompt: "How many pages after Monday and Tuesday?", choices: ["15", "16", "17"], correctIndex: 0),
                            QuestionStep(prompt: "Add the last 5 pages.", choices: ["18", "19", "20"], correctIndex: 2)
                        ]
                    ),
                    Question(
                        prompt: "There are 12 apples. Sara cuts them into groups of 3 to share equally. How many groups does she make?",
                        choices: ["3", "4", "6"],
                        correctIndex: 1,
                        interaction: .wordProblem,
                        steps: [
                            QuestionStep(prompt: "How many groups if each has 3 apples?", choices: ["3", "4", "5"], correctIndex: 1)
                        ]
                    )
                ],
                mode: .wordProblems,
                unlockRequirement: UnlockRequirement(kind: .unitCompleted, value: "g1_placeValue_blocks"),
                challengeSets: [
                    ChallengeSet(
                        id: "g1_wordProblems_challenge",
                        title: "Extended Word Problems",
                        questions: [
                            Question(
                                prompt: "A field trip bus holds 10 students. Three buses are full and 4 students still need seats. How many students are going?",
                                choices: ["30", "34", "40"],
                                correctIndex: 1,
                                interaction: .wordProblem
                            )
                        ],
                        threshold: 2
                    )
                ],
                remediation: [
                    RemediationLink(
                        kindergartenLessonID: "kg_arithmetic",
                        message: "Review Kindergarten addition and subtraction stories before retrying."
                    )
                ]
            ),
            Lesson(
                id: "g1_fractions_intro",
                title: "Introductory Fractions",
                description: "Understand halves and quarters as equal shares.",
                questions: [
                    Question(
                        prompt: "Which picture shows one half?",
                        choices: ["Two equal parts shaded", "One of four parts shaded", "Three parts shaded"],
                        correctIndex: 0,
                        interaction: .fractions
                    ),
                    Question(
                        prompt: "A pizza is cut into 4 equal slices. You eat one slice. What fraction of the pizza did you eat?",
                        choices: ["1/2", "1/3", "1/4"],
                        correctIndex: 2,
                        interaction: .fractions
                    ),
                    Question(
                        prompt: "Choose the fraction that means two equal parts out of four are shaded.",
                        choices: ["1/2", "2/4", "2/3"],
                        correctIndex: 1,
                        interaction: .fractions
                    )
                ],
                mode: .fractions,
                unlockRequirement: UnlockRequirement(kind: .unitCompleted, value: "g1_wordProblems_multiStep"),
                challengeSets: [
                    ChallengeSet(
                        id: "g1_fractions_challenge",
                        title: "Fraction Match",
                        questions: [
                            Question(
                                prompt: "Which is the same as 1/2?",
                                choices: ["2/4", "1/3", "3/6"],
                                correctIndex: 0,
                                interaction: .fractions
                            ),
                            Question(
                                prompt: "Which picture shows 3/4?",
                                choices: ["Three out of four parts shaded", "One out of four parts shaded", "Two out of three parts shaded"],
                                correctIndex: 0,
                                interaction: .fractions
                            )
                        ],
                        threshold: 3
                    )
                ],
                remediation: [
                    RemediationLink(
                        kindergartenLessonID: "kg_shapes",
                        message: "Review equal parts with Kindergarten shapes."
                    )
                ]
            ),
            Lesson(
                id: "g1_time_halfHour",
                title: "Telling Time",
                description: "Tell and write time to the hour and half hour.",
                questions: [
                    Question(
                        prompt: "The hour hand points to 3 and the minute hand points to 12. What time is it?",
                        choices: ["3:00", "3:30", "12:30"],
                        correctIndex: 0,
                        interaction: .timeMatching
                    ),
                    Question(
                        prompt: "The minute hand points to 6 and the hour hand points between 2 and 3. What time is it?",
                        choices: ["2:30", "3:30", "6:00"],
                        correctIndex: 0,
                        interaction: .timeMatching
                    ),
                    Question(
                        prompt: "Which clock shows 5:30?",
                        choices: ["Hour hand at 5, minute hand at 6", "Hour hand at 6, minute hand at 5", "Hour hand at 12, minute hand at 5"],
                        correctIndex: 0,
                        interaction: .timeMatching
                    )
                ],
                mode: .time,
                unlockRequirement: UnlockRequirement(kind: .unitCompleted, value: "g1_fractions_intro"),
                challengeSets: [
                    ChallengeSet(
                        id: "g1_time_challenge",
                        title: "Elapsed Time",
                        questions: [
                            Question(
                                prompt: "School starts at 8:30. Recess is 2 hours later. What time is recess?",
                                choices: ["9:30", "10:30", "11:30"],
                                correctIndex: 1,
                                interaction: .timeMatching
                            )
                        ],
                        threshold: 3
                    )
                ],
                remediation: [
                    RemediationLink(
                        kindergartenLessonID: "kg_counting",
                        message: "Review counting by fives to track minutes on the clock."
                    )
                ]
            ),
            Lesson(
                id: "g1_money_countCoins",
                title: "Money & Coins",
                description: "Count collections of coins to find the total value.",
                questions: [
                    Question(
                        prompt: "Two dimes and one nickel equals how much money?",
                        choices: ["20¢", "25¢", "30¢"],
                        correctIndex: 1,
                        interaction: .moneyCounting
                    ),
                    Question(
                        prompt: "Which set shows 35¢?",
                        choices: ["One quarter and one dime", "Three dimes and one nickel", "Seven nickels"],
                        correctIndex: 1,
                        interaction: .moneyCounting
                    ),
                    Question(
                        prompt: "You have 4 nickels. How much is that?",
                        choices: ["15¢", "20¢", "25¢"],
                        correctIndex: 1,
                        interaction: .moneyCounting
                    )
                ],
                mode: .money,
                unlockRequirement: UnlockRequirement(kind: .unitCompleted, value: "g1_time_halfHour"),
                challengeSets: [
                    ChallengeSet(
                        id: "g1_money_challenge",
                        title: "Change Maker",
                        questions: [
                            Question(
                                prompt: "A toy costs 42¢. Which coins make exactly 42¢?",
                                choices: ["1 quarter, 1 dime, 1 nickel, 2 pennies", "4 dimes, 2 pennies", "3 nickels, 1 dime, 2 pennies"],
                                correctIndex: 0,
                                interaction: .moneyCounting
                            )
                        ],
                        threshold: 3
                    )
                ],
                remediation: [
                    RemediationLink(
                        kindergartenLessonID: "kg_arithmetic",
                        message: "Review Kindergarten addition stories to support coin counting."
                    )
                ]
            ),
            Lesson(
                id: "g1_data_pictureGraphs",
                title: "Data & Picture Graphs",
                description: "Read and interpret simple picture graphs.",
                questions: [
                    Question(
                        prompt: "A picture graph shows 4 apples, 2 bananas, and 3 oranges. Which fruit has the most?",
                        choices: ["Apples", "Bananas", "Oranges"],
                        correctIndex: 0,
                        interaction: .dataAnalysis
                    ),
                    Question(
                        prompt: "How many pieces of fruit are there in total?",
                        choices: ["7", "8", "9"],
                        correctIndex: 2,
                        interaction: .dataAnalysis
                    ),
                    Question(
                        prompt: "If one more banana is added, how many bananas are there now?",
                        choices: ["2", "3", "4"],
                        correctIndex: 1,
                        interaction: .dataAnalysis
                    )
                ],
                mode: .data,
                unlockRequirement: UnlockRequirement(kind: .unitCompleted, value: "g1_money_countCoins"),
                challengeSets: [
                    ChallengeSet(
                        id: "g1_data_challenge",
                        title: "Compare & Interpret",
                        questions: [
                            Question(
                                prompt: "A bar graph shows 12 cats, 9 dogs, and 6 fish adopted. How many more cats than fish were adopted?",
                                choices: ["2", "4", "6"],
                                correctIndex: 2,
                                interaction: .dataAnalysis
                            )
                        ],
                        threshold: 3
                    )
                ],
                remediation: [
                    RemediationLink(
                        kindergartenLessonID: "kg_shapes",
                        message: "Review sorting shapes in Kindergarten to support data grouping."
                    )
                ]
            )
        ]
    }

}