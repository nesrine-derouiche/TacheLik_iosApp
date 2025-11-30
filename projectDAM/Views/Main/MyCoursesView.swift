//
//  MyCoursesView.swift
//  projectDAM
//
//  View displaying all courses owned by the student
//

import SwiftUI

struct MyCoursesView: View {
    @StateObject private var viewModel = DIContainer.shared.makeStudentHomeViewModel()
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(spacing: 20) {
                // Header Stats
                headerStats
                
                // Courses List
                if viewModel.isLoading {
                    loadingView
                } else if viewModel.allCourses.isEmpty {
                    emptyStateView
                } else {
                    coursesListView
                }
            }
            .padding(.vertical, 16)
        }
        .background(Color(.systemGroupedBackground))
        .navigationTitle("My Courses")
        .navigationBarTitleDisplayMode(.large)
        .task {
            await viewModel.loadData()
        }
        .refreshable {
            await viewModel.refresh()
        }
    }
    
    // MARK: - Header Stats
    private var headerStats: some View {
        HStack(spacing: 16) {
            StatBox(
                value: "\(viewModel.totalCourses)",
                label: "Total Courses",
                icon: "book.fill",
                color: .brandPrimary
            )
            
            StatBox(
                value: viewModel.formattedTotalHours,
                label: "Learning Hours",
                icon: "clock.fill",
                color: .blue
            )
            
            StatBox(
                value: "\(viewModel.classesSummary.count)",
                label: "Classes",
                icon: "folder.fill",
                color: .purple
            )
        }
        .padding(.horizontal, 20)
    }
    
    // MARK: - Loading View
    private var loadingView: some View {
        VStack(spacing: 16) {
            ProgressView()
                .scaleEffect(1.2)
            Text("Loading your courses...")
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 60)
    }
    
    // MARK: - Empty State
    private var emptyStateView: some View {
        VStack(spacing: 20) {
            Image(systemName: "book.closed")
                .font(.system(size: 60, weight: .light))
                .foregroundColor(.secondary.opacity(0.5))
            
            VStack(spacing: 8) {
                Text("No Courses Yet")
                    .font(.system(size: 20, weight: .bold))
                
                Text("Start exploring and purchase your first course!")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 60)
        .padding(.horizontal, 40)
    }
    
    // MARK: - Courses List
    private var coursesListView: some View {
        LazyVStack(spacing: 16) {
            ForEach(viewModel.recentCourses) { ownedCourse in
                NavigationLink {
                    LessonsView(
                        courseId: ownedCourse.course.id,
                        accessType: .privateCourse,
                        isOwned: true
                    )
                } label: {
                    MyCourseCard(course: ownedCourse.course)
                }
                .buttonStyle(.plain)
            }
        }
        .padding(.horizontal, 20)
    }
}

// MARK: - Stat Box
private struct StatBox: View {
    let value: String
    let label: String
    let icon: String
    let color: Color
    
    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: icon)
                .font(.system(size: 20, weight: .semibold))
                .foregroundColor(color)
            
            Text(value)
                .font(.system(size: 22, weight: .bold))
                .foregroundColor(.primary)
            
            Text(label)
                .font(.system(size: 10, weight: .medium))
                .foregroundColor(.secondary)
                .lineLimit(1)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 16)
        .background(Color(.systemBackground))
        .cornerRadius(16)
        .shadow(color: Color.black.opacity(0.04), radius: 8, x: 0, y: 4)
    }
}

// MARK: - My Course Card
private struct MyCourseCard: View {
    let course: OwnedCourseDetail
    
    var body: some View {
        HStack(spacing: 16) {
            // Course Icon
            ZStack {
                RoundedRectangle(cornerRadius: 14)
                    .fill(
                        LinearGradient(
                            colors: [.brandPrimary, .brandPrimary.opacity(0.7)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 64, height: 64)
                
                Image(systemName: "book.fill")
                    .font(.system(size: 26, weight: .semibold))
                    .foregroundColor(.white)
            }
            .shadow(color: Color.brandPrimary.opacity(0.3), radius: 6, x: 0, y: 3)
            
            // Course Info
            VStack(alignment: .leading, spacing: 6) {
                Text(course.name)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(.primary)
                    .lineLimit(2)
                
                if let author = course.author {
                    HStack(spacing: 4) {
                        Image(systemName: "person.fill")
                            .font(.system(size: 10))
                        Text(author.username)
                            .font(.system(size: 13, weight: .medium))
                    }
                    .foregroundColor(.secondary)
                }
                
                if let duration = course.duration, duration > 0 {
                    HStack(spacing: 4) {
                        Image(systemName: "clock.fill")
                            .font(.system(size: 10))
                        Text(formatDuration(duration))
                            .font(.system(size: 12, weight: .medium))
                    }
                    .foregroundColor(.secondary)
                }
            }
            
            Spacer()
            
            // Arrow
            Image(systemName: "chevron.right")
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(.secondary.opacity(0.5))
        }
        .padding(16)
        .background(Color(.systemBackground))
        .cornerRadius(18)
        .shadow(color: Color.black.opacity(0.05), radius: 8, x: 0, y: 4)
    }
    
    private func formatDuration(_ hours: Double) -> String {
        if hours >= 1 {
            return String(format: "%.1f hours", hours)
        } else {
            return String(format: "%.0f min", hours * 60)
        }
    }
}
