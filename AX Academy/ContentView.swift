//
//  ContentView.swift
//  AX Academy
//
//  Created by Hoshiar Sher on 10/5/25.
//

import SwiftUI

struct ContentView: View {
    @State private var selectedGrade: Grade?
    @State private var gradeProgress: [GradeProgressSummary] = []

    var body: some View {
        NavigationStack {
            VStack(spacing: 40) {
                // App Header
                VStack(spacing: 16) {
                    Image(systemName: "graduationcap.fill")
                        .font(.system(size: 60))
                        .foregroundStyle(.blue)
                    
                    Text("AX Academy")
                        .font(.largeTitle)
                        .fontWeight(.bold)
                    
                    Text("Choose your grade level to start learning")
                        .font(.title3)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                }
                .padding(.top, 40)

                if !gradeProgress.isEmpty {
                    ProgressOverviewCard(summaries: gradeProgress)
                        .padding(.horizontal, 20)
                }

                // Grade Selection
                VStack(spacing: 20) {
                    ForEach(Grade.allCases, id: \.self) { grade in
                        GradeSelectionCard(grade: grade) {
                            selectedGrade = grade
                        }
                    }
                }
                .padding(.horizontal, 20)
                
                Spacer()
            }
            .navigationTitle("Welcome")
            .navigationBarTitleDisplayMode(.inline)
            .fullScreenCover(item: $selectedGrade) { grade in
                gradeView(for: grade)
            }
            .onAppear(perform: loadProgress)
            .onChange(of: selectedGrade) { newValue in
                if newValue == nil {
                    loadProgress()
                }
            }
        }
    }

    @ViewBuilder
    private func gradeView(for grade: Grade) -> some View {
        let container = DependencyContainer.shared
        let contentProvider = container.resolve(ContentProviding.self)
        let analytics = container.resolve(AnalyticsLogging.self)
        let persistence = container.resolve(Persistence.self)
        
        switch grade {
        case .kindergarten:
            let coordinator = KindergartenCoordinator(
                contentProvider: contentProvider,
                analytics: analytics,
                persistence: persistence
            )
            coordinator.start()
                .onAppear {
                    analytics.log(event: .screenPresented(name: "Kindergarten"))
                }
                
        case .grade1:
            let coordinator = Grade1Coordinator(
                contentProvider: contentProvider,
                analytics: analytics,
                persistence: persistence
            )
            coordinator.start()
                .onAppear {
                    analytics.log(event: .screenPresented(name: "Grade1"))
                }
        }
    }
}

private extension ContentView {
    struct GradeProgressSummary: Identifiable {
        let grade: Grade
        let completedLessons: Int
        let totalLessons: Int

        var id: Grade { grade }
        var progress: Double { totalLessons == 0 ? 0 : Double(completedLessons) / Double(totalLessons) }
    }

    func loadProgress() {
        let container = DependencyContainer.shared
        let provider = container.resolve(ContentProviding.self)
        let persistence = container.resolve(Persistence.self)
        let analytics = container.resolve(AnalyticsLogging.self)
        var summaries: [GradeProgressSummary] = []
        for grade in Grade.allCases {
            let lessons = provider.lessons(for: grade)
            let completed = lessons.filter { lesson in
                let key = "\(grade.rawValue).lessonCompleted.\(lesson.id)"
                return persistence.bool(forKey: key) ?? false
            }.count
            summaries.append(GradeProgressSummary(grade: grade,
                                                  completedLessons: completed,
                                                  totalLessons: lessons.count))
        }
        gradeProgress = summaries
        analytics.log(event: .multiGradeOverviewViewed)
    }
}

private struct ProgressOverviewCard: View {
    let summaries: [ContentView.GradeProgressSummary]

    var body: some View {
        CardView {
            VStack(alignment: .leading, spacing: 16) {
                Text("Progress Overview")
                    .font(DSTypography.title())
                    .foregroundColor(DSColor.primaryText)
                ForEach(summaries) { summary in
                    VStack(alignment: .leading, spacing: 4) {
                        HStack {
                            Text(summary.grade.displayName)
                                .font(DSTypography.body())
                            Spacer()
                            Text("\(summary.completedLessons)/\(summary.totalLessons)")
                                .font(DSTypography.caption())
                                .foregroundColor(DSColor.secondaryText)
                        }
                        ProgressView(value: summary.progress)
                            .tint(DSColor.accent)
                    }
                }
            }
        }
    }
}

struct GradeSelectionCard: View {
    let grade: Grade
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack {
                VStack(alignment: .leading, spacing: 8) {
                    Text(grade.displayName)
                        .font(.title2)
                        .fontWeight(.semibold)
                        .foregroundStyle(.primary)
                    
                    Text("Tap to start learning")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
                
                Spacer()
                
                Image(systemName: "arrow.right.circle.fill")
                    .font(.title2)
                    .foregroundStyle(.blue)
            }
            .padding(20)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(.background)
                    .shadow(color: .black.opacity(0.1), radius: 8, x: 0, y: 4)
            )
        }
        .buttonStyle(.plain)
    }
}

#Preview {
    ContentView()
}
