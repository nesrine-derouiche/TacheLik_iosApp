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
        let response: CoursesResponse = try await networkService.request(
            endpoint: "/courses",
            method: .GET,
            body: nil,
            headers: getAuthHeaders()
        )
        return response.courses
    }
    
    /// Fetch single course by ID
    func fetchCourse(id: String) async throws -> Course {
        let response: CourseResponse = try await networkService.request(
            endpoint: "/courses/\(id)",
            method: .GET,
            body: nil,
            headers: getAuthHeaders()
        )
        return response.course
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
}

private struct CourseResponse: Decodable {
    let course: Course
}

private struct ClassesResponse: Decodable {
    let classes: [ClassItem]
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
        return Course.sampleCourses
    }
    
    func fetchCourse(id: String) async throws -> Course {
        try await Task.sleep(nanoseconds: 500_000_000)
        return Course.sampleCourses.first { $0.id == id } ?? Course.sampleCourses[0]
    }
    
    func enrollCourse(courseId: String) async throws {
        try await Task.sleep(nanoseconds: 500_000_000)
    }
    
    func updateProgress(courseId: String, progress: Double) async throws {
        try await Task.sleep(nanoseconds: 500_000_000)
    }
    
    func fetchUserCourses() async throws -> [Course] {
        try await Task.sleep(nanoseconds: 500_000_000)
        return Array(Course.sampleCourses.prefix(3))
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
