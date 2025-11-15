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
    @Published private(set) var visibleCourses: [Course] = []
    @Published private var visibleCourseCount: Int = 0
    @Published var isLoading = false
    @Published var errorMessage: String?
    @Published var showError = false
    
    // MARK: - Dependencies
    private let courseService: CourseServiceProtocol
    private var cancellables = Set<AnyCancellable>()
    private let initialCourseBatchSize = 3
    private let courseBatchSize = 4

    // MARK: - Computed Properties
    var hasNoCourses: Bool {
        !isLoading && courses.isEmpty && errorMessage == nil
    }
    
    var canLoadMoreCourses: Bool {
        visibleCourseCount < courses.count
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
            resetVisibleCourses()
            
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
    
    func loadMoreCoursesIfNeeded(currentCourseID: String?) {
        guard let currentCourseID,
              let currentIndex = courses.firstIndex(where: { $0.id == currentCourseID }) else { return }
        if currentIndex >= max(0, visibleCourseCount - 2) {
            let newCount = min(visibleCourseCount + courseBatchSize, courses.count)
            if newCount > visibleCourseCount {
                withAnimation(.easeInOut(duration: 0.25)) {
                    visibleCourseCount = newCount
                    updateVisibleCourses()
                }
            }
        }
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
    
    private func resetVisibleCourses() {
        visibleCourseCount = min(initialCourseBatchSize, courses.count)
        updateVisibleCourses()
    }
    
    private func updateVisibleCourses() {
        visibleCourses = Array(courses.prefix(visibleCourseCount))
    }
}
