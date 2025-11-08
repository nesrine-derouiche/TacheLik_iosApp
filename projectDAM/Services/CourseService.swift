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
}
