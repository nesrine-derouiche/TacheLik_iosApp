//
//  StudentHomeService.swift
//  projectDAM
//
//  Service to fetch student dashboard data
//

import Foundation

// MARK: - Student Home Service Protocol
protocol StudentHomeServiceProtocol {
    func fetchUserCourses() async throws -> [OwnedCourse]
    func fetchLastCourses(limit: Int) async throws -> [OwnedCourse]
    func fetchStudentAnalytics() async throws -> StudentHomeAnalytics
}

// MARK: - Student Home Service Implementation
final class StudentHomeService: StudentHomeServiceProtocol {
    
    // MARK: - Properties
    private let networkService: NetworkServiceProtocol
    private let authService: AuthServiceProtocol
    
    // MARK: - Initialization
    init(networkService: NetworkServiceProtocol, authService: AuthServiceProtocol) {
        self.networkService = networkService
        self.authService = authService
    }
    
    // MARK: - Public Methods
    
    /// Fetch all courses owned by the current user
    func fetchUserCourses() async throws -> [OwnedCourse] {
        guard let user = authService.getCurrentUser() else {
            throw NetworkError.unauthorized
        }
        
        if AppConfig.enableLogging {
            print("📡 [StudentHomeService] Fetching user courses for userId: \(user.id)")
        }
        
        let response: UserCoursesResponse = try await networkService.request(
            endpoint: "/course-ownership/user-courses?userId=\(user.id)",
            method: .GET,
            body: nil,
            headers: getAuthHeaders()
        )
        
        if AppConfig.enableLogging {
            print("✅ [StudentHomeService] Received \(response.courses.count) owned courses")
        }
        
        return response.courses
    }
    
    /// Fetch last N courses owned by the user (for continue learning section)
    func fetchLastCourses(limit: Int = 3) async throws -> [OwnedCourse] {
        guard let user = authService.getCurrentUser() else {
            throw NetworkError.unauthorized
        }
        
        if AppConfig.enableLogging {
            print("📡 [StudentHomeService] Fetching last \(limit) courses for userId: \(user.id)")
        }
        
        let response: LastCoursesResponse = try await networkService.request(
            endpoint: "/course-ownership/last-courses?userId=\(user.id)&limit=\(limit)",
            method: .GET,
            body: nil,
            headers: getAuthHeaders()
        )
        
        if AppConfig.enableLogging {
            print("✅ [StudentHomeService] Received \(response.courses.count) last courses")
        }
        
        return response.courses
    }
    
    /// Fetch combined student analytics
    func fetchStudentAnalytics() async throws -> StudentHomeAnalytics {
        guard let user = authService.getCurrentUser() else {
            throw NetworkError.unauthorized
        }
        
        if AppConfig.enableLogging {
            print("📡 [StudentHomeService] Fetching student analytics for userId: \(user.id)")
        }
        
        // Fetch all courses and last courses in parallel for efficiency
        async let allCoursesTask = fetchUserCoursesInternal(userId: user.id)
        async let lastCoursesTask = fetchLastCoursesInternal(userId: user.id, limit: 5)
        
        // Await both results
        let (allCourses, lastCourses) = try await (allCoursesTask, lastCoursesTask)
        
        // Calculate statistics from the courses
        let totalCourses = allCourses.count
        let totalHours = allCourses.reduce(0.0) { $0 + ($1.course.duration ?? 0) }
        
        // Group courses by class for summary
        var classCourseCounts: [String: (id: String, name: String, filterName: String, count: Int)] = [:]
        for course in allCourses {
            if let courseClass = course.course.courseClass {
                let key = courseClass.id
                if let existing = classCourseCounts[key] {
                    classCourseCounts[key] = (existing.id, existing.name, existing.filterName, existing.count + 1)
                } else {
                    classCourseCounts[key] = (courseClass.id, courseClass.name, courseClass.filterName ?? "", 1)
                }
            }
        }
        
        let classesSummary = classCourseCounts.map { (_, value) in
            ClassSummary(id: value.id, name: value.name, filterName: value.filterName, coursesCount: value.count)
        }.sorted { $0.coursesCount > $1.coursesCount }
        
        let analytics = StudentHomeAnalytics(
            totalCourses: totalCourses,
            totalHours: totalHours,
            coursesInProgress: totalCourses, // All are in progress (no completion tracking yet)
            coursesCompleted: 0, // Not tracking completion yet
            averageProgress: 0.0, // Not tracking progress yet
            recentCourses: lastCourses,
            classesSummary: classesSummary
        )
        
        if AppConfig.enableLogging {
            print("✅ [StudentHomeService] Analytics ready: \(totalCourses) courses, \(String(format: "%.1f", totalHours))h total")
        }
        
        return analytics
    }
    
    // MARK: - Private Methods
    
    private func fetchUserCoursesInternal(userId: String) async throws -> [OwnedCourse] {
        do {
            let response: UserCoursesResponse = try await networkService.request(
                endpoint: "/course-ownership/user-courses?userId=\(userId)",
                method: .GET,
                body: nil,
                headers: getAuthHeaders()
            )
            return response.courses
        } catch {
            // Handle 404 as empty list
            if case NetworkError.serverError(let code, _) = error, code == 404 {
                return []
            }
            throw error
        }
    }
    
    private func fetchLastCoursesInternal(userId: String, limit: Int) async throws -> [OwnedCourse] {
        do {
            let response: LastCoursesResponse = try await networkService.request(
                endpoint: "/course-ownership/last-courses?userId=\(userId)&limit=\(limit)",
                method: .GET,
                body: nil,
                headers: getAuthHeaders()
            )
            return response.courses
        } catch {
            // Handle 404 as empty list
            if case NetworkError.serverError(let code, _) = error, code == 404 {
                return []
            }
            throw error
        }
    }
    
    private func getAuthHeaders() -> [String: String] {
        guard let token = authService.getAuthToken() else {
            return [:]
        }
        return ["Authorization": "Bearer \(token)"]
    }
}
