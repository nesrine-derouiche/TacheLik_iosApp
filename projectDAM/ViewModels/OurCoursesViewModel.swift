//
//  OurCoursesViewModel.swift
//  projectDAM
//
//  Created on 11/14/2025.
//

import Foundation
import SwiftUI
import Combine

@MainActor
final class OurCoursesViewModel: ObservableObject {
    
    // MARK: - Published Properties
    @Published var courses: [Course] = []
    @Published var isLoading = false
    @Published var errorMessage: String?
    @Published var showError = false
    
    // MARK: - Dependencies
    private let courseService: CourseServiceProtocol
    private var cancellables = Set<AnyCancellable>()
    
    // MARK: - Computed Properties
    var hasNoCourses: Bool {
        !isLoading && courses.isEmpty && errorMessage == nil
    }
    
    // MARK: - Initialization
    init(courseService: CourseServiceProtocol) {
        self.courseService = courseService
    }
    
    // MARK: - Public Methods
    
    /// Fetch courses for a specific class
    func fetchCourses(forClass classTitle: String) async {
        isLoading = true
        errorMessage = nil
        showError = false
        
        do {
            if AppConfig.enableLogging {
                print("🔄 [OurCoursesViewModel] Fetching courses for class: \(classTitle)")
            }
            
            let fetchedCourses = try await courseService.fetchCoursesByClass(classTitle: classTitle)
            
            // Sort courses by course_order
            courses = fetchedCourses.sorted { course1, course2 in
                // Parse course_order strings (e.g., "1-1", "1-2")
                let order1 = parseCourseOrder(course1.courseOrder)
                let order2 = parseCourseOrder(course2.courseOrder)
                
                if order1.0 == order2.0 {
                    return order1.1 < order2.1
                }
                return order1.0 < order2.0
            }
            
            if AppConfig.enableLogging {
                print("✅ [OurCoursesViewModel] Successfully fetched \(courses.count) courses")
            }
            
            isLoading = false
        } catch {
            if AppConfig.enableLogging {
                print("❌ [OurCoursesViewModel] Error fetching courses: \(error.localizedDescription)")
            }
            
            errorMessage = "Failed to load courses: \(error.localizedDescription)"
            showError = true
            isLoading = false
        }
    }
    
    /// Retry fetching courses
    func retry(forClass classTitle: String) async {
        await fetchCourses(forClass: classTitle)
    }
    
    // MARK: - Private Methods
    
    /// Parse course order string (e.g., "1-1" -> (1, 1))
    private func parseCourseOrder(_ orderString: String) -> (Int, Int) {
        let components = orderString.split(separator: "-").compactMap { Int($0) }
        guard components.count == 2 else {
            return (0, 0)
        }
        return (components[0], components[1])
    }
}
