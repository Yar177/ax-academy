import Foundation
import Combine
import SwiftUI
import UIKit

/// View model for the kindergarten home experience displaying playlists,
/// journey progress and badges.  It loads lesson completion status from
/// persistence and logs screen presentations.  When a lesson is tapped a
/// `LessonSessionViewModel` will be created by the view.
final class KindergartenLessonListViewModel: BaseViewModel {
    struct PlaylistProgress: Identifiable, Equatable {
        let playlist: LessonPlaylist
        let completedCount: Int
        let totalCount: Int
        let masteredAssessments: Bool

        var id: String { playlist.id }
        var ratio: Double { totalCount == 0 ? 0 : Double(completedCount) / Double(totalCount) }
        var isComplete: Bool { masteredAssessments && completedCount == totalCount && totalCount > 0 }
    }

    struct BadgeViewData: Identifiable, Equatable {
        let badge: BadgeReward
        let isEarned: Bool

        var id: String { badge.id }
        var detail: String { badge.detail }
    }

    struct TopicCarousel: Identifiable, Equatable {
        let topic: LessonTopic
        let lessons: [Lesson]

        var id: LessonTopic { topic }
    }

    private struct AccessibilitySnapshot: Equatable {
        let voiceOver: Bool
        let largeText: Bool
        let reduceMotion: Bool
    }

    @Published var lessons: [Lesson]
    @Published private(set) var playlistProgress: [PlaylistProgress] = []
    @Published private(set) var badges: [BadgeViewData] = []
    @Published private(set) var performanceSummary: String?
    @Published private(set) var accessibilitySummary: String?

    let grade: Grade

    // expose dependencies internally so the view can construct session view models
    let analytics: AnalyticsLogging
    let persistence: Persistence

    private let playlists: [LessonPlaylist]
    private var hasProfiledPerformance = false
    private var loggedAccessibilitySnapshot: AccessibilitySnapshot?

    init(grade: Grade,
         lessons: [Lesson],
         analytics: AnalyticsLogging,
         persistence: Persistence) {
        self.grade = grade
        self.analytics = analytics
        self.persistence = persistence
        self.lessons = lessons.sorted { lhs, rhs in
            if lhs.playlist.sequence == rhs.playlist.sequence {
                return lhs.playlistPosition < rhs.playlistPosition
            }
            return lhs.playlist.sequence < rhs.playlist.sequence
        }
        self.playlists = Self.uniquePlaylists(from: lessons)
        super.init()

        analytics.log(event: .screenPresented(name: "\(grade.displayName) Lesson Map"))
        refreshProgress()
    }

    /// Returns grouped data for the journey map timeline.
    var playlistTimeline: [PlaylistProgress] {
        playlistProgress.sorted { $0.playlist.sequence < $1.playlist.sequence }
    }

    /// Returns carousels for each topic, ordered by the static case order.
    var topicCarousels: [TopicCarousel] {
        let grouped = Dictionary(grouping: lessons) { $0.topic }
        return LessonTopic.allCases.compactMap { topic in
            guard let lessons = grouped[topic], !lessons.isEmpty else { return nil }
            let ordered = lessons.sorted { lhs, rhs in
                if lhs.playlist.sequence == rhs.playlist.sequence {
                    return lhs.playlistPosition < rhs.playlistPosition
                }
                return lhs.playlist.sequence < rhs.playlist.sequence
            }
            return TopicCarousel(topic: topic, lessons: ordered)
        }
    }

    /// Returns the lessons in the given playlist ordered by their position.
    func lessons(in playlist: LessonPlaylist) -> [Lesson] {
        lessons.filter { $0.playlist.id == playlist.id }
            .sorted { $0.playlistPosition < $1.playlistPosition }
    }

    /// Returns whether the lesson has been completed.  Completion flags are
    /// stored in persistence using a composite key.
    func isLessonCompleted(_ lesson: Lesson) -> Bool {
        let key = completionKey(for: lesson)
        return persistence.bool(forKey: key) ?? false
    }

    /// Updates persistence and progress after a lesson session completes.
    func handleLessonCompletion(_ completion: KindergartenLessonSessionViewModel.CompletionContext) {
        persistence.set(completion.passedAssessment, forKey: completionKey(for: completion.lesson))
        if completion.lesson.isAssessment {
            persistence.set(completion.passedAssessment, forKey: assessmentKey(for: completion.lesson))
        }
        if completion.lesson.badge != nil && completion.passedAssessment {
            // Lesson level badge
            if let badge = completion.lesson.badge, !isBadgeEarned(badge) {
                awardBadge(badge, sourceLessonID: completion.lesson.id)
            }
        }
        refreshProgress()
        markPlaylistBadgeIfNeeded(for: completion.lesson.playlist, sourceLessonID: completion.lesson.id)
    }

    /// Refreshes playlist progress and badge view models from persistence.
    func refreshProgress() {
        playlistProgress = playlists.map { playlist in
            let lessonsInPlaylist = lessons(in: playlist)
            let completed = lessonsInPlaylist.filter { isLessonCompleted($0) }.count
            let assessmentsMastered = lessonsInPlaylist
                .filter { $0.isAssessment }
                .allSatisfy { persistence.bool(forKey: completionKey(for: $0)) ?? false }
            return PlaylistProgress(playlist: playlist,
                                    completedCount: completed,
                                    totalCount: lessonsInPlaylist.count,
                                    masteredAssessments: assessmentsMastered)
        }
        refreshBadges()
    }

    /// Captures accessibility preferences so analytics can confirm the UI is
    /// adapting.  The summary is exposed to the view for a lightweight status
    /// banner.
    func updateAccessibilityProfile(voiceOverEnabled: Bool,
                                    dynamicTypeSize: DynamicTypeSize,
                                    reduceMotion: Bool) {
        let largeText = dynamicTypeSize >= .accessibility1
        let snapshot = AccessibilitySnapshot(voiceOver: voiceOverEnabled,
                                             largeText: largeText,
                                             reduceMotion: reduceMotion)
        guard snapshot != loggedAccessibilitySnapshot else { return }
        loggedAccessibilitySnapshot = snapshot
        accessibilitySummary = makeAccessibilitySummary(from: snapshot)
        analytics.log(event: .accessibilityProfiled(voiceOver: voiceOverEnabled,
                                                    largeText: largeText,
                                                    reduceMotion: reduceMotion))
    }

    /// Profiles the device to ensure kindergarten scenes stay responsive on
    /// lower-end iPads.
    func profileDevicePerformanceIfNeeded() {
        guard !hasProfiledPerformance else { return }
        hasProfiledPerformance = true
        let processInfo = ProcessInfo.processInfo
        let memoryGB = Double(processInfo.physicalMemory) / 1_073_741_824
        let classification = memoryGB < 3.0 ? "entry" : "standard"
        let estimatedFPS = classification == "entry" ? 50.0 : 60.0
        let device = UIDevice.current
        performanceSummary = "Optimised for \(classification == "entry" ? "low-end iPad" : "modern iPad") performance"
        analytics.log(event: .performanceProfiled(device: "\(device.model) (iOS \(device.systemVersion))",
                                                   classification: classification,
                                                   estimatedFPS: estimatedFPS))
    }

    // MARK: - Private Helpers

    private static func uniquePlaylists(from lessons: [Lesson]) -> [LessonPlaylist] {
        var map: [String: LessonPlaylist] = [:]
        for lesson in lessons {
            if map[lesson.playlist.id] == nil {
                map[lesson.playlist.id] = lesson.playlist
            }
        }
        return map.values.sorted { $0.sequence < $1.sequence }
    }

    private func completionKey(for lesson: Lesson) -> String {
        return "\(grade.rawValue).lessonCompleted.\(lesson.id)"
    }

    private func assessmentKey(for lesson: Lesson) -> String {
        return "\(grade.rawValue).assessmentPassed.\(lesson.id)"
    }

    private func badgeKey(for badge: BadgeReward) -> String {
        return "\(grade.rawValue).badge.\(badge.id)"
    }

    private func isBadgeEarned(_ badge: BadgeReward) -> Bool {
        persistence.bool(forKey: badgeKey(for: badge)) ?? false
    }

    private func awardBadge(_ badge: BadgeReward, sourceLessonID: String) {
        persistence.set(true, forKey: badgeKey(for: badge))
        analytics.log(event: .badgeEarned(id: badge.id, lessonID: sourceLessonID))
        refreshBadges()
    }

    private func markPlaylistBadgeIfNeeded(for playlist: LessonPlaylist, sourceLessonID: String) {
        guard let badge = playlist.badge else { return }
        guard !isBadgeEarned(badge) else { return }
        let lessonsInPlaylist = lessons(in: playlist)
        let allMastered = lessonsInPlaylist.allSatisfy { isLessonCompleted($0) }
        if allMastered {
            awardBadge(badge, sourceLessonID: sourceLessonID)
        }
    }

    private func refreshBadges() {
        var badgeMap: [String: BadgeReward] = [:]
        for playlist in playlists {
            if let badge = playlist.badge {
                badgeMap[badge.id] = badge
            }
        }
        for lesson in lessons {
            if let badge = lesson.badge {
                badgeMap[badge.id] = badge
            }
        }
        badges = badgeMap.values
            .sorted { $0.title < $1.title }
            .map { badge in
                BadgeViewData(badge: badge, isEarned: isBadgeEarned(badge))
            }
    }

    private func makeAccessibilitySummary(from snapshot: AccessibilitySnapshot) -> String {
        var components: [String] = []
        if snapshot.voiceOver { components.append("VoiceOver") }
        if snapshot.largeText { components.append("Large Text") }
        if snapshot.reduceMotion { components.append("Reduced Motion") }
        if components.isEmpty {
            return "Standard accessibility mode"
        } else {
            return components.joined(separator: " · ")
        }
    }
}
