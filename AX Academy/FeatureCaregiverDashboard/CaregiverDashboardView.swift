import SwiftUI

struct CaregiverDashboardView: View {
    @ObservedObject var viewModel: CaregiverDashboardViewModel
    let safeModeEnabled: Bool
    let recommendedFallback: [String]

    @State private var shareText: String = ""

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                header
                if safeModeEnabled {
                    SafeModeBanner()
                }
                progressSection
                badgeSection
                recommendationsSection
                shareSection
            }
            .padding()
        }
        .navigationTitle(L10n.text("dashboard_title"))
        .navigationBarTitleDisplayMode(.large)
        .onAppear {
            viewModel.recordView()
            viewModel.refresh()
            shareText = viewModel.shareSummaryText()
        }
        .onChange(of: viewModel.gradeSummaries) { _ in
            shareText = viewModel.shareSummaryText()
        }
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(L10n.text("dashboard_subtitle"))
                .font(DSTypography.title())
                .foregroundColor(DSColor.primaryText)
            Text(L10n.text("dashboard_overview_message"))
                .font(DSTypography.body())
                .foregroundColor(.secondary)
        }
    }

    private var progressSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(L10n.text("dashboard_progress_header"))
                .font(DSTypography.title())
            ForEach(viewModel.gradeSummaries) { summary in
                CardView {
                    VStack(alignment: .leading, spacing: 8) {
                        Text(summary.grade.displayName)
                            .font(DSTypography.title())
                        Text(String(format: L10n.string("dashboard_lessons_completed"), summary.completedLessons, summary.totalLessons))
                            .font(DSTypography.body())
                            .foregroundColor(.secondary)
                        ProgressView(value: summary.overallAccuracy, total: 1.0) {
                            Text(L10n.text("dashboard_accuracy"))
                        }
                        .progressViewStyle(.linear)
                    }
                }
            }
            if viewModel.gradeSummaries.isEmpty {
                CardView {
                    Text(L10n.text("dashboard_no_progress"))
                        .font(DSTypography.body())
                        .foregroundColor(.secondary)
                }
            }
        }
    }

    private var badgeSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(L10n.text("dashboard_badges_header"))
                .font(DSTypography.title())
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 16) {
                    ForEach(viewModel.badges) { badge in
                        CardView {
                            VStack(alignment: .leading, spacing: 8) {
                                Text(L10n.text(badge.titleKey))
                                    .font(DSTypography.title())
                                Text(L10n.text(badge.detailKey))
                                    .font(DSTypography.body())
                                    .foregroundColor(.secondary)
                            }
                            .frame(width: 220, alignment: .leading)
                        }
                    }
                }
            }
        }
    }

    private var recommendationsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(L10n.text("dashboard_recommendations_header"))
                .font(DSTypography.title())
            let steps = viewModel.recommendedSteps.isEmpty ? recommendedFallback : viewModel.recommendedSteps
            if steps.isEmpty {
                Text(L10n.text("dashboard_recommendations_empty"))
                    .font(DSTypography.body())
                    .foregroundColor(.secondary)
            } else {
                ForEach(Array(steps.enumerated()), id: \.offset) { step in
                    CardView {
                        Text(step.element)
                            .font(DSTypography.body())
                            .foregroundColor(DSColor.primaryText)
                    }
                }
            }
        }
    }

    private var shareSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(L10n.text("dashboard_export_header"))
                .font(DSTypography.title())
            Text(L10n.text("dashboard_export_message"))
                .font(DSTypography.body())
                .foregroundColor(.secondary)
            if viewModel.canShare() {
                ShareLink(item: shareText) {
                    Label(L10n.text("dashboard_share_button"), systemImage: "square.and.arrow.up")
                }
                .buttonStyle(PrimaryButtonStyle())
                .simultaneousGesture(TapGesture().onEnded {
                    viewModel.recordShare()
                })
            } else {
                Text(L10n.text("dashboard_share_disabled"))
                    .font(DSTypography.body())
                    .foregroundColor(.secondary)
            }
        }
    }
}

private struct SafeModeBanner: View {
    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: "exclamationmark.triangle.fill")
                .foregroundColor(.yellow)
            VStack(alignment: .leading, spacing: 4) {
                Text(L10n.text("safe_mode_title"))
                    .font(DSTypography.title())
                Text(L10n.text("safe_mode_message"))
                    .font(DSTypography.body())
                    .foregroundColor(.secondary)
            }
        }
        .padding()
        .background(DSColor.cardBackground)
        .cornerRadius(12)
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(Color.yellow.opacity(0.6), lineWidth: 2)
        )
    }
}
