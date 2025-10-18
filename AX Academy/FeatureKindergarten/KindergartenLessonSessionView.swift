import SwiftUI

/// A view that presents questions from a lesson one at a time.  It provides
/// immediate feedback and automatically advances after a short pause.  When
/// all questions have been answered a summary screen is shown.  The updated
/// implementation adds touch/voice guidance, adaptive hints and formative
/// assessment celebrations tailored for kindergarten learners.
struct KindergartenLessonSessionView: View {
    @ObservedObject var viewModel: KindergartenLessonSessionViewModel
    @Environment(\.dismiss) private var dismiss
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize

    var body: some View {
        Group {
            if viewModel.isFinished {
                completionView
            } else if let question = viewModel.currentQuestion {
                questionView(question)
            } else {
                ProgressView()
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
        }
        .background(DSColor.background.ignoresSafeArea())
        .navigationBarTitleDisplayMode(.inline)
        .onAppear { viewModel.beginSession() }
    }

    // MARK: - Completion

    private var completionView: some View {
        ScrollView {
            VStack(spacing: 24) {
                if viewModel.shouldCelebrateMastery {
                    CelebrationView(reduceMotion: reduceMotion)
                        .accessibilityHidden(true)
                }

                Text(viewModel.shouldCelebrateMastery ? "You did it!" : "Keep practising!")
                    .font(DSTypography.largeTitle())
                    .multilineTextAlignment(.center)
                    .padding(.top)

                if let result = viewModel.assessmentResult {
                    AssessmentSummaryView(result: result)
                        .accessibilityElement(children: .combine)
                }

                if let badge = viewModel.lesson.badge, viewModel.shouldCelebrateMastery {
                    BadgeDisplayView(badge: badge)
                } else if let badge = viewModel.lesson.playlist.badge, viewModel.shouldCelebrateMastery {
                    BadgeDisplayView(badge: badge)
                }

                Button(action: { dismiss() }) {
                    Text("Back to Lessons")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(PrimaryButtonStyle())
                .accessibilityIdentifier("backButton")
            }
            .padding()
        }
    }

    // MARK: - Question Presentation

    private func questionView(_ question: Question) -> some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                headerView

                if let kind = viewModel.assessmentKind {
                    AssessmentBanner(kind: kind)
                }

                questionCard(for: question)

                VoiceGuidanceView(action: viewModel.replayVoicePrompt)

                HintSectionView(currentHint: viewModel.currentHint,
                                requestHint: viewModel.requestHint,
                                dynamicTypeSize: dynamicTypeSize)

                if let tactile = question.tactileGuidance {
                    GuidanceCalloutView(symbol: "hand.point.up.left.fill", text: tactile)
                }

                ProgressSectionView(progress: viewModel.progress,
                                     currentIndex: viewModel.currentIndex,
                                     totalQuestions: viewModel.lesson.questions.count)
            }
            .padding()
        }
    }

    private var headerView: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(viewModel.lesson.title)
                .font(DSTypography.title())
                .foregroundColor(DSColor.primaryText)
                .accessibilityAddTraits(.isHeader)
            Text(viewModel.lesson.description)
                .font(DSTypography.body())
                .foregroundColor(DSColor.secondaryText)
                .accessibilityHint("Lesson description")
        }
    }

    private func questionCard(for question: Question) -> some View {
        VStack(alignment: .leading, spacing: 16) {
            Text(question.prompt)
                .font(DSTypography.title())
                .foregroundColor(DSColor.primaryText)
                .multilineTextAlignment(.leading)
                .accessibilityIdentifier("prompt")

            VStack(spacing: 12) {
                ForEach(question.choices.indices, id: \.self) { index in
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
                FeedbackBanner(correct: correct, reduceMotion: reduceMotion)
            }
        }
        .padding()
        .background(DSColor.surface)
        .cornerRadius(16)
        .shadow(color: reduceMotion ? .clear : Color.black.opacity(0.08), radius: 8, x: 0, y: 4)
        .animation(reduceMotion ? nil : .spring(response: 0.4, dampingFraction: 0.7), value: viewModel.lastAnswerCorrect)
    }
}

// MARK: - Subviews

private struct VoiceGuidanceView: View {
    var action: () -> Void

    var body: some View {
        Button(action: action) {
            Label("Hear it again", systemImage: "speaker.wave.2.fill")
                .frame(maxWidth: .infinity)
        }
        .buttonStyle(SecondaryButtonStyle())
        .accessibilityHint("Replays the spoken instructions")
    }
}

private struct HintSectionView: View {
    var currentHint: String?
    var requestHint: () -> Void
    var dynamicTypeSize: DynamicTypeSize

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            if let hint = currentHint {
                GuidanceCalloutView(symbol: "lightbulb.fill", text: hint)
                    .transition(.opacity)
            } else {
                Button(action: requestHint) {
                    Label("Need a hint?", systemImage: "questionmark.circle")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(SecondaryButtonStyle())
                .accessibilityHint("Shows the next strategy to try")
            }
        }
        .animation(dynamicTypeSize >= .accessibility1 ? nil : .default, value: currentHint)
    }
}

private struct FeedbackBanner: View {
    var correct: Bool
    var reduceMotion: Bool

    var body: some View {
        Text(correct ? "Great!" : "Let's try again")
            .font(DSTypography.caption())
            .foregroundColor(correct ? .green : .red)
            .padding(.vertical, 4)
            .padding(.horizontal, 8)
            .background((correct ? Color.green.opacity(0.15) : Color.red.opacity(0.15)).cornerRadius(8))
            .animation(reduceMotion ? nil : .easeInOut, value: correct)
            .accessibilityLabel(correct ? "Correct answer" : "Incorrect answer")
    }
}

private struct GuidanceCalloutView: View {
    var symbol: String
    var text: String

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: symbol)
                .foregroundColor(DSColor.accent)
                .imageScale(.large)
            Text(text)
                .font(DSTypography.body())
                .foregroundColor(DSColor.primaryText)
        }
        .padding()
        .background(DSColor.surface)
        .cornerRadius(12)
    }
}

private struct ProgressSectionView: View {
    var progress: KindergartenLessonSessionViewModel.ProgressMetrics
    var currentIndex: Int
    var totalQuestions: Int

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            ProgressView(value: Double(progress.answered), total: Double(progress.total))
            Text("Question \(currentIndex + 1) of \(totalQuestions) · Mastery \(Int(progress.score * 100))%")
                .font(DSTypography.caption())
                .foregroundColor(DSColor.secondaryText)
                .accessibilityIdentifier("progress")
        }
    }
}

private struct AssessmentBanner: View {
    var kind: LessonAssessment.Kind

    var body: some View {
        let text: String
        switch kind {
        case .quickCheck:
            text = "Quick Check"
        case .exitTicket:
            text = "Exit Ticket"
        }
        return Text(text)
            .font(DSTypography.caption())
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
            .background(DSColor.accent.opacity(0.15))
            .cornerRadius(12)
            .accessibilityLabel("Formative assessment: \(text)")
    }
}

private struct AssessmentSummaryView: View {
    var result: KindergartenLessonSessionViewModel.AssessmentResult

    var body: some View {
        VStack(spacing: 8) {
            Text(result.kind == .quickCheck ? "Quick Check Results" : "Exit Ticket Results")
                .font(DSTypography.title3())
                .accessibilityAddTraits(.isHeader)
            Text("Score: \(Int(result.score * 100))%")
                .font(DSTypography.body())
                .foregroundColor(result.passed ? .green : .red)
            Text(result.passed ? "Mastery Achieved" : "Try again to reach mastery")
                .font(DSTypography.caption())
                .foregroundColor(DSColor.secondaryText)
        }
        .padding()
        .background(DSColor.surface)
        .cornerRadius(16)
    }
}

private struct BadgeDisplayView: View {
    var badge: BadgeReward

    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: badge.imageName)
                .font(.system(size: 48))
                .foregroundColor(DSColor.accent)
            Text(badge.title)
                .font(DSTypography.title3())
            Text(badge.detail)
                .font(DSTypography.caption())
                .foregroundColor(DSColor.secondaryText)
        }
        .padding()
        .frame(maxWidth: .infinity)
        .background(DSColor.surface)
        .cornerRadius(16)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Badge earned: \(badge.title)")
    }
}

private struct CelebrationView: View {
    var reduceMotion: Bool

    var body: some View {
        Image(systemName: "sparkles")
            .font(.system(size: 64))
            .foregroundColor(DSColor.accent)
            .rotationEffect(reduceMotion ? .zero : Angle(degrees: 5))
            .animation(reduceMotion ? nil : .easeInOut(duration: 1).repeatForever(autoreverses: true), value: reduceMotion)
    }
}
