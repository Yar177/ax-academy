import SwiftUI
import ContentModel
import DesignSystem

/// The root view for kindergarten math.  Displays a list of available
/// lessons.  Tapping a lesson navigates to a quiz for that lesson.  Uses
/// `NavigationStack` which is available on iOS 16 and later.
struct KindergartenRootView: View {
    @ObservedObject var viewModel: LessonListViewModel

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
            .navigationTitle(viewModel.grade.displayName + " Math")
            .navigationDestination(for: Lesson.self) { lesson in
                // Create a session view model for the selected lesson.
                let sessionVM = LessonSessionViewModel(grade: viewModel.grade,
                                                       lesson: lesson,
                                                       analytics: viewModel.analytics,
                                                       persistence: viewModel.persistence,
                                                       markLessonCompleted: { [weak viewModel] lesson in
                                                           viewModel?.markLessonCompleted(lesson)
                                                       })
                LessonSessionView(viewModel: sessionVM)
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
                    .accessibilityLabel(Text("Completed"))
            }
        }
        .padding(.vertical, 8)
    }
}