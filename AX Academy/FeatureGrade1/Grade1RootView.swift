import SwiftUI

/// The root view for grade 1 math.  Presents a goal tracker, unit map, and
/// adaptive navigation that unlocks lessons based on Kindergarten mastery or
/// diagnostic placement.
struct Grade1RootView: View {
    @ObservedObject var viewModel: Grade1LessonListViewModel
    @State private var showingDiagnostic = false
    @State private var diagnosticOutcome: DiagnosticOutcome? = nil

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    GoalTrackerCard(goal: viewModel.goalProgress) {
                        showingDiagnostic = true
                    }
                    ForEach(viewModel.unitMap) { unit in
                        Grade1UnitCard(unit: unit,
                                        isLessonCompleted: { viewModel.isLessonCompleted($0) })
                    }
                }
                .padding()
                .frame(maxWidth: .infinity)
            }
            .background(DSColor.background)
            .navigationTitle(viewModel.grade.displayName + " Math")
            .navigationDestination(for: Lesson.self) { lesson in
                let sessionVM = Grade1LessonSessionViewModel(grade: viewModel.grade,
                                                            lesson: lesson,
                                                            kindergartenLessons: viewModel.kindergartenLessons,
                                                            analytics: viewModel.analytics,
                                                            markLessonCompleted: { [weak viewModel] lesson in
                                                                viewModel?.markLessonCompleted(lesson)
                                                            })
                Grade1LessonSessionView(viewModel: sessionVM)
            }
            .sheet(isPresented: $showingDiagnostic) {
                Grade1DiagnosticView { passed in
                    diagnosticOutcome = passed ? .passed : .needsPractice
                    if passed {
                        viewModel.completeDiagnosticPlacement()
                    }
                    showingDiagnostic = false
                }
            }
            .alert(item: $diagnosticOutcome) { outcome in
                Alert(title: Text(outcome.title),
                      message: Text(outcome.message),
                      dismissButton: .default(Text("OK")))
            }
        }
    }
}

private struct GoalTrackerCard: View {
    let goal: Grade1LessonListViewModel.GoalProgressSnapshot
    let onDiagnosticTap: () -> Void

    var body: some View {
        CardView {
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    Image(systemName: "target")
                        .foregroundColor(DSColor.accent)
                    Text("Grade 1 Goal Tracker")
                        .font(DSTypography.title())
                        .foregroundColor(DSColor.primaryText)
                }
                ProgressView(value: goal.progress)
                    .tint(DSColor.accent)
                Text("\(goal.completedLessons) of \(goal.totalLessons) milestones completed")
                    .font(DSTypography.caption())
                    .foregroundColor(DSColor.secondaryText)
                if let next = goal.nextMilestoneTitle {
                    Text("Next up: \(next)")
                        .font(DSTypography.body())
                        .foregroundColor(DSColor.primaryText)
                }
                if goal.shouldShowDiagnosticPrompt {
                    Button(action: onDiagnosticTap) {
                        Text("Take Placement Check")
                    }
                    .buttonStyle(PrimaryButtonStyle())
                } else if !goal.kindergartenMastered {
                    Text("Finish Kindergarten lessons to unlock more Grade 1 adventures.")
                        .font(DSTypography.caption())
                        .foregroundColor(DSColor.secondaryText)
                }
            }
        }
    }
}

private struct Grade1UnitCard: View {
    let unit: Grade1LessonListViewModel.UnitPresentation
    let isLessonCompleted: (Lesson) -> Bool

    var body: some View {
        CardView {
            VStack(alignment: .leading, spacing: 16) {
                HStack(spacing: 12) {
                    Image(systemName: unit.iconName)
                        .foregroundColor(DSColor.accent)
                        .font(.system(size: 28))
                    VStack(alignment: .leading, spacing: 4) {
                        Text(unit.title)
                            .font(DSTypography.title())
                        Text(unit.description)
                            .font(DSTypography.body())
                            .foregroundColor(DSColor.secondaryText)
                    }
                }
                ProgressView(value: unit.progress)
                    .tint(unit.isUnlocked ? DSColor.accent : .gray)
                if unit.isUnlocked {
                    VStack(spacing: 12) {
                        ForEach(unit.lessons) { lesson in
                            NavigationLink(value: lesson) {
                                LessonRowView(title: lesson.title,
                                              completed: isLessonCompleted(lesson),
                                              isLocked: false)
                            }
                        }
                    }
                } else {
                    LessonRowView(title: unit.lessons.first?.title ?? "Locked",
                                   completed: false,
                                   isLocked: true,
                                   unlockMessage: unit.unlockDescription)
                }
            }
        }
    }
}

private struct LessonRowView: View {
    var title: String
    var completed: Bool
    var isLocked: Bool
    var unlockMessage: String? = nil

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                Text(title)
                    .font(DSTypography.body())
                    .foregroundColor(isLocked ? DSColor.secondaryText : DSColor.primaryText)
                Spacer()
                if completed {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(.green)
                        .accessibilityLabel(Text("Completed"))
                } else if isLocked {
                    Image(systemName: "lock.fill")
                        .foregroundColor(DSColor.secondaryText)
                }
            }
            if let message = unlockMessage {
                Text(message)
                    .font(DSTypography.caption())
                    .foregroundColor(DSColor.secondaryText)
            }
        }
        .padding(.vertical, 4)
    }
}

private enum DiagnosticOutcome: Identifiable {
    case passed
    case needsPractice

    var id: Int { hashValue }
    var title: String {
        switch self {
        case .passed:
            return "Placement Complete"
        case .needsPractice:
            return "Keep Practicing"
        }
    }
    var message: String {
        switch self {
        case .passed:
            return "Grade 1 units are now unlocked!"
        case .needsPractice:
            return "Try a few Kindergarten review lessons, then take the check again."
        }
    }
}

private struct Grade1DiagnosticView: View {
    let onCompletion: (Bool) -> Void
    @Environment(\.dismiss) private var dismiss
    @State private var currentIndex: Int = 0
    @State private var correctCount: Int = 0
    @State private var answeredIndex: Int? = nil
    @State private var wasCorrect: Bool? = nil

    private let questions: [DiagnosticQuestion] = [
        DiagnosticQuestion(prompt: "Which blocks show the number 23?",
                           choices: ["2 tens and 3 ones", "3 tens and 2 ones", "23 ones"],
                           correctIndex: 0),
        DiagnosticQuestion(prompt: "A word problem adds 7 apples and then takes away 2. What strategy helps you solve it?",
                           choices: ["Add then subtract", "Subtract twice", "Guess the answer"],
                           correctIndex: 0),
        DiagnosticQuestion(prompt: "Which clock shows half past five?",
                           choices: ["Hour hand at 5, minute hand at 6", "Hour hand at 6, minute hand at 5", "Hour hand at 12, minute hand at 5"],
                           correctIndex: 0)
    ]

    var body: some View {
        VStack(spacing: 24) {
            Text("Placement Check")
                .font(DSTypography.largeTitle())
            CardView {
                VStack(alignment: .leading, spacing: 16) {
                    Text(questions[currentIndex].prompt)
                        .font(DSTypography.title())
                    ForEach(questions[currentIndex].choices.indices, id: \.self) { index in
                        Button(action: {
                            guard answeredIndex == nil else { return }
                            answeredIndex = index
                            let correct = index == questions[currentIndex].correctIndex
                            wasCorrect = correct
                            if correct { correctCount += 1 }
                        }) {
                            Text(questions[currentIndex].choices[index])
                                .frame(maxWidth: .infinity)
                        }
                        .buttonStyle(PrimaryButtonStyle())
                        .opacity(answeredIndex != nil && answeredIndex != index ? 0.6 : 1.0)
                        .disabled(answeredIndex != nil)
                    }
                    if let wasCorrect {
                        Text(wasCorrect ? "Great work!" : "Give it another try on the next question.")
                            .font(DSTypography.caption())
                            .foregroundColor(wasCorrect ? .green : .red)
                    }
                }
            }
            Button(action: advance) {
                Text(currentIndex == questions.count - 1 ? "Finish" : "Next")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(SecondaryButtonStyle())
            .disabled(answeredIndex == nil)
        }
        .padding()
    }

    private func advance() {
        guard answeredIndex != nil else { return }
        if currentIndex == questions.count - 1 {
            let passed = correctCount >= 2
            onCompletion(passed)
            dismiss()
        } else {
            currentIndex += 1
            answeredIndex = nil
            wasCorrect = nil
        }
    }
}

private struct DiagnosticQuestion {
    let prompt: String
    let choices: [String]
    let correctIndex: Int
}
