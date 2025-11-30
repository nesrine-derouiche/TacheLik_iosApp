//
//  StudentHomeViewModel.swift
//  projectDAM
//
//  ViewModel for student home dashboard with dynamic data
//

import Foundation
import SwiftUI
import Combine

@MainActor
final class StudentHomeViewModel: ObservableObject {
    
    // MARK: - Published Properties
    
    // Loading State
    @Published var isLoading: Bool = false
    @Published var errorMessage: String?
    
    // User Info
    @Published var currentUser: User?
    
    // Statistics
    @Published var totalCourses: Int = 0
    @Published var totalHours: Double = 0
    @Published var coursesInProgress: Int = 0
    @Published var coursesCompleted: Int = 0
    @Published var averageProgress: Double = 0
    
    // Courses Data
    @Published var recentCourses: [OwnedCourse] = []
    @Published var allCourses: [OwnedCourse] = []
    @Published var classesSummary: [ClassSummary] = []
    
    // MARK: - Dependencies
    private let studentHomeService: StudentHomeServiceProtocol
    private let authService: AuthServiceProtocol
    
    // MARK: - Initialization
    init(studentHomeService: StudentHomeServiceProtocol, authService: AuthServiceProtocol) {
        self.studentHomeService = studentHomeService
        self.authService = authService
        self.currentUser = authService.getCurrentUser()
    }
    
    // MARK: - Computed Properties
    
    /// Dynamic greeting based on time of day
    var greeting: String {
        let hour = Calendar.current.component(.hour, from: Date())
        switch hour {
        case 0..<12: return "Good Morning"
        case 12..<17: return "Good Afternoon"
        case 17..<22: return "Good Evening"
        default: return "Good Night"
        }
    }
    
    /// User's display name
    var userName: String {
        return currentUser?.username ?? currentUser?.name ?? "Student"
    }
    
    /// Formatted total hours
    var formattedTotalHours: String {
        if totalHours >= 1 {
            return String(format: "%.0fh", totalHours)
        } else if totalHours > 0 {
            return String(format: "%.0fm", totalHours * 60)
        }
        return "0h"
    }
    
    /// Learning streak (placeholder for future)
    var learningStreak: Int {
        return 7 // Placeholder - would need backend support
    }
    
    /// Achievements count (placeholder for future)
    var achievementsCount: Int {
        return 3 // Placeholder - would need backend support
    }
    
    // MARK: - Public Methods
    
    /// Load all student dashboard data
    func loadData() async {
        isLoading = true
        errorMessage = nil
        
        do {
            // Refresh user
            currentUser = authService.getCurrentUser()
            
            // Fetch analytics
            let analytics = try await studentHomeService.fetchStudentAnalytics()
            
            // Update published properties
            totalCourses = analytics.totalCourses
            totalHours = analytics.totalHours
            coursesInProgress = analytics.coursesInProgress
            coursesCompleted = analytics.coursesCompleted
            averageProgress = analytics.averageProgress
            recentCourses = analytics.recentCourses
            classesSummary = analytics.classesSummary
            
            print("✅ [StudentHomeViewModel] Data loaded: \(totalCourses) courses, \(formattedTotalHours) hours")
            
        } catch {
            handleError(error)
        }
        
        isLoading = false
    }
    
    /// Refresh data
    func refresh() async {
        await loadData()
    }
    
    // MARK: - Private Methods
    
    private func handleError(_ error: Error) {
        if let networkError = error as? NetworkError {
            switch networkError {
            case .unauthorized:
                errorMessage = "Please log in to view your courses"
            case .serverError(let code, let message):
                // 404 is okay - means no courses yet
                let msg = message ?? ""
                if code == 404 || msg.contains("No courses") || msg.contains("not found") {
                    errorMessage = nil
                } else {
                    errorMessage = message ?? "Server error: \(code)"
                }
            case .decodingError:
                errorMessage = "Failed to load data. Please try again."
            case .invalidURL, .invalidResponse, .noData:
                errorMessage = error.localizedDescription
            }
        } else {
            errorMessage = error.localizedDescription
        }
        
        if errorMessage != nil {
            print("❌ [StudentHomeViewModel] Error: \(errorMessage ?? "Unknown")")
        }
    }
}
