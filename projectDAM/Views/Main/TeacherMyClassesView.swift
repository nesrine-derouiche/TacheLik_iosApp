//
//  TeacherMyClassesView.swift
//  projectDAM
//
//  Created on 11/10/2025.
//

import SwiftUI

struct TeacherMyClassesView: View {
    @StateObject private var viewModel: TeacherMyClassesViewModel
    @State private var showingError = false
    @State private var errorMessage = ""
    
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
                viewModel.showCreateCourseSheet = true
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
                viewModel.showCreateCourseSheet = true
            }) {
                HStack(spacing: 12) {
                    Image(systemName: "plus.circle.fill")
                        .font(.system(size: 18, weight: .semibold))
                    
                    Text("Create New Course")
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
        .sheet(isPresented: $viewModel.showCreateCourseSheet) {
            CreateCourseSheetView(
                availableClasses: viewModel.availableClasses,
                selectedClass: viewModel.selectedClassForCourse,
                onDismiss: {
                    viewModel.showCreateCourseSheet = false
                    viewModel.selectedClassForCourse = nil
                }
            )
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
                            }
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
    
    var body: some View {
        VStack(spacing: 0) {
            // Class Header
            Button(action: onToggleExpansion) {
                HStack(spacing: 12) {
                    // Class Image
                    if let imageURL = classWithCourses.classItem.imageURL {
                        AsyncImage(url: imageURL) { image in
                            image
                                .resizable()
                                .aspectRatio(contentMode: .fill)
                        } placeholder: {
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
                        .frame(width: 56, height: 56)
                        .cornerRadius(12)
                    } else {
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
                        .frame(width: 56, height: 56)
                        .cornerRadius(12)
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
                        TeacherCourseCard(course: course)
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
    @State private var showMenu = false
    
    var body: some View {
        VStack(spacing: 16) {
            // Header
            HStack(spacing: 12) {
                // Course Image
                if let imageURL = course.imageURL {
                    AsyncImage(url: imageURL) { image in
                        image
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                    } placeholder: {
                        placeholderImage
                    }
                    .frame(width: 60, height: 60)
                    .cornerRadius(DS.cornerRadiusMD)
                } else {
                    placeholderImage
                        .frame(width: 60, height: 60)
                        .cornerRadius(DS.cornerRadiusMD)
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
                Button(action: {}) {
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
private struct CreateCourseSheetView: View {
    let availableClasses: [AvailableClass]
    let selectedClass: AvailableClass?
    let onDismiss: () -> Void
    
    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                Image(systemName: "plus.app.fill")
                    .font(.system(size: 60, weight: .light))
                    .foregroundColor(.brandPrimary)
                
                Text("Create New Course")
                    .font(.system(size: 24, weight: .bold))
                
                Text("Course creation coming soon")
                    .font(.system(size: 14, weight: .regular))
                    .foregroundColor(.secondary)
                
                if let selectedClass = selectedClass {
                    Text("For class: \(selectedClass.title)")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(.brandPrimary)
                }
            }
            .padding()
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Close") {
                        onDismiss()
                    }
                }
            }
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
