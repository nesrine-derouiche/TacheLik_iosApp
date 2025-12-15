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
    @Published var selectedCourseClassId: String?
    @Published var courseTitle: String = ""
    @Published var courseDescription: String = ""
    @Published var coursePrice: String = ""
    @Published var courseDiscount: String = ""
    @Published var selectedCourseLevel: CourseLevelOption = .introduction
    @Published var courseImageData: Data?
    @Published var courseImageMimeType: String?
    @Published var courseImageFileName: String?
    @Published var isCreatingCourse: Bool = false
    @Published var createCourseError: String?
    @Published var createCourseSuccessMessage: String?
    @Published var didCreateCourseSuccessfully: Bool = false
    @Published var showEditCourseSheet: Bool = false
    @Published var editingCourse: TeacherCourse?
    @Published var editCourseTitle: String = ""
    @Published var editCourseDescription: String = ""
    @Published var editCoursePrice: String = ""
    @Published var editCourseDiscount: String = ""
    @Published var selectedEditCourseLevel: CourseLevelOption = .introduction
    @Published var editCourseImageData: Data?
    @Published var editCourseImageMimeType: String?
    @Published var editCourseImageFileName: String?
    @Published var editChangeReason: String = ""
    @Published var isSubmittingCourseEdit: Bool = false
    @Published var editCourseError: String?
    @Published var editCourseSuccessMessage: String?
    @Published var didSubmitCourseEditSuccessfully: Bool = false
    @Published var archivingCourseIds: Set<String> = []
    @Published var archiveActionError: String?
    @Published var archiveActionSuccessMessage: String?
    
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
            syncSelectedClass()
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
        startCreateCourseFlow(for: classItem)
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

    // MARK: - Course Creation Helpers
    func startCreateCourseFlow(for classItem: AvailableClass? = nil) {
        resetCourseCreationState(preserveClassSelection: false)
        selectedClassForCourse = classItem
        selectedCourseClassId = classItem?.id
        showCreateCourseSheet = true
    }
    
    func closeCreateCourseSheet() {
        showCreateCourseSheet = false
        resetCourseCreationState(preserveClassSelection: false)
    }
    
    func prepareAnotherCourse() {
        didCreateCourseSuccessfully = false
        createCourseSuccessMessage = nil
        resetCourseCreationState(preserveClassSelection: true)
    }
    
    func selectClass(by classId: String) {
        selectedCourseClassId = classId
        selectedClassForCourse = availableClasses.first(where: { $0.id == classId })
    }
    
    func updateCourseImage(data: Data, mimeType: String, fileName: String) {
        let maxSizeInBytes = 5 * 1024 * 1024
        guard data.count <= maxSizeInBytes else {
            createCourseError = "Image must be 5 MB or smaller"
            return
        }
        courseImageData = data
        courseImageMimeType = mimeType
        courseImageFileName = fileName
    }
    
    func clearCourseImageAttachment() {
        courseImageData = nil
        courseImageMimeType = nil
        courseImageFileName = nil
    }
    
    func submitCourseCreation() async {
        guard !isCreatingCourse else { return }
        createCourseError = nil
        didCreateCourseSuccessfully = false
        
        guard courseTitleValidation.isValid else {
            createCourseError = courseTitleValidation.errorMessage
            return
        }
        guard courseDescriptionValidation.isValid else {
            createCourseError = courseDescriptionValidation.errorMessage
            return
        }
        guard coursePriceValidation.isValid, let priceValue = parsePrice() else {
            createCourseError = coursePriceValidation.errorMessage
            return
        }
        guard classSelectionValidation.isValid, let classId = selectedCourseClassId ?? selectedClassForCourse?.id else {
            createCourseError = classSelectionValidation.errorMessage
            return
        }
        if !courseDiscountValidation.isValid {
            createCourseError = courseDiscountValidation.errorMessage
            return
        }
        
        let discountValue = parseDiscount()
        let request = CourseCreationRequest(
            name: courseTitle.trimmingCharacters(in: .whitespacesAndNewlines),
            description: courseDescription.trimmingCharacters(in: .whitespacesAndNewlines),
            price: priceValue,
            level: selectedCourseLevel,
            classId: classId,
            courseReduction: discountValue
        )
        
        var attachment: CourseImageAttachment?
        if let data = courseImageData,
           let mimeType = courseImageMimeType,
           let fileName = courseImageFileName {
            attachment = CourseImageAttachment(data: data, mimeType: mimeType, fileName: fileName)
        }
        
        isCreatingCourse = true
        defer { isCreatingCourse = false }
        
        do {
            let response = try await teacherCoursesService.createCourse(request: request, imageAttachment: attachment)
            await handleCourseCreationSuccess(message: response.message)
        } catch let networkError as NetworkError {
            if shouldIgnoreCourseCreationError(networkError) {
                await handleCourseCreationSuccess(message: nil)
            } else {
                createCourseError = networkError.errorDescription ?? "Failed to create course"
            }
        } catch {
            createCourseError = error.localizedDescription
        }
    }
    
    var courseTitleValidation: ValidationResult {
        let trimmed = courseTitle.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return .invalid("Title is required") }
        guard trimmed.count >= 3 else { return .invalid("Title must be at least 3 characters") }
        return .valid
    }
    
    var courseDescriptionValidation: ValidationResult {
        let trimmed = courseDescription.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return .invalid("Description is required") }
        guard trimmed.count >= 20 else { return .invalid("Description must be at least 20 characters") }
        return .valid
    }
    
    var coursePriceValidation: ValidationResult {
        let trimmed = coursePrice.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return .invalid("Price is required") }
        guard parsePrice() != nil else { return .invalid("Enter a valid price") }
        guard let price = parsePrice(), price >= 1 else { return .invalid("Price must be at least 1") }
        return .valid
    }
    
    var courseDiscountValidation: ValidationResult {
        let trimmed = courseDiscount.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return .valid }
        guard let value = Int(trimmed), (0...100).contains(value) else {
            return .invalid("Discount must be between 0 and 100")
        }
        return .valid
    }
    
    var classSelectionValidation: ValidationResult {
        guard let classId = selectedCourseClassId ?? selectedClassForCourse?.id else {
            return .invalid("Select a class")
        }
        if availableClasses.isEmpty || availableClasses.contains(where: { $0.id == classId }) {
            return .valid
        }
        return .invalid("Select a class")
    }
    
    var canSubmitCourse: Bool {
        courseTitleValidation.isValid &&
        courseDescriptionValidation.isValid &&
        coursePriceValidation.isValid &&
        courseDiscountValidation.isValid &&
        classSelectionValidation.isValid &&
        !isCreatingCourse
    }
    
    private func resetCourseCreationState(preserveClassSelection: Bool) {
        courseTitle = ""
        courseDescription = ""
        coursePrice = ""
        courseDiscount = ""
        selectedCourseLevel = .introduction
        courseImageData = nil
        courseImageMimeType = nil
        courseImageFileName = nil
        createCourseError = nil
        createCourseSuccessMessage = nil
        didCreateCourseSuccessfully = false
        if !preserveClassSelection {
            selectedClassForCourse = nil
            selectedCourseClassId = nil
        }
    }
    
    private func parsePrice() -> Double? {
        let normalized = coursePrice
            .replacingOccurrences(of: ",", with: ".")
            .replacingOccurrences(of: " ", with: "")
        guard let price = Double(normalized) else { return nil }
        return price
    }
    
    private func parseDiscount() -> Int? {
        let trimmed = courseDiscount.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty, let value = Int(trimmed), (0...100).contains(value) else { return nil }
        return value
    }
    
    private func syncSelectedClass() {
        guard let classId = selectedCourseClassId ?? selectedClassForCourse?.id else { return }
        selectedClassForCourse = availableClasses.first(where: { $0.id == classId })
        selectedCourseClassId = selectedClassForCourse?.id
    }

    private func handleCourseCreationSuccess(message: String?) async {
        let trimmedMessage = message?.trimmingCharacters(in: .whitespacesAndNewlines)
        let fallbackMessage = "Course created successfully. Pending admin approval."
        createCourseSuccessMessage = trimmedMessage?.isEmpty == false ? trimmedMessage : fallbackMessage
        createCourseError = nil
        didCreateCourseSuccessfully = true
        await loadCourses()
        await loadAvailableClasses()
    }
    
    private func shouldIgnoreCourseCreationError(_ error: NetworkError) -> Bool {
        guard case let .serverError(_, message) = error,
              let normalizedMessage = message?.lowercased() else {
            return false
        }
        return normalizedMessage.contains("field 'id' doesn't have a default value")
    }
    
    func startEditCourseFlow(for course: TeacherCourse) {
        editingCourse = course
        editCourseTitle = course.name
        editCourseDescription = course.description ?? ""
        if let priceValue = course.price {
            editCoursePrice = String(format: "%.2f", priceValue)
        } else {
            editCoursePrice = ""
        }
        if let reduction = course.courseReduction {
            editCourseDiscount = String(reduction)
        } else {
            editCourseDiscount = ""
        }
        if let levelString = course.level,
           let levelOption = CourseLevelOption(rawValue: levelString) {
            selectedEditCourseLevel = levelOption
        } else {
            selectedEditCourseLevel = .introduction
        }
        editCourseImageData = nil
        editCourseImageMimeType = nil
        editCourseImageFileName = nil
        editChangeReason = ""
        editCourseError = nil
        editCourseSuccessMessage = nil
        didSubmitCourseEditSuccessfully = false
        showEditCourseSheet = true
    }
    
    func closeEditCourseSheet() {
        showEditCourseSheet = false
        editingCourse = nil
        editCourseTitle = ""
        editCourseDescription = ""
        editCoursePrice = ""
        editCourseDiscount = ""
        selectedEditCourseLevel = .introduction
        editCourseImageData = nil
        editCourseImageMimeType = nil
        editCourseImageFileName = nil
        editChangeReason = ""
        editCourseError = nil
        editCourseSuccessMessage = nil
        didSubmitCourseEditSuccessfully = false
        isSubmittingCourseEdit = false
    }
    
    func updateEditCourseImage(data: Data, mimeType: String, fileName: String) {
        let maxSizeInBytes = 5 * 1024 * 1024
        guard data.count <= maxSizeInBytes else {
            editCourseError = "Image must be 5 MB or smaller"
            return
        }
        editCourseImageData = data
        editCourseImageMimeType = mimeType
        editCourseImageFileName = fileName
    }
    
    func clearEditCourseImageAttachment() {
        editCourseImageData = nil
        editCourseImageMimeType = nil
        editCourseImageFileName = nil
    }
    
    func submitCourseEdit() async {
        guard !isSubmittingCourseEdit else { return }
        guard let course = editingCourse else { return }
        editCourseError = nil
        didSubmitCourseEditSuccessfully = false
        
        guard editCourseTitleValidation.isValid else {
            editCourseError = editCourseTitleValidation.errorMessage
            return
        }
        guard editCourseDescriptionValidation.isValid else {
            editCourseError = editCourseDescriptionValidation.errorMessage
            return
        }
        guard editCoursePriceValidation.isValid, let priceValue = parseEditPrice() else {
            editCourseError = editCoursePriceValidation.errorMessage
            return
        }
        if !editCourseDiscountValidation.isValid {
            editCourseError = editCourseDiscountValidation.errorMessage
            return
        }
        guard editChangeReasonValidation.isValid else {
            editCourseError = editChangeReasonValidation.errorMessage
            return
        }
        
        let discountValue = parseEditDiscount()
        
        var attachment: CourseImageAttachment?
        if let data = editCourseImageData,
           let mimeType = editCourseImageMimeType,
           let fileName = editCourseImageFileName {
            attachment = CourseImageAttachment(data: data, mimeType: mimeType, fileName: fileName)
        }
        
        isSubmittingCourseEdit = true
        defer { isSubmittingCourseEdit = false }
        
        do {
            let response = try await teacherCoursesService.createCourseEditRequest(
                courseId: course.id,
                name: editCourseTitle.trimmingCharacters(in: .whitespacesAndNewlines),
                description: editCourseDescription.trimmingCharacters(in: .whitespacesAndNewlines),
                price: priceValue,
                level: selectedEditCourseLevel,
                courseReduction: discountValue,
                changeReason: editChangeReason.trimmingCharacters(in: .whitespacesAndNewlines),
                imageAttachment: attachment
            )
            await handleCourseEditSuccess(message: response.message)
        } catch let networkError as NetworkError {
            editCourseError = networkError.errorDescription ?? "Failed to submit edit request"
        } catch {
            editCourseError = error.localizedDescription
        }
    }
    
    var editCourseTitleValidation: ValidationResult {
        let trimmed = editCourseTitle.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return .invalid("Title is required") }
        guard trimmed.count >= 3 else { return .invalid("Title must be at least 3 characters") }
        return .valid
    }
    
    var editCourseDescriptionValidation: ValidationResult {
        let trimmed = editCourseDescription.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return .invalid("Description is required") }
        guard trimmed.count >= 20 else { return .invalid("Description must be at least 20 characters") }
        return .valid
    }
    
    var editCoursePriceValidation: ValidationResult {
        let trimmed = editCoursePrice.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return .invalid("Price is required") }
        guard parseEditPrice() != nil else { return .invalid("Enter a valid price") }
        guard let price = parseEditPrice(), price >= 1 else { return .invalid("Price must be at least 1") }
        return .valid
    }
    
    var editCourseDiscountValidation: ValidationResult {
        let trimmed = editCourseDiscount.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return .valid }
        guard let value = Int(trimmed), (0...100).contains(value) else {
            return .invalid("Discount must be between 0 and 100")
        }
        return .valid
    }
    
    var editChangeReasonValidation: ValidationResult {
        let trimmed = editChangeReason.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return .invalid("Please provide a reason for your changes") }
        guard trimmed.count >= 5 else { return .invalid("Change reason must be at least 5 characters") }
        return .valid
    }
    
    var canSubmitCourseEdit: Bool {
        editCourseTitleValidation.isValid &&
        editCourseDescriptionValidation.isValid &&
        editCoursePriceValidation.isValid &&
        editCourseDiscountValidation.isValid &&
        editChangeReasonValidation.isValid &&
        editingCourse != nil &&
        !isSubmittingCourseEdit
    }
    
    private func parseEditPrice() -> Double? {
        let normalized = editCoursePrice
            .replacingOccurrences(of: ",", with: ".")
            .replacingOccurrences(of: " ", with: "")
        return Double(normalized)
    }
    
    private func parseEditDiscount() -> Int? {
        let trimmed = editCourseDiscount.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty, let value = Int(trimmed), (0...100).contains(value) else { return nil }
        return value
    }
    
    private func handleCourseEditSuccess(message: String?) async {
        let trimmedMessage = message?.trimmingCharacters(in: .whitespacesAndNewlines)
        let fallbackMessage = "Edit request submitted successfully. Pending admin review."
        editCourseSuccessMessage = trimmedMessage?.isEmpty == false ? trimmedMessage : fallbackMessage
        editCourseError = nil
        didSubmitCourseEditSuccessfully = true
        await loadCourses()
    }

    // MARK: - Archive / Unarchive
    func isCourseArchiving(_ courseId: String) -> Bool {
        archivingCourseIds.contains(courseId)
    }
    
    func toggleArchive(for course: TeacherCourse) async {
        guard !archivingCourseIds.contains(course.id) else { return }
        archiveActionError = nil
        archiveActionSuccessMessage = nil
        archivingCourseIds.insert(course.id)
        defer { archivingCourseIds.remove(course.id) }
        let isArchived = course.approvalStatus?.lowercased() == "archived"
        do {
            if isArchived {
                let response = try await teacherCoursesService.unarchiveCourse(id: course.id)
                archiveActionSuccessMessage = response.message ?? "Course unarchived successfully"
            } else {
                let response = try await teacherCoursesService.archiveCourse(id: course.id)
                archiveActionSuccessMessage = response.message ?? "Course archived successfully"
            }
            await refreshCourses()
        } catch let networkError as NetworkError {
            archiveActionError = networkError.errorDescription ?? (isArchived ? "Failed to unarchive course" : "Failed to archive course")
        } catch {
            archiveActionError = error.localizedDescription
        }
    }
}
