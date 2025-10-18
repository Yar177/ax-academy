import SwiftUI

/// The root view for kindergarten math.  Displays the learning journey map,
/// topic carousels and earned badges.  Tapping a lesson navigates to an
/// interactive session for that lesson.  Uses `NavigationStack` which is
/// available on iOS 16 and later.
struct KindergartenRootView: View {
    @ObservedObject var viewModel: KindergartenLessonListViewModel
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Environment(\.accessibilityVoiceOverEnabled) private var voiceOverEnabled

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 32) {
                    heroSection
                    journeySection
                    ForEach(viewModel.topicCarousels) { carousel in
                        TopicCarouselSection(topic: carousel.topic,
                                             lessons: carousel.lessons,
                                             isReduceMotion: reduceMotion,
                                             completionChecker: viewModel.isLessonCompleted)
                    }
                    if !viewModel.badges.isEmpty {
                        BadgeSection(badges: viewModel.badges)
                    }
                    if let summary = viewModel.performanceSummary {
                        InfoBanner(symbol: "gauge", title: "Performance", message: summary)
                    }
                    if let accessibility = viewModel.accessibilitySummary {
                        InfoBanner(symbol: "figure.wave.circle", title: "Accessibility", message: accessibility)
                    }
                }
                .padding()
            }
            .background(DSColor.background.ignoresSafeArea())
            .navigationTitle(viewModel.grade.displayName + " Math")
            .navigationDestination(for: Lesson.self) { lesson in
                let sessionVM = KindergartenLessonSessionViewModel(grade: viewModel.grade,
                                                                   lesson: lesson,
                                                                   analytics: viewModel.analytics,
                                                                   persistence: viewModel.persistence) { [weak viewModel] completion in
                    viewModel?.handleLessonCompletion(completion)
                }
                KindergartenLessonSessionView(viewModel: sessionVM)
            }
            .onAppear {
                viewModel.refreshProgress()
                viewModel.profileDevicePerformanceIfNeeded()
                viewModel.updateAccessibilityProfile(voiceOverEnabled: voiceOverEnabled,
                                                     dynamicTypeSize: dynamicTypeSize,
                                                     reduceMotion: reduceMotion)
            }
            .onChange(of: dynamicTypeSize) { newValue in
                viewModel.updateAccessibilityProfile(voiceOverEnabled: voiceOverEnabled,
                                                     dynamicTypeSize: newValue,
                                                     reduceMotion: reduceMotion)
            }
            .onChange(of: voiceOverEnabled) { newValue in
                viewModel.updateAccessibilityProfile(voiceOverEnabled: newValue,
                                                     dynamicTypeSize: dynamicTypeSize,
                                                     reduceMotion: reduceMotion)
            }
            .onChange(of: reduceMotion) { newValue in
                viewModel.updateAccessibilityProfile(voiceOverEnabled: voiceOverEnabled,
                                                     dynamicTypeSize: dynamicTypeSize,
                                                     reduceMotion: newValue)
            }
        }
    }

    private var heroSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Kindergarten Journey")
                .font(DSTypography.largeTitle())
                .foregroundColor(DSColor.primaryText)
            Text("Explore playful lessons with voice guidance, tactile hints and celebrations for every win.")
                .font(DSTypography.body())
                .foregroundColor(DSColor.secondaryText)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private var journeySection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Learning Journey")
                .font(DSTypography.title2())
                .foregroundColor(DSColor.primaryText)

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 16) {
                    ForEach(viewModel.playlistTimeline) { progress in
                        JourneyStageCard(progress: progress,
                                          nextLesson: nextLesson(in: progress.playlist),
                                          isReduceMotion: reduceMotion)
                    }
                }
                .padding(.vertical, 4)
            }
        }
    }

    private func nextLesson(in playlist: LessonPlaylist) -> Lesson? {
        viewModel.lessons(in: playlist).first { !viewModel.isLessonCompleted($0) }
    }
}

// MARK: - Journey Map

private struct JourneyStageCard: View {
    var progress: KindergartenLessonListViewModel.PlaylistProgress
    var nextLesson: Lesson?
    var isReduceMotion: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(progress.playlist.title)
                        .font(DSTypography.title3())
                    Text(progress.playlist.description)
                        .font(DSTypography.caption())
                        .foregroundColor(DSColor.secondaryText)
                }
                Spacer()
                if progress.isComplete {
                    Image(systemName: "checkmark.seal.fill")
                        .foregroundColor(.green)
                        .accessibilityLabel("Playlist complete")
                }
            }

            ProgressView(value: progress.ratio)
                .tint(DSColor.accent)

            if let lesson = nextLesson {
                NavigationLink(value: lesson) {
                    Label("Continue: \(lesson.title)", systemImage: "play.fill")
                        .font(DSTypography.caption())
                }
                .buttonStyle(SecondaryButtonStyle())
            } else {
                Text("All lessons complete")
                    .font(DSTypography.caption())
                    .foregroundColor(.green)
            }
        }
        .padding()
        .frame(width: 260)
        .background(DSColor.surface)
        .cornerRadius(16)
        .shadow(color: isReduceMotion ? .clear : Color.black.opacity(0.08), radius: 8, x: 0, y: 4)
    }
}

// MARK: - Topic Carousels

private struct TopicCarouselSection: View {
    var topic: LessonTopic
    var lessons: [Lesson]
    var isReduceMotion: Bool
    var completionChecker: (Lesson) -> Bool

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Label(topic.displayName, systemImage: topic.symbolName)
                    .font(DSTypography.title2())
                    .foregroundColor(DSColor.primaryText)
                Spacer()
            }

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 16) {
                    ForEach(lessons) { lesson in
                        NavigationLink(value: lesson) {
                            LessonCard(lesson: lesson,
                                       completed: completionChecker(lesson),
                                       isReduceMotion: isReduceMotion)
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
        }
    }
}

private struct LessonCard: View {
    var lesson: Lesson
    var completed: Bool
    var isReduceMotion: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(lesson.title)
                .font(DSTypography.body())
                .foregroundColor(DSColor.primaryText)
                .multilineTextAlignment(.leading)
            Text(lesson.description)
                .font(DSTypography.caption())
                .foregroundColor(DSColor.secondaryText)
                .lineLimit(2)
            Spacer(minLength: 0)
            HStack {
                if completed {
                    Label("Completed", systemImage: "checkmark.circle.fill")
                        .foregroundColor(.green)
                        .font(DSTypography.caption())
                } else if lesson.isAssessment {
                    Label(lesson.assessment?.kind == .quickCheck ? "Quick Check" : "Exit Ticket",
                          systemImage: "clipboard")
                        .foregroundColor(DSColor.accent)
                        .font(DSTypography.caption())
                } else {
                    Label("Play", systemImage: "play.fill")
                        .foregroundColor(DSColor.accent)
                        .font(DSTypography.caption())
                }
                Spacer()
                if let badge = lesson.badge {
                    Image(systemName: badge.imageName)
                        .foregroundColor(DSColor.accent)
                        .accessibilityLabel("Badge opportunity")
                }
            }
        }
        .padding()
        .frame(width: 240, height: 180, alignment: .leading)
        .background(DSColor.surface)
        .cornerRadius(18)
        .shadow(color: isReduceMotion ? .clear : Color.black.opacity(0.06), radius: 6, x: 0, y: 4)
    }
}

// MARK: - Badges & Info

private struct BadgeSection: View {
    var badges: [KindergartenLessonListViewModel.BadgeViewData]

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Badges")
                .font(DSTypography.title2())
            LazyVGrid(columns: [GridItem(.adaptive(minimum: 140), spacing: 16)], spacing: 16) {
                ForEach(badges) { badge in
                    VStack(spacing: 8) {
                        Image(systemName: badge.badge.imageName)
                            .font(.system(size: 36))
                            .foregroundColor(badge.isEarned ? DSColor.accent : DSColor.secondaryText)
                        Text(badge.badge.title)
                            .font(DSTypography.body())
                            .multilineTextAlignment(.center)
                        Text(badge.detail)
                            .font(DSTypography.caption())
                            .foregroundColor(DSColor.secondaryText)
                            .multilineTextAlignment(.center)
                    }
                    .padding()
                    .frame(maxWidth: .infinity)
                    .background(DSColor.surface.opacity(badge.isEarned ? 1 : 0.6))
                    .cornerRadius(16)
                    .overlay(
                        RoundedRectangle(cornerRadius: 16)
                            .stroke(badge.isEarned ? DSColor.accent : DSColor.secondaryText.opacity(0.3), lineWidth: 1)
                    )
                    .accessibilityLabel(badge.isEarned ? "Badge earned: \(badge.badge.title)" : "Badge locked: \(badge.badge.title)")
                }
            }
        }
    }
}

private struct InfoBanner: View {
    var symbol: String
    var title: String
    var message: String

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: symbol)
                .foregroundColor(DSColor.accent)
                .imageScale(.large)
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(DSTypography.title3())
                Text(message)
                    .font(DSTypography.caption())
                    .foregroundColor(DSColor.secondaryText)
            }
        }
        .padding()
        .background(DSColor.surface)
        .cornerRadius(16)
    }
}
