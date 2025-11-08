//
//  ClassesViewModel.swift
//  projectDAM
//
//  Created on 11/7/2025.
//

import Foundation
import SwiftUI
import Combine

// MARK: - Classes View Model
/// Manages classes screen state and course filtering logic
@MainActor
final class ClassesViewModel: ObservableObject {
    
    // MARK: - Published Properties
    @Published var courses: [Course] = []
    @Published var selectedCategory: String = "All"
    @Published var searchText: String = ""
    @Published var isLoading: Bool = false
    @Published var errorMessage: String?
    
    // MARK: - Dependencies
    private let courseService: CourseServiceProtocol
    
    // MARK: - Initialization
    init(courseService: CourseServiceProtocol) {
        self.courseService = courseService
    }
    
    // MARK: - Public Methods
    
    /// Load all courses
    func loadCourses() async {
        isLoading = true
        errorMessage = nil
        
        do {
            courses = try await courseService.fetchCourses()
            print("✅ Courses loaded: \(courses.count) courses")
        } catch {
            errorMessage = error.localizedDescription
            print("❌ Failed to load courses: \(error.localizedDescription)")
        }
        
        isLoading = false
    }
    
    /// Get filtered courses based on category and search
    var filteredCourses: [Course] {
        var result = courses
        
        // Filter by category
        if selectedCategory != "All" {
            result = result.filter { $0.category == selectedCategory }
        }
        
        // Filter by search text
        if !searchText.isEmpty {
            result = result.filter { course in
                course.title.localizedCaseInsensitiveContains(searchText) ||
                course.instructor.localizedCaseInsensitiveContains(searchText)
            }
        }
        
        return result
    }
    
    /// Get unique categories from courses
    var categories: [String] {
        var cats = Set(courses.map { $0.category })
        return ["All"] + cats.sorted()
    }
    
    /// Select a category
    func selectCategory(_ category: String) {
        selectedCategory = category
    }
    
    /// Enroll in a course
    func enrollCourse(_ course: Course) async {
        do {
            try await courseService.enrollCourse(courseId: course.id)
            print("✅ Enrolled in course: \(course.title)")
            // Reload courses to update enrollment status
            await loadCourses()
        } catch {
            errorMessage = error.localizedDescription
            print("❌ Failed to enroll: \(error.localizedDescription)")
        }
    }
}
