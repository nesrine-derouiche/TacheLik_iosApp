import SwiftUI
import YouTubePlayerKit

// MARK: - Lessons View
struct LessonsView: View {
    @StateObject private var viewModel: LessonsViewModel
    @State private var selectedVideoId: String?
    @Namespace private var videoNamespace
    @StateObject private var youtubePlayer = YouTubePlayer()
    
    // MARK: - Initializers
    init(courseId: String, accessType: LessonAccessType, isOwned: Bool = false, lessonService: LessonServiceProtocol = DIContainer.shared.lessonService) {
        _viewModel = StateObject(wrappedValue: LessonsViewModel(courseId: courseId, accessType: accessType, isOwned: isOwned, lessonService: lessonService))
    }
    
    init(viewModel: LessonsViewModel) {
        _viewModel = StateObject(wrappedValue: viewModel)
    }
    
    // MARK: - Body
    var body: some View {
        ZStack {
            Color(.systemGroupedBackground)
                .ignoresSafeArea()
            content
        }
        .navigationTitle(viewModel.lessonTitle)
        .navigationBarTitleDisplayMode(.inline)
        .task { await viewModel.loadLesson() }
        .refreshable { await viewModel.loadLesson(force: true) }
        .onChange(of: viewModel.visibleVideos, perform: handleVideoListChange)
    }
    
    // MARK: - Content States
    @ViewBuilder
    private var content: some View {
        if viewModel.isLoading && viewModel.lesson == nil {
            loadingState
        } else if let error = viewModel.errorMessage, viewModel.lesson == nil {
            errorState(message: error)
        } else if let lesson = viewModel.lesson {
            ScrollView(showsIndicators: false) {
                VStack(spacing: 28) {
                    headerSection(for: lesson)
                    metadataSection(for: lesson)
                    videoHeroSection
                    videoTimelineSection
                    TeacherProfileCard(teacher: lesson.teacher)
                        .padding(.horizontal, DS.paddingMD)
                    if let description = lesson.description, !description.isEmpty {
                        lessonDescriptionSection(description)
                    }
                    footerSection(for: lesson)
                }
                .padding(.vertical, 24)
            }
        } else {
            emptyState
        }
    }
    
    // MARK: - Sections
    private func headerSection(for lesson: Lesson) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 8) {
                accessBadge
                if let updatedText = formattedDate(lesson.updatedDate) {
                    infoPill(icon: "clock.arrow.circlepath", text: "Updated \(updatedText)")
                }
            }
            .padding(.horizontal, DS.paddingMD)
            
            Text(lesson.title)
                .font(.system(size: 30, weight: .black, design: .rounded))
                .lineSpacing(4)
                .fixedSize(horizontal: false, vertical: true)
                .padding(.horizontal, DS.paddingMD)
        }
    }
    
    private func metadataSection(for lesson: Lesson) -> some View {
        let totalMinutes = lesson.videos.reduce(0) { $0 + $1.duration } / 60
        let stats: [(String, String, String)] = [
            ("play.rectangle.fill", "Videos", "\(lesson.videos.count)"),
            ("clock.fill", "Runtime", "\(totalMinutes) min"),
            ("book.fill", "Course", lesson.courseId ?? "—")
        ]
        
        return ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 14) {
                ForEach(stats, id: \.1) { stat in
                    statCard(icon: stat.0, title: stat.1, value: stat.2)
                }
            }
            .padding(.horizontal, DS.paddingMD)
        }
    }
    
    private var videoHeroSection: some View {
        let currentVideo = selectedVideo
        return VStack(alignment: .leading, spacing: 16) {
            if viewModel.accessType == .publicCourse {
                EmbeddedYouTubePlayerView(player: youtubePlayer)
                    .frame(height: 220)
                    .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
            } else if viewModel.isLockedPaidCourse {
                ZStack(alignment: .center) {
                    RoundedRectangle(cornerRadius: 24, style: .continuous)
                        .fill(
                            LinearGradient(
                                colors: [Color.gray.opacity(0.25), Color.gray.opacity(0.35)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(height: 220)
                    
                    VStack(spacing: 10) {
                        Image(systemName: "lock.fill")
                            .font(.system(size: 28, weight: .bold))
                            .foregroundColor(.white)
                        Text("This premium course is locked")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(.white)
                        Text("Purchase this course to unlock all videos.")
                            .font(.system(size: 13))
                            .foregroundColor(.white.opacity(0.9))
                    }
                    .padding(24)
                }
            } else {
                ZStack(alignment: .bottomLeading) {
                    RoundedRectangle(cornerRadius: 24, style: .continuous)
                        .fill(
                            LinearGradient(
                                colors: [Color.brandPrimary, Color.brandPrimaryHover],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(height: 220)
                    
                    VStack(alignment: .leading, spacing: 10) {
                        Text(currentVideo?.title ?? "Select a video")
                            .font(.system(size: 18, weight: .bold))
                            .foregroundColor(.white)
                            .lineLimit(2)
                        
                        HStack(spacing: 12) {
                            infoPill(icon: "clock", text: currentVideo?.formattedDuration ?? "–")
                                .foregroundColor(.white.opacity(0.9))
                            Button {
                                // Share placeholder
                            } label: {
                                Image(systemName: "square.and.arrow.up")
                                    .foregroundColor(.white)
                                    .padding(10)
                                    .background(Color.white.opacity(0.15))
                                    .clipShape(Circle())
                            }
                        }
                    }
                    .padding(24)
                }
            }
        }
        .animation(.spring(response: 0.35, dampingFraction: 0.85), value: selectedVideoId)
        .padding(.horizontal, DS.paddingMD)
    }
    
    private var videoTimelineSection: some View {
        VStack(spacing: 0) {
            HStack {
                Text("Lesson Timeline")
                    .font(.system(size: 18, weight: .semibold))
                Spacer()
                if viewModel.hasMoreVideos {
                    infoPill(icon: "arrow.down", text: "More incoming")
                }
            }
            .padding([.horizontal, .bottom], DS.paddingMD)
            
            if viewModel.visibleVideos.isEmpty {
                EmptyStateCard(message: "Videos will appear here once available.")
                    .padding(.horizontal, DS.paddingMD)
                    .padding(.bottom, DS.paddingMD)
            } else {
                VStack(spacing: 0) {
                    ForEach(Array(viewModel.visibleVideos.enumerated()), id: \.element.id) { index, video in
                        VideoListItemView(
                            video: video,
                            isSelected: selectedVideoId == video.id,
                            index: index + 1,
                            isLocked: viewModel.isLockedPaidCourse && viewModel.accessType == .privateCourse
                        )
                        .onTapGesture {
                            guard !viewModel.isLockedPaidCourse else { return }
                            withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                                selectedVideoId = video.id
                            }
                            if viewModel.accessType == .publicCourse {
                                updateYouTubePlayer(with: video)
                            } else {
                                Task {
                                    await DIContainer.shared.vdoCipherService.playPaidVideo(videoId: video.id)
                                }
                            }
                        }
                        .onAppear {
                            viewModel.loadMoreVideosIfNeeded(currentVideoId: video.id)
                        }
                        
                        if index < viewModel.visibleVideos.count - 1 {
                            Divider()
                                .padding(.horizontal, DS.paddingMD)
                        }
                    }
                }
            }
            
            if viewModel.hasMoreVideos {
                HStack(spacing: 12) {
                    ProgressView()
                    Text("Fetching more videos…")
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundColor(.secondary)
                    Spacer()
                }
                .padding(.horizontal, DS.paddingMD)
                .padding(.vertical, 12)
            }
        }
        .background(Color(.systemBackground))
        .cornerRadius(24)
        .padding(.horizontal, DS.paddingMD)
        .shadow(color: Color.black.opacity(0.05), radius: 12, x: 0, y: 4)
    }
    
    private func lessonDescriptionSection(_ description: String) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Overview")
                .font(.system(size: 17, weight: .semibold))
                .textCase(.uppercase)
                .foregroundColor(.secondary)
            Text(description)
                .font(.system(size: 15, weight: .regular))
                .foregroundColor(.primary)
                .lineSpacing(4)
        }
        .padding(DS.paddingMD)
        .background(Color(.systemBackground))
        .cornerRadius(24)
        .padding(.horizontal, DS.paddingMD)
        .shadow(color: Color.black.opacity(0.05), radius: 10, x: 0, y: 4)
    }
    
    private func footerSection(for lesson: Lesson) -> some View {
        VStack(spacing: 6) {
            Text("Need this lesson offline?")
                .font(.system(size: 16, weight: .semibold))
            Text("Future versions will let you download sessions and continue without internet.")
                .font(.system(size: 13))
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 32)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 24)
        .background(
            RoundedRectangle(cornerRadius: 28, style: .continuous)
                .fill(Color.brandPrimary.opacity(0.08))
        )
        .padding(.horizontal, DS.paddingMD)
    }
    
    // MARK: - States
    private var loadingState: some View {
        VStack(spacing: 20) {
            ShimmerCard(height: 200)
            ShimmerCard(height: 140)
            ShimmerCard(height: 120)
        }
        .padding(24)
    }
    
    private func errorState(message: String) -> some View {
        VStack(spacing: 16) {
            Image(systemName: "exclamationmark.triangle.fill")
                .font(.system(size: 40))
                .foregroundColor(.orange)
            Text("We couldn't load this lesson")
                .font(.system(size: 20, weight: .semibold))
            Text(message)
                .font(.system(size: 15))
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
            Button(action: { Task { await viewModel.retry() } }) {
                Text("Retry")
                    .font(.system(size: 16, weight: .bold))
                    .padding(.horizontal, 32)
                    .padding(.vertical, 12)
                    .background(Color.brandPrimary)
                    .foregroundColor(.white)
                    .cornerRadius(16)
            }
        }
        .padding(32)
    }
    
    private var emptyState: some View {
        VStack(spacing: 12) {
            Image(systemName: "book")
                .font(.system(size: 44))
                .foregroundColor(.secondary)
            Text("Lesson unavailable")
                .font(.system(size: 20, weight: .semibold))
            Text("This course doesn't expose a lesson yet. Check again soon.")
                .font(.system(size: 14))
                .foregroundColor(.secondary)
        }
        .padding(32)
    }
    
    // MARK: - Helpers
    private var accessBadge: some View {
        let label: String
        let colors: [Color]
        if viewModel.accessType == .publicCourse {
            label = "Free Lesson"
            colors = [Color.green.opacity(0.9), Color.green.opacity(0.7)]
        } else if viewModel.isLockedPaidCourse {
            label = "Locked Lesson"
            colors = [Color.gray.opacity(0.9), Color.gray.opacity(0.7)]
        } else {
            label = "Premium Lesson"
            colors = [Color.purple.opacity(0.9), Color.purple.opacity(0.7)]
        }
        
        return Text(label)
            .font(.system(size: 12, weight: .bold))
            .foregroundColor(.white)
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
            .background(
                Capsule()
                    .fill(LinearGradient(colors: colors, startPoint: .topLeading, endPoint: .bottomTrailing))
            )
    }
    
    private func infoPill(icon: String, text: String) -> some View {
        HStack(spacing: 6) {
            Image(systemName: icon)
                .font(.system(size: 12, weight: .semibold))
            Text(text)
                .font(.system(size: 12, weight: .semibold))
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 6)
        .background(Color.white.opacity(0.2))
        .clipShape(Capsule())
    }
    
    private func statCard(icon: String, title: String, value: String) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Image(systemName: icon)
                .font(.system(size: 18, weight: .semibold))
                .foregroundColor(.brandPrimary)
            Text(title.uppercased())
                .font(.system(size: 11, weight: .bold))
                .foregroundColor(.secondary)
            Text(value)
                .font(.system(size: 17, weight: .heavy))
        }
        .padding(16)
        .frame(width: 140, alignment: .leading)
        .background(Color(.systemBackground))
        .cornerRadius(18)
        .shadow(color: Color.black.opacity(0.04), radius: 8, x: 0, y: 4)
    }
    
    private func formattedDate(_ isoString: String?) -> String? {
        guard let isoString else { return nil }
        let formatter = ISO8601DateFormatter()
        guard let date = formatter.date(from: isoString) else { return nil }
        let displayFormatter = DateFormatter()
        displayFormatter.dateStyle = .medium
        return displayFormatter.string(from: date)
    }
    
    private func handleVideoListChange(_ videos: [VideoContent]) {
        guard let first = videos.first else {
            selectedVideoId = nil
            return
        }
        if let current = selectedVideoId, videos.contains(where: { $0.id == current }) {
            return
        }
        selectedVideoId = first.id
        if viewModel.accessType == .publicCourse {
            updateYouTubePlayer(with: first)
        } else if !viewModel.isLockedPaidCourse {
            Task {
                await DIContainer.shared.vdoCipherService.playPaidVideo(videoId: first.id)
            }
        }
    }
    
    private var selectedVideo: VideoContent? {
        guard let id = selectedVideoId else { return viewModel.visibleVideos.first }
        return viewModel.visibleVideos.first(where: { $0.id == id }) ?? viewModel.visibleVideos.first
    }

    private func updateYouTubePlayer(with video: VideoContent) {
        guard viewModel.accessType == .publicCourse,
              let youtubeId = video.youtubeVideoId else {
            return
        }
        print("[LessonsView] Updating YouTube player with id=\(youtubeId) for video id=\(video.id)")
        Task {
            do {
                try await youtubePlayer.load(source: .video(id: youtubeId))
            } catch {
                print("[LessonsView] Failed to load YouTube video id=\(youtubeId): \(error)")
            }
        }
    }
}

// MARK: - Video List Item
struct VideoListItemView: View {
    let video: VideoContent
    let isSelected: Bool
    let index: Int
    let isLocked: Bool
    
    @State private var isPressed = false
    
    var body: some View {
        HStack(spacing: DS.paddingMD) {
            ZStack {
                Circle()
                    .fill(
                        isLocked
                        ? LinearGradient(colors: [Color.gray.opacity(0.3), Color.gray.opacity(0.4)], startPoint: .topLeading, endPoint: .bottomTrailing)
                        : (
                            isSelected
                            ? LinearGradient(colors: [Color.brandPrimary, Color.brandPrimaryHover], startPoint: .topLeading, endPoint: .bottomTrailing)
                            : LinearGradient(colors: [Color(.secondarySystemBackground), Color(.tertiarySystemBackground)], startPoint: .topLeading, endPoint: .bottomTrailing)
                        )
                    )
                if isLocked {
                    Image(systemName: "lock.fill")
                        .font(.system(size: 12, weight: .bold))
                        .foregroundColor(.white)
                } else if isSelected {
                    Image(systemName: "play.fill")
                        .font(.system(size: 12, weight: .bold))
                        .foregroundColor(.white)
                } else {
                    Text("\(index)")
                        .font(.system(size: 12, weight: .bold))
                        .foregroundColor(.secondary)
                }
            }
            .frame(width: 42, height: 42)
            .shadow(color: isSelected ? Color.brandPrimary.opacity(0.25) : .clear, radius: 8, x: 0, y: 2)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(video.title)
                    .font(.system(size: 15, weight: isSelected ? .semibold : .medium))
                    .foregroundColor(isLocked ? .secondary : .primary)
                    .lineLimit(2)
                if let description = video.description, !description.isEmpty {
                    Text(description)
                        .font(.system(size: 12))
                        .foregroundColor(.secondary)
                        .lineLimit(2)
                }
                Text(video.formattedDuration)
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            Image(systemName: isLocked ? "lock.fill" : (isSelected ? "checkmark.circle.fill" : "chevron.right"))
                .font(.system(size: isSelected ? 18 : 12, weight: .semibold))
                .foregroundColor(isLocked ? .secondary : (isSelected ? .brandPrimary : .secondary))
                .opacity(isLocked ? 0.7 : (isSelected ? 1 : 0.4))
        }
        .padding(DS.paddingMD)
        .contentShape(Rectangle())
        .scaleEffect(isPressed ? 0.98 : 1)
        .onLongPressGesture(minimumDuration: 0.1, perform: {}) { pressing in
            withAnimation(.spring(response: 0.2)) { isPressed = pressing }
        }
    }
}

// MARK: - Utility Views
private struct ShimmerCard: View {
    var height: CGFloat
    @State private var phase: CGFloat = -1
    
    var body: some View {
        RoundedRectangle(cornerRadius: 24, style: .continuous)
            .fill(Color(.secondarySystemBackground))
            .frame(height: height)
            .overlay(
                GeometryReader { geometry in
                    LinearGradient(
                        colors: [Color.white.opacity(0.1), Color.white.opacity(0.6), Color.white.opacity(0.1)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                    .frame(width: geometry.size.width, height: geometry.size.height)
                    .offset(x: geometry.size.width * phase)
                }
                .mask(
                    RoundedRectangle(cornerRadius: 24, style: .continuous)
                        .frame(height: height)
                )
            )
            .onAppear {
                withAnimation(.linear(duration: 1.2).repeatForever(autoreverses: false)) {
                    phase = 1.5
                }
            }
    }
}

private struct EmptyStateCard: View {
    let message: String
    var body: some View {
        VStack(spacing: 10) {
            Image(systemName: "sparkles")
                .font(.system(size: 26))
                .foregroundColor(.secondary)
            Text(message)
                .font(.system(size: 13))
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
        .padding(24)
        .frame(maxWidth: .infinity)
        .background(Color(.tertiarySystemBackground))
        .cornerRadius(18)
    }
}

// MARK: - Preview
#Preview {
    NavigationView {
        LessonsView(
            viewModel: LessonsViewModel(
                courseId: "course-1a",
                accessType: .publicCourse,
                isOwned: true,
                lessonService: MockLessonService(lesson: .sampleLesson)
            )
        )
    }
}
