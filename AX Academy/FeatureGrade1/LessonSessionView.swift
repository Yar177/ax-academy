import SwiftUI
import ContentModel
import DesignSystem

/// Quiz view for grade 1 lessons.  Presents one question at a time and
/// provides feedback.  Once the lesson is complete a summary screen
/// encourages the learner before returning to the lesson list.
struct LessonSessionView: View {
    @ObservedObject var viewModel: LessonSessionViewModel
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