//
//  ProgressViewModel.swift
//  projectDAM
//
//  Created on 11/7/2025.
//

import Foundation
import SwiftUI
import Combine

// MARK: - Progress View Model
/// Manages learning progress tracking and statistics
@MainActor
final class ProgressViewModel: ObservableObject {
    
    // MARK: - Published Properties
    @Published var courses: [Course] = []
    @Published var userStats: UserStats?
    @Published var isLoading: Bool = false
    @Published var errorMessage: String?
    
    // MARK: - Dependencies
    private let courseService: CourseServiceProtocol
    private let authService: AuthServiceProtocol
    
    // MARK: - Initialization
    init(courseService: CourseServiceProtocol, authService: AuthServiceProtocol) {
        self.courseService = courseService
        self.authService = authService
    }
    
    // MARK: - Public Methods
    
    /// Load progress data
    func loadProgress() async {
        isLoading = true
        errorMessage = nil
        
        do {
            courses = try await courseService.fetchUserCourses()
            calculateStats()
            print("✅ Progress data loaded")
        } catch {
            errorMessage = error.localizedDescription
            print("❌ Failed to load progress: \(error.localizedDescription)")
        }
        
        isLoading = false
    }
    
    /// Get courses in progress
    /// Note: Progress tracking will be implemented with user-course relationship in future
    var coursesInProgress: [Course] {
        // TODO: Implement progress tracking via backend API
        return courses
    }
    
    /// Get completed courses
    /// Note: Progress tracking will be implemented with user-course relationship in future
    var completedCourses: [Course] {
        // TODO: Implement progress tracking via backend API
        return []
    }
    
    /// Calculate overall progress percentage
    /// Note: Progress tracking will be implemented with user-course relationship in future
    var overallProgress: Double {
        // TODO: Implement progress tracking via backend API
        return 0.0
    }
    
    // MARK: - Private Methods
    
    private func calculateStats() {
        // Note: Progress tracking needs to be implemented via backend API
        let completed = completedCourses.count
        let totalHours = courses.reduce(into: 0.0) { result, course in
            result += course.duration
        }
        
        userStats = UserStats(
            coursesCompleted: completed,
            totalHours: Int(totalHours),
            currentStreak: 7 // TODO: Fetch from backend
        )
    }
}
