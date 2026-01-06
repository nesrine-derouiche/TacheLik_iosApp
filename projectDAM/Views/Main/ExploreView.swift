import SwiftUI
import AVKit
import Combine

/// Explore (Reels) feed.
///
/// UI is rebuilt from scratch to provide a modern, vertically paging reels experience.
/// All data flow and behaviors remain driven by `ReelsViewModel`.
struct ExploreView: View {
    @StateObject private var viewModel = ReelsViewModel()
    @StateObject private var networkMonitor = NetworkMonitor()

    @State private var currentReelId: String?
    @State private var seenReelIds: Set<String> = []

    var body: some View {
        GeometryReader { geo in
            let size = geo.size
            let safeArea = geo.safeAreaInsets

            ZStack {
                Color.reelsBackground.ignoresSafeArea()

                if viewModel.isLoading && viewModel.reels.isEmpty {
                    ReelsLoadingStateView()
                } else if let error = viewModel.error, viewModel.reels.isEmpty {
                    ReelsErrorStateView(message: error) {
                        Task { await viewModel.loadInitialReels() }
                    }
                } else if viewModel.reels.isEmpty {
                    ReelsEmptyStateView {
                        Task { await viewModel.loadInitialReels() }
                    }
                } else {
                    ReelsVerticalPagerView(
                        reels: viewModel.reels,
                        currentReelId: $currentReelId,
                        onCurrentIndexChanged: { index in
                            viewModel.managePreloading(currentIndex: index)
                            let activeId = viewModel.reels.indices.contains(index) ? viewModel.reels[index].id : nil
                            viewModel.pauseAllPlayers(except: activeId)
                        },
                        reelContent: { reel in
                            if reel.id == Reel.endOfFeed.id {
                                EndOfFeedView()
                                    .frame(width: size.width, height: size.height)
                            } else {
                                ReelCellView(
                                    reel: reel,
                                    viewModel: viewModel,
                                    containerSize: size,
                                    safeAreaInsets: safeArea,
                                    isActive: currentReelId == reel.id
                                )
                                .frame(width: size.width, height: size.height)
                                .onAppear {
                                    Task { await viewModel.loadMoreReels(currentItemId: reel.id) }
                                }
                            }
                        }
                    )
                    .frame(width: size.width, height: size.height)
                    .ignoresSafeArea()
                    .onChange(of: viewModel.reels) { newReels in
                        guard let first = newReels.first else { return }

                        if currentReelId == nil {
                            currentReelId = first.id
                            viewModel.managePreloading(currentIndex: 0)
                            viewModel.pauseAllPlayers(except: first.id)
                            return
                        }

                        // When newly generated reels are inserted at the top, smoothly scroll to them once.
                        if currentReelId != first.id && !seenReelIds.contains(first.id) {
                            withAnimation(.easeInOut(duration: 0.25)) {
                                currentReelId = first.id
                            }
                            viewModel.managePreloading(currentIndex: 0)
                            viewModel.pauseAllPlayers(except: first.id)
                            seenReelIds.insert(first.id)
                            print("[ExploreView] 🎬 Scrolled to newly generated reel: \(first.id)")
                        }
                    }
                }

                if !networkMonitor.isOnline {
                    VStack {
                        OfflineBanner(subtitle: "Connect to the internet for best playback")
                            .padding(.top, safeArea.top + 10)
                            .padding(.horizontal, 16)
                        Spacer()
                    }
                    .transition(.move(edge: .top).combined(with: .opacity))
                }
            }
        }
        .onAppear {
            Task { await viewModel.loadInitialReels() }
        }
        .onDisappear {
            viewModel.stopAllPlayers()
        }
        .statusBar(hidden: true)
        .appHideNavigationBar()
    }
}

// MARK: - Vertical Paging Container

private struct ReelsVerticalPagerView<Content: View>: View {
    let reels: [Reel]
    @Binding var currentReelId: String?
    let onCurrentIndexChanged: (Int) -> Void
    let reelContent: (Reel) -> Content

    init(
        reels: [Reel],
        currentReelId: Binding<String?>,
        onCurrentIndexChanged: @escaping (Int) -> Void,
        @ViewBuilder reelContent: @escaping (Reel) -> Content
    ) {
        self.reels = reels
        self._currentReelId = currentReelId
        self.onCurrentIndexChanged = onCurrentIndexChanged
        self.reelContent = reelContent
    }

    var body: some View {
        if #available(iOS 17.0, *) {
            GeometryReader { geo in
                ScrollView(.vertical) {
                    LazyVStack(spacing: 0) {
                        ForEach(reels) { reel in
                            reelContent(reel)
                                .frame(width: geo.size.width, height: geo.size.height)
                                .id(reel.id)
                        }
                    }
                    .scrollTargetLayout()
                }
                .scrollTargetBehavior(.paging)
                .scrollIndicators(.hidden)
                .scrollPosition(id: $currentReelId)
                .onChange(of: currentReelId) { _, newValue in
                    guard let newValue else { return }
                    if let index = reels.firstIndex(where: { $0.id == newValue }) {
                        onCurrentIndexChanged(index)
                    }
                }
            }
        } else {
            // iOS 16 fallback: TabView rotated to vertical paging.
            // The cell UI is still the new design; the paging mechanism is the only fallback.
            GeometryReader { geo in
                let w = geo.size.width
                let h = geo.size.height

                TabView(selection: $currentReelId) {
                    ForEach(reels) { reel in
                        reelContent(reel)
                            .frame(width: w, height: h)
                            .rotationEffect(.degrees(-90))
                            .frame(width: h, height: w)
                            .tag(Optional(reel.id))
                    }
                }
                .frame(width: h, height: w)
                .rotationEffect(.degrees(90), anchor: .center)
                .frame(width: w, height: h)
                .tabViewStyle(.page(indexDisplayMode: .never))
                .onChange(of: currentReelId) { newValue in
                    guard let newValue else { return }
                    if let index = reels.firstIndex(where: { $0.id == newValue }) {
                        onCurrentIndexChanged(index)
                    }
                }
            }
        }
    }
}

// MARK: - Reel Cell (New UI)

private struct ReelCellView: View {
    let reel: Reel
    @ObservedObject var viewModel: ReelsViewModel
    let containerSize: CGSize
    let safeAreaInsets: EdgeInsets
    let isActive: Bool

    @State private var player: AVPlayer?
    @State private var isPlaying = true
    @State private var showPlayIcon = false
    @State private var showComments = false

    // Bottom padding that accounts for the custom tab bar area + safe area
    private var bottomOverlayPadding: CGFloat {
        max(safeAreaInsets.bottom, 16) + 92
    }

    var body: some View {
        ZStack {
            Color.reelsBackground

            // Video layer (always centered and aspect-fill)
            ZStack {
                if let player {
                    PlayerView(player: player)
                        .contentShape(Rectangle())
                        .onTapGesture { togglePlayback() }
                        .onReceive(NotificationCenter.default.publisher(for: .AVPlayerItemDidPlayToEndTime, object: player.currentItem)) { _ in
                            // Loop seamlessly.
                            player.seek(to: .zero)
                            if isActive && isPlaying {
                                player.play()
                            }
                        }
                        .onAppear {
                            applyActivePlaybackState(shouldAutoPlay: true)
                        }
                        .onDisappear { player.pause() }
                } else {
                    ReelsVideoSkeletonView()
                }

                // Subtle top/bottom scrims for readability
                VStack(spacing: 0) {
                    LinearGradient(
                        colors: [Color.black.opacity(0.55), Color.black.opacity(0.0)],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                    .frame(height: max(120, safeAreaInsets.top + 84))

                    Spacer()

                    LinearGradient(
                        colors: [Color.black.opacity(0.0), Color.black.opacity(0.7)],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                    .frame(height: 240)
                }
                .allowsHitTesting(false)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
            .clipped()

            // Center play icon (tap-to-pause)
            if showPlayIcon {
                Image(systemName: "play.fill")
                    .font(.system(size: 64, weight: .semibold))
                    .foregroundColor(.white.opacity(0.85))
                    .shadow(color: .black.opacity(0.6), radius: 10, x: 0, y: 4)
                    .transition(.opacity.combined(with: .scale))
                    .allowsHitTesting(false)
            }

            // Overlays
            VStack(spacing: 0) {
                Spacer()

                HStack(alignment: .bottom, spacing: 16) {
                    ReelCaptionView(reel: reel)

                    Spacer(minLength: 0)

                    ReelActionsColumn(
                        reel: reel,
                        onLike: { Task { await viewModel.toggleLike(reel: reel) } },
                        onComments: { showComments = true },
                        onBookmark: { Task { await viewModel.toggleBookmark(reel: reel) } }
                    )
                }
                .padding(.horizontal, 16)
                .padding(.bottom, bottomOverlayPadding)
            }
        }
        .frame(width: containerSize.width, height: containerSize.height)
        .clipped()
        .onAppear {
            setupPlayer()
            applyActivePlaybackState(shouldAutoPlay: true)
        }
        .onDisappear {
            player?.pause()
            showPlayIcon = false
        }
        .onChange(of: isActive) { _, _ in
            applyActivePlaybackState(shouldAutoPlay: true)
        }
        .sheet(isPresented: $showComments) {
            if #available(iOS 16.0, *) {
                CommentsSheet(reelId: reel.id) { newCount in
                    viewModel.updateReelCommentCount(reelId: reel.id, newCount: newCount)
                }
                .presentationDetents([.medium, .large])
                .presentationDragIndicator(.visible)
            } else {
                CommentsSheet(reelId: reel.id) { newCount in
                    viewModel.updateReelCommentCount(reelId: reel.id, newCount: newCount)
                }
            }
        }
    }

    private func setupPlayer() {
        let player = viewModel.getPlayer(for: reel)
        self.player = player

        // Prefer a Reels-like audio experience (single source, consistent start/pause/resume).
        try? AVAudioSession.sharedInstance().setCategory(.playback, mode: .moviePlayback)
        try? AVAudioSession.sharedInstance().setActive(true)
    }

    private func applyActivePlaybackState(shouldAutoPlay: Bool) {
        guard let player else { return }

        if isActive {
            if shouldAutoPlay {
                isPlaying = true
                showPlayIcon = false
            }
            player.isMuted = false
            player.volume = 1
            if isPlaying {
                player.play()
            }
        } else {
            player.pause()
            player.isMuted = true
            player.volume = 0
            showPlayIcon = false
        }
    }

    private func togglePlayback() {
        guard isActive else { return }
        withAnimation(.easeInOut(duration: 0.18)) {
            isPlaying.toggle()
            showPlayIcon = !isPlaying
        }

        if isPlaying {
            player?.play()
        } else {
            player?.pause()
        }
    }
}

private struct ReelCaptionView: View {
    let reel: Reel

    @State private var isDescriptionExpanded = false
    @State private var showAudioDetails = false

    private var trimmedDescription: String? {
        guard let description = reel.description?
            .trimmingCharacters(in: .whitespacesAndNewlines),
            !description.isEmpty
        else {
            return nil
        }
        return description
    }

    private var audioDisplayText: String {
        if let id = reel.videoId, !id.isEmpty {
            return "Original audio • \(id)"
        }
        if let urlString = reel.originalVideoUrl, let url = URL(string: urlString) {
            let host = url.host?.replacingOccurrences(of: "www.", with: "")
            if let host, !host.isEmpty {
                return "Original audio • \(host)"
            }
            let last = url.lastPathComponent
            if !last.isEmpty {
                return "Original audio • \(last)"
            }
        }
        if let filePath = reel.filePath, let last = filePath.components(separatedBy: "/").last, !last.isEmpty {
            return "Original audio • \(last)"
        }
        return "Original audio"
    }

    private var audioDetailsMessage: String {
        var lines: [String] = []

        if let id = reel.videoId, !id.isEmpty {
            lines.append("Video ID: \(id)")
        }
        if let start = reel.startTime, !start.isEmpty {
            lines.append("Start: \(start)")
        }
        if let end = reel.endTime, !end.isEmpty {
            lines.append("End: \(end)")
        }
        if let url = reel.originalVideoUrl, !url.isEmpty {
            lines.append("Source: \(url)")
        }
        if let filePath = reel.filePath, !filePath.isEmpty {
            lines.append("File: \(filePath)")
        }

        return lines.isEmpty ? "No audio details available for this reel." : lines.joined(separator: "\n")
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            let createdDate = ReelRelativeTimestampView.parseCreatedAt(reel.createdAt)

            if let title = reel.title, !title.isEmpty {
                HStack(alignment: .firstTextBaseline, spacing: 6) {
                    Text(title)
                        .font(.headline)
                        .foregroundStyle(.white)
                        .lineLimit(1)

                    if let createdDate {
                        Text("•")
                            .font(.caption)
                            .foregroundStyle(.white.opacity(0.75))
                            .accessibilityHidden(true)

                        ReelRelativeTimestampView(createdAt: reel.createdAt ?? "")
                    }
                }
            } else if let createdDate {
                ReelRelativeTimestampView(createdAt: reel.createdAt ?? "")
            }

            if let description = trimmedDescription {
                Text(description)
                    .font(.subheadline)
                    .foregroundStyle(.white.opacity(0.95))
                    .lineLimit(isDescriptionExpanded ? nil : 2)
                    .animation(.spring(response: 0.28, dampingFraction: 0.86), value: isDescriptionExpanded)
                    .onTapGesture {
                        withAnimation(.spring(response: 0.28, dampingFraction: 0.86)) {
                            isDescriptionExpanded.toggle()
                        }
                    }
                    .accessibilityAddTraits(.isButton)
            }

            Button {
                showAudioDetails = true
            } label: {
                HStack(spacing: 6) {
                    Image(systemName: "music.note")
                        .font(.caption)
                    Text(audioDisplayText)
                        .font(.caption)
                        .lineLimit(1)
                }
                .foregroundStyle(.white.opacity(0.9))
            }
            .buttonStyle(.plain)
            .alert("Audio", isPresented: $showAudioDetails) {
                Button("OK", role: .cancel) {}
            } message: {
                Text(audioDetailsMessage)
            }
        }
        .shadow(color: .black.opacity(0.6), radius: 6, x: 0, y: 2)
        .frame(maxWidth: 420, alignment: .leading)
    }
}

private struct ReelActionsColumn: View {
    let reel: Reel
    let onLike: () -> Void
    let onComments: () -> Void
    let onBookmark: () -> Void

    private var likesTitle: String {
        if let count = reel.likesCount { return "\(count)" }
        return "—"
    }

    private var commentsTitle: String {
        if let count = reel.commentsCount { return "\(count)" }
        return "—"
    }

    var body: some View {
        VStack(spacing: 18) {
            ReelActionButton(
                systemImage: "heart.fill",
                title: likesTitle,
                isSelected: reel.isLiked ?? false,
                selectedTint: .red,
                action: onLike
            )

            ReelActionButton(
                systemImage: "bubble.right.fill",
                title: commentsTitle,
                isSelected: false,
                selectedTint: .brandPrimary,
                action: onComments
            )

            ReelActionButton(
                systemImage: (reel.isBookmarked ?? false) ? "bookmark.fill" : "bookmark",
                title: (reel.isBookmarked ?? false) ? "Saved" : "Save",
                isSelected: reel.isBookmarked ?? false,
                selectedTint: .brandWarning,
                action: onBookmark
            )
        }
    }
}

private struct ReelActionButton: View {
    let systemImage: String
    let title: String
    let isSelected: Bool
    let selectedTint: Color
    let action: () -> Void

    @State private var pressed = false

    var body: some View {
        Button {
            let impact = UIImpactFeedbackGenerator(style: .light)
            impact.impactOccurred()

            withAnimation(.spring(response: 0.25, dampingFraction: 0.7)) {
                pressed = true
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.12) {
                withAnimation(.spring(response: 0.25, dampingFraction: 0.7)) {
                    pressed = false
                }
            }

            action()
        } label: {
            VStack(spacing: 6) {
                Image(systemName: systemImage)
                    .font(.system(size: 28, weight: .semibold))
                    .foregroundStyle(isSelected ? selectedTint : .white)
                    .shadow(color: .black.opacity(0.5), radius: 6, x: 0, y: 2)
                    .scaleEffect(pressed ? 0.86 : (isSelected ? 1.08 : 1.0))

                Text(title)
                    .font(.caption)
                    .fontWeight(.semibold)
                    .foregroundStyle(isSelected ? selectedTint : .white)
                    .monospacedDigit()
                    .shadow(color: .black.opacity(0.5), radius: 4, x: 0, y: 1)
            }
            .frame(width: 64)
        }
        .buttonStyle(.plain)
    }
}

// MARK: - States

private struct ReelsLoadingStateView: View {
    var body: some View {
        VStack(spacing: 14) {
            ProgressView()
                .tint(.white)
                .scaleEffect(1.25)

            Text("Loading reels…")
                .font(.subheadline)
                .foregroundStyle(.white.opacity(0.9))
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.reelsBackground)
    }
}

private struct ReelsErrorStateView: View {
    let message: String
    let onRetry: () -> Void

    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: "exclamationmark.triangle.fill")
                .font(.system(size: 40, weight: .semibold))
                .foregroundStyle(Color.brandWarning)

            Text("Something went wrong")
                .font(.headline)
                .foregroundStyle(.white)

            Text(message)
                .font(.subheadline)
                .foregroundStyle(.white.opacity(0.85))
                .multilineTextAlignment(.center)
                .padding(.horizontal, 24)

            Button("Retry") { onRetry() }
                .font(.headline)
                .foregroundStyle(.black)
                .padding(.horizontal, 18)
                .padding(.vertical, 10)
                .background(Color.white)
                .clipShape(Capsule())
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.reelsBackground)
    }
}

private struct ReelsEmptyStateView: View {
    let onRefresh: () -> Void

    var body: some View {
        VStack(spacing: 14) {
            Image(systemName: "film")
                .font(.system(size: 42, weight: .semibold))
                .foregroundStyle(.white.opacity(0.9))

            Text("No reels yet")
                .font(.headline)
                .foregroundStyle(.white)

            Button("Refresh") { onRefresh() }
                .font(.headline)
                .foregroundStyle(.black)
                .padding(.horizontal, 18)
                .padding(.vertical, 10)
                .background(Color.white)
                .clipShape(Capsule())
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.reelsBackground)
    }
}

private struct ReelsVideoSkeletonView: View {
    @State private var animate = false

    var body: some View {
        ZStack {
            Color.reelsBackground

            VStack(spacing: 12) {
                ZStack {
                    Circle()
                        .stroke(Color.white.opacity(0.18), lineWidth: 3)
                        .frame(width: 46, height: 46)

                    Circle()
                        .trim(from: 0, to: 0.68)
                        .stroke(
                            LinearGradient.brandPrimaryGradient,
                            style: StrokeStyle(lineWidth: 3, lineCap: .round)
                        )
                        .frame(width: 46, height: 46)
                        .rotationEffect(.degrees(animate ? 360 : 0))
                }

                Text("Loading…")
                    .font(.caption)
                    .foregroundStyle(.white.opacity(0.75))
            }
        }
        .onAppear {
            withAnimation(.linear(duration: 1.0).repeatForever(autoreverses: false)) {
                animate = true
            }
        }
    }
}

// MARK: - End of Feed

private struct EndOfFeedView: View {
    var body: some View {
        VStack(spacing: 14) {
            Image(systemName: "sparkles")
                .font(.system(size: 52, weight: .semibold))
                .foregroundStyle(Color.brandWarning)

            Text("You’re all caught up")
                .font(.title2)
                .fontWeight(.bold)
                .foregroundStyle(.white)

            Text("More reels coming soon")
                .font(.subheadline)
                .foregroundStyle(.white.opacity(0.75))
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.reelsBackground)
    }
}

#Preview {
    ExploreView()
}
