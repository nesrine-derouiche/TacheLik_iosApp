import SwiftUI
import Combine

struct CourseSelectionForGameView: View {
    @Environment(\.presentationMode) var presentationMode
    @StateObject private var viewModel = CourseSelectionViewModel()
    let onCourseSelected: (String) -> Void
    
    var body: some View {
        NavigationView {
            VStack {
                if viewModel.isLoading {
                    ProgressView("Loading courses...")
                } else if viewModel.courses.isEmpty {
                    VStack(spacing: 16) {
                        Image(systemName: "book.closed")
                            .font(.system(size: 60))
                            .foregroundColor(.secondary)
                        Text("No courses available")
                            .font(.headline)
                            .foregroundColor(.secondary)
                    }
                } else {
                    List(viewModel.courses) { course in
                        Button {
                            onCourseSelected(course.id)
                        } label: {
                            HStack {
                                VStack(alignment: .leading, spacing: 4) {
                                    Text(course.title)
                                        .font(.headline)
                                        .foregroundColor(.primary)
                                    if !course.description.isEmpty {
                                        Text(course.description)
                                            .font(.caption)
                                            .foregroundColor(.secondary)
                                            .lineLimit(2)
                                    }
                                }
                                Spacer()
                                Image(systemName: "chevron.right")
                                    .foregroundColor(.secondary)
                            }
                        }
                    }
                }
            }
            .navigationTitle("Select Course")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        presentationMode.wrappedValue.dismiss()
                    }
                }
            }
        }
        .onAppear {
            Task {
                await viewModel.loadCourses()
            }
        }
    }
}

class CourseSelectionViewModel: ObservableObject {
    @Published var courses: [Course] = []
    @Published var isLoading = false
    
    func loadCourses() async {
        await MainActor.run {
            isLoading = true
        }
        
        do {
            let courseService = DIContainer.shared.courseService
            let fetchedCourses = try await courseService.fetchCourses()
            
            await MainActor.run {
                courses = fetchedCourses
                isLoading = false
            }
        } catch {
            print("❌ [CourseSelectionViewModel] Failed to load courses: \(error.localizedDescription)")
            await MainActor.run {
                isLoading = false
            }
        }
    }
}

