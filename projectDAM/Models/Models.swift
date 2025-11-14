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
struct Course: Identifiable, Codable, Equatable {
    let id: String
    let name: String
    let image: String
    let description: String
    let time: Double // in hours
    let nbVideos: Int
    let nbQuizzes: Int
    let price: Double
    let level: CourseLevel
    let previewVideoId: String?
    let author: CourseAuthor
    let classItem: CourseClass
    let courseOrder: String
    let courseReduction: Int
    let hot: Bool
    let approvalStatus: String
    let folderId: String?
    
    // Computed properties for display
    var title: String { name }
    var instructor: String { author.username }
    var category: String { level.rawValue }
    var duration: Double { time }
    var totalLessons: Int { nbVideos + nbQuizzes }
    var durationInMinutes: Int { Int(time * 60) }
    
    // Image URL construction
    var imageURL: URL? {
        guard !image.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty,
              let baseURL = URL(string: AppConfig.baseURL) else {
            return nil
        }
        // Remove /api from baseURL and construct uploads path
        let uploadsBase = baseURL.deletingLastPathComponent()
        return uploadsBase
            .appendingPathComponent("uploads")
            .appendingPathComponent("courses")
            .appendingPathComponent(image)
    }
    
    var imageURLString: String? {
        imageURL?.absoluteString
    }
    
    enum CourseLevel: String, Codable {
        case introduction = "Introduction"
        case foundation = "Foundation"
        case mastery = "Mastery"
        
        // Legacy mapping
        var displayName: String {
            switch self {
            case .introduction: return "Beginner"
            case .foundation: return "Intermediate"
            case .mastery: return "Advanced"
            }
        }
    }
    
    enum CodingKeys: String, CodingKey {
        case id, name, image, description, time, price, level, hot
        case nbVideos = "nb_videos"
        case nbQuizzes = "nb_quizzes"
        case previewVideoId = "preview_video_id"
        case author
        case classItem = "class"
        case courseOrder = "course_order"
        case courseReduction = "course_reduction"
        case approvalStatus = "approval_status"
        case folderId = "folder_id"
    }
}

// MARK: - Course Author Model
struct CourseAuthor: Codable, Equatable {
    let id: String
    let username: String
    let email: String
    let role: String
    let image: String?
    
    var imageURL: URL? {
        guard let image,
              !image.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty,
              !image.hasPrefix("data:"),
              let baseURL = URL(string: AppConfig.baseURL) else {
            return nil
        }
        let uploadsBase = baseURL.deletingLastPathComponent()
        return uploadsBase
            .appendingPathComponent("uploads")
            .appendingPathComponent("users")
            .appendingPathComponent(image)
    }
}

// MARK: - Course Class Model
struct CourseClass: Codable, Equatable {
    let id: String
    let title: String
    let image: String?
    let classOrder: String
    let filterName: String
    
    var imageURL: URL? {
        guard let image,
              !image.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty,
              let baseURL = URL(string: AppConfig.baseURL) else {
            return nil
        }
        let uploadsBase = baseURL.deletingLastPathComponent()
        return uploadsBase
            .appendingPathComponent("uploads")
            .appendingPathComponent("classes")
            .appendingPathComponent(image)
    }
    
    enum CodingKeys: String, CodingKey {
        case id, title, image
        case classOrder = "class_order"
        case filterName = "filter_name"
    }
    
    init(id: String, title: String, image: String?, classOrder: String, filterName: String) {
        self.id = id
        self.title = title
        self.image = image
        self.classOrder = classOrder
        self.filterName = filterName
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(String.self, forKey: .id)
        title = try container.decode(String.self, forKey: .title)
        image = try container.decodeIfPresent(String.self, forKey: .image)
        classOrder = try container.decode(String.self, forKey: .classOrder)
        
        if let filterNameString = try? container.decode(String.self, forKey: .filterName) {
            filterName = filterNameString
        } else if let category = try? container.decode(CategoryReference.self, forKey: .filterName) {
            filterName = category.filterName
        } else {
            filterName = "Unknown"
        }
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        try container.encode(title, forKey: .title)
        try container.encodeIfPresent(image, forKey: .image)
        try container.encode(classOrder, forKey: .classOrder)
        try container.encode(filterName, forKey: .filterName)
    }
    
    private struct CategoryReference: Decodable {
        let filterName: String
        
        enum CodingKeys: String, CodingKey {
            case filterName = "filter_name"
        }
    }
}

// MARK: - Class Model
struct ClassItem: Identifiable, Codable, Equatable {
    let id: String
    let title: String
    let image: String?
    let classOrder: String
    let filterName: String
    
    var imageURL: URL? {
        guard let image,
              !image.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty,
              let baseURL = URL(string: AppConfig.baseURL) else {
            return nil
        }
        return baseURL
            .appendingPathComponent("uploads")
            .appendingPathComponent("classes")
            .appendingPathComponent(image)
    }
    
    var imageURLString: String? {
        imageURL?.absoluteString
    }
    
    enum CodingKeys: String, CodingKey {
        case id
        case title
        case image
        case classOrder = "class_order"
        case filterName = "filter_name"
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

