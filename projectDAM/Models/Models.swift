import Foundation

// MARK: - User Model
struct User: Identifiable, Codable, Equatable {
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
    
    // Memberwise initializer
    init(id: String, username: String, email: String, phone: String?, phoneNbVerified: Bool?, role: UserRole, creationDate: String?, image: String?, verified: Bool?, banned: Bool?, credit: Int?, isTeacher: Bool?, inviteLink: String?, invitedBy: String?, inviteLinkType: String?, haveReduction: Bool?, warningTimes: Int?, lastLoginDate: String?) {
        self.id = id
        self.username = username
        self.email = email
        self.phone = phone
        self.phoneNbVerified = phoneNbVerified
        self.role = role
        self.creationDate = creationDate
        self.image = image
        self.verified = verified
        self.banned = banned
        self.credit = credit
        self.isTeacher = isTeacher
        self.inviteLink = inviteLink
        self.invitedBy = invitedBy
        self.inviteLinkType = inviteLinkType
        self.haveReduction = haveReduction
        self.warningTimes = warningTimes
        self.lastLoginDate = lastLoginDate
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        
        id = try container.decode(String.self, forKey: .id)
        username = try container.decode(String.self, forKey: .username)
        email = try container.decode(String.self, forKey: .email)
        phone = try container.decodeIfPresent(String.self, forKey: .phone)
        phoneNbVerified = try container.decodeIfPresent(Bool.self, forKey: .phoneNbVerified)
        role = try container.decode(UserRole.self, forKey: .role)
        creationDate = try container.decodeIfPresent(String.self, forKey: .creationDate)
        verified = try container.decodeIfPresent(Bool.self, forKey: .verified)
        banned = try container.decodeIfPresent(Bool.self, forKey: .banned)
        credit = try container.decodeIfPresent(Int.self, forKey: .credit)
        isTeacher = try container.decodeIfPresent(Bool.self, forKey: .isTeacher)
        inviteLink = try container.decodeIfPresent(String.self, forKey: .inviteLink)
        invitedBy = try container.decodeIfPresent(String.self, forKey: .invitedBy)
        inviteLinkType = try container.decodeIfPresent(String.self, forKey: .inviteLinkType)
        haveReduction = try container.decodeIfPresent(Bool.self, forKey: .haveReduction)
        warningTimes = try container.decodeIfPresent(Int.self, forKey: .warningTimes)
        lastLoginDate = try container.decodeIfPresent(String.self, forKey: .lastLoginDate)
        
        // Handle image - it can be a string URL, a Buffer object, or null
        if let imageString = try? container.decode(String.self, forKey: .image) {
            image = imageString
        } else if let buffer = try? container.decode(ImageBuffer.self, forKey: .image) {
            // Convert Buffer to base64 data URL
            let data = Data(buffer.data)
            let base64String = data.base64EncodedString()
            image = "data:image/jpeg;base64,\(base64String)"
        } else {
            image = nil
        }
    }
}

// Helper struct to decode Buffer objects from backend
private struct ImageBuffer: Decodable {
    let type: String
    let data: [UInt8]
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

