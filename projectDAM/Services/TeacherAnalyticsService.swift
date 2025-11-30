//
//  TeacherAnalyticsService.swift
//  projectDAM
//
//  Created for dynamic teacher dashboard analytics
//

import Foundation

// MARK: - Teacher Analytics Service Protocol
protocol TeacherAnalyticsServiceProtocol {
    /// Fetches comprehensive analytics for the current teacher
    /// - Parameter timeframe: Optional timeframe (7d, 30d, 90d, 1y). Defaults to 30d.
    /// - Returns: TeacherAnalyticsData containing all analytics metrics
    func fetchAnalytics(timeframe: String?) async throws -> TeacherAnalyticsData
    
    /// Fetches course summary with student counts for the current teacher
    /// - Returns: Array of CourseSummary objects
    func fetchCourseSummary() async throws -> [CourseSummary]
}

// MARK: - Teacher Analytics Service Implementation
class TeacherAnalyticsService: TeacherAnalyticsServiceProtocol {
    
    private let baseURL: String
    private let authService: AuthServiceProtocol
    
    init(authService: AuthServiceProtocol) {
        self.baseURL = AppConfig.baseURL
        self.authService = authService
    }
    
    // MARK: - Fetch Analytics
    func fetchAnalytics(timeframe: String? = nil) async throws -> TeacherAnalyticsData {
        // Build URL with query parameters
        var urlComponents = URLComponents(string: "\(baseURL)/teacher-analytics")
        
        if let timeframe = timeframe {
            urlComponents?.queryItems = [URLQueryItem(name: "timeframe", value: timeframe)]
        }
        
        guard let url = urlComponents?.url else {
            print("❌ [TeacherAnalyticsService] Invalid URL")
            throw NetworkError.invalidURL
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        // Add authentication token
        if let token = authService.getAuthToken() {
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
            print("🔑 [TeacherAnalyticsService] Token added to request")
        } else {
            print("⚠️ [TeacherAnalyticsService] No auth token available")
            throw NetworkError.unauthorized
        }
        
        print("📡 [TeacherAnalyticsService] Fetching analytics from: \(url.absoluteString)")
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            print("❌ [TeacherAnalyticsService] Invalid response type")
            throw NetworkError.invalidResponse
        }
        
        print("📊 [TeacherAnalyticsService] Response status: \(httpResponse.statusCode)")
        
        // Log raw response for debugging
        if let responseString = String(data: data, encoding: .utf8) {
            let truncated = responseString.prefix(500)
            print("📦 [TeacherAnalyticsService] Response preview: \(truncated)...")
        }
        
        switch httpResponse.statusCode {
        case 200...299:
            let decoder = JSONDecoder()
            let analyticsResponse = try decoder.decode(TeacherAnalyticsResponse.self, from: data)
            
            if analyticsResponse.success, let analyticsData = analyticsResponse.data {
                print("✅ [TeacherAnalyticsService] Analytics fetched successfully")
                print("   - Total Enrollments: \(analyticsData.totalEnrollments ?? 0)")
                print("   - Active Students: \(analyticsData.activeStudents ?? 0)")
                print("   - Total Revenue: \(analyticsData.totalRevenue ?? 0)")
                return analyticsData
            } else {
                print("❌ [TeacherAnalyticsService] API returned success=false: \(analyticsResponse.message ?? "No message")")
                throw NetworkError.serverError(httpResponse.statusCode, analyticsResponse.message ?? "Failed to fetch analytics")
            }
            
        case 401:
            print("❌ [TeacherAnalyticsService] Unauthorized")
            throw NetworkError.unauthorized
            
        case 403:
            print("❌ [TeacherAnalyticsService] Forbidden - Not a teacher")
            throw NetworkError.serverError(403, "Teacher privileges required")
            
        default:
            print("❌ [TeacherAnalyticsService] Server error: \(httpResponse.statusCode)")
            throw NetworkError.serverError(httpResponse.statusCode, "Server error")
        }
    }
    
    // MARK: - Fetch Course Summary
    func fetchCourseSummary() async throws -> [CourseSummary] {
        guard let url = URL(string: "\(baseURL)/teacher-analytics/courses") else {
            print("❌ [TeacherAnalyticsService] Invalid URL for course summary")
            throw NetworkError.invalidURL
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        // Add authentication token
        if let token = authService.getAuthToken() {
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        } else {
            throw NetworkError.unauthorized
        }
        
        print("📡 [TeacherAnalyticsService] Fetching course summary from: \(url.absoluteString)")
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw NetworkError.invalidResponse
        }
        
        print("📊 [TeacherAnalyticsService] Course summary response status: \(httpResponse.statusCode)")
        
        switch httpResponse.statusCode {
        case 200...299:
            let decoder = JSONDecoder()
            let summaryResponse = try decoder.decode(TeacherCourseSummaryResponse.self, from: data)
            
            if summaryResponse.success, let courses = summaryResponse.data {
                print("✅ [TeacherAnalyticsService] Course summary fetched: \(courses.count) courses")
                return courses
            } else {
                throw NetworkError.serverError(httpResponse.statusCode, summaryResponse.message ?? "Failed to fetch course summary")
            }
            
        case 401:
            throw NetworkError.unauthorized
            
        default:
            throw NetworkError.serverError(httpResponse.statusCode, "Server error")
        }
    }
}
