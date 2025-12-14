//
//  AdminDashboardView.swift
//  projectDAM
//
//  Created on 11/10/2025.
//

import SwiftUI

struct AdminDashboardView: View {
    @ObservedObject private var authService = DIContainer.shared.authService as! AuthService
    @State private var activeQuickAction: AdminQuickAction?
    @State private var totalStudents = 2847
    @State private var totalMentors = 47
    @State private var activeCourses = 128
    @State private var completionRate = 73
    @State private var pendingApprovals = 3
    @State private var chartData: [Double] = [65, 68, 70, 72, 73, 75, 74]
    
    private var currentUser: User? {
        authService.currentUser
    }
    
    private var userCredits: Int {
        currentUser?.credit ?? 0
    }
    
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

                        // Quick Actions Row
                        quickActionsSection()

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
                ToolbarItem(placement: .navigationBarLeading) {
                    UnifiedTopAppBarLogoView()
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    UnifiedTopAppBarActions(
                        userCredits: userCredits,
                        isShowingWalletAlert: .constant(false),
                        showNotifications: false
                    )
                }
            }
            .alert(item: $activeQuickAction) { action in
                Alert(
                    title: Text(action.title),
                    message: Text(action.placeholderMessage),
                    dismissButton: .default(Text("Awesome"))
                )
            }
        }
        .navigationViewStyle(.stack)
    }
    
    // MARK: - Header Section
    private func headerSection() -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Welcome back, \(currentUser?.username ?? "Admin")")
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
    
    // MARK: - Quick Actions Section
    private func quickActionsSection() -> some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack(spacing: 12) {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Quick Actions")
                        .font(.system(size: 16, weight: .bold))
                        .foregroundColor(.primary)
                    Text("Jump into the tools you need most")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(.secondary)
                }
                
                Spacer(minLength: 12)
                
                Image(systemName: "sparkles")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(.brandPrimary)
                    .padding(8)
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(Color.brandPrimary.opacity(0.08))
                    )
            }
            
            HStack(spacing: 16) {
                ForEach(AdminQuickAction.allCases) { action in
                    AdminQuickActionTile(action: action) {
                        UIImpactFeedbackGenerator(style: .medium).impactOccurred()
                        withAnimation(.spring(response: 0.45, dampingFraction: 0.82)) {
                            activeQuickAction = action
                        }
                    }
                }
            }
            .padding(.vertical, DS.paddingMD / 2)
            .padding(.horizontal, DS.paddingMD)
            .background(
                RoundedRectangle(cornerRadius: DS.cornerRadiusMD + 6)
                    .fill(Color(.systemBackground).opacity(0.7))
                    .overlay(
                        RoundedRectangle(cornerRadius: DS.cornerRadiusMD + 6)
                            .stroke(Color.brandPrimary.opacity(0.08), lineWidth: 1)
                    )
                    .shadow(color: Color.black.opacity(0.05), radius: 20, x: 0, y: 12)
            )
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

// MARK: - Admin Quick Action Models & Components
private enum AdminQuickAction: String, CaseIterable, Identifiable {
    case classes
    case category
    case store
    case wallet
    
    var id: String { rawValue }
    
    var title: String {
        switch self {
        case .classes: return "Classes"
        case .category: return "Category"
        case .store: return "Store"
        case .wallet: return "Wallet"
        }
    }
    
    var subtitle: String {
        switch self {
        case .classes: return "Manage cohorts"
        case .category: return "Edit course tags"
        case .store: return "Review assets"
        case .wallet: return "Track balances"
        }
    }
    
    var icon: String {
        switch self {
        case .classes: return "rectangle.grid.2x2.fill"
        case .category: return "square.grid.3x3.fill"
        case .store: return "cart.fill"
        case .wallet: return "creditcard.fill"
        }
    }
    
    var accentColor: Color {
        switch self {
        case .classes: return .brandPrimary
        case .category: return .brandSecondary
        case .store: return .brandWarning
        case .wallet: return .brandSuccess
        }
    }
    
    var gradient: LinearGradient {
        LinearGradient(
            colors: [accentColor.opacity(0.28), accentColor.opacity(0.08)],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }
    
    var placeholderMessage: String {
        switch self {
        case .classes:
            return "Classes management is coming soon. Stay tuned for a delightful workflow!"
        case .category:
            return "Category curation will soon let you reshape the catalog in seconds."
        case .store:
            return "Store operations are almost ready. Keep an eye out for inventory insights."
        case .wallet:
            return "Wallet insights will appear here once the financial suite ships."
        }
    }
}

private struct AdminQuickActionTile: View {
    let action: AdminQuickAction
    let onTap: () -> Void
    @State private var isPressed = false
    
    var body: some View {
        Button {
            withAnimation(.easeInOut(duration: 0.14)) { isPressed = true }
            onTap()
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                withAnimation(.easeOut(duration: 0.25)) { isPressed = false }
            }
        } label: {
            VStack(spacing: 8) {
                ZStack {
                    Circle()
                        .fill(action.accentColor.opacity(0.12))
                        .frame(width: 56, height: 56)
                        .overlay(
                            Circle()
                                .stroke(action.accentColor.opacity(0.18), lineWidth: 1)
                        )
                        .shadow(color: action.accentColor.opacity(0.12), radius: 12, x: 0, y: 6)
                    Image(systemName: action.icon)
                        .font(.system(size: 22, weight: .semibold))
                        .foregroundColor(action.accentColor)
                }
                
                Text(action.title)
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundColor(.primary)
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)
                    .frame(maxWidth: .infinity)
                
                Text("Coming soon")
                    .font(.system(size: 10, weight: .medium))
                    .foregroundColor(action.accentColor.opacity(0.8))
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, DS.paddingMD / 2)
            .contentShape(Rectangle())
            .scaleEffect(isPressed ? 0.94 : 1)
            .animation(.spring(response: 0.5, dampingFraction: 0.85), value: isPressed)
        }
        .buttonStyle(.plain)
        .accessibilityLabel(action.title)
        .accessibilityHint(action.subtitle)
    }
}

#Preview {
    AdminDashboardView()
}
