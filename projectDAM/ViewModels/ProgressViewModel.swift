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
    var coursesInProgress: [Course] {
        return courses.filter { ($0.progress ?? 0) > 0 && ($0.progress ?? 0) < 1.0 }
    }
    
    /// Get completed courses
    var completedCourses: [Course] {
        return courses.filter { ($0.progress ?? 0) >= 1.0 }
    }
    
    /// Calculate overall progress percentage
    var overallProgress: Double {
        guard !courses.isEmpty else { return 0 }
        let totalProgress = courses.reduce(0.0) { $0 + ($1.progress ?? 0) }
        return totalProgress / Double(courses.count)
    }
    
    // MARK: - Private Methods
    
    private func calculateStats() {
        let completed = completedCourses.count
        let totalHours = courses.reduce(0.0) { $0 + ($1.duration * ($1.progress ?? 0)) }
        
        userStats = UserStats(
            coursesCompleted: completed,
            totalHours: Int(totalHours),
            currentStreak: 7 // Mock value
        )
    }
}
