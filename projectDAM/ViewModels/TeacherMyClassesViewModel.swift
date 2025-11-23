//
//  TeacherMyClassesViewModel.swift
//  projectDAM
//
//  Created on 11/23/2025.
//

import Foundation
import SwiftUI
import Combine

@MainActor
final class TeacherMyClassesViewModel: ObservableObject {
    
    // MARK: - Published Properties
    @Published var viewState: TeacherClassesViewState = .loading
    @Published var searchText: String = ""
    @Published var selectedSortOption: SortOption = .newest
    @Published var expandedClassIds: Set<String> = []
    @Published var isRefreshing: Bool = false
    @Published var availableClasses: [AvailableClass] = []
    @Published var showCreateCourseSheet: Bool = false
    @Published var selectedClassForCourse: AvailableClass?
    
    // MARK: - Private Properties
    private let teacherCoursesService: TeacherCoursesServiceProtocol
    private var allClasses: [ClassWithCourses] = []
    private var cancellables = Set<AnyCancellable>()
    
    // MARK: - Computed Properties
    var filteredAndSortedClasses: [ClassWithCourses] {
        var classes = allClasses
        
        // Apply search filter
        if !searchText.isEmpty {
            classes = classes.compactMap { classWithCourses in
                // Filter courses within the class
                let filteredCourses = classWithCourses.courses.filter { course in
                    course.name.localizedCaseInsensitiveContains(searchText) ||
                    course.description?.localizedCaseInsensitiveContains(searchText) == true
                }
                
                // Check if class title matches
                let classMatches = classWithCourses.classItem.title.localizedCaseInsensitiveContains(searchText)
                
                // Return class if it matches or has matching courses
                if classMatches || !filteredCourses.isEmpty {
                    return ClassWithCourses(
                        classItem: classWithCourses.classItem,
                        courses: classMatches ? classWithCourses.courses : filteredCourses
                    )
                }
                return nil
            }
        }
        
        // Apply sorting to courses within each class
        classes = classes.map { classWithCourses in
            let sortedCourses = sortCourses(classWithCourses.courses, by: selectedSortOption)
            return ClassWithCourses(
                classItem: classWithCourses.classItem,
                courses: sortedCourses
            )
        }
        
        return classes
    }
    
    var totalCourses: Int {
        allClasses.reduce(0) { $0 + $1.courses.count }
    }
    
    var totalStudents: Int {
        allClasses.flatMap { $0.courses }.reduce(0) { $0 + $1.studentCount }
    }
    
    var approvedCoursesCount: Int {
        allClasses.flatMap { $0.courses }.filter { $0.approvalStatus?.lowercased() == "approved" }.count
    }
    
    var pendingCoursesCount: Int {
        allClasses.flatMap { $0.courses }.filter { $0.approvalStatus?.lowercased() == "pending" }.count
    }
    
    // MARK: - Sort Options
    enum SortOption: String, CaseIterable {
        case newest = "Newest"
        case enrollment = "Enrollment"
        case rating = "Rating"
    }
    
    // MARK: - Initialization
    init(teacherCoursesService: TeacherCoursesServiceProtocol) {
        self.teacherCoursesService = teacherCoursesService
        setupSearchDebounce()
    }
    
    // MARK: - Public Methods
    
    /// Load teacher's courses
    func loadCourses() async {
        viewState = .loading
        
        do {
            print("🔄 [TeacherMyClassesViewModel] Loading courses...")
            let classes = try await teacherCoursesService.fetchMyCourses()
            
            if classes.isEmpty {
                print("ℹ️ [TeacherMyClassesViewModel] No classes found - showing empty state")
                viewState = .empty
            } else {
                print("✅ [TeacherMyClassesViewModel] Loaded \(classes.count) classes successfully")
                allClasses = classes
                viewState = .loaded(classes)
                
                // Auto-expand classes with courses
                expandedClassIds = Set(classes.filter { !$0.courses.isEmpty }.map { $0.id })
            }
        } catch {
            print("❌ [TeacherMyClassesViewModel] Error loading courses: \(error)")
            
            // Provide user-friendly error messages matching Android
            let errorMessage: String
            if let networkError = error as? NetworkError {
                switch networkError {
                case .unauthorized:
                    errorMessage = "Your session has expired. Please log in again."
                case .serverError(let code, let message):
                    if let msg = message {
                        errorMessage = msg
                    } else {
                        switch code {
                        case 0:
                            errorMessage = "Unable to connect to server. Please check your internet connection."
                        case 404:
                            errorMessage = "Endpoint not found. Please update the app."
                        case 500...599:
                            errorMessage = "Server error. Please try again later."
                        default:
                            errorMessage = "Network error (\(code)). Please try again."
                        }
                    }
                case .decodingError:
                    errorMessage = "Failed to load data. Please try again."
                case .invalidURL:
                    errorMessage = "Invalid server configuration. Please contact support."
                case .invalidResponse:
                    errorMessage = "Invalid server response. Please try again."
                case .noData:
                    errorMessage = "No data received from server."
                }
            } else if let decodingError = error as? DecodingError {
                print("🔍 Decoding error details: \(decodingError)")
                errorMessage = "Failed to load data. Please try again."
            } else {
                errorMessage = "Something went wrong. Please try again."
            }
            
            viewState = .error(errorMessage)
        }
    }
    
    /// Refresh courses
    func refreshCourses() async {
        isRefreshing = true
        defer { isRefreshing = false }
        
        do {
            let classes = try await teacherCoursesService.fetchMyCourses()
            allClasses = classes
            
            if classes.isEmpty {
                viewState = .empty
            } else {
                viewState = .loaded(classes)
            }
        } catch {
            // Keep current state on refresh error, just show alert
            print("Error refreshing: \(error.localizedDescription)")
        }
    }
    
    /// Load available classes for course creation
    func loadAvailableClasses() async {
        do {
            availableClasses = try await teacherCoursesService.fetchAvailableClasses()
        } catch {
            print("Error loading available classes: \(error.localizedDescription)")
        }
    }
    
    /// Toggle class expansion
    func toggleClassExpansion(_ classId: String) {
        if expandedClassIds.contains(classId) {
            expandedClassIds.remove(classId)
        } else {
            expandedClassIds.insert(classId)
        }
    }
    
    /// Check if class is expanded
    func isClassExpanded(_ classId: String) -> Bool {
        expandedClassIds.contains(classId)
    }
    
    /// Get courses for a specific class
    func getCoursesForClass(_ classId: String) -> [TeacherCourse] {
        allClasses.first(where: { $0.id == classId })?.courses ?? []
    }
    
    /// Show create course sheet for a specific class
    func showCreateCourse(for classItem: AvailableClass) {
        selectedClassForCourse = classItem
        showCreateCourseSheet = true
    }
    
    /// Clear search
    func clearSearch() {
        searchText = ""
    }
    
    // MARK: - Private Methods
    
    private func setupSearchDebounce() {
        // Debounce search to avoid too many state updates
        $searchText
            .debounce(for: .milliseconds(300), scheduler: DispatchQueue.main)
            .sink { [weak self] _ in
                self?.objectWillChange.send()
            }
            .store(in: &cancellables)
    }
    
    private func sortCourses(_ courses: [TeacherCourse], by option: SortOption) -> [TeacherCourse] {
        switch option {
        case .newest:
            // Sort by course order (assuming lower order = newer)
            return courses.sorted { (lhs, rhs) in
                guard let lhsOrder = Int(lhs.courseOrder ?? "999"),
                      let rhsOrder = Int(rhs.courseOrder ?? "999") else {
                    return false
                }
                return lhsOrder < rhsOrder
            }
        case .enrollment:
            return courses.sorted { $0.studentCount > $1.studentCount }
        case .rating:
            // For now, sort by student count as we don't have ratings
            // TODO: Implement actual rating when backend provides it
            return courses.sorted { $0.studentCount > $1.studentCount }
        }
    }
}
