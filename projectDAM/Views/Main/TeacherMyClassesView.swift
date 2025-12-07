//
//  TeacherMyClassesView.swift
//  projectDAM
//
//  Created on 11/10/2025.
//

import SwiftUI
import PhotosUI
import UIKit

struct TeacherMyClassesView: View {
    @StateObject private var viewModel: TeacherMyClassesViewModel
    @State private var showingError = false
    @State private var errorMessage = ""
    @State private var showComingSoonAlert = false
    @State private var selectedCourseForLessons: TeacherCourse?
    @State private var selectedClassForLessons: TeacherClass?
    
    // MARK: - Initialization
    init(viewModel: TeacherMyClassesViewModel) {
        _viewModel = StateObject(wrappedValue: viewModel)
    }
    
    var body: some View {
        NavigationView {
            ZStack {
                // Background
                Color(.systemBackground)
                    .ignoresSafeArea()
                
                contentView
            }
            .background(navigationLinkToLessons)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .principal) {
                    Text("My Classes")
                        .font(.system(size: 18, weight: .bold))
                        .foregroundColor(.brandPrimary)
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: {
                        Task {
                            await viewModel.refreshCourses()
                        }
                    }) {
                        Image(systemName: "arrow.clockwise")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(.brandPrimary)
                    }
                    .disabled(viewModel.isRefreshing)
                }
            }
        }
        .navigationViewStyle(.stack)
        .task {
            await viewModel.loadCourses()
            await viewModel.loadAvailableClasses()
        }
        .sheet(isPresented: $viewModel.showEditCourseSheet, onDismiss: {
            viewModel.closeEditCourseSheet()
        }) {
            EditCourseSheetView(
                viewModel: viewModel,
                onDismiss: {
                    viewModel.closeEditCourseSheet()
                }
            )
            .presentationDetents([.fraction(0.95)])
            .presentationDragIndicator(.visible)
            .interactiveDismissDisabled(viewModel.isSubmittingCourseEdit)
        }
        .alert("Error", isPresented: $showingError) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(errorMessage)
        }
    }
    
    // MARK: - Content View
    @ViewBuilder
    private var contentView: some View {
        switch viewModel.viewState {
        case .loading:
            loadingView
        case .loaded(let classes):
            if classes.isEmpty {
                emptyView
            } else {
                loadedView
            }
        case .error(let error):
            errorView(error)
        case .empty:
            emptyView
        }
    }
    
    // MARK: - Loading View
    private var loadingView: some View {
        VStack(spacing: 16) {
            ProgressView()
                .scaleEffect(1.2)
            Text("Loading your classes...")
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(.secondary)
        }
    }
    
    // MARK: - Empty View
    private var emptyView: some View {
        VStack(spacing: 20) {
            Image(systemName: "books.vertical")
                .font(.system(size: 60, weight: .light))
                .foregroundColor(.secondary)
            
            Text("No Classes Yet")
                .font(.system(size: 20, weight: .bold))
                .foregroundColor(.primary)
            
            Text("Start creating courses to see them here")
                .font(.system(size: 14, weight: .regular))
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
            
            Button(action: {
                viewModel.startCreateCourseFlow()
            }) {
                HStack(spacing: 8) {
                    Image(systemName: "plus.circle.fill")
                    Text("Create Your First Course")
                }
                .font(.system(size: 16, weight: .semibold))
                .foregroundColor(.white)
                .padding(.horizontal, 24)
                .padding(.vertical, 12)
                .background(Color.brandPrimary)
                .cornerRadius(12)
            }
        }
        .padding(DS.paddingLG)
    }
    
    // MARK: - Error View
    private func errorView(_ error: String) -> some View {
        VStack(spacing: 20) {
            Image(systemName: "exclamationmark.triangle")
                .font(.system(size: 60, weight: .light))
                .foregroundColor(.brandError)
            
            Text("Something went wrong")
                .font(.system(size: 20, weight: .bold))
                .foregroundColor(.primary)
            
            Text(error)
                .font(.system(size: 14, weight: .regular))
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
            
            Button(action: {
                Task {
                    await viewModel.loadCourses()
                }
            }) {
                HStack(spacing: 8) {
                    Image(systemName: "arrow.clockwise")
                    Text("Try Again")
                }
                .font(.system(size: 16, weight: .semibold))
                .foregroundColor(.white)
                .padding(.horizontal, 24)
                .padding(.vertical, 12)
                .background(Color.brandPrimary)
                .cornerRadius(12)
            }
        }
        .padding(DS.paddingLG)
    }
    
    // MARK: - Loaded View
    private var loadedView: some View {
        VStack(spacing: 0) {
            // Search & Filter Bar
            searchAndFilterBar()
            
            // Stats Summary
            statsSummary()
            
            // Create New Course Button
            createCourseButton()
            
            // Classes List
            classesListView()
        }
    }
    
    // MARK: - Search & Filter Bar
    private func searchAndFilterBar() -> some View {
        VStack(spacing: 12) {
            HStack(spacing: 12) {
                Image(systemName: "magnifyingglass")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(.secondary)
                
                TextField("Search classes...", text: $viewModel.searchText)
                    .font(.system(size: 14, weight: .medium))
                    .textInputAutocapitalization(.never)
                
                if !viewModel.searchText.isEmpty {
                    Button(action: { viewModel.clearSearch() }) {
                        Image(systemName: "xmark.circle.fill")
                            .font(.system(size: 14))
                            .foregroundColor(.secondary)
                    }
                }
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 10)
            .background(
                RoundedRectangle(cornerRadius: DS.cornerRadiusMD)
                    .fill(Color(.systemBackground).opacity(0.5))
                    .stroke(Color.brandPrimary.opacity(0.1), lineWidth: 1)
            )
            
            // Sort Options
            HStack(spacing: 8) {
                ForEach(TeacherMyClassesViewModel.SortOption.allCases, id: \.self) { option in
                    Button(action: { viewModel.selectedSortOption = option }) {
                        Text(option.rawValue)
                            .font(.system(size: 12, weight: .semibold))
                            .foregroundColor(viewModel.selectedSortOption == option ? .white : .secondary)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 6)
                            .background(
                                viewModel.selectedSortOption == option ?
                                    Color.brandPrimary :
                                    Color.secondary.opacity(0.1)
                            )
                            .cornerRadius(6)
                    }
                }
                
                Spacer()
            }
        }
        .padding(DS.paddingMD)
    }
    
    // MARK: - Stats Summary
    private func statsSummary() -> some View {
        HStack(spacing: 16) {
            TeacherStatCard(
                title: "Total Courses",
                value: "\(viewModel.totalCourses)",
                icon: "book.fill",
                color: .brandPrimary
            )
            
            TeacherStatCard(
                title: "Students",
                value: "\(viewModel.totalStudents)",
                icon: "person.2.fill",
                color: .brandSuccess
            )
            
            TeacherStatCard(
                title: "Approved",
                value: "\(viewModel.approvedCoursesCount)",
                icon: "checkmark.circle.fill",
                color: .brandSuccess
            )
            
            if viewModel.pendingCoursesCount > 0 {
                TeacherStatCard(
                    title: "Pending",
                    value: "\(viewModel.pendingCoursesCount)",
                    icon: "clock.fill",
                    color: .brandWarning
                )
            }
        }
        .padding(.horizontal, DS.paddingMD)
        .padding(.bottom, DS.paddingMD)
    }
    
    // MARK: - Create New Course Button
    private func createCourseButton() -> some View {
        VStack {
            Button(action: {
                showComingSoonAlert = true
            }) {
                HStack(spacing: 12) {
                    Image(systemName: "plus.circle.fill")
                        .font(.system(size: 18, weight: .semibold))
                    
                    Text("Create New Class")
                        .font(.system(size: 16, weight: .semibold))
                    
                    Spacer()
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 14)
                .foregroundColor(.white)
                .background(
                    LinearGradient(
                        colors: [Color.brandPrimary, Color.brandPrimaryHover],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .cornerRadius(DS.cornerRadiusMD)
            }
            .padding(.horizontal, DS.paddingMD)
            .padding(.vertical, 12)
        }
        .sheet(isPresented: $viewModel.showCreateCourseSheet, onDismiss: {
            viewModel.closeCreateCourseSheet()
        }) {
            CreateCourseSheetView(
                viewModel: viewModel,
                onDismiss: {
                    viewModel.closeCreateCourseSheet()
                }
            )
            .presentationDetents([.fraction(0.95)])
            .presentationDragIndicator(.visible)
            .interactiveDismissDisabled(viewModel.isCreatingCourse)
        }
        .alert("Coming soon", isPresented: $showComingSoonAlert) {
            Button("OK", role: .cancel) { }
        } message: {
            Text("Class creation is almost ready. For now, add courses from an existing class.")
        }
    }
    
    // MARK: - Classes List View
    private func classesListView() -> some View {
        ScrollView(.vertical, showsIndicators: false) {
            LazyVStack(spacing: 16) {
                ForEach(viewModel.filteredAndSortedClasses) { classWithCourses in
                    ClassCard(
                        classWithCourses: classWithCourses,
                        isExpanded: viewModel.isClassExpanded(classWithCourses.id),
                        onToggleExpansion: {
                            withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                                viewModel.toggleClassExpansion(classWithCourses.id)
                            }
                        },
                        onCreateCourse: {
                            if let availableClass = viewModel.availableClasses.first(where: { $0.id == classWithCourses.id }) {
                                viewModel.showCreateCourse(for: availableClass)
                            } else {
                                let classItem = classWithCourses.classItem
                                let fallbackClass = AvailableClass(
                                    id: classItem.id,
                                    title: classItem.title,
                                    image: classItem.image,
                                    classOrder: classItem.classOrder,
                                    filterName: classItem.filterName
                                )
                                viewModel.showCreateCourse(for: fallbackClass)
                            }
                        },
                        onOpenLessons: { course in
                            openLessons(for: course, classItem: classWithCourses.classItem)
                        },
                        onEditCourse: { course in
                            viewModel.startEditCourseFlow(for: course)
                        }
                    )
                }
                
                Spacer(minLength: 20)
            }
            .padding(.horizontal, DS.paddingMD)
            .padding(.vertical, DS.paddingMD)
        }
        .refreshable {
            await viewModel.refreshCourses()
        }
    }
}

// MARK: - Navigation Helpers
private extension TeacherMyClassesView {
    var navigationLinkToLessons: some View {
        NavigationLink(
            destination: Group {
                if let course = selectedCourseForLessons,
                   let classItem = selectedClassForLessons {
                    TeacherCourseLessonsView(
                        course: course,
                        classItem: classItem
                    )
                } else {
                    EmptyView()
                }
            },
            isActive: Binding(
                get: { selectedCourseForLessons != nil && selectedClassForLessons != nil },
                set: { isActive in
                    if !isActive {
                        selectedCourseForLessons = nil
                        selectedClassForLessons = nil
                    }
                }
            )
        ) {
            EmptyView()
        }
        .hidden()
    }
    
    func openLessons(for course: TeacherCourse, classItem: TeacherClass) {
        selectedCourseForLessons = course
        selectedClassForLessons = classItem
    }
}

// MARK: - Teacher Stat Card Component
private struct TeacherStatCard: View {
    let title: String
    let value: String
    let icon: String
    let color: Color
    
    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: icon)
                .font(.system(size: 16, weight: .semibold))
                .foregroundColor(color)
            
            Text(value)
                .font(.system(size: 18, weight: .bold))
                .foregroundColor(.primary)
            
            Text(title)
                .font(.system(size: 10, weight: .medium))
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 12)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(color.opacity(0.1))
        )
    }
}

// MARK: - Class Card Component
private struct ClassCard: View {
    let classWithCourses: ClassWithCourses
    let isExpanded: Bool
    let onToggleExpansion: () -> Void
    let onCreateCourse: () -> Void
    let onOpenLessons: (TeacherCourse) -> Void
    let onEditCourse: (TeacherCourse) -> Void
    
    var body: some View {
        VStack(spacing: 0) {
            // Class Header
            Button(action: onToggleExpansion) {
                HStack(spacing: 12) {
                    // Class Image
                    RemoteThumbnailImageView(
                        url: classWithCourses.classItem.imageURL,
                        width: 56,
                        height: 56,
                        cornerRadius: 12,
                        baseColor: .brandPrimary
                    ) {
                        ZStack {
                            LinearGradient(
                                colors: [Color.brandPrimary.opacity(0.3), Color.brandSecondary.opacity(0.2)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                            Text(classWithCourses.classItem.title.prefix(1))
                                .font(.system(size: 24, weight: .bold))
                                .foregroundColor(.brandPrimary)
                        }
                    }
                    
                    VStack(alignment: .leading, spacing: 4) {
                        Text(classWithCourses.classItem.title)
                            .font(.system(size: 16, weight: .bold))
                            .foregroundColor(.primary)
                        
                        Text("\(classWithCourses.courses.count) courses · \(classWithCourses.courses.reduce(0) { $0 + $1.studentCount }) students")
                            .font(.system(size: 12, weight: .medium))
                            .foregroundColor(.secondary)
                    }
                    
                    Spacer()
                    
                    Image(systemName: isExpanded ? "chevron.up" : "chevron.down")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(.secondary)
                }
                .padding(DS.paddingMD)
                .background(
                    RoundedRectangle(cornerRadius: DS.cornerRadiusMD)
                        .fill(Color(.systemBackground))
                        .stroke(Color.brandPrimary.opacity(0.1), lineWidth: 1)
                )
            }
            .buttonStyle(PlainButtonStyle())
            
            // Expanded Content
            if isExpanded {
                VStack(spacing: 12) {
                    // Create Course Button
                    Button(action: onCreateCourse) {
                        HStack(spacing: 8) {
                            Image(systemName: "plus.circle.fill")
                                .font(.system(size: 14, weight: .semibold))
                            Text("Create course for this class")
                                .font(.system(size: 14, weight: .semibold))
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                        .foregroundColor(.white)
                        .background(Color.brandPrimary)
                        .cornerRadius(10)
                    }
                    .padding(.top, 8)
                    
                    // Courses
                    ForEach(classWithCourses.courses) { course in
                        TeacherCourseCard(
                            course: course,
                            onOpenLessons: {
                                onOpenLessons(course)
                            },
                            onEdit: {
                                onEditCourse(course)
                            }
                        )
                    }
                }
                .padding(.horizontal, DS.paddingMD)
                .padding(.bottom, DS.paddingMD)
            }
        }
    }
}

// MARK: - Teacher Course Card Component
private struct TeacherCourseCard: View {
    let course: TeacherCourse
    let onOpenLessons: () -> Void
    let onEdit: () -> Void
    @State private var showMenu = false
    
    var body: some View {
        VStack(spacing: 16) {
            // Header
            HStack(spacing: 12) {
                // Course Image
                RemoteThumbnailImageView(
                    url: course.imageURL,
                    width: 60,
                    height: 60,
                    cornerRadius: DS.cornerRadiusMD,
                    baseColor: .brandPrimary
                ) {
                    placeholderImage
                }

                VStack(alignment: .leading, spacing: 6) {
                    HStack(spacing: 8) {
                        Text(course.name)
                            .font(.system(size: 15, weight: .bold))
                            .foregroundColor(.primary)
                            .lineLimit(2)
                        
                        Spacer()
                        
                        // Status Badge
                        statusBadge
                    }
                    
                    HStack(spacing: 12) {
                        HStack(spacing: 4) {
                            Image(systemName: "person.2.fill")
                                .font(.system(size: 11, weight: .semibold))
                            Text("\(course.studentCount)")
                                .font(.system(size: 11, weight: .medium))
                        }
                        .foregroundColor(.secondary)
                        
                        HStack(spacing: 4) {
                            Image(systemName: "play.circle.fill")
                                .font(.system(size: 11, weight: .semibold))
                            Text("\(course.nbVideos ?? 0) videos")
                                .font(.system(size: 11, weight: .medium))
                        }
                        .foregroundColor(.secondary)
                    }
                }
            }
            
            // Action Buttons
            HStack(spacing: 10) {
                Button(action: onEdit) {
                    HStack(spacing: 6) {
                        Image(systemName: "pencil.circle.fill")
                            .font(.system(size: 14, weight: .semibold))
                        Text("Edit")
                            .font(.system(size: 12, weight: .semibold))
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 10)
                    .foregroundColor(.white)
                    .background(Color.brandPrimary)
                    .cornerRadius(8)
                }
                
                Button(action: {}) {
                    HStack(spacing: 6) {
                        Image(systemName: "chart.bar.fill")
                            .font(.system(size: 14, weight: .semibold))
                        Text("Analytics")
                            .font(.system(size: 12, weight: .semibold))
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 10)
                    .foregroundColor(.brandPrimary)
                    .background(
                        RoundedRectangle(cornerRadius: 8)
                            .stroke(Color.brandPrimary, lineWidth: 1.5)
                    )
                }
            }
        }
        .padding(DS.paddingMD)
        .background(
            RoundedRectangle(cornerRadius: DS.cornerRadiusMD)
                .fill(Color(.systemBackground))
                .stroke(Color.brandPrimary.opacity(0.15), lineWidth: 1)
        )
        .contentShape(Rectangle())
        .onTapGesture(perform: onOpenLessons)
    }
    
    private var placeholderImage: some View {
        ZStack {
            LinearGradient(
                colors: [
                    Color.brandPrimary.opacity(0.3),
                    Color.brandSecondary.opacity(0.2)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            
            Image(systemName: "book.fill")
                .font(.system(size: 24, weight: .semibold))
                .foregroundColor(.brandPrimary)
        }
    }
    
    private var statusBadge: some View {
        Text((course.approvalStatus ?? "unknown").capitalized)
            .font(.system(size: 10, weight: .bold))
            .foregroundColor(.white)
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(statusColor)
            .cornerRadius(6)
    }
    
    private var statusColor: Color {
        guard let status = course.approvalStatus else { return .secondary }
        switch status.lowercased() {
        case "approved":
            return .brandSuccess
        case "pending":
            return .brandWarning
        case "declined":
            return .brandError
        default:
            return .secondary
        }
    }
}

// MARK: - Create Course Sheet View
@MainActor
private struct CreateCourseSheetView: View {
    @ObservedObject var viewModel: TeacherMyClassesViewModel
    let onDismiss: () -> Void
    @State private var photoPickerItem: PhotosPickerItem?
    @State private var attemptedSubmission = false
    @FocusState private var focusedField: Field?
    
    private enum Field: Hashable {
        case title
        case description
        case price
        case discount
    }
    
    var body: some View {
        NavigationView {
            ZStack {
                Color(.systemGroupedBackground)
                    .ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 20) {
                        heroHeader
                        statusInfoCard
                        if let error = viewModel.createCourseError {
                            errorBanner(error)
                        }
                        if viewModel.didCreateCourseSuccessfully {
                            successState
                        } else {
                            classPicker
                            titleField
                            descriptionField
                            priceStack
                            levelSelector
                            imagePicker
                            policyInfo
                            primaryActionButton
                        }
                    }
                    .padding(.horizontal, 20)
                    .padding(.vertical, 24)
                }
                
                if viewModel.isCreatingCourse {
                    Color.black.opacity(0.2)
                        .ignoresSafeArea()
                    ProgressView("Creating course…")
                        .padding(24)
                        .background(
                            RoundedRectangle(cornerRadius: 16)
                                .fill(Color(.systemBackground))
                        )
                        .shadow(radius: 12)
                }
            }
            .navigationTitle(viewModel.selectedClassForCourse?.title ?? "Create Course")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Close") {
                        onDismiss()
                    }
                    .disabled(viewModel.isCreatingCourse)
                }
            }
        }
        .task(id: photoPickerItem) {
            await handlePhotoChange(photoPickerItem)
        }
        .onAppear {
            attemptedSubmission = false
        }
    }
    
    private var heroHeader: some View {
        VStack(spacing: 8) {
            HStack(spacing: 12) {
                Image(systemName: "plus.app.fill")
                    .font(.system(size: 30, weight: .semibold))
                    .foregroundColor(.brandPrimary)
                VStack(alignment: .leading, spacing: 4) {
                    Text(headerTitle)
                        .font(.system(size: 20, weight: .bold))
                    Text("Complete the form below to submit a new course for review")
                        .font(.system(size: 13, weight: .medium))
                        .foregroundColor(.secondary)
                }
                Spacer()
            }
            .padding()
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(Color(.systemBackground))
                    .shadow(color: Color.black.opacity(0.05), radius: 12, x: 0, y: 6)
            )
        }
    }
    
    private var headerTitle: String {
        if let selectedClass = viewModel.selectedClassForCourse {
            return "Create course for \(selectedClass.title)"
        }
        return "Create a new course"
    }
    
    private var statusInfoCard: some View {
        HStack(spacing: 12) {
            Image(systemName: "clock.badge.checkmark")
                .font(.system(size: 20, weight: .semibold))
                .foregroundColor(.brandWarning)
            VStack(alignment: .leading, spacing: 4) {
                Text("Pending approval")
                    .font(.system(size: 14, weight: .semibold))
                Text("New courses stay inactive until an admin approves them. We'll notify you once reviewed.")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(.secondary)
            }
            Spacer()
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 14)
                .fill(Color.brandWarning.opacity(0.12))
        )
    }
    
    private func errorBanner(_ message: String) -> some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: "exclamationmark.triangle.fill")
                .foregroundColor(.brandError)
            Text(message)
                .font(.system(size: 13, weight: .semibold))
                .foregroundColor(.brandError)
                .fixedSize(horizontal: false, vertical: true)
            Spacer()
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 14)
                .fill(Color.brandError.opacity(0.1))
        )
    }
    
    private var classPicker: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Class")
                .font(.system(size: 14, weight: .semibold))
            if viewModel.availableClasses.isEmpty {
                HStack(spacing: 8) {
                    ProgressView()
                    Text("Loading available classes…")
                        .font(.system(size: 13, weight: .medium))
                        .foregroundColor(.secondary)
                }
                .padding()
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(classFieldBackground)
                .overlay(classFieldBorder(showError: shouldShowClassError))
                .cornerRadius(14)
            } else {
                Menu {
                    ForEach(viewModel.availableClasses) { classItem in
                        Button(action: {
                            viewModel.selectClass(by: classItem.id)
                        }) {
                            HStack {
                                Text(classItem.title)
                                if classItem.id == viewModel.selectedClassForCourse?.id {
                                    Spacer()
                                    Image(systemName: "checkmark")
                                }
                            }
                        }
                    }
                } label: {
                    HStack {
                        VStack(alignment: .leading, spacing: 4) {
                            Text(viewModel.selectedClassForCourse?.title ?? "Select class")
                                .foregroundColor(viewModel.selectedClassForCourse == nil ? .secondary : .primary)
                            if let subtitle = viewModel.selectedClassForCourse?.filterName?.filterName {
                                Text(subtitle)
                                    .font(.system(size: 11, weight: .medium))
                                    .foregroundColor(.secondary)
                            }
                        }
                        Spacer()
                        Image(systemName: "chevron.down")
                            .foregroundColor(.secondary)
                    }
                    .padding()
                    .frame(maxWidth: .infinity)
                    .background(classFieldBackground)
                    .overlay(classFieldBorder(showError: shouldShowClassError))
                    .cornerRadius(14)
                }
            }
            if shouldShowClassError, let message = viewModel.classSelectionValidation.errorMessage {
                validationText(message)
            }
        }
    }
    
    private var titleField: some View {
        validatedTextField(
            title: "Course title",
            text: $viewModel.courseTitle,
            placeholder: "e.g. SwiftUI Crash Course",
            validation: viewModel.courseTitleValidation,
            field: .title,
            keyboard: .default,
            autocapitalization: .words
        )
    }
    
    private var descriptionField: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Description")
                .font(.system(size: 14, weight: .semibold))
            TextEditor(text: $viewModel.courseDescription)
                .focused($focusedField, equals: .description)
                .frame(minHeight: 120)
                .padding(12)
                .background(fieldBackground(showError: showError(for: viewModel.courseDescriptionValidation, text: viewModel.courseDescription)))
                .overlay(fieldBorder(showError: showError(for: viewModel.courseDescriptionValidation, text: viewModel.courseDescription)))
                .cornerRadius(14)
            if showError(for: viewModel.courseDescriptionValidation, text: viewModel.courseDescription),
               let message = viewModel.courseDescriptionValidation.errorMessage {
                validationText(message)
            }
        }
    }
    
    private var priceStack: some View {
        HStack(spacing: 16) {
            validatedTextField(
                title: "Price (TND)",
                text: $viewModel.coursePrice,
                placeholder: "49.99",
                validation: viewModel.coursePriceValidation,
                field: .price,
                keyboard: .decimalPad,
                autocapitalization: .never
            )
            validatedTextField(
                title: "Discount %",
                text: $viewModel.courseDiscount,
                placeholder: "Optional",
                validation: viewModel.courseDiscountValidation,
                field: .discount,
                keyboard: .numberPad,
                autocapitalization: .never
            )
        }
    }
    
    private var levelSelector: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Level")
                .font(.system(size: 14, weight: .semibold))
            HStack(spacing: 10) {
                ForEach(CourseLevelOption.allCases) { level in
                    Button(action: {
                        viewModel.selectedCourseLevel = level
                    }) {
                        VStack(spacing: 4) {
                            Text(level.displayName)
                                .font(.system(size: 13, weight: .semibold))
                            Text(level.helperText)
                                .font(.system(size: 10, weight: .medium))
                        }
                        .foregroundColor(viewModel.selectedCourseLevel == level ? .white : .primary)
                        .padding(.vertical, 10)
                        .frame(maxWidth: .infinity)
                        .background(
                            RoundedRectangle(cornerRadius: 12)
                                .fill(viewModel.selectedCourseLevel == level ? Color.brandPrimary : Color(.secondarySystemBackground))
                        )
                    }
                }
            }
        }
    }
    
    private var imagePicker: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Course image (optional)")
                .font(.system(size: 14, weight: .semibold))
            PhotosPicker(selection: $photoPickerItem, matching: .images) {
                HStack(spacing: 12) {
                    Image(systemName: "photo.on.rectangle")
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundColor(.brandPrimary)
                    VStack(alignment: .leading, spacing: 2) {
                        Text(viewModel.courseImageFileName ?? "Add course image")
                            .font(.system(size: 14, weight: .semibold))
                        Text("JPG, PNG, WebP · Max 5 MB")
                            .font(.system(size: 11, weight: .medium))
                            .foregroundColor(.secondary)
                    }
                    Spacer()
                    Image(systemName: "chevron.up.chevron.down")
                        .font(.system(size: 12, weight: .bold))
                        .foregroundColor(.secondary)
                }
                .padding()
                .frame(maxWidth: .infinity)
                .background(fieldBackground(showError: false))
                .overlay(fieldBorder(showError: false))
                .cornerRadius(14)
            }
            
            if let data = viewModel.courseImageData,
               let uiImage = UIImage(data: data) {
                ZStack(alignment: .topTrailing) {
                    Image(uiImage: uiImage)
                        .resizable()
                        .scaledToFill()
                        .frame(height: 160)
                        .frame(maxWidth: .infinity)
                        .clipped()
                        .cornerRadius(16)
                        .overlay(
                            RoundedRectangle(cornerRadius: 16)
                                .stroke(Color.brandPrimary.opacity(0.2), lineWidth: 1)
                        )
                    Button(action: {
                        viewModel.clearCourseImageAttachment()
                        photoPickerItem = nil
                    }) {
                        Image(systemName: "xmark.circle.fill")
                            .font(.system(size: 22))
                            .foregroundColor(.white)
                            .shadow(radius: 4)
                    }
                    .padding(10)
                }
            }
        }
    }
    
    private var policyInfo: some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: "info.circle.fill")
                .foregroundColor(.brandPrimary)
            Text("Only admins can approve or decline courses. You can monitor the status from the classes tab.")
                .font(.system(size: 12, weight: .medium))
                .foregroundColor(.secondary)
            Spacer()
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 14)
                .fill(Color.brandPrimary.opacity(0.08))
        )
    }
    
    private var primaryActionButton: some View {
        Button(action: {
            attemptedSubmission = true
            focusedField = nil
            Task {
                await viewModel.submitCourseCreation()
            }
        }) {
            HStack {
                if viewModel.isCreatingCourse {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle(tint: .white))
                } else {
                    Text("Create Course")
                        .font(.system(size: 16, weight: .semibold))
                }
            }
            .foregroundColor(.white)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
            .background(LinearGradient.brandPrimaryGradient.opacity(viewModel.canSubmitCourse ? 1 : 0.5))
            .cornerRadius(18)
        }
        .disabled(viewModel.isCreatingCourse)
    }
    
    private var successState: some View {
        VStack(spacing: 16) {
            Image(systemName: "checkmark.seal.fill")
                .font(.system(size: 48, weight: .bold))
                .foregroundColor(.brandSuccess)
            Text(viewModel.createCourseSuccessMessage ?? "Course created successfully")
                .font(.system(size: 18, weight: .bold))
                .multilineTextAlignment(.center)
            Text("We will notify you once the admin reviews your course.")
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
            Button(action: {
                attemptedSubmission = false
                viewModel.prepareAnotherCourse()
            }) {
                Text("Create another course")
                    .font(.system(size: 16, weight: .semibold))
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(RoundedRectangle(cornerRadius: 16).fill(Color.brandPrimary.opacity(0.1)))
            }
            Button(action: {
                onDismiss()
            }) {
                Text("Done")
                    .font(.system(size: 16, weight: .semibold))
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(RoundedRectangle(cornerRadius: 16).fill(LinearGradient.brandPrimaryGradient))
                    .foregroundColor(.white)
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(Color(.systemBackground))
                .shadow(color: Color.black.opacity(0.08), radius: 20, x: 0, y: 10)
        )
    }
    
    private func validatedTextField(
        title: String,
        text: Binding<String>,
        placeholder: String,
        validation: ValidationResult,
        field: Field,
        keyboard: UIKeyboardType,
        autocapitalization: TextInputAutocapitalization
    ) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.system(size: 14, weight: .semibold))
            TextField(placeholder, text: text)
                .keyboardType(keyboard)
                .textInputAutocapitalization(autocapitalization)
                .disableAutocorrection(true)
                .focused($focusedField, equals: field)
                .padding()
                .background(fieldBackground(showError: showError(for: validation, text: text.wrappedValue)))
                .overlay(fieldBorder(showError: showError(for: validation, text: text.wrappedValue)))
                .cornerRadius(14)
            if showError(for: validation, text: text.wrappedValue), let message = validation.errorMessage {
                validationText(message)
            }
        }
    }
    
    private func showError(for validation: ValidationResult, text: String) -> Bool {
        if !validation.isValid {
            return attemptedSubmission || !text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
        }
        return false
    }
    
    private var shouldShowClassError: Bool {
        attemptedSubmission && !viewModel.classSelectionValidation.isValid
    }
    
    private func validationText(_ message: String) -> some View {
        Text(message)
            .font(.system(size: 11, weight: .semibold))
            .foregroundColor(.brandError)
    }
    
    private func fieldBackground(showError: Bool) -> some View {
        RoundedRectangle(cornerRadius: 14)
            .fill(showError ? Color.brandError.opacity(0.05) : Color(.systemBackground))
    }
    
    private func fieldBorder(showError: Bool) -> some View {
        RoundedRectangle(cornerRadius: 14)
            .stroke(showError ? Color.brandError : Color.brandPrimary.opacity(0.15), lineWidth: showError ? 1.5 : 1)
    }
    
    private var classFieldBackground: some View {
        Color(.systemBackground)
    }
    
    private func classFieldBorder(showError: Bool) -> some View {
        RoundedRectangle(cornerRadius: 14)
            .stroke(showError ? Color.brandError : Color.brandPrimary.opacity(0.15), lineWidth: showError ? 1.5 : 1)
    }
    
    private func handlePhotoChange(_ item: PhotosPickerItem?) async {
        guard let item else { return }
        do {
            if let data = try await item.loadTransferable(type: Data.self) {
                let contentType = item.supportedContentTypes.first
                let mimeType = contentType?.preferredMIMEType ?? "image/jpeg"
                let fileExtension = contentType?.preferredFilenameExtension ?? "jpg"
                let fileName = "course-image.\(fileExtension)"
                viewModel.updateCourseImage(data: data, mimeType: mimeType, fileName: fileName)
            }
        } catch {
            viewModel.createCourseError = "Failed to load image from library"
        }
    }
}

@MainActor
private struct EditCourseSheetView: View {
    @ObservedObject var viewModel: TeacherMyClassesViewModel
    let onDismiss: () -> Void
    @State private var photoPickerItem: PhotosPickerItem?
    @State private var attemptedSubmission = false
    @FocusState private var focusedField: Field?
    
    private enum Field: Hashable {
        case title
        case description
        case price
        case discount
        case reason
    }
    
    var body: some View {
        NavigationView {
            ZStack {
                Color(.systemGroupedBackground)
                    .ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 20) {
                        editHeader
                        if let error = viewModel.editCourseError {
                            editErrorBanner(error)
                        }
                        if viewModel.didSubmitCourseEditSuccessfully {
                            editSuccessState
                        } else {
                            editTitleField
                            editDescriptionField
                            editPriceStack
                            editLevelSelector
                            editImagePicker
                            changeReasonField
                            editPrimaryActionButton
                        }
                    }
                    .padding(.horizontal, 20)
                    .padding(.vertical, 24)
                }
                
                if viewModel.isSubmittingCourseEdit {
                    Color.black.opacity(0.2)
                        .ignoresSafeArea()
                    ProgressView("Submitting changes…")
                        .padding(24)
                        .background(
                            RoundedRectangle(cornerRadius: 16)
                                .fill(Color(.systemBackground))
                        )
                        .shadow(radius: 12)
                }
            }
            .navigationTitle(viewModel.editingCourse?.name ?? "Edit Course")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Close") {
                        onDismiss()
                    }
                    .disabled(viewModel.isSubmittingCourseEdit)
                }
            }
        }
        .task(id: photoPickerItem) {
            await handlePhotoChange(photoPickerItem)
        }
        .onAppear {
            attemptedSubmission = false
        }
    }
    
    private var editHeader: some View {
        HStack(spacing: 12) {
            Image(systemName: "pencil.circle.fill")
                .font(.system(size: 30, weight: .semibold))
                .foregroundColor(.brandPrimary)
            VStack(alignment: .leading, spacing: 4) {
                Text("Edit course")
                    .font(.system(size: 20, weight: .bold))
                if let name = viewModel.editingCourse?.name {
                    Text(name)
                        .font(.system(size: 13, weight: .medium))
                        .foregroundColor(.secondary)
                        .lineLimit(2)
                }
            }
            Spacer()
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(.systemBackground))
                .shadow(color: Color.black.opacity(0.05), radius: 12, x: 0, y: 6)
        )
    }
    
    private func editErrorBanner(_ message: String) -> some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: "exclamationmark.triangle.fill")
                .foregroundColor(.brandError)
            Text(message)
                .font(.system(size: 13, weight: .semibold))
                .foregroundColor(.brandError)
                .fixedSize(horizontal: false, vertical: true)
            Spacer()
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 14)
                .fill(Color.brandError.opacity(0.1))
        )
    }
    
    private var editTitleField: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Course title")
                .font(.system(size: 14, weight: .semibold))
            TextField("e.g. SwiftUI Crash Course", text: $viewModel.editCourseTitle)
                .keyboardType(.default)
                .textInputAutocapitalization(.words)
                .disableAutocorrection(true)
                .focused($focusedField, equals: .title)
                .padding()
                .background(fieldBackground(showError: showError(for: viewModel.editCourseTitleValidation, text: viewModel.editCourseTitle)))
                .overlay(fieldBorder(showError: showError(for: viewModel.editCourseTitleValidation, text: viewModel.editCourseTitle)))
                .cornerRadius(14)
            if showError(for: viewModel.editCourseTitleValidation, text: viewModel.editCourseTitle),
               let message = viewModel.editCourseTitleValidation.errorMessage {
                validationText(message)
            }
        }
    }
    
    private var editDescriptionField: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Description")
                .font(.system(size: 14, weight: .semibold))
            TextEditor(text: $viewModel.editCourseDescription)
                .focused($focusedField, equals: .description)
                .frame(minHeight: 120)
                .padding(12)
                .background(fieldBackground(showError: showError(for: viewModel.editCourseDescriptionValidation, text: viewModel.editCourseDescription)))
                .overlay(fieldBorder(showError: showError(for: viewModel.editCourseDescriptionValidation, text: viewModel.editCourseDescription)))
                .cornerRadius(14)
            if showError(for: viewModel.editCourseDescriptionValidation, text: viewModel.editCourseDescription),
               let message = viewModel.editCourseDescriptionValidation.errorMessage {
                validationText(message)
            }
        }
    }
    
    private var editPriceStack: some View {
        HStack(spacing: 16) {
            VStack(alignment: .leading, spacing: 8) {
                Text("Price (TND)")
                    .font(.system(size: 14, weight: .semibold))
                TextField("49.99", text: $viewModel.editCoursePrice)
                    .keyboardType(.decimalPad)
                    .textInputAutocapitalization(.never)
                    .disableAutocorrection(true)
                    .focused($focusedField, equals: .price)
                    .padding()
                    .background(fieldBackground(showError: showError(for: viewModel.editCoursePriceValidation, text: viewModel.editCoursePrice)))
                    .overlay(fieldBorder(showError: showError(for: viewModel.editCoursePriceValidation, text: viewModel.editCoursePrice)))
                    .cornerRadius(14)
                if showError(for: viewModel.editCoursePriceValidation, text: viewModel.editCoursePrice),
                   let message = viewModel.editCoursePriceValidation.errorMessage {
                    validationText(message)
                }
            }
            VStack(alignment: .leading, spacing: 8) {
                Text("Discount %")
                    .font(.system(size: 14, weight: .semibold))
                TextField("Optional", text: $viewModel.editCourseDiscount)
                    .keyboardType(.numberPad)
                    .textInputAutocapitalization(.never)
                    .disableAutocorrection(true)
                    .focused($focusedField, equals: .discount)
                    .padding()
                    .background(fieldBackground(showError: showError(for: viewModel.editCourseDiscountValidation, text: viewModel.editCourseDiscount)))
                    .overlay(fieldBorder(showError: showError(for: viewModel.editCourseDiscountValidation, text: viewModel.editCourseDiscount)))
                    .cornerRadius(14)
                if showError(for: viewModel.editCourseDiscountValidation, text: viewModel.editCourseDiscount),
                   let message = viewModel.editCourseDiscountValidation.errorMessage {
                    validationText(message)
                }
            }
        }
    }
    
    private var editLevelSelector: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Level")
                .font(.system(size: 14, weight: .semibold))
            HStack(spacing: 10) {
                ForEach(CourseLevelOption.allCases) { level in
                    Button(action: {
                        viewModel.selectedEditCourseLevel = level
                    }) {
                        VStack(spacing: 4) {
                            Text(level.displayName)
                                .font(.system(size: 13, weight: .semibold))
                            Text(level.helperText)
                                .font(.system(size: 10, weight: .medium))
                        }
                        .foregroundColor(viewModel.selectedEditCourseLevel == level ? .white : .primary)
                        .padding(.vertical, 10)
                        .frame(maxWidth: .infinity)
                        .background(
                            RoundedRectangle(cornerRadius: 12)
                                .fill(viewModel.selectedEditCourseLevel == level ? Color.brandPrimary : Color(.secondarySystemBackground))
                        )
                    }
                }
            }
        }
    }
    
    private var editImagePicker: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Course image (optional)")
                .font(.system(size: 14, weight: .semibold))
            PhotosPicker(selection: $photoPickerItem, matching: .images) {
                HStack(spacing: 12) {
                    Image(systemName: "photo.on.rectangle")
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundColor(.brandPrimary)
                    VStack(alignment: .leading, spacing: 2) {
                        Text(viewModel.editCourseImageFileName ?? "Change course image")
                            .font(.system(size: 14, weight: .semibold))
                        Text("JPG, PNG, WebP · Max 5 MB")
                            .font(.system(size: 11, weight: .medium))
                            .foregroundColor(.secondary)
                    }
                    Spacer()
                    Image(systemName: "chevron.up.chevron.down")
                        .font(.system(size: 12, weight: .bold))
                        .foregroundColor(.secondary)
                }
                .padding()
                .frame(maxWidth: .infinity)
                .background(fieldBackground(showError: false))
                .overlay(fieldBorder(showError: false))
                .cornerRadius(14)
            }
            
            if let data = viewModel.editCourseImageData,
               let uiImage = UIImage(data: data) {
                ZStack(alignment: .topTrailing) {
                    Image(uiImage: uiImage)
                        .resizable()
                        .scaledToFill()
                        .frame(height: 160)
                        .frame(maxWidth: .infinity)
                        .clipped()
                        .cornerRadius(16)
                        .overlay(
                            RoundedRectangle(cornerRadius: 16)
                                .stroke(Color.brandPrimary.opacity(0.2), lineWidth: 1)
                        )
                    Button(action: {
                        viewModel.clearEditCourseImageAttachment()
                        photoPickerItem = nil
                    }) {
                        Image(systemName: "xmark.circle.fill")
                            .font(.system(size: 22))
                            .foregroundColor(.white)
                            .shadow(radius: 4)
                    }
                    .padding(10)
                }
            }
        }
    }
    
    private var changeReasonField: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Why are you editing this course?")
                .font(.system(size: 14, weight: .semibold))
            TextEditor(text: $viewModel.editChangeReason)
                .focused($focusedField, equals: .reason)
                .frame(minHeight: 80)
                .padding(12)
                .background(fieldBackground(showError: showError(for: viewModel.editChangeReasonValidation, text: viewModel.editChangeReason)))
                .overlay(fieldBorder(showError: showError(for: viewModel.editChangeReasonValidation, text: viewModel.editChangeReason)))
                .cornerRadius(14)
            if showError(for: viewModel.editChangeReasonValidation, text: viewModel.editChangeReason),
               let message = viewModel.editChangeReasonValidation.errorMessage {
                validationText(message)
            }
        }
    }
    
    private var editPrimaryActionButton: some View {
        Button(action: {
            attemptedSubmission = true
            focusedField = nil
            Task {
                await viewModel.submitCourseEdit()
            }
        }) {
            HStack {
                if viewModel.isSubmittingCourseEdit {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle(tint: .white))
                } else {
                    Text("Submit for review")
                        .font(.system(size: 16, weight: .semibold))
                }
            }
            .foregroundColor(.white)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
            .background(LinearGradient.brandPrimaryGradient.opacity(viewModel.canSubmitCourseEdit ? 1 : 0.5))
            .cornerRadius(18)
        }
        .disabled(viewModel.isSubmittingCourseEdit)
    }
    
    private var editSuccessState: some View {
        VStack(spacing: 16) {
            Image(systemName: "checkmark.seal.fill")
                .font(.system(size: 48, weight: .bold))
                .foregroundColor(.brandSuccess)
            Text(viewModel.editCourseSuccessMessage ?? "Edit request submitted successfully")
                .font(.system(size: 18, weight: .bold))
                .multilineTextAlignment(.center)
            Text("Your changes will go live once an admin approves them.")
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
            Button(action: {
                onDismiss()
            }) {
                Text("Done")
                    .font(.system(size: 16, weight: .semibold))
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(RoundedRectangle(cornerRadius: 16).fill(LinearGradient.brandPrimaryGradient))
                    .foregroundColor(.white)
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(Color(.systemBackground))
                .shadow(color: Color.black.opacity(0.08), radius: 20, x: 0, y: 10)
        )
    }
    
    private func showError(for validation: ValidationResult, text: String) -> Bool {
        if !validation.isValid {
            return attemptedSubmission || !text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
        }
        return false
    }
    
    private func validationText(_ message: String) -> some View {
        Text(message)
            .font(.system(size: 11, weight: .semibold))
            .foregroundColor(.brandError)
    }
    
    private func fieldBackground(showError: Bool) -> some View {
        RoundedRectangle(cornerRadius: 14)
            .fill(showError ? Color.brandError.opacity(0.05) : Color(.systemBackground))
    }
    
    private func fieldBorder(showError: Bool) -> some View {
        RoundedRectangle(cornerRadius: 14)
            .stroke(showError ? Color.brandError : Color.brandPrimary.opacity(0.15), lineWidth: showError ? 1.5 : 1)
    }
    
    private func handlePhotoChange(_ item: PhotosPickerItem?) async {
        guard let item else { return }
        do {
            if let data = try await item.loadTransferable(type: Data.self) {
                let contentType = item.supportedContentTypes.first
                let mimeType = contentType?.preferredMIMEType ?? "image/jpeg"
                let fileExtension = contentType?.preferredFilenameExtension ?? "jpg"
                let fileName = "course-image.\(fileExtension)"
                viewModel.updateEditCourseImage(data: data, mimeType: mimeType, fileName: fileName)
            }
        } catch {
            viewModel.editCourseError = "Failed to load image from library"
        }
    }
}

#Preview {
    let networkService = NetworkService()
    let authService = AuthService(networkService: networkService)
    let teacherCoursesService = MockTeacherCoursesService()
    let viewModel = TeacherMyClassesViewModel(teacherCoursesService: teacherCoursesService)
    
    return TeacherMyClassesView(viewModel: viewModel)
}
