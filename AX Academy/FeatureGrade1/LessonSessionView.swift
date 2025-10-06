import SwiftUI

/// A Grade 1 view that presents questions from a lesson one at a time.
/// Provides immediate feedback and automatically advances after a pause.
/// Shows a summary screen when all questions are answered.
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
        .background(DSColor.background)
    }

    private func questionView(_ question: Question) -> some View {
        VStack(alignment: .leading, spacing: 16) {
            Text(question.prompt)
                .font(DSTypography.title())
                .foregroundColor(DSColor.primaryText)
                .multilineTextAlignment(.leading)
            VStack(spacing: 12) {
                ForEach(question.choices.indices, id: \ .self) { index in
                    Button(action: {
                        viewModel.answer(choiceAt: index)
                    }) {
                        Text(question.choices[index])
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
            Spacer()
            Text("Question \(viewModel.currentIndex + 1) of \(viewModel.lesson.questions.count)")
                .font(DSTypography.caption())
                .foregroundColor(DSColor.secondaryText)
        }
    }
}
