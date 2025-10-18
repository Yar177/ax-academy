import SwiftUI

/// A Grade 1 view that presents questions from a lesson one at a time.
/// Provides immediate feedback, adaptive challenge sets, and remediation links
/// to Kindergarten content.
struct Grade1LessonSessionView: View {
    @ObservedObject var viewModel: Grade1LessonSessionViewModel
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        Group {
            if viewModel.isFinished {
                completionView
            } else if let question = viewModel.currentQuestion {
                questionView(question)
            } else {
                ProgressView()
            }
        }
        .navigationBarTitleDisplayMode(.inline)
        .padding()
        .background(DSColor.background)
    }

    @ViewBuilder
    private var completionView: some View {
        VStack(spacing: 24) {
            Text("Fantastic!")
                .font(DSTypography.largeTitle())
            Text("You've completed this lesson.")
                .font(DSTypography.body())
            Button(action: { dismiss() }) {
                Text("Back to Lessons")
            }
            .buttonStyle(PrimaryButtonStyle())
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private func questionView(_ question: Question) -> some View {
        VStack(alignment: .leading, spacing: 16) {
            if viewModel.isInChallengeMode {
                Label("Challenge Round!", systemImage: "flame.fill")
                    .font(DSTypography.body())
                    .foregroundColor(.orange)
            }
            CardView {
                VStack(alignment: .leading, spacing: 12) {
                    let presentation = interactionPresentation(for: question.interaction)
                    Label(presentation.title, systemImage: presentation.icon)
                        .font(DSTypography.caption())
                        .foregroundColor(DSColor.secondaryText)
                    Text(question.prompt)
                        .font(DSTypography.title())
                        .foregroundColor(DSColor.primaryText)
                    if let step = viewModel.currentStep {
                        Text(step.prompt)
                            .font(DSTypography.body())
                            .foregroundColor(DSColor.primaryText)
                        Text("Step \(viewModel.currentStepIndex + 1) of \(question.steps.count)")
                            .font(DSTypography.caption())
                            .foregroundColor(DSColor.secondaryText)
                    }
                }
            }
            VStack(spacing: 12) {
                ForEach(viewModel.currentChoices.indices, id: \.self) { index in
                    Button(action: {
                        viewModel.answer(choiceAt: index)
                    }) {
                        Text(viewModel.currentChoices[index])
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(PrimaryButtonStyle())
                }
            }
            if let correct = viewModel.lastAnswerCorrect {
                Text(correct ? "Correct!" : "Try again")
                    .font(DSTypography.caption())
                    .foregroundColor(correct ? .green : .red)
            }
            if let hint = viewModel.currentHint, viewModel.lastAnswerCorrect == false {
                Text("Hint: \(hint)")
                    .font(DSTypography.caption())
                    .foregroundColor(DSColor.secondaryText)
            }
            if let remediation = viewModel.remediationState {
                RemediationCard(remediation: remediation, onContinue: {
                    viewModel.acknowledgeRemediation()
                })
            }
            Spacer()
            Text(progressDescription(for: question))
                .font(DSTypography.caption())
                .foregroundColor(DSColor.secondaryText)
        }
    }

    private func progressDescription(for question: Question) -> String {
        if viewModel.isInChallengeMode {
            let total = max(viewModel.totalChallengeQuestions, 1)
            return "Challenge question \(viewModel.currentIndex + 1) of \(total)"
        } else {
            let total = max(viewModel.totalCoreQuestions, 1)
            return "Question \(viewModel.currentIndex + 1) of \(total)"
        }
    }

    private func interactionPresentation(for interaction: QuestionInteraction) -> (title: String, icon: String) {
        switch interaction {
        case .multipleChoice:
            return ("Quick Pick", "list.bullet")
        case .baseTenBlocks:
            return ("Place Value", "square.grid.3x3.fill")
        case .wordProblem:
            return ("Word Problem", "text.book.closed")
        case .fractions:
            return ("Fractions", "circle.lefthalf.fill")
        case .timeMatching:
            return ("Telling Time", "clock")
        case .moneyCounting:
            return ("Money", "dollarsign.circle")
        case .dataAnalysis:
            return ("Data", "chart.bar")
        }
    }
}

private struct RemediationCard: View {
    let remediation: Grade1LessonSessionViewModel.RemediationState
    let onContinue: () -> Void

    var body: some View {
        CardView {
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    Image(systemName: "arrow.uturn.backward.circle")
                        .foregroundColor(DSColor.accent)
                    Text("Let's review")
                        .font(DSTypography.title())
                }
                Text(remediation.link.message)
                    .font(DSTypography.body())
                    .foregroundColor(DSColor.primaryText)
                if let lesson = remediation.lesson {
                    Text("Recommended Kindergarten lesson: \(lesson.title)")
                        .font(DSTypography.caption())
                        .foregroundColor(DSColor.secondaryText)
                }
                Button(action: onContinue) {
                    Text("Reviewed – Try Again")
                }
                .buttonStyle(SecondaryButtonStyle())
            }
        }
    }
}
