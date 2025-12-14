import Foundation

// MARK: - Student Home (/student-dashboard/home)

struct StudentHomeResponse: Codable {
    let success: Bool
    let message: String?
    let data: StudentHomeData?
}

struct StudentHomeData: Codable, Equatable {
    let meta: HomeMeta
    let capabilities: StudentHomeCapabilities
    let user: HomeUser
    let quickActions: StudentQuickActions
    let continueLearning: [StudentContinueLearningItem]
    let goals: StudentGoals
    let skeleton: StudentHomeSkeleton

    static let empty = StudentHomeData(
        meta: HomeMeta(generatedAt: nil, apiVersion: nil),
        capabilities: StudentHomeCapabilities(progressTracking: false, nextLesson: false, streaks: false, watchTracking: false, goalTargets: false),
        user: HomeUser(id: "", username: "", role: "", isTeacher: false, image: nil, credits: 0),
        quickActions: StudentQuickActions(unreadMessages: 0, ownedCourses: 0, quizzesTaken: 0, badgesEarned: 0),
        continueLearning: [],
        goals: StudentGoals(daily: StudentGoalWindow(xp: GoalXp(value: 0, unit: "score"), quizzesCompleted: 0, message: nil),
                           weekly: StudentGoalWindow(xp: GoalXp(value: 0, unit: "score"), quizzesCompleted: 0, message: nil)),
        skeleton: StudentHomeSkeleton(sections: StudentHomeSkeletonSections(continueLearningItems: 0, quickActions: true, goals: true))
    )
}

struct StudentHomeCapabilities: Codable, Equatable {
    let progressTracking: Bool
    let nextLesson: Bool
    let streaks: Bool
    let watchTracking: Bool
    let goalTargets: Bool
}

struct HomeUser: Codable, Equatable {
    let id: String
    let username: String
    let role: String
    let isTeacher: Bool
    let image: String?
    let credits: Int
}

struct StudentQuickActions: Codable, Equatable {
    let unreadMessages: Int
    let ownedCourses: Int
    let quizzesTaken: Int
    let badgesEarned: Int
}

struct StudentContinueLearningItem: Codable, Equatable, Identifiable {
    var id: String { courseId }

    let courseId: String
    let title: String
    let progress: Int
    let lastAccessed: String?
}

struct StudentGoals: Codable, Equatable {
    let daily: StudentGoalWindow
    let weekly: StudentGoalWindow
}

struct StudentGoalWindow: Codable, Equatable {
    let xp: GoalXp
    let quizzesCompleted: Int
    let message: String?
}

struct GoalXp: Codable, Equatable {
    let value: Int
    let unit: String
}

struct StudentHomeSkeleton: Codable, Equatable {
    let sections: StudentHomeSkeletonSections
}

struct StudentHomeSkeletonSections: Codable, Equatable {
    let continueLearningItems: Int
    let quickActions: Bool
    let goals: Bool
}

// MARK: - Teacher Home (/teacher-dashboard/home)

struct TeacherHomeResponse: Codable {
    let success: Bool
    let message: String?
    let data: TeacherHomeData?
    let teacherId: String?
}

struct TeacherHomeData: Codable, Equatable {
    let meta: HomeMeta
    let capabilities: TeacherHomeCapabilities
    let teacher: TeacherHomeProfile
    let quickStats: TeacherQuickStats
    let engagementFeed: TeacherEngagementFeed
    let analyticsCards: TeacherAnalyticsCards
    let pendingActions: TeacherPendingActions
    let skeleton: TeacherHomeSkeleton
}

struct TeacherHomeCapabilities: Codable, Equatable {
    let engagementQuestions: Bool
    let courseReviews: Bool
    let submissions: Bool
    let realTimeMessages: Bool
}

struct TeacherHomeProfile: Codable, Equatable {
    let id: String
    let username: String
    let email: String
    let image: String?
    let contractPercentage: Int?
}

struct TeacherQuickStats: Codable, Equatable {
    let totalStudents: Int
    let activeCourses: Int
    let pendingCourses: Int
    let totalRevenue: Double
    let unreadMessages: Int
}

struct TeacherEngagementFeed: Codable, Equatable {
    let recentEnrollments: [TeacherRecentEnrollment]
    let recentMessages: [TeacherRecentMessage]
}

struct TeacherRecentEnrollment: Codable, Equatable, Identifiable {
    var id: String { "\(studentName)|\(courseName)|\(enrolledAt ?? "")" }

    let studentName: String
    let courseName: String
    let enrolledAt: String?
}

struct TeacherRecentMessage: Codable, Equatable, Identifiable {
    var id: String { "\(senderName)|\(sentAt ?? "")|\(content.prefix(24))" }

    let senderName: String
    let content: String
    let sentAt: String?
}

struct TeacherAnalyticsCards: Codable, Equatable {
    let revenueChart: [TeacherRevenueChartPoint]
}

struct TeacherRevenueChartPoint: Codable, Equatable, Identifiable {
    var id: String { month }

    let month: String
    let revenue: Double
    let enrollments: Int
}

struct TeacherPendingActions: Codable, Equatable {
    let pendingCourseRequests: Int
    let pendingWithdrawals: Int
    let unreadMessages: Int
    let courseEditsAwaitingApproval: Int
}

struct TeacherHomeSkeleton: Codable, Equatable {
    let sections: TeacherHomeSkeletonSections
}

struct TeacherHomeSkeletonSections: Codable, Equatable {
    let quickStats: Bool
    let engagementFeed: Bool
    let analyticsCards: Bool
}

// MARK: - Shared

struct HomeMeta: Codable, Equatable {
    let generatedAt: String?
    let apiVersion: String?
}
