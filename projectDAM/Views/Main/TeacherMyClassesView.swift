//
//  TeacherMyClassesView.swift
//  projectDAM
//
//  Created on 11/10/2025.
//

import SwiftUI

struct TeacherMyClassesView: View {
    @State private var searchText = ""
    @State private var selectedSortOption = 0
    
    enum SortOption: Int, CaseIterable {
        case newest, enrollment, rating
        
        var label: String {
            switch self {
            case .newest: return "Newest"
            case .enrollment: return "Enrollment"
            case .rating: return "Rating"
            }
        }
    }
    
    var body: some View {
        NavigationView {
            ZStack {
                // Background
                Color(.systemBackground)
                    .ignoresSafeArea()
                
                VStack(spacing: 0) {
                    // Search & Filter Bar
                    searchAndFilterBar()
                    
                    // Create New Course Button
                    createCourseButton()
                    
                    // Courses List
                    coursesList()
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .principal) {
                    Text("My Classes")
                        .font(.system(size: 18, weight: .bold))
                        .foregroundColor(.brandPrimary)
                }
            }
        }
        .navigationViewStyle(.stack)
    }
    
    // MARK: - Search & Filter Bar
    private func searchAndFilterBar() -> some View {
        VStack(spacing: 12) {
            HStack(spacing: 12) {
                Image(systemName: "magnifyingglass")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(.secondary)
                
                TextField("Search classes...", text: $searchText)
                    .font(.system(size: 14, weight: .medium))
                    .textInputAutocapitalization(.never)
                
                if !searchText.isEmpty {
                    Button(action: { searchText = "" }) {
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
                ForEach(SortOption.allCases, id: \.self) { option in
                    Button(action: { selectedSortOption = option.rawValue }) {
                        Text(option.label)
                            .font(.system(size: 12, weight: .semibold))
                            .foregroundColor(selectedSortOption == option.rawValue ? .white : .secondary)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 6)
                            .background(
                                selectedSortOption == option.rawValue ?
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
    
    // MARK: - Create New Course Button
    private func createCourseButton() -> some View {
        VStack {
            Button(action: {}) {
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
    }
    
    // MARK: - Courses List
    private func coursesList() -> some View {
        ScrollView(.vertical, showsIndicators: false) {
            VStack(spacing: 16) {
                TeacherCourseCard(
                    title: "Advanced Web Development",
                    students: 89,
                    rating: 4.9,
                    newSubmissions: 5,
                    completion: 0.67,
                    image: "webdev"
                )
                
                TeacherCourseCard(
                    title: "React & Modern JavaScript",
                    students: 124,
                    rating: 4.7,
                    newSubmissions: 8,
                    completion: 0.78,
                    image: "react"
                )
                
                TeacherCourseCard(
                    title: "Full Stack Development",
                    students: 67,
                    rating: 4.8,
                    newSubmissions: 3,
                    completion: 0.45,
                    image: "fullstack"
                )
                
                TeacherCourseCard(
                    title: "TypeScript Essentials",
                    students: 45,
                    rating: 4.6,
                    newSubmissions: 2,
                    completion: 0.52,
                    image: "typescript"
                )
                
                TeacherCourseCard(
                    title: "Mobile App Development",
                    students: 92,
                    rating: 4.9,
                    newSubmissions: 6,
                    completion: 0.71,
                    image: "mobile"
                )
                
                Spacer(minLength: 20)
            }
            .padding(.horizontal, DS.paddingMD)
            .padding(.vertical, DS.paddingMD)
        }
    }
}

// MARK: - Teacher Course Card Component
private struct TeacherCourseCard: View {
    let title: String
    let students: Int
    let rating: Double
    let newSubmissions: Int
    let completion: Double
    let image: String
    
    @State private var showMenu = false
    
    var body: some View {
        VStack(spacing: 16) {
            // Header
            HStack(spacing: 12) {
                // Course Image Placeholder
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
                .frame(width: 60, height: 60)
                .cornerRadius(DS.cornerRadiusMD)
                
                VStack(alignment: .leading, spacing: 6) {
                    Text(title)
                        .font(.system(size: 15, weight: .bold))
                        .foregroundColor(.primary)
                        .lineLimit(2)
                    
                    HStack(spacing: 12) {
                        HStack(spacing: 4) {
                            Image(systemName: "person.2.fill")
                                .font(.system(size: 11, weight: .semibold))
                            Text("\(students) students")
                                .font(.system(size: 11, weight: .medium))
                        }
                        .foregroundColor(.secondary)
                        
                        HStack(spacing: 4) {
                            Image(systemName: "star.fill")
                                .font(.system(size: 11, weight: .semibold))
                            Text(String(format: "%.1f", rating))
                                .font(.system(size: 11, weight: .medium))
                        }
                        .foregroundColor(.brandWarning)
                    }
                }
                
                Spacer()
                
                // New Submissions Badge
                if newSubmissions > 0 {
                    ZStack {
                        Circle()
                            .fill(Color.brandError)
                        VStack {
                            Text("\(newSubmissions)")
                                .font(.system(size: 11, weight: .bold))
                                .foregroundColor(.white)
                        }
                    }
                    .frame(width: 32, height: 32)
                }
            }
            
            // Stats & Progress
            VStack(spacing: 12) {
                // Progress Bar
                VStack(alignment: .leading, spacing: 6) {
                    HStack {
                        Text("Avg. Completion")
                            .font(.system(size: 12, weight: .medium))
                            .foregroundColor(.secondary)
                        
                        Spacer()
                        
                        Text("\(Int(completion * 100))%")
                            .font(.system(size: 12, weight: .bold))
                            .foregroundColor(.brandPrimary)
                    }
                    
                    ZStack(alignment: .leading) {
                        RoundedRectangle(cornerRadius: 4)
                            .fill(Color.secondary.opacity(0.1))
                            .frame(height: 6)
                        
                        RoundedRectangle(cornerRadius: 4)
                            .fill(
                                LinearGradient(
                                    colors: [Color.brandPrimary, Color.brandSuccess],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                            .frame(width: completion * (UIScreen.main.bounds.width - 64), height: 6)
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
                    .background(
                        RoundedRectangle(cornerRadius: 8)
                            .fill(Color.brandPrimary)
                    )
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
                
                Button(action: {}) {
                    Image(systemName: "ellipsis")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(.secondary)
                        .frame(width: 40, height: 40)
                        .background(Color.secondary.opacity(0.1))
                        .cornerRadius(8)
                }
            }
        }
        .padding(DS.paddingMD)
        .background(
            RoundedRectangle(cornerRadius: DS.cornerRadiusMD)
                .fill(Color(.systemBackground))
                .stroke(Color.brandPrimary.opacity(0.1), lineWidth: 1)
        )
    }
}

#Preview {
    TeacherMyClassesView()
}
