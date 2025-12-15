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
    /// UI title. Backward-compatible: decodes from `title` (legacy) or `courseName` (backend).
    let title: String
    /// Percent complete (0-100). Backend may return null.
    let progress: Int
    /// Backward-compatible: decodes from `lastAccessed` (legacy) or `lastTouchedAt` (backend).
    let lastAccessed: String?

    enum CodingKeys: String, CodingKey {
        case courseId
        case title
        case courseName
        case progress
        case lastAccessed
        case lastTouchedAt
    }

    init(courseId: String, title: String, progress: Int, lastAccessed: String?) {
        self.courseId = courseId
        self.title = title
        self.progress = progress
        self.lastAccessed = lastAccessed
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.courseId = try container.decode(String.self, forKey: .courseId)

        let decodedTitle = (try? container.decodeIfPresent(String.self, forKey: .title))
            ?? (try? container.decodeIfPresent(String.self, forKey: .courseName))
            ?? ""
        self.title = decodedTitle

        // Backend may return null for progress; treat as 0.
        self.progress = (try? container.decodeIfPresent(Int.self, forKey: .progress)) ?? 0

        self.lastAccessed = (try? container.decodeIfPresent(String.self, forKey: .lastAccessed))
            ?? (try? container.decodeIfPresent(String.self, forKey: .lastTouchedAt))
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(courseId, forKey: .courseId)
        // Encode both legacy and backend keys for maximum compatibility.
        try container.encode(title, forKey: .title)
        try container.encode(title, forKey: .courseName)
        try container.encode(progress, forKey: .progress)
        try container.encodeIfPresent(lastAccessed, forKey: .lastAccessed)
        try container.encodeIfPresent(lastAccessed, forKey: .lastTouchedAt)
    }
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
    /// Prefer backend-provided id when available.
    let id: String

    /// Backward-compatible: decodes from `senderName` (legacy) or `fromUserId` (backend).
    let senderName: String
    /// Backward-compatible: decodes from `content` (legacy) or `contentPreview` (backend).
    let content: String
    /// Backward-compatible: decodes from `sentAt` (legacy) or `createdAt` (backend).
    let sentAt: String?
    let isRead: Bool?

    enum CodingKeys: String, CodingKey {
        case id
        case senderName
        case fromUserId
        case content
        case contentPreview
        case sentAt
        case createdAt
        case isRead
    }

    init(id: String, senderName: String, content: String, sentAt: String?, isRead: Bool?) {
        self.id = id
        self.senderName = senderName
        self.content = content
        self.sentAt = sentAt
        self.isRead = isRead
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)

        // id might be absent in some legacy payloads; synthesize a stable fallback.
        let rawId = (try? container.decodeIfPresent(String.self, forKey: .id))

        let explicitName = try? container.decodeIfPresent(String.self, forKey: .senderName)
        let fromUserId = try? container.decodeIfPresent(String.self, forKey: .fromUserId)

        if let explicitName, !explicitName.isEmpty {
            self.senderName = explicitName
        } else if let fromUserId, !fromUserId.isEmpty {
            self.senderName = "User \(fromUserId.prefix(6))"
        } else {
            self.senderName = "Message"
        }

        let content = (try? container.decodeIfPresent(String.self, forKey: .content))
            ?? (try? container.decodeIfPresent(String.self, forKey: .contentPreview))
            ?? ""
        self.content = content

        let sentAt = (try? container.decodeIfPresent(String.self, forKey: .sentAt))
            ?? (try? container.decodeIfPresent(String.self, forKey: .createdAt))
        self.sentAt = sentAt

        self.isRead = (try? container.decodeIfPresent(Bool.self, forKey: .isRead))

        self.id = rawId ?? "\(self.senderName)|\(sentAt ?? "")|\(content.prefix(24))"
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        // Encode both legacy and backend keys for maximum compatibility.
        try container.encode(senderName, forKey: .senderName)
        try container.encode(content, forKey: .content)
        try container.encode(content, forKey: .contentPreview)
        try container.encodeIfPresent(sentAt, forKey: .sentAt)
        try container.encodeIfPresent(sentAt, forKey: .createdAt)
        try container.encodeIfPresent(isRead, forKey: .isRead)
    }
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
