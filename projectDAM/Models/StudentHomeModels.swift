//
//  StudentHomeModels.swift
//  projectDAM
//
//  Created for dynamic student home dashboard
//

import Foundation

// MARK: - Student Home Analytics Response
struct StudentHomeAnalytics: Codable {
    let totalCourses: Int
    let totalHours: Double
    let coursesInProgress: Int
    let coursesCompleted: Int
    let averageProgress: Double
    let recentCourses: [OwnedCourse]
    let classesSummary: [ClassSummary]
    
    enum CodingKeys: String, CodingKey {
        case totalCourses
        case totalHours
        case coursesInProgress
        case coursesCompleted
        case averageProgress
        case recentCourses
        case classesSummary
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        totalCourses = try container.decodeIfPresent(Int.self, forKey: .totalCourses) ?? 0
        totalHours = try container.decodeIfPresent(Double.self, forKey: .totalHours) ?? 0.0
        coursesInProgress = try container.decodeIfPresent(Int.self, forKey: .coursesInProgress) ?? 0
        coursesCompleted = try container.decodeIfPresent(Int.self, forKey: .coursesCompleted) ?? 0
        averageProgress = try container.decodeIfPresent(Double.self, forKey: .averageProgress) ?? 0.0
        recentCourses = try container.decodeIfPresent([OwnedCourse].self, forKey: .recentCourses) ?? []
        classesSummary = try container.decodeIfPresent([ClassSummary].self, forKey: .classesSummary) ?? []
    }
    
    init(totalCourses: Int = 0, totalHours: Double = 0, coursesInProgress: Int = 0, coursesCompleted: Int = 0, averageProgress: Double = 0, recentCourses: [OwnedCourse] = [], classesSummary: [ClassSummary] = []) {
        self.totalCourses = totalCourses
        self.totalHours = totalHours
        self.coursesInProgress = coursesInProgress
        self.coursesCompleted = coursesCompleted
        self.averageProgress = averageProgress
        self.recentCourses = recentCourses
        self.classesSummary = classesSummary
    }
}

// MARK: - Owned Course (from course-ownership endpoint)
struct OwnedCourse: Codable, Identifiable {
    let id: String
    let course: OwnedCourseDetail
    let createdAt: String?
    
    enum CodingKeys: String, CodingKey {
        case id
        case course
        case createdAt = "created_at"
    }
    
    var courseId: String {
        return course.id
    }
}

// MARK: - Owned Course Detail
struct OwnedCourseDetail: Codable, Identifiable {
    let id: String
    let name: String
    let image: String?
    let duration: Double?
    let description: String?
    let price: Double?
    let author: CourseAuthorInfo?
    let createdAt: String?
    let courseClass: CourseClassInfo?
    
    enum CodingKeys: String, CodingKey {
        case id, name, image, description, price, author
        case duration, time // Backend may use "time" instead of "duration"
        case createdAt = "created_at"
        case courseClass = "class"
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(String.self, forKey: .id)
        name = try container.decode(String.self, forKey: .name)
        image = try container.decodeIfPresent(String.self, forKey: .image)
        
        // Duration can be "duration" or "time" from backend
        if let durationValue = try container.decodeIfPresent(Double.self, forKey: .duration) {
            duration = durationValue
        } else if let timeValue = try container.decodeIfPresent(Double.self, forKey: .time) {
            duration = timeValue
        } else {
            duration = nil
        }
        
        description = try container.decodeIfPresent(String.self, forKey: .description)
        price = try container.decodeIfPresent(Double.self, forKey: .price)
        author = try container.decodeIfPresent(CourseAuthorInfo.self, forKey: .author)
        createdAt = try container.decodeIfPresent(String.self, forKey: .createdAt)
        courseClass = try container.decodeIfPresent(CourseClassInfo.self, forKey: .courseClass)
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        try container.encode(name, forKey: .name)
        try container.encodeIfPresent(image, forKey: .image)
        try container.encodeIfPresent(duration, forKey: .duration)
        try container.encodeIfPresent(description, forKey: .description)
        try container.encodeIfPresent(price, forKey: .price)
        try container.encodeIfPresent(author, forKey: .author)
        try container.encodeIfPresent(createdAt, forKey: .createdAt)
        try container.encodeIfPresent(courseClass, forKey: .courseClass)
    }
    
    init(id: String, name: String, image: String? = nil, duration: Double? = nil, description: String? = nil, price: Double? = nil, author: CourseAuthorInfo? = nil, createdAt: String? = nil, courseClass: CourseClassInfo? = nil) {
        self.id = id
        self.name = name
        self.image = image
        self.duration = duration
        self.description = description
        self.price = price
        self.author = author
        self.createdAt = createdAt
        self.courseClass = courseClass
    }
}

// MARK: - Course Author Info
struct CourseAuthorInfo: Codable {
    let id: String
    let username: String
    let name: String?
    let image: String?
    
    enum CodingKeys: String, CodingKey {
        case id, username, name, image
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(String.self, forKey: .id)
        username = try container.decode(String.self, forKey: .username)
        name = try container.decodeIfPresent(String.self, forKey: .name)
        image = try container.decodeIfPresent(String.self, forKey: .image)
    }
    
    init(id: String, username: String, name: String? = nil, image: String? = nil) {
        self.id = id
        self.username = username
        self.name = name
        self.image = image
    }
}

// MARK: - Course Class Info
struct CourseClassInfo: Codable {
    let id: String
    let name: String
    let filterName: String?
    
    private enum CodingKeys: String, CodingKey {
        case id, name, title
        case filterName = "filter_name"
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(String.self, forKey: .id)
        // Backend may return "name" or "title" for class name
        if let nameValue = try container.decodeIfPresent(String.self, forKey: .name) {
            name = nameValue
        } else if let titleValue = try container.decodeIfPresent(String.self, forKey: .title) {
            name = titleValue
        } else {
            name = "Unknown"
        }
        // filter_name may be a string or an object with filter_name property
        if let filterNameString = try? container.decodeIfPresent(String.self, forKey: .filterName) {
            filterName = filterNameString
        } else {
            filterName = nil
        }
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        try container.encode(name, forKey: .name)
        try container.encodeIfPresent(filterName, forKey: .filterName)
    }
    
    init(id: String, name: String, filterName: String? = nil) {
        self.id = id
        self.name = name
        self.filterName = filterName
    }
}

// MARK: - Class Summary
struct ClassSummary: Codable, Identifiable {
    let id: String
    let name: String
    let filterName: String
    let coursesCount: Int
    
    enum CodingKeys: String, CodingKey {
        case id, name
        case filterName = "filter_name"
        case coursesCount = "courses_count"
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(String.self, forKey: .id)
        name = try container.decode(String.self, forKey: .name)
        filterName = try container.decodeIfPresent(String.self, forKey: .filterName) ?? ""
        coursesCount = try container.decodeIfPresent(Int.self, forKey: .coursesCount) ?? 0
    }
    
    init(id: String, name: String, filterName: String, coursesCount: Int) {
        self.id = id
        self.name = name
        self.filterName = filterName
        self.coursesCount = coursesCount
    }
}

// MARK: - API Response Wrappers
struct UserCoursesResponse: Codable {
    let courses: [OwnedCourse]
    let success: Bool
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        courses = try container.decodeIfPresent([OwnedCourse].self, forKey: .courses) ?? []
        success = try container.decodeIfPresent(Bool.self, forKey: .success) ?? false
    }
}

struct LastCoursesResponse: Codable {
    let courses: [OwnedCourse]
    let success: Bool
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        courses = try container.decodeIfPresent([OwnedCourse].self, forKey: .courses) ?? []
        success = try container.decodeIfPresent(Bool.self, forKey: .success) ?? false
    }
}

// MARK: - Badge Models
struct UserBadge: Codable, Identifiable {
    let id: String
    let name: String
    let description: String?
    let iconUrl: String?
    let criteria: String?
    let awardedAt: String?
    
    enum CodingKeys: String, CodingKey {
        case id, name, description, criteria
        case iconUrl = "icon_url"
        case awardedAt = "awarded_at"
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(String.self, forKey: .id)
        name = try container.decode(String.self, forKey: .name)
        description = try container.decodeIfPresent(String.self, forKey: .description)
        iconUrl = try container.decodeIfPresent(String.self, forKey: .iconUrl)
        criteria = try container.decodeIfPresent(String.self, forKey: .criteria)
        awardedAt = try container.decodeIfPresent(String.self, forKey: .awardedAt)
    }
    
    init(id: String, name: String, description: String? = nil, iconUrl: String? = nil, criteria: String? = nil, awardedAt: String? = nil) {
        self.id = id
        self.name = name
        self.description = description
        self.iconUrl = iconUrl
        self.criteria = criteria
        self.awardedAt = awardedAt
    }
}

struct UserBadgesResponse: Codable {
    let badges: [UserBadge]
    let success: Bool
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        badges = try container.decodeIfPresent([UserBadge].self, forKey: .badges) ?? []
        success = try container.decodeIfPresent(Bool.self, forKey: .success) ?? false
    }
}

// MARK: - Student User Stats (from User entity fields)
struct StudentUserStats: Codable {
    let credit: Int
    let streak: Int
    let lastActiveDate: String?
    
    enum CodingKeys: String, CodingKey {
        case credit, streak
        case lastActiveDate = "last_active_date"
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        credit = try container.decodeIfPresent(Int.self, forKey: .credit) ?? 0
        streak = try container.decodeIfPresent(Int.self, forKey: .streak) ?? 0
        lastActiveDate = try container.decodeIfPresent(String.self, forKey: .lastActiveDate)
    }
    
    init(credit: Int = 0, streak: Int = 0, lastActiveDate: String? = nil) {
        self.credit = credit
        self.streak = streak
        self.lastActiveDate = lastActiveDate
    }
}
