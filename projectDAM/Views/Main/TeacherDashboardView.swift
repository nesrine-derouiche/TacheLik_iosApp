//
//  TeacherDashboardView.swift
//  projectDAM
//
//  Created on 11/10/2025.
//

import SwiftUI

struct TeacherDashboardView: View {
    @State private var totalStudents = 342
    @State private var activeCourses = 5
    @State private var avgRating = 4.8
    @State private var totalQuestions = 23
    
    var body: some View {
        NavigationView {
            ZStack {
                // Background
                Color(.systemBackground)
                    .ignoresSafeArea()
                
                ScrollView(.vertical, showsIndicators: false) {
                    VStack(spacing: 20) {
                        // Header
                        headerSection()
                        
                        // Stats Grid
                        statsGrid()
                        
                        // Quick Actions
                        quickActionsSection()
                        
                        // Recent Student Activity
                        recentActivitySection()
                        
                        Spacer(minLength: 20)
                    }
                    .padding(.horizontal, DS.paddingMD)
                    .padding(.vertical, DS.paddingMD)
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .principal) {
                    Text("Teacher Dashboard")
                        .font(.system(size: 18, weight: .bold))
                        .foregroundColor(.brandPrimary)
                }
            }
        }
        .navigationViewStyle(.stack)
    }
    
    // MARK: - Header Section
    private func headerSection() -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Welcome, Instructor")
                .font(.system(size: 24, weight: .bold))
                .foregroundColor(.primary)
            
            Text("Here's your teaching overview")
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
    
    // MARK: - Stats Grid
    private func statsGrid() -> some View {
        VStack(spacing: 12) {
            HStack(spacing: 12) {
                TeacherStatCard(
                    icon: "person.2.fill",
                    iconColor: .brandPrimary,
                    title: "Total Students",
                    value: "\(totalStudents)",
                    subtitle: nil
                )
                
                TeacherStatCard(
                    icon: "book.fill",
                    iconColor: .brandSecondary,
                    title: "Active Courses",
                    value: "\(activeCourses)",
                    subtitle: nil
                )
            }
            
            HStack(spacing: 12) {
                TeacherStatCard(
                    icon: "star.fill",
                    iconColor: .brandWarning,
                    title: "Avg Rating",
                    value: "\(String(format: "%.1f", avgRating))",
                    subtitle: "out of 5.0"
                )
                
                TeacherStatCard(
                    icon: "message.fill",
                    iconColor: .brandSuccess,
                    title: "Questions",
                    value: "\(totalQuestions)",
                    subtitle: "pending answers"
                )
            }
        }
    }
    
    // MARK: - Quick Actions Section
    private func quickActionsSection() -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Quick Actions")
                .font(.system(size: 16, weight: .bold))
                .foregroundColor(.primary)
            
            VStack(spacing: 10) {
                HStack(spacing: 12) {
                    QuickActionButton(
                        icon: "plus.circle.fill",
                        title: "New Lesson",
                        color: .brandPrimary
                    )
                    
                    QuickActionButton(
                        icon: "message.circle.fill",
                        title: "Answer Q&A",
                        color: .brandError
                    )
                }
                
                HStack(spacing: 12) {
                    QuickActionButton(
                        icon: "chart.bar.fill",
                        title: "Analytics",
                        color: .brandSecondary
                    )
                    
                    QuickActionButton(
                        icon: "person.fill",
                        title: "Students",
                        color: .brandSuccess
                    )
                }
            }
        }
    }
    
    // MARK: - Recent Activity Section
    private func recentActivitySection() -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Recent Student Activity")
                .font(.system(size: 16, weight: .bold))
                .foregroundColor(.primary)
            
            VStack(spacing: 12) {
                StudentActivityItemView(
                    initials: "ABA",
                    name: "Ahmed Ben Ali",
                    course: "Web Dev",
                    action: "completed assignment",
                    timeAgo: "2h ago",
                    actionIcon: "checkmark.circle.fill",
                    actionColor: .brandSuccess
                )
                
                StudentActivityItemView(
                    initials: "SM",
                    name: "Sarra Mansour",
                    course: "React Course",
                    action: "asked a question",
                    timeAgo: "4h ago",
                    actionIcon: "questionmark.circle.fill",
                    actionColor: .brandWarning
                )
                
                StudentActivityItemView(
                    initials: "YT",
                    name: "Youssef Trabelsi",
                    course: "Full Stack Dev",
                    action: "submitted project",
                    timeAgo: "6h ago",
                    actionIcon: "arrow.up.circle.fill",
                    actionColor: .brandPrimary
                )
            }
            .padding(.vertical, DS.paddingMD)
            .padding(.horizontal, DS.paddingMD)
            .background(
                RoundedRectangle(cornerRadius: DS.cornerRadiusMD)
                    .fill(Color(.systemBackground).opacity(0.5))
                    .stroke(Color.brandPrimary.opacity(0.1), lineWidth: 1)
            )
        }
    }
}

// MARK: - Teacher Stat Card Component
private struct TeacherStatCard: View {
    let icon: String
    let iconColor: Color
    let title: String
    let value: String
    let subtitle: String?
    
    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Image(systemName: icon)
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundColor(iconColor)
                
                Spacer()
                
                Image(systemName: "arrow.up.right")
                    .font(.system(size: 10, weight: .semibold))
                    .foregroundColor(.brandSuccess)
            }
            
            VStack(alignment: .leading, spacing: 4) {
                Text(value)
                    .font(.system(size: 24, weight: .bold))
                    .foregroundColor(.primary)
                
                Text(title)
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(.secondary)
                
                if let subtitle = subtitle {
                    Text(subtitle)
                        .font(.system(size: 11, weight: .regular))
                        .foregroundColor(.secondary)
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(DS.paddingMD)
        .background(
            RoundedRectangle(cornerRadius: DS.cornerRadiusMD)
                .fill(Color(.systemBackground))
                .stroke(Color.brandPrimary.opacity(0.1), lineWidth: 1)
        )
    }
}

// MARK: - Quick Action Button Component
private struct QuickActionButton: View {
    let icon: String
    let title: String
    let color: Color
    
    var body: some View {
        Button(action: {}) {
            VStack(spacing: 8) {
                ZStack {
                    Circle()
                        .fill(
                            LinearGradient(
                                colors: [
                                    color.opacity(0.2),
                                    color.opacity(0.1)
                                ],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                    
                    Image(systemName: icon)
                        .font(.system(size: 22, weight: .semibold))
                        .foregroundColor(color)
                }
                .frame(height: 56)
                
                Text(title)
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundColor(.primary)
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, DS.paddingMD)
            .background(
                RoundedRectangle(cornerRadius: DS.cornerRadiusMD)
                    .fill(Color(.systemBackground))
                    .stroke(color.opacity(0.2), lineWidth: 1)
            )
        }
    }
}

// MARK: - Student Activity Item Component
private struct StudentActivityItemView: View {
    let initials: String
    let name: String
    let course: String
    let action: String
    let timeAgo: String
    let actionIcon: String
    let actionColor: Color
    
    var body: some View {
        HStack(spacing: 12) {
            // Avatar
            ZStack {
                Circle()
                    .fill(
                        LinearGradient(
                            colors: [
                                Color.brandPrimary.opacity(0.3),
                                Color.brandAccent.opacity(0.2)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                
                Text(initials)
                    .font(.system(size: 12, weight: .bold))
                    .foregroundColor(.brandPrimary)
            }
            .frame(width: 40, height: 40)
            
            // Info
            VStack(alignment: .leading, spacing: 4) {
                HStack(spacing: 6) {
                    Text(name)
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundColor(.primary)
                    
                    Image(systemName: actionIcon)
                        .font(.system(size: 11, weight: .semibold))
                        .foregroundColor(actionColor)
                }
                
                HStack(spacing: 6) {
                    Text(course)
                        .font(.system(size: 11, weight: .medium))
                        .foregroundColor(.secondary)
                    
                    Text("•")
                        .foregroundColor(.secondary)
                    
                    Text(action)
                        .font(.system(size: 11, weight: .medium))
                        .foregroundColor(.secondary)
                }
            }
            
            Spacer()
            
            Text(timeAgo)
                .font(.system(size: 11, weight: .medium))
                .foregroundColor(.secondary)
        }
    }
}

#Preview {
    TeacherDashboardView()
}
