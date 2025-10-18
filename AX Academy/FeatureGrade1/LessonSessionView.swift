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
            } else if let item = viewModel.currentQuestion {
                itemView(item)
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

    private func itemView(_ item: LessonItem) -> some View {
        VStack(alignment: .leading, spacing: 16) {
            Text(item.prompt)
                .font(DSTypography.title())
                .foregroundColor(DSColor.primaryText)
                .multilineTextAlignment(.leading)
            if let choices = item.choices {
                VStack(spacing: 12) {
                    ForEach(Array(choices.enumerated()), id: \.offset) { pair in
                        Button(action: {
                            viewModel.answer(choiceAt: pair.offset)
                        }) {
                            Text(pair.element.text)
                                .frame(maxWidth: .infinity)
                        }
                        .buttonStyle(PrimaryButtonStyle())
                    }
                }
            }
            if let correct = viewModel.lastAnswerCorrect {
                Text(correct ? "Correct!" : "Try again")
                    .font(DSTypography.caption())
                    .foregroundColor(correct ? .green : .red)
            }
            Spacer()
            Text("Question \(viewModel.currentIndex + 1) of \(viewModel.lesson.items.count)")
                .font(DSTypography.caption())
                .foregroundColor(DSColor.secondaryText)
        }
    }
}
