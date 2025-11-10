//
//  AdminDashboardView.swift
//  projectDAM
//
//  Created on 11/10/2025.
//

import SwiftUI

struct AdminDashboardView: View {
    @State private var totalStudents = 2847
    @State private var totalMentors = 47
    @State private var activeCourses = 128
    @State private var completionRate = 73
    @State private var pendingApprovals = 3
    @State private var chartData: [Double] = [65, 68, 70, 72, 73, 75, 74]
    
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
                        
                        // Stats Cards Grid
                        statsGrid()
                        
                        // Pending Approvals Section
                        pendingApprovalsSection()
                        
                        // Platform Analytics
                        analyticsSection()
                        
                        // Recent Activity
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
                    Text("Admin Dashboard")
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
            Text("Welcome back, Admin")
                .font(.system(size: 24, weight: .bold))
                .foregroundColor(.primary)
            
            Text("Platform Overview & Management")
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
    
    // MARK: - Stats Grid
    private func statsGrid() -> some View {
        VStack(spacing: 12) {
            HStack(spacing: 12) {
                AdminStatCard(
                    icon: "person.2.fill",
                    iconColor: .brandPrimary,
                    title: "Total Students",
                    value: "2,847",
                    trend: "+12%",
                    trendColor: .brandSuccess
                )
                
                AdminStatCard(
                    icon: "person.fill",
                    iconColor: .brandError,
                    title: "Total Mentors",
                    value: "47",
                    trend: "+3",
                    trendColor: .brandSuccess
                )
            }
            
            HStack(spacing: 12) {
                AdminStatCard(
                    icon: "book.fill",
                    iconColor: .brandSecondary,
                    title: "Active Courses",
                    value: "128",
                    trend: "+8",
                    trendColor: .brandSuccess
                )
                
                AdminStatCard(
                    icon: "chart.line.uptrend.xyaxis",
                    iconColor: .brandWarning,
                    title: "Completion Rate",
                    value: "73%",
                    trend: "+5%",
                    trendColor: .brandSuccess
                )
            }
        }
    }
    
    // MARK: - Pending Approvals Section
    private func pendingApprovalsSection() -> some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Pending Approvals")
                    .font(.system(size: 16, weight: .bold))
                    .foregroundColor(.primary)
                
                Spacer()
                
                // Badge with pending count
                ZStack(alignment: .center) {
                    Circle()
                        .fill(Color.brandError)
                    Text("\(pendingApprovals)")
                        .font(.system(size: 12, weight: .bold))
                        .foregroundColor(.white)
                }
                .frame(width: 28, height: 28)
            }
            
            VStack(spacing: 10) {
                // Approval Item 1
                ApprovalItemView(
                    icon: "person.fill",
                    title: "Dr. Amine Khelifi",
                    subtitle: "AI & Machine Learning",
                    badge: "mentor",
                    timeAgo: "2h ago",
                    hasApproved: false,
                    hasRejected: false
                )
                
                Divider()
                    .padding(.vertical, 4)
                
                // Approval Item 2
                ApprovalItemView(
                    icon: "book.fill",
                    title: "Blockchain Development",
                    subtitle: "by Eng. Sara Ben Salah",
                    badge: "course",
                    timeAgo: "5h ago",
                    hasApproved: false,
                    hasRejected: false
                )
                
                Divider()
                    .padding(.vertical, 4)
                
                // Approval Item 3
                ApprovalItemView(
                    icon: "person.fill",
                    title: "Prof. Hichem Mansour",
                    subtitle: "Software Engineering",
                    badge: "mentor",
                    timeAgo: "1d ago",
                    hasApproved: false,
                    hasRejected: false
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
    
    // MARK: - Analytics Section
    private func analyticsSection() -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Platform Analytics")
                .font(.system(size: 16, weight: .bold))
                .foregroundColor(.primary)
            
            VStack(spacing: 24) {
                // Chart Placeholder
                ZStack {
                    RoundedRectangle(cornerRadius: DS.cornerRadiusMD)
                        .fill(
                            LinearGradient(
                                colors: [
                                    Color.brandPrimary.opacity(0.05),
                                    Color.brandSecondary.opacity(0.05)
                                ],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                    
                    VStack(spacing: 12) {
                        Image(systemName: "chart.bar.fill")
                            .font(.system(size: 40))
                            .foregroundColor(.brandPrimary.opacity(0.3))
                        
                        Text("Analytics Dashboard")
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(.secondary)
                        
                        Text("Student engagement & course performance")
                            .font(.system(size: 12, weight: .regular))
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                    }
                    .frame(maxWidth: .infinity)
                }
                .frame(height: 180)
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
    
    // MARK: - Recent Activity Section
    private func recentActivitySection() -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Recent Activity")
                .font(.system(size: 16, weight: .bold))
                .foregroundColor(.primary)
            
            VStack(spacing: 12) {
                ActivityItemView(
                    icon: "person.badge.plus.fill",
                    title: "New student enrolled",
                    subtitle: "Web Development",
                    timeAgo: "5 min ago"
                )
                
                ActivityItemView(
                    icon: "checkmark.circle.fill",
                    title: "Course completed",
                    subtitle: "Ahmed Ben Ali",
                    timeAgo: "12 min ago"
                )
                
                ActivityItemView(
                    icon: "person.badge.plus.fill",
                    title: "New mentor joined",
                    subtitle: "Dr. Leila Rezgui",
                    timeAgo: "1h ago"
                )
                
                ActivityItemView(
                    icon: "pencil.circle.fill",
                    title: "Course updated",
                    subtitle: "Mobile Development",
                    timeAgo: "2h ago"
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

// MARK: - Admin Stat Card Component
private struct AdminStatCard: View {
    let icon: String
    let iconColor: Color
    let title: String
    let value: String
    let trend: String
    let trendColor: Color
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: icon)
                    .font(.system(size: 20))
                    .foregroundColor(iconColor)
                
                Spacer()
                
                Image(systemName: "arrow.up.right")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundColor(trendColor)
            }
            
            VStack(alignment: .leading, spacing: 4) {
                Text(value)
                    .font(.system(size: 20, weight: .bold))
                    .foregroundColor(.primary)
                
                HStack(spacing: 6) {
                    Text(title)
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(.secondary)
                    
                    Spacer()
                    
                    Text(trend)
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundColor(trendColor)
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

// MARK: - Approval Item Component
private struct ApprovalItemView: View {
    let icon: String
    let title: String
    let subtitle: String
    let badge: String
    let timeAgo: String
    let hasApproved: Bool
    let hasRejected: Bool
    
    @State private var localApproved = false
    @State private var localRejected = false
    
    var body: some View {
        VStack(spacing: 12) {
            HStack(spacing: 12) {
                ZStack {
                    Circle()
                        .fill(
                            LinearGradient(
                                colors: [
                                    Color.brandPrimary.opacity(0.2),
                                    Color.brandAccent.opacity(0.1)
                                ],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                    
                    Image(systemName: icon)
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(.brandPrimary)
                }
                .frame(width: 44, height: 44)
                
                VStack(alignment: .leading, spacing: 4) {
                    HStack(spacing: 8) {
                        Text(title)
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundColor(.primary)
                        
                        Text(badge.uppercased())
                            .font(.system(size: 10, weight: .bold))
                            .foregroundColor(.white)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 2)
                            .background(Color.brandPrimary.opacity(0.7))
                            .cornerRadius(4)
                    }
                    
                    Text(subtitle)
                        .font(.system(size: 12, weight: .regular))
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                VStack(alignment: .trailing, spacing: 4) {
                    Image(systemName: "clock.fill")
                        .font(.system(size: 12))
                        .foregroundColor(.secondary)
                    
                    Text(timeAgo)
                        .font(.system(size: 10, weight: .medium))
                        .foregroundColor(.secondary)
                }
            }
            
            // Action Buttons
            HStack(spacing: 12) {
                Button(action: { localApproved.toggle() }) {
                    HStack(spacing: 8) {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.system(size: 16))
                        Text("Approve")
                            .font(.system(size: 14, weight: .semibold))
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 10)
                    .foregroundColor(.white)
                    .background(
                        RoundedRectangle(cornerRadius: 8)
                            .fill(Color.brandSuccess.opacity(localApproved ? 1 : 0.8))
                    )
                }
                
                Button(action: { localRejected.toggle() }) {
                    HStack(spacing: 8) {
                        Image(systemName: "xmark.circle.fill")
                            .font(.system(size: 16))
                        Text("Reject")
                            .font(.system(size: 14, weight: .semibold))
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 10)
                    .foregroundColor(.brandError)
                    .background(
                        RoundedRectangle(cornerRadius: 8)
                            .stroke(Color.brandError.opacity(0.5), lineWidth: 1.5)
                    )
                }
            }
        }
    }
}

// MARK: - Activity Item Component
private struct ActivityItemView: View {
    let icon: String
    let title: String
    let subtitle: String
    let timeAgo: String
    
    var body: some View {
        HStack(spacing: 12) {
            ZStack {
                Circle()
                    .fill(
                        LinearGradient(
                            colors: [
                                Color.brandPrimary.opacity(0.2),
                                Color.brandAccent.opacity(0.1)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                
                Image(systemName: icon)
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(.brandPrimary)
            }
            .frame(width: 40, height: 40)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundColor(.primary)
                
                Text(subtitle)
                    .font(.system(size: 11, weight: .regular))
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            Text(timeAgo)
                .font(.system(size: 11, weight: .medium))
                .foregroundColor(.secondary)
        }
    }
}

#Preview {
    AdminDashboardView()
}
