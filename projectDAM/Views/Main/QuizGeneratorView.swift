import SwiftUI

private enum QuizGenerationMode: String, CaseIterable, Identifiable {
    case course
    case videos

    var id: String { rawValue }

    var title: String {
        switch self {
        case .course: return "Whole course"
        case .videos: return "Selected videos"
        }
    }
}

struct QuizGeneratorView: View {
    @Environment(\.dismiss) private var dismiss

    @State private var mode: QuizGenerationMode = .course
    @State private var isLoadingCourses = false
    @State private var courses: [Course] = []
    @State private var selectedCourse: Course?

    @State private var isLoadingVideos = false
    @State private var videos: [VideoContent] = []
    @State private var selectedVideoIds: Set<String> = []

    @State private var titleText: String = ""
    @State private var descriptionText: String = ""
    @State private var isGenerating: Bool = false
    @State private var errorMessage: String?

    private let quizService: QuizServiceProtocol
    private let courseService: CourseServiceProtocol
    private let lessonService: LessonServiceProtocol
    private let lessonContext: Lesson?
    let onQuizCreated: (QuizSummary) -> Void

    init(
        quizService: QuizServiceProtocol = DIContainer.shared.quizService,
        courseService: CourseServiceProtocol = DIContainer.shared.courseService,
        lessonService: LessonServiceProtocol = DIContainer.shared.lessonService,
        onQuizCreated: @escaping (QuizSummary) -> Void
    ) {
        self.quizService = quizService
        self.courseService = courseService
        self.lessonService = lessonService
        self.lessonContext = nil
        self.onQuizCreated = onQuizCreated
    }

    init(
        lesson: Lesson,
        quizService: QuizServiceProtocol = DIContainer.shared.quizService,
        courseService: CourseServiceProtocol = DIContainer.shared.courseService,
        lessonService: LessonServiceProtocol = DIContainer.shared.lessonService,
        onQuizCreated: @escaping (QuizSummary) -> Void
    ) {
        self.quizService = quizService
        self.courseService = courseService
        self.lessonService = lessonService
        self.lessonContext = lesson
        self.onQuizCreated = onQuizCreated
        _videos = State(initialValue: lesson.videos)
        _selectedVideoIds = State(initialValue: Set(lesson.videos.map { $0.id }))
        _titleText = State(initialValue: "AI Quiz for \(lesson.title)")
    }

    var body: some View {
        NavigationView {
            content
                .navigationTitle("AI Quiz Generator")
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .cancellationAction) {
                        ToolbarIconButton(
                            systemName: "xmark",
                            accessibilityLabel: "Close",
                            action: { dismiss() }
                        )
                    }
                    ToolbarItem(placement: .confirmationAction) {
                        Button(action: { Task { await generateQuiz() } }) {
                            if isGenerating {
                                ProgressView()
                                    .frame(width: 44, height: 44)
                            } else {
                                Image(systemName: "sparkles")
                                    .font(.system(size: 17, weight: .semibold))
                                    .foregroundStyle(.primary)
                                    .frame(width: 44, height: 44)
                            }
                        }
                        .accessibilityLabel("Generate")
                        .buttonStyle(.plain)
                        .disabled(!canGenerate || isGenerating)
                    }
                }
        }
        .task {
            if lessonContext == nil {
                await loadCourses()
            }
        }
        .onAppear {
            if let lesson = lessonContext, videos.isEmpty {
                videos = lesson.videos
                selectedVideoIds = Set(lesson.videos.map { $0.id })
                if titleText.isEmpty {
                    titleText = "AI Quiz for \(lesson.title)"
                }
            }
        }
    }

    @ViewBuilder
    private var content: some View {
        ScrollView(showsIndicators: false) {
            VStack(spacing: 18) {
                headerSection

                VStack(spacing: 16) {
                    modeSelector

                    if lessonContext == nil {
                        courseSelectorSection
                    } else if let lesson = lessonContext {
                        lessonContextPill(for: lesson)
                    }

                    if mode == .videos {
                        videosSection
                    }

                    configurationSection
                }

                if let error = errorMessage {
                    Text(error)
                        .font(.system(size: 13))
                        .foregroundColor(.red)
                        .padding(.horizontal, 4)
                }

                Spacer(minLength: 8)
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 16)
        }
        .background(Color(.systemGroupedBackground).ignoresSafeArea())
    }

    // MARK: - Sections

    private var headerSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: 10) {
                ZStack {
                    Circle()
                        .fill(
                            LinearGradient(
                                colors: [Color.brandPrimary, Color.brandPrimary.opacity(0.7)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 34, height: 34)
                    Image(systemName: "sparkles")
                        .foregroundColor(.white)
                        .font(.system(size: 16, weight: .semibold))
                }

                VStack(alignment: .leading, spacing: 4) {
                    Text("AI-powered quiz")
                        .font(.system(size: 16, weight: .semibold))
                    if let lesson = lessonContext {
                        Text("Based on \(lesson.title)")
                            .font(.system(size: 13))
                            .foregroundColor(.secondary)
                            .lineLimit(2)
                    } else {
                        Text("Generate questions from your course content in seconds.")
                            .font(.system(size: 13))
                            .foregroundColor(.secondary)
                    }
                }

                Spacer()
            }

            HStack(spacing: 8) {
                Label("Keeps your answers randomized", systemImage: "shuffle")
                Label("One-click quiz creation", systemImage: "bolt.fill")
            }
            .font(.system(size: 11, weight: .semibold))
            .foregroundColor(.secondary)
            .lineLimit(1)
            .minimumScaleFactor(0.8)
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .fill(Color(.systemBackground))
                .shadow(color: Color.black.opacity(0.05), radius: 12, x: 0, y: 4)
        )
    }

    private var modeSelector: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("What do you want to generate from?")
                .font(.system(size: 15, weight: .semibold))

            Picker("Mode", selection: $mode) {
                ForEach(QuizGenerationMode.allCases) { mode in
                    Text(mode.title).tag(mode)
                }
            }
            .pickerStyle(.segmented)
        }
    }

    private func lessonContextPill(for lesson: Lesson) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("Source lesson")
                .font(.system(size: 13, weight: .semibold))
                .foregroundColor(.secondary)

            HStack(alignment: .top, spacing: 10) {
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .fill(Color.brandPrimary.opacity(0.12))
                    .frame(width: 34, height: 34)
                    .overlay(
                        Image(systemName: "play.rectangle.fill")
                            .foregroundColor(.brandPrimary)
                    )

                VStack(alignment: .leading, spacing: 4) {
                    Text(lesson.title)
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(.primary)
                        .lineLimit(2)
                    if let count = Optional(lesson.videos.count) {
                        Text("\(count) videos in this lesson")
                            .font(.system(size: 12))
                            .foregroundColor(.secondary)
                    }
                }

                Spacer()
            }
            .padding(10)
            .background(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .fill(Color(.secondarySystemBackground))
            )
        }
    }

    private var courseSelectorSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Text("Course")
                    .font(.system(size: 15, weight: .semibold))
                Spacer()
                if isLoadingCourses {
                    ProgressView().scaleEffect(0.8)
                }
            }

            if courses.isEmpty && !isLoadingCourses {
                Text("No courses available.")
                    .font(.system(size: 13))
                    .foregroundColor(.secondary)
            } else {
                Menu {
                    ForEach(courses) { course in
                        Button(action: {
                            selectCourse(course)
                        }) {
                            HStack {
                                Text(course.title)
                                if course.id == selectedCourse?.id {
                                    Image(systemName: "checkmark")
                                }
                            }
                        }
                    }
                } label: {
                    HStack {
                        Text(selectedCourse?.title ?? "Select a course")
                            .foregroundColor(selectedCourse == nil ? .secondary : .primary)
                        Spacer()
                        Image(systemName: "chevron.down")
                            .foregroundColor(.secondary)
                    }
                    .padding(12)
                    .background(Color(.systemBackground))
                    .cornerRadius(14)
                    .shadow(color: Color.black.opacity(0.03), radius: 6, x: 0, y: 2)
                }
            }
        }
    }

    private var videosSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Text("Videos")
                    .font(.system(size: 15, weight: .semibold))
                Spacer()
                if isLoadingVideos {
                    ProgressView().scaleEffect(0.8)
                } else if !videos.isEmpty {
                    Text("Selected: \(selectedVideoIds.count)/\(videos.count)")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundColor(.secondary)
                }
            }

            if selectedCourse == nil && lessonContext == nil {
                Text("Select a course first to choose its videos.")
                    .font(.system(size: 13))
                    .foregroundColor(.secondary)
            } else if videos.isEmpty && !isLoadingVideos {
                Text("No videos found for this course.")
                    .font(.system(size: 13))
                    .foregroundColor(.secondary)
            } else {
                VStack(alignment: .leading, spacing: 8) {
                    ScrollView {
                        VStack(alignment: .leading, spacing: 8) {
                            ForEach(videos) { video in
                                videoRow(video)
                            }
                        }
                    }
                    .frame(maxHeight: 220)

                    if !videos.isEmpty {
                        HStack(spacing: 12) {
                            Button("Select all") {
                                selectedVideoIds = Set(videos.map { $0.id })
                            }
                            .font(.system(size: 13, weight: .semibold))

                            Button("Clear") {
                                selectedVideoIds.removeAll()
                            }
                            .font(.system(size: 13, weight: .semibold))
                            .foregroundColor(.secondary)

                            Spacer()
                        }
                        .padding(.top, 4)
                    }
                }
            }
        }
    }

    private var configurationSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Quiz details (optional)")
                .font(.system(size: 15, weight: .semibold))

            VStack(spacing: 8) {
                TextField("Title (optional)", text: $titleText)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 10)
                    .background(
                        RoundedRectangle(cornerRadius: 14, style: .continuous)
                            .fill(Color(.systemBackground))
                            .shadow(color: Color.black.opacity(0.02), radius: 4, x: 0, y: 1)
                    )

                TextField("Description (optional)", text: $descriptionText, axis: .vertical)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 10)
                    .background(
                        RoundedRectangle(cornerRadius: 14, style: .continuous)
                            .fill(Color(.systemBackground))
                            .shadow(color: Color.black.opacity(0.02), radius: 4, x: 0, y: 1)
                    )
            }
        }
    }

    private func videoRow(_ video: VideoContent) -> some View {
        let isSelected = selectedVideoIds.contains(video.id)
        return Button {
            if isSelected {
                selectedVideoIds.remove(video.id)
            } else {
                selectedVideoIds.insert(video.id)
            }
        } label: {
            HStack(alignment: .top, spacing: 10) {
                Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                    .foregroundColor(isSelected ? .brandPrimary : .secondary)
                VStack(alignment: .leading, spacing: 4) {
                    Text(video.title)
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(.primary)
                        .lineLimit(2)
                    if let description = video.description, !description.isEmpty {
                        Text(description)
                            .font(.system(size: 12))
                            .foregroundColor(.secondary)
                            .lineLimit(2)
                    }
                    Text(video.formattedDuration)
                        .font(.system(size: 11, weight: .semibold))
                        .foregroundColor(.secondary)
                }
                Spacer()
            }
            .padding(10)
            .background(
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .fill(
                        isSelected
                        ? Color.brandPrimary.opacity(0.08)
                        : Color(.systemBackground)
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 14, style: .continuous)
                            .stroke(isSelected ? Color.brandPrimary.opacity(0.4) : Color.clear, lineWidth: 1)
                    )
            )
        }
        .buttonStyle(.plain)
    }

    // MARK: - Actions

    private var canGenerate: Bool {
        if mode == .videos {
            return !selectedVideoIds.isEmpty
        }
        if selectedCourse != nil {
            return true
        }
        if let lesson = lessonContext, lesson.courseId != nil {
            return true
        }
        return false
    }

    private func loadCourses() async {
        guard !isLoadingCourses else { return }
        isLoadingCourses = true
        errorMessage = nil
        do {
            // Prefer user courses if available
            if let userCourseService = courseService as? CourseService {
                courses = try await userCourseService.fetchUserCourses()
            } else {
                courses = try await courseService.fetchUserCourses()
            }
        } catch {
            errorMessage = error.localizedDescription
        }
        isLoadingCourses = false
    }

    private func selectCourse(_ course: Course) {
        selectedCourse = course
        if mode == .course {
            if titleText.isEmpty { titleText = "AI Generated Quiz for \(course.title)" }
            if descriptionText.isEmpty { descriptionText = "Quiz generated automatically based on all videos in the course." }
        }
        if mode == .videos {
            Task { await loadVideos(for: course) }
        }
    }

    private func loadVideos(for course: Course) async {
        guard !isLoadingVideos else { return }
        isLoadingVideos = true
        errorMessage = nil
        do {
            let lesson = try await lessonService.fetchLesson(courseId: course.id, accessType: .publicCourse)
            videos = lesson.videos
            selectedVideoIds = Set(videos.map { $0.id })
        } catch {
            errorMessage = error.localizedDescription
            videos = []
            selectedVideoIds.removeAll()
        }
        isLoadingVideos = false
    }

    private func generateQuiz() async {
        guard canGenerate else { return }
        isGenerating = true
        errorMessage = nil
        do {
            let quiz: QuizSummary
            switch mode {
            case .course:
                let courseId: String
                if let selected = selectedCourse {
                    courseId = selected.id
                } else if let lesson = lessonContext, let id = lesson.courseId {
                    courseId = id
                } else {
                    isGenerating = false
                    return
                }
                quiz = try await quizService.generateQuizFromCourse(
                    courseId: courseId,
                    title: titleText.isEmpty ? nil : titleText,
                    description: descriptionText.isEmpty ? nil : descriptionText
                )
            case .videos:
                let ids = Array(selectedVideoIds)
                quiz = try await quizService.generateQuizFromVideos(
                    videoIds: ids,
                    title: titleText.isEmpty ? nil : titleText,
                    description: descriptionText.isEmpty ? nil : descriptionText
                )
            }

            onQuizCreated(quiz)
            dismiss()
        } catch {
            errorMessage = error.localizedDescription
        }
        isGenerating = false
    }
}
