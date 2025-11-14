//
//  HomeViewModel.swift
//  projectDAM
//
//  Created on 11/7/2025.
//

import Foundation
import SwiftUI
import Combine

// MARK: - Home View Model
/// Manages home screen state and business logic
@MainActor
final class HomeViewModel: ObservableObject {
    
    // MARK: - Published Properties
    @Published var courses: [Course] = []
    @Published var userStats: ProfileStats?
    @Published var isLoading: Bool = false
    @Published var errorMessage: String?
    @Published var currentUser: User?
    
    // MARK: - Dependencies
    private let courseService: CourseServiceProtocol
    private let authService: AuthServiceProtocol
    
    // MARK: - Initialization
    init(courseService: CourseServiceProtocol, authService: AuthServiceProtocol) {
        self.courseService = courseService
        self.authService = authService
        self.currentUser = authService.getCurrentUser()
    }
    
    // MARK: - Public Methods
    
    /// Load home data
    func loadData() async {
        isLoading = true
        errorMessage = nil
        
        do {
            // Fetch user's enrolled courses
            courses = try await courseService.fetchUserCourses()
            
            // Calculate stats from courses
            calculateStats()
            
            print("✅ Home data loaded: \(courses.count) courses")
        } catch {
            errorMessage = error.localizedDescription
            print("❌ Failed to load home data: \(error.localizedDescription)")
        }
        
        isLoading = false
    }
    
    /// Get greeting based on time of day
    var greeting: String {
        let hour = Calendar.current.component(.hour, from: Date())
        switch hour {
        case 0..<12: return "Good Morning"
        case 12..<17: return "Good Afternoon"
        default: return "Good Evening"
        }
    }
    
    /// Get user's name or default
    var userName: String {
        return currentUser?.name ?? "Student"
    }
    
    /// Get continue learning courses (in progress)
    /// Note: Progress tracking will be implemented with user-course relationship in future
    var continueLearningCourses: [Course] {
        // For now, return all enrolled courses
        // TODO: Implement progress tracking via backend API
        return courses
    }
    
    // MARK: - Private Methods
    
    private func calculateStats() {
        // Note: Progress tracking needs to be implemented via backend API
        // For now, using course count as enrolled courses
        let totalHours = courses.reduce(0.0) { $0 + $1.duration }
        
        userStats = ProfileStats(
            coursesCompleted: 0, // TODO: Fetch from backend
            coursesInProgress: courses.count, // All enrolled courses
            totalHours: Int(totalHours),
            averageScore: 85, // TODO: Fetch from backend
            dayStreak: 7, // TODO: Fetch from backend
            classRank: "Top 10%" // TODO: Fetch from backend
        )
    }
}
