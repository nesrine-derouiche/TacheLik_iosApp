//
//  TeacherCoursesService.swift
//  projectDAM
//
//  Created on 11/23/2025.
//

import Foundation

// MARK: - Service Protocol
protocol TeacherCoursesServiceProtocol {
    func fetchMyCourses() async throws -> [ClassWithCourses]
    func fetchAvailableClasses() async throws -> [AvailableClass]
}

// MARK: - Service Implementation
final class TeacherCoursesService: TeacherCoursesServiceProtocol {
    private let networkService: NetworkServiceProtocol
    private let authService: AuthServiceProtocol
    
    init(networkService: NetworkServiceProtocol, authService: AuthServiceProtocol) {
        self.networkService = networkService
        self.authService = authService
    }
    
    /// Fetch teacher's courses grouped by classes
    /// Endpoint: GET /course/my-courses
    func fetchMyCourses() async throws -> [ClassWithCourses] {
        guard let token = authService.getAuthToken() else {
            print("❌ [TeacherCoursesService] No auth token available")
            throw NetworkError.unauthorized
        }
        
        print("📡 [TeacherCoursesService] Fetching my courses from: \(AppConfig.baseURL)/course/my-courses")
        print("📡 [TeacherCoursesService] Token prefix: \(String(token.prefix(20)))...")
        
        do {
            print("🔄 [TeacherCoursesService] Starting request...")
            let response: TeacherClassesResponse = try await networkService.request(
                endpoint: "/course/my-courses",
                method: .GET,
                body: nil,
                headers: ["Authorization": "Bearer \(token)"]
            )
            
            print("✅ [TeacherCoursesService] Received \(response.classesWithCourses.count) classes with courses")
            print("✅ [TeacherCoursesService] Response success: \(response.success)")
            
            return response.classesWithCourses
        } catch let error as NetworkError {
            print("❌ [TeacherCoursesService] NetworkError: \(error)")
            switch error {
            case .invalidURL:
                print("❌ Invalid URL constructed")
            case .invalidResponse:
                print("❌ Invalid response from server")
            case .decodingError:
                print("❌ Failed to decode JSON response")
            case .serverError(let code, let message):
                print("❌ Server error \(code): \(message ?? "no message")")
            case .noData:
                print("❌ No data received from server")
            case .unauthorized:
                print("❌ Unauthorized - token may be invalid")
            }
            throw error
        } catch {
            print("❌ [TeacherCoursesService] Unexpected error: \(error)")
            if let decodingError = error as? DecodingError {
                switch decodingError {
                case .keyNotFound(let key, let context):
                    print("❌ Missing key: \(key.stringValue) - \(context.debugDescription)")
                case .typeMismatch(let type, let context):
                    print("❌ Type mismatch: \(type) - \(context.debugDescription)")
                case .valueNotFound(let type, let context):
                    print("❌ Value not found: \(type) - \(context.debugDescription)")
                case .dataCorrupted(let context):
                    print("❌ Data corrupted: \(context.debugDescription)")
                @unknown default:
                    print("❌ Unknown decoding error")
                }
            }
            throw error
        }
    }
    
    /// Fetch available classes for course creation
    /// Endpoint: GET /course/available-classes
    func fetchAvailableClasses() async throws -> [AvailableClass] {
        guard let token = authService.getAuthToken() else {
            throw NetworkError.unauthorized
        }
        
        if AppConfig.enableLogging {
            print("📡 [TeacherCoursesService] Fetching available classes at GET /course/available-classes")
        }
        
        let response: AvailableClassesResponse = try await networkService.request(
            endpoint: "/course/available-classes",
            method: .GET,
            body: nil,
            headers: ["Authorization": "Bearer \(token)"]
        )
        
        if AppConfig.enableLogging {
            print("✅ [TeacherCoursesService] Received \(response.availableClasses.count) available classes")
        }
        
        return response.availableClasses
    }
}

// MARK: - Mock Service (for preview/testing)
final class MockTeacherCoursesService: TeacherCoursesServiceProtocol {
    
    func fetchMyCourses() async throws -> [ClassWithCourses] {
        // Simulate network delay
        try await Task.sleep(nanoseconds: 1_000_000_000)
        
        // Return empty array to simulate no courses (remove all dummy data)
        return []
    }
    
    func fetchAvailableClasses() async throws -> [AvailableClass] {
        // Simulate network delay
        try await Task.sleep(nanoseconds: 500_000_000)
        
        // Return empty array (no dummy data - will fetch from real API)
        return []
    }
}
