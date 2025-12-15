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
    func createCourse(request: CourseCreationRequest, imageAttachment: CourseImageAttachment?) async throws -> CourseCreationResponse
    func createCourseEditRequest(
        courseId: String,
        name: String,
        description: String,
        price: Double,
        level: CourseLevelOption,
        courseReduction: Int?,
        changeReason: String,
        imageAttachment: CourseImageAttachment?
    ) async throws -> CourseEditRequestResponse
    func archiveCourse(id: String) async throws -> BasicMessageResponse
    func unarchiveCourse(id: String) async throws -> BasicMessageResponse
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
    
    /// Create a new course (POST /course/create)
    func createCourse(request: CourseCreationRequest, imageAttachment: CourseImageAttachment?) async throws -> CourseCreationResponse {
        guard let token = authService.getAuthToken() else {
            throw NetworkError.unauthorized
        }
        guard let currentUser = authService.getCurrentUser() else {
            throw NetworkError.unauthorized
        }
        
        var multipart = MultipartFormData()
        let trimmedName = request.name.trimmingCharacters(in: .whitespacesAndNewlines)
        let trimmedDescription = request.description.trimmingCharacters(in: .whitespacesAndNewlines)
        multipart.addField(name: "name", value: trimmedName)
        multipart.addField(name: "description", value: trimmedDescription)
        multipart.addField(name: "price", value: String(format: "%.2f", request.price))
        multipart.addField(name: "level", value: request.level.rawValue)
        multipart.addField(name: "author_id", value: currentUser.id)
        multipart.addField(name: "class_id", value: request.classId)
        if let reduction = request.courseReduction {
            multipart.addField(name: "course_reduction", value: String(reduction))
        }
        if let imageAttachment {
            multipart.addFile(
                fieldName: "image",
                fileName: imageAttachment.fileName,
                mimeType: imageAttachment.mimeType,
                data: imageAttachment.data
            )
        }
        
        if AppConfig.enableLogging {
            print("📡 [TeacherCoursesService] Creating course for class \(request.classId)")
        }
        
        return try await networkService.upload(
            endpoint: "/course/create",
            method: .POST,
            multipart: multipart,
            headers: ["Authorization": "Bearer \(token)"]
        )
    }
    
    /// Create a course edit request (POST /course/edit-request/:courseId)
    func createCourseEditRequest(
        courseId: String,
        name: String,
        description: String,
        price: Double,
        level: CourseLevelOption,
        courseReduction: Int?,
        changeReason: String,
        imageAttachment: CourseImageAttachment?
    ) async throws -> CourseEditRequestResponse {
        guard let token = authService.getAuthToken() else {
            throw NetworkError.unauthorized
        }
        
        var multipart = MultipartFormData()
        let trimmedName = name.trimmingCharacters(in: .whitespacesAndNewlines)
        let trimmedDescription = description.trimmingCharacters(in: .whitespacesAndNewlines)
        let trimmedReason = changeReason.trimmingCharacters(in: .whitespacesAndNewlines)
        multipart.addField(name: "name", value: trimmedName)
        multipart.addField(name: "description", value: trimmedDescription)
        multipart.addField(name: "price", value: String(format: "%.2f", price))
        multipart.addField(name: "level", value: level.rawValue)
        if let reduction = courseReduction {
            multipart.addField(name: "course_reduction", value: String(reduction))
        }
        multipart.addField(name: "changeReason", value: trimmedReason)
        if let imageAttachment {
            multipart.addFile(
                fieldName: "image",
                fileName: imageAttachment.fileName,
                mimeType: imageAttachment.mimeType,
                data: imageAttachment.data
            )
        }
        
        if AppConfig.enableLogging {
            print("📡 [TeacherCoursesService] Submitting edit request for course \(courseId)")
        }
        
        return try await networkService.upload(
            endpoint: "/course/edit-request/\(courseId)",
            method: .POST,
            multipart: multipart,
            headers: ["Authorization": "Bearer \(token)"]
        )
    }

    /// Archive a course (DELETE /course/archive/:id)
    func archiveCourse(id: String) async throws -> BasicMessageResponse {
        guard let token = authService.getAuthToken() else {
            throw NetworkError.unauthorized
        }
        if AppConfig.enableLogging {
            print("📡 [TeacherCoursesService] Archiving course \(id)")
        }
        return try await networkService.request(
            endpoint: "/course/archive/\(id)",
            method: .DELETE,
            body: nil,
            headers: ["Authorization": "Bearer \(token)"]
        )
    }

    /// Unarchive a course (PUT /course/unarchive/:id)
    func unarchiveCourse(id: String) async throws -> BasicMessageResponse {
        guard let token = authService.getAuthToken() else {
            throw NetworkError.unauthorized
        }
        if AppConfig.enableLogging {
            print("📡 [TeacherCoursesService] Unarchiving course \(id)")
        }
        return try await networkService.request(
            endpoint: "/course/unarchive/\(id)",
            method: .PUT,
            body: nil,
            headers: ["Authorization": "Bearer \(token)"]
        )
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
    
    func createCourse(request: CourseCreationRequest, imageAttachment: CourseImageAttachment?) async throws -> CourseCreationResponse {
        try await Task.sleep(nanoseconds: 500_000_000)
        let payload = CourseCreationPayload(
            id: UUID().uuidString,
            name: request.name,
            image: nil,
            description: request.description,
            price: request.price,
            level: request.level.rawValue,
            courseOrder: "1",
            courseReduction: request.courseReduction
        )
        return CourseCreationResponse(
            success: true,
            message: "Mock course created successfully",
            data: payload
        )
    }
    
    func createCourseEditRequest(
        courseId: String,
        name: String,
        description: String,
        price: Double,
        level: CourseLevelOption,
        courseReduction: Int?,
        changeReason: String,
        imageAttachment: CourseImageAttachment?
    ) async throws -> CourseEditRequestResponse {
        try await Task.sleep(nanoseconds: 300_000_000)
        return CourseEditRequestResponse(
            success: true,
            message: "Mock edit request submitted successfully"
        )
    }

    func archiveCourse(id: String) async throws -> BasicMessageResponse {
        try await Task.sleep(nanoseconds: 200_000_000)
        return BasicMessageResponse(success: true, message: "Course archived successfully")
    }
    
    func unarchiveCourse(id: String) async throws -> BasicMessageResponse {
        try await Task.sleep(nanoseconds: 200_000_000)
        return BasicMessageResponse(success: true, message: "Course unarchived successfully")
    }
}

// MARK: - Generic Message Response
struct BasicMessageResponse: Decodable {
    let success: Bool
    let message: String?
}
