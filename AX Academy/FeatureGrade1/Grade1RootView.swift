import SwiftUI

/// The root view for grade 1 math.  Lists available lessons and navigates to
/// quizzes.
struct Grade1RootView: View {
    @ObservedObject var viewModel: Grade1LessonListViewModel
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
                let sessionVM = Grade1LessonSessionViewModel(grade: viewModel.grade,
                                                       lesson: lesson,
                                                       analytics: viewModel.analytics,
                                                       persistence: viewModel.persistence,
                                                       markLessonCompleted: { [weak viewModel] lesson in
                                                           viewModel?.markLessonCompleted(lesson)
                                                       })
                Grade1LessonSessionView(viewModel: sessionVM)
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
