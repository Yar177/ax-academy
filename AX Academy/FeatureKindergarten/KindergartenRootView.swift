import SwiftUI

/// The root view for kindergarten math.  Displays a list of available
/// lessons.  Tapping a lesson navigates to a quiz for that lesson.  Uses
/// `NavigationStack` which is available on iOS 16 and later.
struct KindergartenRootView: View {
    @ObservedObject var viewModel: KindergartenLessonListViewModel

    var body: some View {
        NavigationStack {
            List {
                ForEach(viewModel.lessons) { lesson in
                    NavigationLink(value: lesson) {
                        LessonRowView(title: lesson.title,
                                      completed: viewModel.isLessonCompleted(lesson))
                    }
                }
            }
            .navigationTitle(String(format: L10n.string("grade_math_title"), viewModel.grade.displayName))
            .navigationDestination(for: Lesson.self) { lesson in
                // Create a session view model for the selected lesson.
                let sessionVM = KindergartenLessonSessionViewModel(grade: viewModel.grade,
                                                       lesson: lesson,
                                                       analytics: viewModel.analytics,
                                                       persistence: viewModel.persistence,
                                                       progressTracker: viewModel.progressTracker,
                                                       markLessonCompleted: { [weak viewModel] lesson in
                                                           viewModel?.markLessonCompleted(lesson)
                                                       })
                KindergartenLessonSessionView(viewModel: sessionVM)
            }
        }
    }
}

private struct LessonRowView: View {
    var title: String
    var completed: Bool
    var body: some View {
        HStack {
            Text(title)
                .font(DSTypography.body())
                .foregroundColor(DSColor.primaryText)
            Spacer()
            if completed {
                Image(systemName: "checkmark.circle.fill")
                    .foregroundColor(.green)
                    .accessibilityLabel(Text(L10n.text("lesson_completed_accessibility")))
            }
        }
        .padding(.vertical, 8)
    }
}
