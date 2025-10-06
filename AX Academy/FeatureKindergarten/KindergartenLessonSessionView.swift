import SwiftUI

/// A view that presents questions from a lesson one at a time.  It provides
/// immediate feedback and automatically advances after a short pause.  When
/// all questions have been answered a summary screen is shown.
struct KindergartenLessonSessionView: View {
    @ObservedObject var viewModel: KindergartenLessonSessionViewModel
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
    }

    @ViewBuilder
    private var completionView: some View {
        VStack(spacing: 24) {
            Text("Great job!")
                .font(DSTypography.largeTitle())
                .multilineTextAlignment(.center)
            Text("You've completed the lesson.")
                .font(DSTypography.body())
                .multilineTextAlignment(.center)
            Button(action: {
                dismiss()
            }) {
                Text("Back to Lessons")
            }
            .buttonStyle(PrimaryButtonStyle())
            .accessibilityIdentifier("backButton")
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(DSColor.background)
    }

    private func questionView(_ question: Question) -> some View {
        VStack(alignment: .leading, spacing: 16) {
            Text(question.prompt)
                .font(DSTypography.title())
                .foregroundColor(DSColor.primaryText)
                .multilineTextAlignment(.leading)
                .accessibilityIdentifier("prompt")
            VStack(spacing: 12) {
                ForEach(question.choices.indices, id: \ .self) { index in
                    Button(action: {
                        viewModel.answer(choiceAt: index)
                    }) {
                        Text(question.choices[index])
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(PrimaryButtonStyle())
                    .accessibilityIdentifier("choice_\(index)")
                }
            }
            if let correct = viewModel.lastAnswerCorrect {
                Text(correct ? "Correct!" : "Try again")
                    .font(DSTypography.caption())
                    .foregroundColor(correct ? .green : .red)
                    .transition(.opacity)
            }
            Spacer()
            // Progress indicator
            Text("Question \(viewModel.currentIndex + 1) of \(viewModel.lesson.questions.count)")
                .font(DSTypography.caption())
                .foregroundColor(DSColor.secondaryText)
                .accessibilityIdentifier("progress")
        }
    }
}
