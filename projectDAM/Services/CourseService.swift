//
//  CourseService.swift
//  projectDAM
//
//  Created on 11/7/2025.
//

import Foundation
import Combine

// MARK: - Course Service Protocol
protocol CourseServiceProtocol {
    func fetchCourses() async throws -> [Course]
    func fetchCourse(id: String) async throws -> Course
    func fetchCoursesByClass(classTitle: String) async throws -> [Course]
    func fetchOwnedCourseIdsForClass(classTitle: String) async throws -> [String]
    func enrollCourse(courseId: String) async throws
    func updateProgress(courseId: String, progress: Double) async throws
    func fetchUserCourses() async throws -> [Course]
    func fetchClasses() async throws -> [ClassItem]
    func fetchClasses(byCategory category: String) async throws -> [ClassItem]
}

// MARK: - Course Service Implementation
final class CourseService: CourseServiceProtocol {
    
    // MARK: - Properties
    private let networkService: NetworkServiceProtocol
    private let authService: AuthServiceProtocol
    
    // MARK: - Initialization
    init(networkService: NetworkServiceProtocol, authService: AuthServiceProtocol) {
        self.networkService = networkService
        self.authService = authService
    }
    
    // MARK: - Public Methods
    
    /// Fetch all available courses
    func fetchCourses() async throws -> [Course] {
        if AppConfig.enableLogging {
            print("📡 [CourseService] Requesting all approved courses at GET /course/approved")
        }
        let response: CoursesResponse = try await networkService.request(
            endpoint: "/course/approved",
            method: .GET,
            body: nil,
            headers: nil
        )
        if AppConfig.enableLogging {
            print("✅ [CourseService] Received \(response.courses.count) courses")
        }
        return response.courses
    }
    
    /// Fetch single course by ID
    func fetchCourse(id: String) async throws -> Course {
        if AppConfig.enableLogging {
            print("📡 [CourseService] Requesting course \(id) at GET /course/id?courseId=\(id)")
        }
        let response: CourseResponse = try await networkService.request(
            endpoint: "/course/id?courseId=\(id)",
            method: .GET,
            body: nil,
            headers: nil
        )
        if AppConfig.enableLogging {
            print("✅ [CourseService] Received course: \(response.course.name)")
        }
        return response.course
    }
    
    /// Fetch courses by class title
    func fetchCoursesByClass(classTitle: String) async throws -> [Course] {
        let encodedTitle = classTitle.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? classTitle
        if AppConfig.enableLogging {
            print("📡 [CourseService] Requesting courses for class '\(classTitle)' at GET /course/class-name?className=\(encodedTitle)")
        }
        let response: CoursesResponse = try await networkService.request(
            endpoint: "/course/class-name?className=\(encodedTitle)",
            method: .GET,
            body: nil,
            headers: nil
        )
        if AppConfig.enableLogging {
            print("✅ [CourseService] Received \(response.courses.count) courses for class '\(classTitle)'")
        }
        return response.courses
    }
    
    /// Fetch IDs of courses owned by the current user for a given class title
    func fetchOwnedCourseIdsForClass(classTitle: String) async throws -> [String] {
        guard let user = authService.getCurrentUser() else {
            if AppConfig.enableLogging {
                print("❌ [CourseService] Cannot fetch owned courses: no current user")
            }
            throw NetworkError.unauthorized
        }
        let encodedTitle = classTitle.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? classTitle
        if AppConfig.enableLogging {
            print("📡 [CourseService] Requesting owned courses for user=\(user.id) class='\(classTitle)' at GET /course-ownership/user-class-owned-courses")
        }
        do {
            let response: OwnedCoursesByClassResponse = try await networkService.request(
                endpoint: "/course-ownership/user-class-owned-courses?userId=\(user.id)&className=\(encodedTitle)",
                method: .GET,
                body: nil,
                headers: getAuthHeaders()
            )
            if AppConfig.enableLogging {
                print("✅ [CourseService] Received \(response.ownedCourseIds.count) owned course IDs for class '\(classTitle)'")
            }
            return response.ownedCourseIds
        } catch NetworkError.serverError(let code, _) where code == 404 {
            if AppConfig.enableLogging {
                print("ℹ️ [CourseService] No owned courses for user=\(user.id) in class '\(classTitle)' (404)")
            }
            return []
        }
    }
    
    /// Enroll in a course
    func enrollCourse(courseId: String) async throws {
        let request = EnrollRequest(courseId: courseId)
        let requestData = try JSONEncoder().encode(request)
        
        let _: EmptyResponse = try await networkService.request(
            endpoint: "/courses/enroll",
            method: .POST,
            body: requestData,
            headers: getAuthHeaders()
        )
    }
    
    /// Update course progress
    func updateProgress(courseId: String, progress: Double) async throws {
        let request = ProgressUpdateRequest(courseId: courseId, progress: progress)
        let requestData = try JSONEncoder().encode(request)
        
        let _: EmptyResponse = try await networkService.request(
            endpoint: "/courses/progress",
            method: .PUT,
            body: requestData,
            headers: getAuthHeaders()
        )
    }
    
    /// Fetch user's enrolled courses
    func fetchUserCourses() async throws -> [Course] {
        let response: CoursesResponse = try await networkService.request(
            endpoint: "/users/me/courses",
            method: .GET,
            body: nil,
            headers: getAuthHeaders()
        )
        return response.courses
    }
    
    /// Fetch all classes
    func fetchClasses() async throws -> [ClassItem] {
        if AppConfig.enableLogging {
            print("📡 [CourseService] Requesting classes at GET /class/all")
        }
        let response: ClassesResponse = try await networkService.request(
            endpoint: "/class/all",
            method: .GET,
            body: nil,
            headers: nil
        )
        if AppConfig.enableLogging {
            print("✅ [CourseService] Received \(response.classes.count) classes")
        }
        return response.classes
    }
    
    /// Fetch classes for a given category filter name
    func fetchClasses(byCategory category: String) async throws -> [ClassItem] {
        let encodedCategory = category.addingPercentEncoding(withAllowedCharacters: .urlPathAllowed) ?? category
        if AppConfig.enableLogging {
            print("📡 [CourseService] Requesting classes for category \(category) at GET /class/by-category/\(encodedCategory)")
        }
        let response: ClassesResponse = try await networkService.request(
            endpoint: "/class/by-category/\(encodedCategory)",
            method: .GET,
            body: nil,
            headers: nil
        )
        if AppConfig.enableLogging {
            print("✅ [CourseService] Received \(response.classes.count) classes for category \(category)")
        }
        return response.classes
    }
    
    // MARK: - Private Methods
    
    private func getAuthHeaders() -> [String: String] {
        guard let token = authService.getAuthToken() else {
            return [:]
        }
        return ["Authorization": "Bearer \(token)"]
    }
}

// MARK: - Request/Response Models
private struct CoursesResponse: Decodable {
    let courses: [Course]
    let success: Bool
}

private struct CourseResponse: Decodable {
    let course: Course
    let success: Bool
}

private struct ClassesResponse: Decodable {
    let classes: [ClassItem]
    let success: Bool
}

private struct OwnedCoursesByClassResponse: Decodable {
    let ownedCourseIds: [String]
    let success: Bool
}

private struct EnrollRequest: Encodable {
    let courseId: String
}

private struct ProgressUpdateRequest: Encodable {
    let courseId: String
    let progress: Double
}

private struct EmptyResponse: Decodable {}

// MARK: - Mock Course Service (for testing/development)
final class MockCourseService: CourseServiceProtocol {
    
    func fetchCourses() async throws -> [Course] {
        try await Task.sleep(nanoseconds: 500_000_000)
        return []
    }
    
    func fetchCourse(id: String) async throws -> Course {
        try await Task.sleep(nanoseconds: 500_000_000)
        throw NSError(domain: "MockCourseService", code: 404, userInfo: [NSLocalizedDescriptionKey: "Course not found"])
    }
    
    func fetchCoursesByClass(classTitle: String) async throws -> [Course] {
        try await Task.sleep(nanoseconds: 500_000_000)
        return []
    }
    
    func fetchOwnedCourseIdsForClass(classTitle: String) async throws -> [String] {
        try await Task.sleep(nanoseconds: 200_000_000)
        return []
    }
    
    func enrollCourse(courseId: String) async throws {
        try await Task.sleep(nanoseconds: 500_000_000)
    }
    
    func updateProgress(courseId: String, progress: Double) async throws {
        try await Task.sleep(nanoseconds: 500_000_000)
    }
    
    func fetchUserCourses() async throws -> [Course] {
        try await Task.sleep(nanoseconds: 500_000_000)
        return []
    }
    
    func fetchClasses() async throws -> [ClassItem] {
        try await Task.sleep(nanoseconds: 300_000_000)
        return MockCourseService.sampleClasses
    }
    
    func fetchClasses(byCategory category: String) async throws -> [ClassItem] {
        try await Task.sleep(nanoseconds: 300_000_000)
        return MockCourseService.sampleClasses.filter { $0.filterName.caseInsensitiveCompare(category) == .orderedSame }
    }
    
    private static let sampleClasses: [ClassItem] = [
        ClassItem(id: "class-1a-1", title: "Algorithms Basics", image: nil, classOrder: "1-1", filterName: "1A"),
        ClassItem(id: "class-1a-2", title: "Introduction to Web", image: nil, classOrder: "1-2", filterName: "1A"),
        ClassItem(id: "class-2a-1", title: "Qt Workshop", image: nil, classOrder: "2-1", filterName: "2A"),
        ClassItem(id: "class-3a-1", title: "TLA Foundations", image: nil, classOrder: "3-1", filterName: "3A"),
        ClassItem(id: "class-3b-1", title: "Cloud Architecture", image: nil, classOrder: "3-1", filterName: "3B")
    ]
}
