import SwiftUI

struct LearningProgressView: View {
    @State private var userStats = UserStats(
        coursesCompleted: 12,
        totalHours: 156,
        currentStreak: 7
    )
    @State private var coursesInProgress = 5
    @State private var averageScore = 87
    
    var body: some View {
        NavigationView {
            ScrollView(showsIndicators: false) {
                VStack(spacing: 24) {
                    // Learning Journey Header Card
                    VStack(spacing: 20) {
                        Text("Your Learning Journey")
                            .font(.system(size: 20, weight: .bold))
                            .frame(maxWidth: .infinity, alignment: .leading)
                        
                        HStack(spacing: 24) {
                            JourneyStatBox(value: "\(userStats.coursesCompleted)", label: "Completed")
                            JourneyStatBox(value: "\(coursesInProgress)", label: "In Progress")
                            JourneyStatBox(value: "\(userStats.totalHours)h", label: "Total Time")
                        }
                        
                        // Achievement Cards
                        LazyVGrid(columns: [
                            GridItem(.flexible()),
                            GridItem(.flexible()),
                            GridItem(.flexible())
                        ], spacing: 16) {
                            AchievementCardNew(
                                icon: "chart.line.uptrend.xyaxis",
                                value: "\(averageScore)%",
                                label: "Avg Score",
                                color: .brandPrimary
                            )
                            AchievementCardNew(
                                icon: "flame.fill",
                                value: "\(userStats.currentStreak)",
                                label: "Day Streak",
                                color: .brandAccent
                            )
                            AchievementCardNew(
                                icon: "trophy.fill",
                                value: "Top 10%",
                                label: "Class Rank",
                                color: .brandWarning
                            )
                        }
                    }
                    .padding(24)
                    .background(
                        LinearGradient(
                            colors: [Color.brandPrimary.opacity(0.1), Color.brandSecondary.opacity(0.05)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .cornerRadius(24)
                    .overlay(
                        RoundedRectangle(cornerRadius: 24)
                            .stroke(Color.brandPrimary.opacity(0.2), lineWidth: 1)
                    )
                    .padding(.horizontal, 20)
                    
                    // Course Progress Section
                    VStack(alignment: .leading, spacing: 16) {
                        Text("Course Progress")
                            .font(.system(size: 22, weight: .bold))
                            .padding(.horizontal, 20)
                        
                        CourseProgressCard(
                            title: "Advanced Web Development",
                            instructor: "Dr. Sami Rezgui",
                            progress: 0.65,
                            completedLessons: 13,
                            totalLessons: 20,
                            lastAccess: "Nov 12",
                            color: .brandPrimary
                        )
                        .padding(.horizontal, 20)
                        
                        CourseProgressCard(
                            title: "Data Structures & Algorithms",
                            instructor: "Prof. Leila Ben Amor",
                            progress: 0.42,
                            completedLessons: 7,
                            totalLessons: 15,
                            lastAccess: "Nov 10",
                            color: .purple
                        )
                        .padding(.horizontal, 20)
                    }
                }
                .padding(.vertical, 8)
            }
            .background(Color(.systemGroupedBackground))
            .navigationTitle("Progress")
            .navigationBarTitleDisplayMode(.large)
        }
    }
}

struct JourneyStatBox: View {
    let value: String
    let label: String
    
    var body: some View {
        VStack(spacing: 8) {
            Text(value)
                .font(.system(size: 28, weight: .bold))
                .foregroundStyle(LinearGradient.brandPrimaryGradient)
            Text(label)
                .font(.system(size: 13, weight: .medium))
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
    }
}

struct AchievementCardNew: View {
    let icon: String
    let value: String
    let label: String
    let color: Color
    
    var body: some View {
        VStack(spacing: 12) {
            ZStack {
                Circle()
                    .fill(color.opacity(0.15))
                    .frame(width: 48, height: 48)
                
                Image(systemName: icon)
                    .font(.system(size: 20, weight: .semibold))
                    .foregroundColor(color)
            }
            
            VStack(spacing: 4) {
                Text(value)
                    .font(.system(size: 18, weight: .bold))
                Text(label)
                    .font(.system(size: 11, weight: .medium))
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 16)
        .background(Color(.systemBackground))
        .cornerRadius(16)
        .shadow(color: Color.black.opacity(0.05), radius: 8, x: 0, y: 4)
    }
}

struct CourseProgressCard: View {
    let title: String
    let instructor: String
    let progress: Double
    let completedLessons: Int
    let totalLessons: Int
    let lastAccess: String
    let color: Color
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 8) {
                    Text(title)
                        .font(.system(size: 17, weight: .bold))
                        .lineLimit(2)
                    
                    Text(instructor)
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(.secondary)
                    
                    HStack(spacing: 6) {
                        Image(systemName: "calendar")
                            .font(.system(size: 12, weight: .medium))
                        Text(lastAccess)
                            .font(.system(size: 13, weight: .medium))
                    }
                    .foregroundColor(.secondary)
                }
                
                Spacer()
                
                Button(action: {}) {
                    Text("View")
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundColor(color)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 8)
                        .background(color.opacity(0.15))
                        .cornerRadius(8)
                }
            }
            
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    Text("\(completedLessons)/\(totalLessons) lessons")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(.secondary)
                    Spacer()
                    Text("\(Int(progress * 100))%")
                        .font(.system(size: 16, weight: .bold))
                        .foregroundColor(color)
                }
                
                GeometryReader { geometry in
                    ZStack(alignment: .leading) {
                        RoundedRectangle(cornerRadius: 8)
                            .fill(Color(.tertiarySystemFill))
                            .frame(height: 10)
                        
                        RoundedRectangle(cornerRadius: 8)
                            .fill(
                                LinearGradient(
                                    colors: [color, color.opacity(0.7)],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                            .frame(width: geometry.size.width * progress, height: 10)
                    }
                }
                .frame(height: 10)
            }
        }
        .padding(20)
        .background(Color(.systemBackground))
        .cornerRadius(20)
        .shadow(color: Color.black.opacity(0.08), radius: 12, x: 0, y: 6)
    }
}
