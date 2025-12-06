//
//  ReelsView.swift
//  projectDAM
//
//  Instagram-style full-screen reels viewer
//

import SwiftUI
import AVKit

// MARK: - Wrapper for fullScreenCover item
struct LessonPresentationItem: Identifiable {
    let id = UUID()
    let courseId: String
    let courseName: String
}

// MARK: - Main Reels View
struct ReelsView: View {
    @StateObject private var viewModel: ReelsViewModel
    @Environment(\.dismiss) private var dismiss
    @State private var showShareSheet: Bool = false
    @State private var selectedReelForShare: Reel?
    @State private var lessonToPresent: LessonPresentationItem?
    
    init(reelService: ReelServiceProtocol) {
        _viewModel = StateObject(wrappedValue: ReelsViewModel(reelService: reelService))
    }
    
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                Color.black.ignoresSafeArea()
                
                switch viewModel.viewState {
                case .idle, .loading:
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle(tint: .white))
                        .scaleEffect(1.5)
                    
                case .loaded:
                    if viewModel.reels.isEmpty {
                        emptyStateView
                    } else {
                        reelsPageView(geometry: geometry)
                    }
                    
                case .error(let message):
                    errorView(message: message)
                }
                
                // Close button
                VStack {
                    HStack {
                        Button {
                            dismiss()
                        } label: {
                            Image(systemName: "xmark")
                                .font(.title2.weight(.semibold))
                                .foregroundColor(.white)
                                .padding(12)
                                .background(Circle().fill(Color.black.opacity(0.5)))
                        }
                        .padding(.leading, 16)
                        
                        Spacer()
                        
                        // Filter menu
                        filterMenu
                    }
                    .padding(.top, 8)
                    
                    Spacer()
                }
            }
        }
        .navigationBarHidden(true)
        .statusBar(hidden: true)
        .task {
            await viewModel.loadReels()
        }
        .sheet(isPresented: $showShareSheet) {
            if let reel = selectedReelForShare {
                ShareSheet(activityItems: [reel.shareURL])
            }
        }
    }
    
    // MARK: - Reels Page View
    @ViewBuilder
    private func reelsPageView(geometry: GeometryProxy) -> some View {
        TabView(selection: $viewModel.currentIndex) {
            ForEach(Array(viewModel.reels.enumerated()), id: \.element.id) { index, reel in
                ReelItemView(
                    reel: reel,
                    isActive: index == viewModel.currentIndex,
                    onLike: {
                        Task { await viewModel.toggleLike(for: reel) }
                    },
                    onShare: {
                        selectedReelForShare = reel
                        showShareSheet = true
                        Task { await viewModel.recordShare(for: reel) }
                    },
                    onWatchLesson: {
                        print("🎬 [ReelsView] onWatchLesson tapped for reel: \(reel.id)")
                        print("🎬 [ReelsView] Reel title: \(reel.title)")
                        print("🎬 [ReelsView] Reel has course: \(reel.course != nil)")
                        if let course = reel.course, !course.id.isEmpty {
                            print("🎬 [ReelsView] Course ID: \(course.id), Name: \(course.name)")
                            lessonToPresent = LessonPresentationItem(courseId: course.id, courseName: course.name)
                        } else {
                            print("⚠️ [ReelsView] No valid course info for this reel")
                        }
                    }
                )
                .frame(width: geometry.size.width, height: geometry.size.height)
                .tag(index)
            }
        }
        .tabViewStyle(.page(indexDisplayMode: .never))
        .ignoresSafeArea()
        .onChange(of: viewModel.currentIndex) { newIndex in
            viewModel.onReelChange(to: newIndex)
        }
        .fullScreenCover(item: $lessonToPresent) { lesson in
            let _ = print("📚 [ReelsView] Opening lesson - courseId: '\(lesson.courseId)', courseName: '\(lesson.courseName)'")
            ReelLessonFullScreenView(courseId: lesson.courseId, courseName: lesson.courseName)
        }
    }
    
    // MARK: - Filter Menu
    private var filterMenu: some View {
        Menu {
            Button("All Reels") {
                viewModel.filterByType(nil)
            }
            
            ForEach(ReelType.allCases, id: \.self) { type in
                Button(type.displayName) {
                    viewModel.filterByType(type)
                }
            }
        } label: {
            HStack(spacing: 4) {
                Text(viewModel.selectedType?.displayName ?? "All")
                    .font(.subheadline.weight(.medium))
                Image(systemName: "chevron.down")
                    .font(.caption)
            }
            .foregroundColor(.white)
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(Capsule().fill(Color.black.opacity(0.5)))
        }
        .padding(.trailing, 16)
    }
    
    // MARK: - Empty State
    private var emptyStateView: some View {
        VStack(spacing: 16) {
            Image(systemName: "play.rectangle.on.rectangle")
                .font(.system(size: 60))
                .foregroundColor(.gray)
            
            Text("No Reels Available")
                .font(.title2.weight(.semibold))
                .foregroundColor(.white)
            
            Text("Check back later for new content")
                .font(.subheadline)
                .foregroundColor(.gray)
        }
    }
    
    // MARK: - Error View
    private func errorView(message: String) -> some View {
        VStack(spacing: 16) {
            Image(systemName: "exclamationmark.triangle")
                .font(.system(size: 50))
                .foregroundColor(.orange)
            
            Text("Something went wrong")
                .font(.title2.weight(.semibold))
                .foregroundColor(.white)
            
            Text(message)
                .font(.subheadline)
                .foregroundColor(.gray)
                .multilineTextAlignment(.center)
                .padding(.horizontal)
            
            Button {
                Task { await viewModel.loadReels() }
            } label: {
                Text("Try Again")
                    .font(.headline)
                    .foregroundColor(.black)
                    .padding(.horizontal, 24)
                    .padding(.vertical, 12)
                    .background(Capsule().fill(Color.white))
            }
        }
    }
}

// MARK: - Single Reel Item View
struct ReelItemView: View {
    let reel: Reel
    let isActive: Bool
    let onLike: () -> Void
    let onShare: () -> Void
    let onWatchLesson: () -> Void  // Navigate to full lesson
    
    @State private var player: AVPlayer?
    @State private var showLikeAnimation: Bool = false
    @State private var showFullDescription: Bool = false
    @State private var showSwipeHint: Bool = true
    
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                // Background
                Color.black
                
                // Video or Image content - fills the whole screen
                if reel.hasVideo {
                    videoPlayerView
                        .frame(width: geometry.size.width, height: geometry.size.height)
                } else {
                    imageContentView
                        .frame(width: geometry.size.width, height: geometry.size.height)
                }
                
                // Bottom gradient only - for text readability
                VStack {
                    Spacer()
                    LinearGradient(
                        colors: [.clear, .black.opacity(0.7), .black.opacity(0.9)],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                    .frame(height: 250)
                }
                
                // Content overlay at the very bottom
                VStack(spacing: 0) {
                    Spacer()
                    
                    // "Watch Full Lesson" link button (Instagram-style)
                    if reel.course != nil {
                        watchLessonButton
                            .padding(.bottom, 12)
                    }
                    
                    HStack(alignment: .bottom, spacing: 12) {
                        // Left: Info section (compact)
                        bottomInfoSection
                        
                        Spacer()
                        
                        // Right: Action buttons (vertical)
                        sideActionButtons
                    }
                    .padding(.horizontal, 16)
                    .padding(.bottom, 30)
                }
                
                // Swipe up hint (shows briefly)
                if showSwipeHint && reel.course != nil {
                    VStack {
                        Spacer()
                        swipeUpHint
                            .padding(.bottom, 180)
                    }
                    .transition(.opacity)
                    .onAppear {
                        // Hide after 3 seconds
                        DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
                            withAnimation(.easeOut(duration: 0.5)) {
                                showSwipeHint = false
                            }
                        }
                    }
                }
                
                // Double-tap like animation
                if showLikeAnimation {
                    Image(systemName: "heart.fill")
                        .font(.system(size: 80))
                        .foregroundColor(.red)
                        .transition(.scale.combined(with: .opacity))
                }
            }
            .contentShape(Rectangle())
            .onTapGesture(count: 2) {
                handleDoubleTap()
            }
            .onTapGesture(count: 1) {
                // Single tap to show/hide full description
                withAnimation(.easeInOut(duration: 0.2)) {
                    showFullDescription.toggle()
                }
            }
        }
        .onAppear {
            if isActive && reel.hasVideo {
                setupPlayer()
            }
        }
        .onChange(of: isActive) { active in
            if active && reel.hasVideo {
                setupPlayer()
                player?.play()
            } else {
                player?.pause()
            }
        }
        .onDisappear {
            player?.pause()
            player = nil
        }
    }
    
    // MARK: - Bottom Info Section (Instagram-style)
    private var bottomInfoSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            // Author row
            if let author = reel.author {
                HStack(spacing: 8) {
                    // Profile picture
                    AsyncImage(url: URL(string: author.profileImage ?? "")) { image in
                        image
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                    } placeholder: {
                        Circle()
                            .fill(Color.white.opacity(0.3))
                            .overlay(
                                Text(String(author.name.prefix(1)).uppercased())
                                    .font(.system(size: 14, weight: .bold))
                                    .foregroundColor(.white)
                            )
                    }
                    .frame(width: 32, height: 32)
                    .clipShape(Circle())
                    
                    // Name
                    Text(author.name)
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(.white)
                    
                    // Role badge
                    if let role = author.role {
                        Text(role.capitalized)
                            .font(.system(size: 11))
                            .foregroundColor(.white.opacity(0.8))
                            .padding(.horizontal, 8)
                            .padding(.vertical, 3)
                            .background(Capsule().fill(Color.white.opacity(0.2)))
                    }
                }
            }
            
            // Description (expandable)
            if let description = reel.description, !description.isEmpty {
                Text(description)
                    .font(.system(size: 13))
                    .foregroundColor(.white.opacity(0.9))
                    .lineLimit(showFullDescription ? nil : 2)
                    .animation(.easeInOut, value: showFullDescription)
            }
            
            // Course tag
            if let course = reel.course {
                HStack(spacing: 6) {
                    Image(systemName: "book.fill")
                        .font(.system(size: 11))
                    Text(course.name)
                        .font(.system(size: 12, weight: .medium))
                }
                .foregroundColor(.white)
                .padding(.horizontal, 10)
                .padding(.vertical, 6)
                .background(
                    Capsule()
                        .fill(Color.blue.opacity(0.8))
                )
            }
            
            // Reel type indicator
            HStack(spacing: 4) {
                Image(systemName: "play.circle.fill")
                    .font(.system(size: 10))
                Text(reel.type.displayName)
                    .font(.system(size: 11))
            }
            .foregroundColor(.white.opacity(0.7))
        }
        .frame(maxWidth: UIScreen.main.bounds.width * 0.7, alignment: .leading)
    }
    
    // MARK: - Side Action Buttons (Instagram-style vertical)
    private var sideActionButtons: some View {
        VStack(spacing: 20) {
            // Like button
            Button {
                onLike()
            } label: {
                VStack(spacing: 4) {
                    Image(systemName: reel.isLiked ? "heart.fill" : "heart")
                        .font(.system(size: 28))
                        .foregroundColor(reel.isLiked ? .red : .white)
                    
                    Text(formatCount(reel.likesCount))
                        .font(.system(size: 12))
                        .foregroundColor(.white)
                }
            }
            
            // Share button
            Button {
                onShare()
            } label: {
                VStack(spacing: 4) {
                    Image(systemName: "paperplane.fill")
                        .font(.system(size: 26))
                        .foregroundColor(.white)
                    
                    Text(formatCount(reel.sharesCount))
                        .font(.system(size: 12))
                        .foregroundColor(.white)
                }
            }
            
            // Views
            VStack(spacing: 4) {
                Image(systemName: "eye.fill")
                    .font(.system(size: 24))
                    .foregroundColor(.white.opacity(0.8))
                
                Text(formatCount(reel.viewsCount))
                    .font(.system(size: 12))
                    .foregroundColor(.white.opacity(0.8))
            }
            
            // Watch full lesson button (in side bar)
            Button {
                onWatchLesson()
            } label: {
                VStack(spacing: 4) {
                    Image(systemName: "play.rectangle.fill")
                        .font(.system(size: 24))
                        .foregroundColor(.white)
                    
                    Text("Lesson")
                        .font(.system(size: 10))
                        .foregroundColor(.white.opacity(0.8))
                }
            }
        }
        .padding(.bottom, 20)
    }
    
    // MARK: - Watch Full Lesson Button (Instagram link style)
    private var watchLessonButton: some View {
        Button {
            onWatchLesson()
        } label: {
            HStack(spacing: 10) {
                Image(systemName: "play.circle.fill")
                    .font(.system(size: 18))
                
                Text("Watch Full Lesson")
                    .font(.system(size: 14, weight: .semibold))
                
                Image(systemName: "chevron.right")
                    .font(.system(size: 12, weight: .semibold))
            }
            .foregroundColor(.white)
            .padding(.horizontal, 20)
            .padding(.vertical, 12)
            .background(
                Capsule()
                    .fill(
                        LinearGradient(
                            colors: [Color.purple, Color.pink, Color.orange],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
            )
            .shadow(color: .black.opacity(0.3), radius: 8, x: 0, y: 4)
        }
    }
    
    // MARK: - Swipe Up Hint
    private var swipeUpHint: some View {
        VStack(spacing: 8) {
            Image(systemName: "chevron.up")
                .font(.system(size: 20, weight: .semibold))
                .foregroundColor(.white)
                .offset(y: -5)
                .animation(
                    Animation.easeInOut(duration: 0.8).repeatForever(autoreverses: true),
                    value: showSwipeHint
                )
            
            Text("Tap to watch full lesson")
                .font(.system(size: 12, weight: .medium))
                .foregroundColor(.white.opacity(0.9))
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 10)
        .background(
            Capsule()
                .fill(Color.black.opacity(0.5))
        )
    }
    
    // MARK: - Video Player
    @ViewBuilder
    private var videoPlayerView: some View {
        // Try to play actual video if available
        if let videoUrlString = reel.videoUrl {
            if videoUrlString.contains("youtube.com") || videoUrlString.contains("youtu.be") {
                // YouTube video - use iframe API
                if let ytId = extractYouTubeId(from: videoUrlString) {
                    ReelYouTubePlayerView(videoId: ytId, isActive: isActive)
                } else {
                    animatedThumbnailView
                }
            } else if videoUrlString.hasPrefix("vdocipher://") {
                // VdoCipher video - use the reel player with thumbnail fallback
                let videoId = String(videoUrlString.dropFirst("vdocipher://".count))
                VdoCipherReelPlayer(
                    videoId: videoId,
                    isActive: isActive,
                    thumbnailUrl: reel.thumbnailImageURL ?? reel.displayImageURL
                )
            } else if let url = URL(string: videoUrlString) {
                // Direct video URL
                VideoPlayer(player: player)
                    .disabled(true)
                    .onAppear {
                        if isActive {
                            setupPlayer()
                        }
                    }
            } else {
                animatedThumbnailView
            }
        } else {
            // No video URL - show animated thumbnail
            animatedThumbnailView
        }
    }
    
    // MARK: - Animated Thumbnail View
    private var animatedThumbnailView: some View {
        ReelVideoPreview(
            thumbnailUrl: reel.thumbnailImageURL ?? reel.displayImageURL,
            courseName: reel.course?.name ?? reel.title,
            isActive: isActive
        )
    }
    
    // MARK: - Extract YouTube ID
    private func extractYouTubeId(from urlString: String) -> String? {
        // Handle various YouTube URL formats
        if urlString.contains("youtube.com/embed/") {
            let parts = urlString.components(separatedBy: "youtube.com/embed/")
            if parts.count > 1 {
                return parts[1].components(separatedBy: "?").first
            }
        }
        if urlString.contains("youtube.com/watch?v=") {
            let parts = urlString.components(separatedBy: "v=")
            if parts.count > 1 {
                return parts[1].components(separatedBy: "&").first
            }
        }
        if urlString.contains("youtu.be/") {
            let parts = urlString.components(separatedBy: "youtu.be/")
            if parts.count > 1 {
                return parts[1].components(separatedBy: "?").first
            }
        }
        return nil
    }
    
    // MARK: - Image Content
    private var imageContentView: some View {
        AsyncImage(url: reel.displayImageURL) { phase in
            switch phase {
            case .empty:
                ProgressView()
                    .progressViewStyle(CircularProgressViewStyle(tint: .white))
            case .success(let image):
                image
                    .resizable()
                    .aspectRatio(contentMode: .fill)
            case .failure:
                thumbnailView
            @unknown default:
                thumbnailView
            }
        }
    }
    
    // MARK: - Thumbnail Fallback
    private var thumbnailView: some View {
        AsyncImage(url: reel.thumbnailImageURL) { phase in
            switch phase {
            case .success(let image):
                image
                    .resizable()
                    .aspectRatio(contentMode: .fill)
            default:
                Color.gray.opacity(0.3)
                    .overlay(
                        Image(systemName: "play.circle.fill")
                            .font(.system(size: 50))
                            .foregroundColor(.white.opacity(0.7))
                    )
            }
        }
    }
    
    // MARK: - Helper Methods
    private func setupPlayer() {
        guard let url = reel.videoURL else { return }
        
        if player == nil {
            player = AVPlayer(url: url)
            player?.actionAtItemEnd = .none
            
            NotificationCenter.default.addObserver(
                forName: .AVPlayerItemDidPlayToEndTime,
                object: player?.currentItem,
                queue: .main
            ) { _ in
                player?.seek(to: .zero)
                player?.play()
            }
        }
        
        player?.play()
    }
    
    private func handleDoubleTap() {
        withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) {
            showLikeAnimation = true
        }
        
        if !reel.isLiked {
            onLike()
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.8) {
            withAnimation {
                showLikeAnimation = false
            }
        }
    }
    
    private func formatCount(_ count: Int) -> String {
        if count >= 1_000_000 {
            return String(format: "%.1fM", Double(count) / 1_000_000)
        } else if count >= 1_000 {
            return String(format: "%.1fK", Double(count) / 1_000)
        }
        return "\(count)"
    }
}

// MARK: - Reel Video Preview (Animated Thumbnail)
struct ReelVideoPreview: View {
    let thumbnailUrl: URL?
    let courseName: String
    @State var isActive: Bool
    
    @State private var animationProgress: CGFloat = 0
    @State private var showPlayIcon: Bool = true
    @State private var pulseScale: CGFloat = 1.0
    @State private var shimmerOffset: CGFloat = -1
    
    var body: some View {
        ZStack {
            // Background thumbnail
            AsyncImage(url: thumbnailUrl) { phase in
                switch phase {
                case .success(let image):
                    image
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                        .overlay(
                            // Animated gradient overlay
                            LinearGradient(
                                colors: [
                                    Color.black.opacity(0.3),
                                    Color.clear,
                                    Color.black.opacity(0.5)
                                ],
                                startPoint: .top,
                                endPoint: .bottom
                            )
                        )
                case .empty:
                    gradientBackground
                        .overlay(shimmerEffect)
                case .failure:
                    gradientBackground
                @unknown default:
                    gradientBackground
                }
            }
            
            // Animated content overlay
            VStack(spacing: 20) {
                Spacer()
                
                // Pulsing play icon
                if showPlayIcon {
                    Image(systemName: "play.circle.fill")
                        .font(.system(size: 80))
                        .foregroundStyle(.white.opacity(0.9))
                        .scaleEffect(pulseScale)
                        .shadow(color: .black.opacity(0.3), radius: 10, x: 0, y: 5)
                }
                
                Spacer()
                
                // Animated progress bar (simulates video timeline)
                VStack(spacing: 8) {
                    // Mini course name
                    Text(courseName)
                        .font(.caption)
                        .fontWeight(.semibold)
                        .foregroundColor(.white)
                        .lineLimit(1)
                    
                    // Progress bar
                    GeometryReader { geo in
                        ZStack(alignment: .leading) {
                            // Background track
                            RoundedRectangle(cornerRadius: 2)
                                .fill(Color.white.opacity(0.3))
                                .frame(height: 4)
                            
                            // Progress fill
                            RoundedRectangle(cornerRadius: 2)
                                .fill(
                                    LinearGradient(
                                        colors: [.purple, .pink, .orange],
                                        startPoint: .leading,
                                        endPoint: .trailing
                                    )
                                )
                                .frame(width: geo.size.width * animationProgress, height: 4)
                        }
                    }
                    .frame(height: 4)
                    
                    // Time indicator
                    HStack {
                        Text(timeString(from: animationProgress * 60))
                            .font(.caption2)
                            .foregroundColor(.white.opacity(0.8))
                        Spacer()
                        Text("1:00")
                            .font(.caption2)
                            .foregroundColor(.white.opacity(0.8))
                    }
                }
                .padding(.horizontal, 40)
                .padding(.bottom, 100)
            }
        }
        .onAppear {
            if isActive {
                startAnimations()
            }
        }
        .onChange(of: isActive) { newValue in
            if newValue {
                startAnimations()
            } else {
                stopAnimations()
            }
        }
    }
    
    // MARK: - Gradient Background
    private var gradientBackground: some View {
        LinearGradient(
            colors: [
                Color.purple.opacity(0.8),
                Color.blue.opacity(0.6),
                Color.indigo.opacity(0.9)
            ],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }
    
    // MARK: - Shimmer Effect
    private var shimmerEffect: some View {
        GeometryReader { geo in
            LinearGradient(
                colors: [
                    Color.white.opacity(0),
                    Color.white.opacity(0.3),
                    Color.white.opacity(0)
                ],
                startPoint: .leading,
                endPoint: .trailing
            )
            .frame(width: geo.size.width * 0.4)
            .offset(x: geo.size.width * shimmerOffset)
        }
        .mask(Rectangle())
    }
    
    // MARK: - Animations
    private func startAnimations() {
        // Play icon pulse animation
        withAnimation(.easeInOut(duration: 0.8).repeatForever(autoreverses: true)) {
            pulseScale = 1.2
        }
        
        // Progress bar animation (loops every 10 seconds)
        withAnimation(.linear(duration: 10).repeatForever(autoreverses: false)) {
            animationProgress = 1.0
        }
        
        // Shimmer animation
        withAnimation(.linear(duration: 2).repeatForever(autoreverses: false)) {
            shimmerOffset = 2
        }
        
        // Hide play icon after a moment
        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
            withAnimation(.easeOut(duration: 0.3)) {
                showPlayIcon = false
            }
        }
    }
    
    private func stopAnimations() {
        pulseScale = 1.0
        animationProgress = 0
        showPlayIcon = true
        shimmerOffset = -1
    }
    
    private func timeString(from seconds: CGFloat) -> String {
        let mins = Int(seconds) / 60
        let secs = Int(seconds) % 60
        return String(format: "%d:%02d", mins, secs)
    }
}

// MARK: - Share Sheet
struct ShareSheet: UIViewControllerRepresentable {
    let activityItems: [Any]
    
    func makeUIViewController(context: Context) -> UIActivityViewController {
        UIActivityViewController(activityItems: activityItems, applicationActivities: nil)
    }
    
    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
}

// MARK: - Reel Lesson Full Screen View (Opens lesson from Reel)
struct ReelLessonFullScreenView: View {
    let courseId: String
    let courseName: String
    @Environment(\.dismiss) private var dismiss
    @State private var isLoading = true
    @State private var errorMessage: String?
    @State private var lesson: Lesson?
    
    private let lessonService = DIContainer.shared.lessonService
    
    var body: some View {
        NavigationStack {
            Group {
                if isLoading {
                    VStack(spacing: 20) {
                        ProgressView()
                            .scaleEffect(1.5)
                        Text("Loading \(courseName)...")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .background(Color(.systemGroupedBackground))
                } else if let error = errorMessage {
                    VStack(spacing: 16) {
                        Image(systemName: "exclamationmark.triangle.fill")
                            .font(.system(size: 50))
                            .foregroundColor(.orange)
                        Text("Failed to load lesson")
                            .font(.headline)
                        Text(error)
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal)
                        Button("Try Again") {
                            Task { await loadLesson() }
                        }
                        .buttonStyle(.borderedProminent)
                        
                        Button("Close") {
                            dismiss()
                        }
                        .foregroundColor(.secondary)
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .background(Color(.systemGroupedBackground))
                } else {
                    // Successfully loaded - show LessonsView
                    LessonsView(
                        courseId: courseId,
                        accessType: .publicCourse,
                        isOwned: true,
                        lessonService: lessonService
                    )
                }
            }
            .navigationTitle(courseName)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button {
                        dismiss()
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .font(.system(size: 28))
                            .symbolRenderingMode(.hierarchical)
                            .foregroundStyle(.gray)
                    }
                }
            }
        }
        .task {
            await loadLesson()
        }
    }
    
    private func loadLesson() async {
        isLoading = true
        errorMessage = nil
        
        print("📚 [ReelLessonFullScreenView] Starting to load lesson for courseId: \(courseId)")
        
        do {
            // Pre-fetch to verify the course exists
            let fetchedLesson = try await lessonService.fetchLesson(courseId: courseId, accessType: .publicCourse)
            print("✅ [ReelLessonFullScreenView] Lesson loaded successfully: \(fetchedLesson.title)")
            
            await MainActor.run {
                self.lesson = fetchedLesson
                self.isLoading = false
            }
        } catch {
            print("❌ [ReelLessonFullScreenView] Failed to load lesson: \(error)")
            await MainActor.run {
                self.errorMessage = error.localizedDescription
                self.isLoading = false
            }
        }
    }
}

// MARK: - Preview
struct ReelsView_Previews: PreviewProvider {
    static var previews: some View {
        ReelsView(reelService: MockReelService())
    }
}
