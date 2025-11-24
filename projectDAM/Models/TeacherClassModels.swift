//
//  TeacherClassModels.swift
//  projectDAM
//
//  Created on 11/23/2025.
//

import Foundation
import SwiftUI

// MARK: - Teacher Classes Response (from GET /course/my-courses)
struct TeacherClassesResponse: Codable {
    let classesWithCourses: [ClassWithCourses]
    let success: Bool
    
    enum CodingKeys: String, CodingKey {
        case classesWithCourses, success
    }
}

// MARK: - Class With Courses
struct ClassWithCourses: Codable, Identifiable {
    let classItem: TeacherClass
    let courses: [TeacherCourse]
    
    var id: String { classItem.id }
    
    enum CodingKeys: String, CodingKey {
        case classItem = "class"
        case courses
    }
}

// MARK: - Teacher Class
struct TeacherClass: Codable, Identifiable {
    let id: String
    let title: String
    let description: String?
    let image: String?
    let classOrder: String?
    let filterName: ClassFilterName?
    let createdAt: String?
    let updatedAt: String?
    
    var imageURL: URL? {
        guard let image = image else { return nil }
        // If it's already a full URL
        if image.hasPrefix("http://") || image.hasPrefix("https://") {
            return URL(string: image)
        }
        // Construct URL from base
        let baseURL = AppConfig.baseURL.replacingOccurrences(of: "/api", with: "")
        return URL(string: "\(baseURL)/uploads/classes/\(image)")
    }
    
    // Custom decoder to handle all optional fields gracefully
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(String.self, forKey: .id)
        title = try container.decode(String.self, forKey: .title)
        description = try container.decodeIfPresent(String.self, forKey: .description)
        image = try container.decodeIfPresent(String.self, forKey: .image)
        classOrder = try container.decodeIfPresent(String.self, forKey: .classOrder)
        filterName = try? container.decodeIfPresent(ClassFilterName.self, forKey: .filterName)
        createdAt = try container.decodeIfPresent(String.self, forKey: .createdAt)
        updatedAt = try container.decodeIfPresent(String.self, forKey: .updatedAt)
    }
    
    enum CodingKeys: String, CodingKey {
        case id, title, description, image
        case classOrder = "class_order"
        case filterName = "filter_name"
        case createdAt = "created_at"
        case updatedAt = "updated_at"
    }
}

// MARK: - Class Filter Name
struct ClassFilterName: Codable {
    let filterName: String
    
    enum CodingKeys: String, CodingKey {
        case filterName = "filter_name"
    }
}

// MARK: - Teacher Course
struct TeacherCourse: Codable, Identifiable {
    let id: String
    let name: String
    let description: String?
    let image: String?
    let time: Double?
    let nbVideos: Int?
    let nbQuizzes: Int?
    let price: Double?
    let level: String?
    let courseOrder: String?
    let courseReduction: Int?
    let hot: Bool?
    let approvalStatus: String?
    let folderId: String?
    let author: CourseAuthorBasic?
    let studentCount: Int
    
    // Custom decoder to handle all optional fields gracefully
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(String.self, forKey: .id)
        name = try container.decode(String.self, forKey: .name)
        description = try container.decodeIfPresent(String.self, forKey: .description)
        image = try container.decodeIfPresent(String.self, forKey: .image)
        time = try container.decodeIfPresent(Double.self, forKey: .time)
        nbVideos = try container.decodeIfPresent(Int.self, forKey: .nbVideos)
        nbQuizzes = try container.decodeIfPresent(Int.self, forKey: .nbQuizzes)
        price = try container.decodeIfPresent(Double.self, forKey: .price)
        level = try container.decodeIfPresent(String.self, forKey: .level)
        courseOrder = try container.decodeIfPresent(String.self, forKey: .courseOrder)
        courseReduction = try container.decodeIfPresent(Int.self, forKey: .courseReduction)
        hot = try container.decodeIfPresent(Bool.self, forKey: .hot)
        approvalStatus = try container.decodeIfPresent(String.self, forKey: .approvalStatus)
        folderId = try container.decodeIfPresent(String.self, forKey: .folderId)
        author = try? container.decodeIfPresent(CourseAuthorBasic.self, forKey: .author)
        studentCount = (try? container.decode(Int.self, forKey: .studentCount)) ?? 0
    }
    
    var imageURL: URL? {
        guard let image = image else { return nil }
        // If it's already a full URL
        if image.hasPrefix("http://") || image.hasPrefix("https://") {
            return URL(string: image)
        }
        // Construct URL from base
        let baseURL = AppConfig.baseURL.replacingOccurrences(of: "/api", with: "")
        return URL(string: "\(baseURL)/uploads/courses/\(image)")
    }
    
    var durationInMinutes: Int {
        guard let time = time else { return 0 }
        return Int(time * 60)
    }
    
    var totalLessons: Int {
        (nbVideos ?? 0) + (nbQuizzes ?? 0)
    }
    
    var statusBadgeColor: String {
        guard let status = approvalStatus else { return "gray" }
        switch status.lowercased() {
        case "approved":
            return "green"
        case "pending":
            return "orange"
        case "declined":
            return "red"
        default:
            return "gray"
        }
    }
    
    enum CodingKeys: String, CodingKey {
        case id, name, description, image, time, price, level, hot, author
        case nbVideos = "nb_videos"
        case nbQuizzes = "nb_quizzes"
        case courseOrder = "course_order"
        case courseReduction = "course_reduction"
        case approvalStatus = "approval_status"
        case folderId = "folder_id"
        case studentCount
    }
}

// MARK: - Course Author Basic
struct CourseAuthorBasic: Codable {
    let id: String
    let username: String
    let email: String
    let image: String?
}

// MARK: - Available Classes Response (from GET /course/available-classes)
struct AvailableClassesResponse: Codable {
    let availableClasses: [AvailableClass]
    let success: Bool
    
    enum CodingKeys: String, CodingKey {
        case availableClasses = "classes"
        case success
    }
}

// MARK: - Available Class
struct AvailableClass: Codable, Identifiable {
    let id: String
    let title: String
    let image: String?
    let classOrder: String?
    let filterName: ClassFilterName?
    
    var imageURL: URL? {
        guard let image = image else { return nil }
        // If it's already a full URL
        if image.hasPrefix("http://") || image.hasPrefix("https://") {
            return URL(string: image)
        }
        // Construct URL from base
        let baseURL = AppConfig.baseURL.replacingOccurrences(of: "/api", with: "")
        return URL(string: "\(baseURL)/uploads/classes/\(image)")
    }
    
    enum CodingKeys: String, CodingKey {
        case id, title, image
        case classOrder = "class_order"
        case filterName = "filter_name"
    }
}

// MARK: - View State Enum
enum TeacherClassesViewState {
    case loading
    case loaded([ClassWithCourses])
    case error(String)
    case empty
}

// MARK: - Course Creation Support

enum CourseLevelOption: String, CaseIterable, Identifiable, Codable {
    case introduction = "Introduction"
    case foundation = "Foundation"
    case mastery = "Mastery"
    
    var id: String { rawValue }
    
    var displayName: String {
        switch self {
        case .introduction: return "Introduction"
        case .foundation: return "Foundation"
        case .mastery: return "Mastery"
        }
    }
    
    var helperText: String {
        switch self {
        case .introduction: return "Great for beginners"
        case .foundation: return "Build solid fundamentals"
        case .mastery: return "Deep dive & advanced"
        }
    }
}

struct CourseCreationRequest {
    let name: String
    let description: String
    let price: Double
    let level: CourseLevelOption
    let classId: String
    let courseReduction: Int?
}

struct CourseImageAttachment {
    let data: Data
    let mimeType: String
    let fileName: String
}

struct CourseCreationResponse: Decodable {
    let success: Bool
    let message: String?
    let data: CourseCreationPayload?
}

struct CourseCreationPayload: Decodable {
    let id: String
    let name: String
    let image: String?
    let description: String?
    let price: Double?
    let level: String?
    let courseOrder: String?
    let courseReduction: Int?
    
    enum CodingKeys: String, CodingKey {
        case id, name, image, description, price, level
        case courseOrder = "course_order"
        case courseReduction = "course_reduction"
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(String.self, forKey: .id)
        name = try container.decode(String.self, forKey: .name)
        image = try container.decodeIfPresent(String.self, forKey: .image)
        description = try container.decodeIfPresent(String.self, forKey: .description)
        level = try container.decodeIfPresent(String.self, forKey: .level)
        courseOrder = try container.decodeIfPresent(String.self, forKey: .courseOrder)
        
        if let rawPrice = try? container.decode(Double.self, forKey: .price) {
            price = rawPrice
        } else if let stringPrice = try? container.decode(String.self, forKey: .price),
                  let parsed = Double(stringPrice) {
            price = parsed
        } else {
            price = nil
        }
        
        if let reduction = try? container.decode(Int.self, forKey: .courseReduction) {
            courseReduction = reduction
        } else if let stringReduction = try? container.decode(String.self, forKey: .courseReduction),
                  let parsed = Int(stringReduction) {
            courseReduction = parsed
        } else {
            courseReduction = nil
        }
    }
    
    init(id: String, name: String, image: String?, description: String?, price: Double?, level: String?, courseOrder: String?, courseReduction: Int?) {
        self.id = id
        self.name = name
        self.image = image
        self.description = description
        self.price = price
        self.level = level
        self.courseOrder = courseOrder
        self.courseReduction = courseReduction
    }
}

struct CourseEditRequestResponse: Decodable {
    let success: Bool
    let message: String?
}
