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
        let countingBadge = BadgeReward(id: "badge.kindergarten.counting",
                                        title: "Counting Star",
                                        detail: "Complete the counting journey",
                                        imageName: "star.circle.fill")
        let numeralsBadge = BadgeReward(id: "badge.kindergarten.numerals",
                                        title: "Number Scribe",
                                        detail: "Write numerals with confidence",
                                        imageName: "pencil.circle.fill")
        let shapesBadge = BadgeReward(id: "badge.kindergarten.shapes",
                                      title: "Shape Ranger",
                                      detail: "Spot shapes everywhere",
                                      imageName: "triangle.circle.fill")

        let countingPlaylist = LessonPlaylist(id: "kg.playlist.counting",
                                              title: "Counting Adventure",
                                              description: "Build counting fluency to five",
                                              sequence: 0,
                                              badge: countingBadge)
        let numeralsPlaylist = LessonPlaylist(id: "kg.playlist.numerals",
                                              title: "Numeral Workshop",
                                              description: "Write and recognise numerals",
                                              sequence: 1,
                                              badge: numeralsBadge)
        let ordinalPlaylist = LessonPlaylist(id: "kg.playlist.ordinal",
                                             title: "Order the Parade",
                                             description: "Reason about position words",
                                             sequence: 2,
                                             badge: nil)
        let operationsPlaylist = LessonPlaylist(id: "kg.playlist.operations",
                                                title: "Math Stories",
                                                description: "Act out simple addition and subtraction",
                                                sequence: 3,
                                                badge: nil)
        let shapesPlaylist = LessonPlaylist(id: "kg.playlist.shapes",
                                            title: "Shape Safari",
                                            description: "Describe two- and three-dimensional shapes",
                                            sequence: 4,
                                            badge: shapesBadge)
        let measurementPlaylist = LessonPlaylist(id: "kg.playlist.measurement",
                                                 title: "Measure & Compare",
                                                 description: "Use informal units to measure",
                                                 sequence: 5,
                                                 badge: nil)
        let moneyPlaylist = LessonPlaylist(id: "kg.playlist.money",
                                           title: "Play Store",
                                           description: "Explore coins through pretend play",
                                           sequence: 6,
                                           badge: nil)

        return [
            Lesson(
                id: "kg_counting_journey",
                title: "Counting Adventure",
                description: "Tap and count sets to five using touch and voice guidance.",
                questions: [
                    Question(prompt: "How many ladybugs are on the leaf? 🐞🐞🐞",
                             choices: ["2", "3", "5"],
                             correctIndex: 1,
                             voicePrompt: "Count the ladybugs out loud with me. How many do you see?",
                             hints: [
                                "Point to each ladybug as you count.",
                                "We counted together: one, two, three."
                             ],
                             tactileGuidance: "Tap each ladybug gently as you count.",
                             strategy: .tactile),
                    Question(prompt: "What number comes after 4?",
                             choices: ["3", "4", "5"],
                             correctIndex: 2,
                             voicePrompt: "Let's march from one to five. What comes after four?",
                             hints: [
                                "Say: one, two, three, four...", "The next number is the one we shout for a high five!"
                             ],
                             tactileGuidance: "Slide your finger along the number line to the next spot.",
                             strategy: .verbal),
                    Question(prompt: "Which group shows five? 🍎🍎🍎🍎🍎",
                             choices: ["🍎🍎🍎", "🍎🍎🍎🍎🍎", "🍎🍎"],
                             correctIndex: 1,
                             voicePrompt: "Look carefully at the apples. Which group has five?",
                             hints: [
                                "Touch and count each apple.",
                                "The group with five apples fills both hands."
                             ],
                             tactileGuidance: "Drag your finger under each apple as you count.",
                             strategy: .visual)
                ],
                topic: .counting,
                playlist: countingPlaylist,
                playlistPosition: 0
            ),
            Lesson(
                id: "kg_counting_quickcheck",
                title: "Quick Check: Counting to Five",
                description: "Show what you know about counting in a speedy check-in.",
                questions: [
                    Question(prompt: "Count the stars ⭐️⭐️⭐️⭐️. How many?",
                             choices: ["3", "4", "5"],
                             correctIndex: 1,
                             voicePrompt: "Count with me: one, two, three, four. What number did we say last?",
                             hints: [
                                "Touch each star once.",
                                "We counted to four together."
                             ],
                             tactileGuidance: "Tap the stars in a rhythm: tap-tap-tap-tap.",
                             strategy: .tactile),
                    Question(prompt: "Which picture shows fewer objects?",
                             choices: ["🎈🎈", "🎈🎈🎈🎈"],
                             correctIndex: 0,
                             voicePrompt: "Find the group that has less.",
                             hints: [
                                "Match one balloon from each group.",
                                "The smaller group stops matching sooner."
                             ],
                             tactileGuidance: "Slide balloons from one group to the other to compare.",
                             strategy: .visual)
                ],
                topic: .counting,
                playlist: countingPlaylist,
                playlistPosition: 1,
                assessment: LessonAssessment(kind: .quickCheck,
                                             masteryThreshold: 0.7,
                                             instructions: "Two-item pulse check on counting fluency")
            ),
            Lesson(
                id: "kg_numeral_writing",
                title: "Numeral Writing Workshop",
                description: "Trace numerals and connect them to quantities.",
                questions: [
                    Question(prompt: "Trace the number 2.",
                             choices: ["2", "3", "5"],
                             correctIndex: 0,
                             voicePrompt: "Start at the top and make a gentle curve for the number two.",
                             hints: [
                                "Draw a rainbow down, then a straight line across.",
                                "Two looks like a swan gliding on the lake."
                             ],
                             tactileGuidance: "Use one finger to trace over the glowing path.",
                             strategy: .tactile),
                    Question(prompt: "Which picture shows the number 4 written correctly?",
                             choices: ["④", "4️⃣", "4"],
                             correctIndex: 2,
                             voicePrompt: "Find the plain number four we write on paper.",
                             hints: [
                                "Look for the number without a circle or box.",
                                "It has one down line and one across line."
                             ],
                             tactileGuidance: "Tap the number you would see in a book.",
                             strategy: .visual)
                ],
                topic: .numeralWriting,
                playlist: numeralsPlaylist,
                playlistPosition: 0
            ),
            Lesson(
                id: "kg_numeral_exit_ticket",
                title: "Exit Ticket: Numbers",
                description: "Write and match numerals in a final celebration.",
                questions: [
                    Question(prompt: "Write the number for this many dots: •••",
                             choices: ["2", "3", "6"],
                             correctIndex: 1,
                             voicePrompt: "Count the dots and choose the matching number.",
                             hints: [
                                "Point and count: one, two, three.",
                                "The number we say last is the answer."
                             ],
                             tactileGuidance: "Tap each dot, then tap the numeral.",
                             strategy: .verbal),
                    Question(prompt: "Which number shows five?",
                             choices: ["5", "7", "3"],
                             correctIndex: 0,
                             voicePrompt: "Find the number that matches a whole hand of fingers.",
                             hints: [
                                "Imagine holding up your hand with all fingers.",
                                "The number starts the counting adventure again."
                             ],
                             tactileGuidance: "Hold up your hand and match the number.",
                             strategy: .tactile)
                ],
                topic: .numeralWriting,
                playlist: numeralsPlaylist,
                playlistPosition: 1,
                assessment: LessonAssessment(kind: .exitTicket,
                                             masteryThreshold: 0.8,
                                             instructions: "Capture transfer of numeral writing to symbols"),
                badge: numeralsBadge
            ),
            Lesson(
                id: "kg_ordinal_reasoning",
                title: "Parade Positions",
                description: "Use words like first, second and third to describe order.",
                questions: [
                    Question(prompt: "In the parade 🦊🐰🐻, who is second?",
                             choices: ["🦊", "🐰", "🐻"],
                             correctIndex: 1,
                             voicePrompt: "Let's say the order together: first fox, second bunny, third bear.",
                             hints: [
                                "Point to each friend as you say the order.",
                                "Second means the friend in the middle."
                             ],
                             tactileGuidance: "Swipe along the line of friends until you reach the middle one.",
                             strategy: .verbal),
                    Question(prompt: "Which turtle is first in line? 🐢🐢🐢",
                             choices: ["Front", "Middle", "Back"],
                             correctIndex: 0,
                             voicePrompt: "Find the turtle that starts the line.",
                             hints: [
                                "The first turtle is the leader.",
                                "Look for the turtle at the starting flag."
                             ],
                             tactileGuidance: "Tap the turtle nearest the start cone.",
                             strategy: .visual)
                ],
                topic: .ordinalReasoning,
                playlist: ordinalPlaylist,
                playlistPosition: 0
            ),
            Lesson(
                id: "kg_operations_story",
                title: "Number Story Playground",
                description: "Solve simple addition and subtraction stories with manipulatives.",
                questions: [
                    Question(prompt: "You have 2 toy cars. A friend gives you 1 more. How many now?",
                             choices: ["2", "3", "4"],
                             correctIndex: 1,
                             voicePrompt: "Let's count the cars together: one, two... and one more makes?",
                             hints: [
                                "Count all the cars after sliding them together.",
                                "Two and one more is like a trio of cars."
                             ],
                             tactileGuidance: "Drag the cars into a parking spot to see the total.",
                             strategy: .tactile),
                    Question(prompt: "There are 5 apples. You eat 2. How many are left?",
                             choices: ["2", "3", "5"],
                             correctIndex: 1,
                             voicePrompt: "Start with five. Take away two. How many stay in the basket?",
                             hints: [
                                "Cover two apples with your hand.",
                                "Five take away two leaves a trio."
                             ],
                             tactileGuidance: "Move two apples to the compost bin, then count what's left.",
                             strategy: .visual)
                ],
                topic: .operations,
                playlist: operationsPlaylist,
                playlistPosition: 0
            ),
            Lesson(
                id: "kg_shapes_explorer",
                title: "Shape Safari",
                description: "Identify and describe shapes in the environment.",
                questions: [
                    Question(prompt: "Which shape has three sides?",
                             choices: ["Triangle", "Square", "Circle"],
                             correctIndex: 0,
                             voicePrompt: "A shape with three sides is called a triangle. Can you find it?",
                             hints: [
                                "Trace the sides with your finger.",
                                "Count the corners—one, two, three."
                             ],
                             tactileGuidance: "Follow the edges of each shape.",
                             strategy: .visual),
                    Question(prompt: "Which shape can roll?",
                             choices: ["Sphere", "Cube", "Cone"],
                             correctIndex: 0,
                             voicePrompt: "Think about which shape can roll smoothly like a ball.",
                             hints: [
                                "A rolling shape has no flat sides.",
                                "Imagine playing catch."
                             ],
                             tactileGuidance: "Drag the shapes to see which rolls easily.",
                             strategy: .tactile)
                ],
                topic: .shapes,
                playlist: shapesPlaylist,
                playlistPosition: 0
            ),
            Lesson(
                id: "kg_measurement",
                title: "Measure the Garden",
                description: "Compare lengths using non-standard units like cubes and hands.",
                questions: [
                    Question(prompt: "The worm is 4 cubes long. The stick is 3 cubes long. Which is longer?",
                             choices: ["Worm", "Stick", "They are the same"],
                             correctIndex: 0,
                             voicePrompt: "Line up the cubes and compare. Which stretches farther?",
                             hints: [
                                "Match the cubes from the start.",
                                "The longer one reaches past the other."
                             ],
                             tactileGuidance: "Drag cubes under each object to compare.",
                             strategy: .visual),
                    Question(prompt: "How many hand spans long is the table?",
                             choices: ["3", "4", "6"],
                             correctIndex: 1,
                             voicePrompt: "Slide your hand across the table and count.",
                             hints: [
                                "Say a number each time you move your hand.",
                                "We stopped counting at four."
                             ],
                             tactileGuidance: "Tap each hand print as you count across.",
                             strategy: .tactile)
                ],
                topic: .measurement,
                playlist: measurementPlaylist,
                playlistPosition: 0
            ),
            Lesson(
                id: "kg_money_store",
                title: "Play Store",
                description: "Match coins to prices in a pretend store.",
                questions: [
                    Question(prompt: "A sticker costs 1¢. Which coin pays for it?",
                             choices: ["🪙 Penny", "🪙 Nickel", "🪙 Dime"],
                             correctIndex: 0,
                             voicePrompt: "Find the penny with Abraham Lincoln on it.",
                             hints: [
                                "The penny is brown and worth one cent.",
                                "Look for the smallest amount."
                             ],
                             tactileGuidance: "Drag the coin that matches one cent to the register.",
                             strategy: .visual),
                    Question(prompt: "You have two nickels. How much money do you have?",
                             choices: ["10¢", "5¢", "2¢"],
                             correctIndex: 0,
                             voicePrompt: "Count by fives: five, ten!",
                             hints: [
                                "Each nickel is five cents.",
                                "Two fives make ten."
                             ],
                             tactileGuidance: "Tap each nickel as you count by fives.",
                             strategy: .verbal)
                ],
                topic: .money,
                playlist: moneyPlaylist,
                playlistPosition: 0,
                badge: BadgeReward(id: "badge.kindergarten.money",
                                   title: "Market Helper",
                                   detail: "Completed the play store challenge",
                                   imageName: "cart.circle")
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
