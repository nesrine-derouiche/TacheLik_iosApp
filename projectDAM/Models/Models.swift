import Foundation

// MARK: - User Model
struct User: Identifiable, Codable {
    let id: String
    let username: String
    let email: String
    let phone: String?
    let phoneNbVerified: Bool?
    let role: UserRole
    let creationDate: String?
    let image: String?
    let verified: Bool?
    let banned: Bool?
    let credit: Int?
    let isTeacher: Bool?
    let inviteLink: String?
    let invitedBy: String?
    let inviteLinkType: String?
    let haveReduction: Bool?
    let warningTimes: Int?
    let lastLoginDate: String?
    
    // Computed property for display name
    var name: String {
        return username
    }
    
    // Computed property for avatar
    var avatar: String? {
        return image
    }
    
    enum UserRole: String, Codable {
        case student = "Student"
        case mentor = "Teacher"
        case admin = "Admin"
    }
    
    enum CodingKeys: String, CodingKey {
        case id, username, email, phone, role, image, verified, banned, credit
        case phoneNbVerified = "phone_nb_verified"
        case creationDate = "creation_date"
        case isTeacher = "is_teacher"
        case inviteLink = "invite_link"
        case invitedBy = "invited_by"
        case inviteLinkType = "invite_link_type"
        case haveReduction = "have_reduction"
        case warningTimes = "warning_times"
        case lastLoginDate = "last_login_date"
    }
}

// MARK: - Course Model
struct Course: Identifiable, Codable {
    let id: String
    let title: String
    let instructor: String
    let image: String
    let category: String
    let level: CourseLevel
    let rating: Double?
    let progress: Double?
    let duration: Double // in hours
    let totalLessons: Int
    let completedLessons: Int
    let lastAccessDate: Date?
    
    enum CourseLevel: String, Codable {
        case beginner = "Beginner"
        case intermediate = "Intermediate"
        case advanced = "Advanced"
    }
}

// MARK: - User Profile Model
struct UserProfile {
    var name: String
    var email: String
    var role: String
    var initials: String
    
    var stats: ProfileStats
}


struct ProfileStats {
    var coursesCompleted: Int
    var coursesInProgress: Int
    var totalHours: Int
    var averageScore: Int
    var dayStreak: Int
    var classRank: String
}

struct UserStats {
    var coursesCompleted: Int
    var totalHours: Int
    var currentStreak: Int
    
    static let demo = UserStats(
        coursesCompleted: 12,
        totalHours: 156,
        currentStreak: 7
    )
}


// MARK: - Demo Data
extension Course {
    static let sampleCourses = [
        Course(
            id: "1",
            title: "Advanced Web Development",
            instructor: "Dr. Sami Rezgui",
            image: "webdev",
            category: "Programming",
            level: .advanced,
            rating: 4.8,
            progress: 0.65,
            duration: 24.5,
            totalLessons: 20,
            completedLessons: 13,
            lastAccessDate: Date()
        ),
        Course(
            id: "2",
            title: "Data Structures & Algorithms",
            instructor: "Prof. Leila Ben Amor",
            image: "datastructures",
            category: "Programming",
            level: .intermediate,
            rating: 4.7,
            progress: 0.42,
            duration: 18.0,
            totalLessons: 15,
            completedLessons: 7,
            lastAccessDate: Date()
        ),
        Course(
            id: "3",
            title: "Cloud Computing Essentials",
            instructor: "Dr. Hichem Ben Said",
            image: "cloud",
            category: "Cloud",
            level: .beginner,
            rating: 4.6,
            progress: 0.0,
            duration: 12.0,
            totalLessons: 10,
            completedLessons: 0,
            lastAccessDate: nil
        ),
        Course(
            id: "4",
            title: "Cybersecurity Basics",
            instructor: "Dr. Mohamed Trabelsi",
            image: "security",
            category: "Security",
            level: .beginner,
            rating: 4.9,
            progress: 0.0,
            duration: 15.0,
            totalLessons: 12,
            completedLessons: 0,
            lastAccessDate: nil
        ),
        Course(
            id: "5",
            title: "Machine Learning Fundamentals",
            instructor: "Dr. Sarah Smith",
            image: "ml",
            category: "AI",
            level: .intermediate,
            rating: 4.8,
            progress: 0.25,
            duration: 32.0,
            totalLessons: 25,
            completedLessons: 6,
            lastAccessDate: Date()
        ),
        Course(
            id: "6",
            title: "Mobile App Development",
            instructor: "Prof. John Doe",
            image: "mobile",
            category: "Programming",
            level: .intermediate,
            rating: 4.7,
            progress: 0.0,
            duration: 28.0,
            totalLessons: 22,
            completedLessons: 0,
            lastAccessDate: nil
        )
    ]
}

extension UserProfile {
    static let demo = UserProfile(
        name: "Ahmed Ben Ali",
        email: "ahmed.benali@esprit.tn",
        role: "Student",
        initials: "ABA",
        stats: ProfileStats(
            coursesCompleted: 3,
            coursesInProgress: 5,
            totalHours: 124,
            averageScore: 87,
            dayStreak: 15,
            classRank: "Top 10%"
        )
    )
}

