//
//  BookmarksView.swift
//  projectDAM
//
//  Created by Antigravity on 12/08/2025.
//

import SwiftUI
import AVKit
import Combine

struct BookmarksView: View {
    @StateObject private var viewModel = BookmarksViewModel()
    @State private var currentReelId: String?
    @StateObject private var networkMonitor = NetworkMonitor()
    @State private var hasAppeared = false
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        GeometryReader { geo in
            let size = geo.size
            let safeArea = geo.safeAreaInsets

            ZStack {
                Color.reelsBackground.ignoresSafeArea()

                if viewModel.isLoading && viewModel.bookmarkedReels.isEmpty {
                    ReelsLoadingStateView()
                } else if let error = viewModel.error, viewModel.bookmarkedReels.isEmpty {
                    ReelsErrorStateView(message: error) {
                        Task { await viewModel.loadBookmarks() }
                    }
                } else if viewModel.bookmarkedReels.isEmpty {
                    ReelsEmptyStateView {
                        Task { await viewModel.loadBookmarks() }
                    }
                } else {
                    ReelsVerticalPagerView(
                        reels: viewModel.bookmarkedReels,
                        currentReelId: $currentReelId,
                        onCurrentIndexChanged: { index in
                            viewModel.managePreloading(currentIndex: index)
                            let activeId = viewModel.bookmarkedReels.indices.contains(index)
                                ? viewModel.bookmarkedReels[index].id
                                : nil
                            viewModel.pauseAllPlayers(except: activeId)
                        },
                        reelContent: { reel in
                            ReelCellView(
                                reel: reel,
                                viewModel: viewModel,
                                containerSize: size,
                                safeAreaInsets: safeArea,
                                isActive: currentReelId == reel.id
                            )
                            .frame(width: size.width, height: size.height)
                        }
                    )
                    .frame(width: size.width, height: size.height)
                    .ignoresSafeArea()
                }

                // Top bar overlay
                VStack {
                    savedTopBar(safeArea: safeArea)
                    Spacer()
                }
                .zIndex(100)

                if !networkMonitor.isOnline {
                    VStack {
                        OfflineBanner(subtitle: "Connect to the internet for best playback")
                            .padding(.top, safeArea.top + 10)
                            .padding(.horizontal, 16)
                        Spacer()
                    }
                    .transition(.move(edge: .top).combined(with: .opacity))
                    .zIndex(1000)
                }
            }
            .onChange(of: viewModel.bookmarkedReels) { _, newReels in
                guard let first = newReels.first else {
                    currentReelId = nil
                    viewModel.stopAllPlayers()
                    return
                }

                if currentReelId == nil {
                    currentReelId = first.id
                    viewModel.managePreloading(currentIndex: 0)
                    viewModel.pauseAllPlayers(except: first.id)
                    return
                }

                if let currentId = currentReelId,
                   newReels.firstIndex(where: { $0.id == currentId }) == nil {
                    currentReelId = first.id
                    viewModel.managePreloading(currentIndex: 0)
                    viewModel.pauseAllPlayers(except: first.id)
                }
            }
            .onChange(of: currentReelId) { _, newId in
                viewModel.pauseAllPlayers(except: newId)
            }
        }
        .appHideNavigationBar()
        .ignoresSafeArea()
        .onAppear {
            guard !hasAppeared else { return }
            hasAppeared = true
            Task { await viewModel.loadBookmarks() }
        }
        .onDisappear {
            viewModel.stopAllPlayers()
        }
        .statusBar(hidden: true)
    }

    private func savedTopBar(safeArea: EdgeInsets) -> some View {
        HStack {
            Button {
                dismiss()
            } label: {
                Image(systemName: "chevron.left")
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundStyle(.white)
                    .frame(width: 36, height: 36)
                    .background(Color.black.opacity(0.5))
                    .clipShape(Circle())
            }

            Spacer()

            Text("Saved Reels")
                .font(.system(size: 18, weight: .bold))
                .foregroundStyle(.white)

            Spacer()

            Color.clear
                .frame(width: 36, height: 36)
        }
        .padding(.horizontal, 16)
        .padding(.top, max(safeArea.top, 44) + 4)
    }

}

/*
    // MARK: - Top Bar
        private func topBar(safeAreaTop: CGFloat) -> some View {
        HStack {
            Button {
                dismiss()
            } label: {
                Image(systemName: "chevron.left")
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundStyle(.white)
                    .frame(width: 40, height: 40)
                    .background(Color.black.opacity(0.5))
                    .clipShape(Circle())
            }
            
            Spacer()
            
            Text("Saved Reels")
                .font(.system(size: 18, weight: .bold))
                .foregroundStyle(.white)
            
            Spacer()
            
            Color.clear
                .frame(width: 40, height: 40)
        }
        .padding(.horizontal, 16)
        .padding(.top, max(safeAreaTop, 44) + 4)
    }
    
    // MARK: - Loading View
    private var loadingView: some View {
        VStack(spacing: 20) {
            ZStack {
                Circle()
                    .stroke(Color.gray.opacity(0.3), lineWidth: 4)
                    .frame(width: 60, height: 60)
                
                Circle()
                    .trim(from: 0, to: 0.7)
                    .stroke(
                        LinearGradient(
                            colors: [.yellow, .orange],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        style: StrokeStyle(lineWidth: 4, lineCap: .round)
                    )
                    .frame(width: 60, height: 60)
                    .rotationEffect(.degrees(-90))
                    .modifier(RotatingModifier())
            }
            
            Text("Loading saved reels...")
                .font(.subheadline)
                        @StateObject private var networkMonitor = NetworkMonitor()
                .foregroundStyle(.gray)
        }
                        @State private var hasAppeared = false
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
                            GeometryReader { geo in
                                let size = geo.size
                                let safeArea = geo.safeAreaInsets

                                ZStack {
                                    Color.black.ignoresSafeArea()

                                    if viewModel.isLoading && viewModel.bookmarkedReels.isEmpty {
                                        ReelsLoadingStateView()
                                    } else if let error = viewModel.error, viewModel.bookmarkedReels.isEmpty {
                                        ReelsErrorStateView(message: error) {
                                            Task { await viewModel.loadBookmarks() }
                                        }
                                    } else if viewModel.bookmarkedReels.isEmpty {
                                        ReelsEmptyStateView {
                                            Task { await viewModel.loadBookmarks() }
                                        }
                                    } else {
                                        ReelsVerticalPagerView(
                                            reels: viewModel.bookmarkedReels,
                                            currentReelId: $currentReelId,
                                            onCurrentIndexChanged: { index in
                                                viewModel.managePreloading(currentIndex: index)
                                                let activeId = viewModel.bookmarkedReels.indices.contains(index) ? viewModel.bookmarkedReels[index].id : nil
                                                viewModel.pauseAllPlayers(except: activeId)
                                            },
                                            reelContent: { reel in
                                                ReelCellView(
                                                    reel: reel,
                                                    viewModel: viewModel,
                                                    containerSize: size,
                                                    safeAreaInsets: safeArea,
                                                    isActive: currentReelId == reel.id
                                                )
                                                .frame(width: size.width, height: size.height)
                                            }
                                        )
                                        .frame(width: size.width, height: size.height)
                                        .ignoresSafeArea()
                                    }

                                    // Top bar overlay
                                    VStack {
                                        savedTopBar(safeArea: safeArea)
                                        Spacer()
                                    }
                                    .zIndex(100)

                                    if !networkMonitor.isOnline {
                                        VStack {
                                            OfflineBanner(subtitle: "Connect to the internet for best playback")
                                                .padding(.top, safeArea.top + 10)
                                                .padding(.horizontal, 16)
                                            Spacer()
                                        }
                                        .transition(.move(edge: .top).combined(with: .opacity))
                                        .zIndex(1000)
                                    }
                                }
                                .onChange(of: viewModel.bookmarkedReels) { _, newReels in
                                    guard let first = newReels.first else {
                                        currentReelId = nil
                                        viewModel.stopAllPlayers()
                                        return
                                    }

                                    if currentReelId == nil {
                                        currentReelId = first.id
                                        viewModel.managePreloading(currentIndex: 0)
                                        viewModel.pauseAllPlayers(except: first.id)
                                        return
                                    }

                                    if let currentId = currentReelId,
                                       newReels.firstIndex(where: { $0.id == currentId }) == nil {
                                        // Current reel got removed (e.g. un-saved). Move to the next best candidate.
                                        currentReelId = first.id
                                        viewModel.managePreloading(currentIndex: 0)
                                        viewModel.pauseAllPlayers(except: first.id)
                                    }
                                }
                            }
                            .appHideNavigationBar()
                            .ignoresSafeArea()
                            .onAppear {
                                guard !hasAppeared else { return }
                                hasAppeared = true
                                Task { await viewModel.loadBookmarks() }
                            }
                            .onDisappear {
                                viewModel.stopAllPlayers()
                            }
                            .statusBar(hidden: true)
    // MARK: - Empty State View
    private var emptyStateView: some View {
                        // MARK: - Top Bar
                        private func savedTopBar(safeArea: EdgeInsets) -> some View {
                Circle()
                    .fill(Color.yellow.opacity(0.15))
                    .frame(width: 100, height: 100)
                
                Image(systemName: "bookmark")
                    .font(.system(size: 44))
                    .foregroundStyle(.yellow)
                                        .frame(width: 36, height: 36)
            
            VStack(spacing: 8) {
                Text("No Saved Reels")
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundStyle(.white)
                
                Text("Reels you save will appear here.\nStart exploring and save your favorites!")
                    .font(.subheadline)
                    .foregroundStyle(.gray)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 32)
            }
                                    .frame(width: 36, height: 36)
            Button {
                dismiss()
                            .padding(.top, safeArea.top + 8)
                HStack(spacing: 10) {
                    Image(systemName: "safari.fill")
                    Text("Explore Reels")
                }
                .fontWeight(.bold)
                .foregroundStyle(.white)
                .padding(.horizontal, 32)
                .padding(.vertical, 14)
                .background(
                    LinearGradient(
                        colors: [.brandPrimary, .purple],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
                .cornerRadius(16)
                .shadow(color: .brandPrimary.opacity(0.3), radius: 10, x: 0, y: 5)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
    
    // MARK: - Reels Feed View
    private func reelsFeedView(screenWidth: CGFloat, screenHeight: CGFloat, safeArea: EdgeInsets) -> some View {
        TabView(selection: $currentReelId) {
            ForEach(viewModel.bookmarkedReels) { reel in
                BookmarkedReelView(
                    reel: reel,
                    viewModel: viewModel,
                    safeAreaInsets: safeArea,
                    screenSize: CGSize(width: screenWidth, height: screenHeight)
                )
                .frame(width: screenWidth, height: screenHeight)
                .rotationEffect(.degrees(-90))
                .frame(width: screenHeight, height: screenWidth)
                .tag(Optional(reel.id))
            }
        }
        .frame(width: screenHeight, height: screenWidth)
        .rotationEffect(.degrees(90), anchor: .center)
        .frame(width: screenWidth, height: screenHeight)
        .tabViewStyle(.page(indexDisplayMode: .never))
        .indexViewStyle(.page(backgroundDisplayMode: .never))
        .onChange(of: currentReelId) { oldId, newId in
            if let id = newId, let index = viewModel.bookmarkedReels.firstIndex(where: { $0.id == id }) {
                viewModel.managePreloading(currentIndex: index)
            }
        }
        .onChange(of: viewModel.bookmarkedReels) { oldReels, newReels in
            if currentReelId == nil, let first = newReels.first {
                currentReelId = first.id
                viewModel.managePreloading(currentIndex: 0)
            }
        }
    }
}

// MARK: - Rotating Modifier for Loading Animation
struct RotatingModifier: ViewModifier {
    @State private var isRotating = false
    
    func body(content: Content) -> some View {
        content
            .rotationEffect(.degrees(isRotating ? 360 : 0))
            .animation(.linear(duration: 1).repeatForever(autoreverses: false), value: isRotating)
            .onAppear {
                isRotating = true
            }
    }
}

// MARK: - Bookmarked Reel View
struct BookmarkedReelView: View {
    let reel: Reel
    @ObservedObject var viewModel: BookmarksViewModel
    let safeAreaInsets: EdgeInsets
    let screenSize: CGSize

    @Environment(\.colorScheme) private var colorScheme
    
    @State private var player: AVPlayer?
    @State private var isPlaying = true
    @State private var showPlayIcon = false
    @State private var showComments = false
    @State private var isLoading = true
    @State private var cancellables = Set<AnyCancellable>()
    
    // Bottom padding that accounts for tab bar and safe area
    private var bottomPadding: CGFloat {
        max(safeAreaInsets.bottom, 34) + 70
    }
    
    var body: some View {
        ZStack {
            Color.reelsBackground
            
            // Video Player - Centered
            GeometryReader { geo in
                if let player = player {
                    PlayerView(player: player)
                        .frame(width: geo.size.width, height: geo.size.height)
                        .contentShape(Rectangle())
                        .onAppear {
                            if isPlaying { player.play() }
                            NotificationCenter.default.addObserver(
                                forName: .AVPlayerItemDidPlayToEndTime,
                                object: player.currentItem,
                                queue: .main
                            ) { _ in
                                player.seek(to: .zero)
                                if isPlaying { player.play() }
                            }
                        }
                        .onDisappear {
                            player.pause()
                        }
                        .onTapGesture {
                            withAnimation(.easeInOut(duration: 0.2)) {
                                isPlaying.toggle()
                            }
                            if isPlaying {
                                player.play()
                                showPlayIcon = false
                            } else {
                                player.pause()
                                showPlayIcon = true
                            }
                        }
                }
            }
            
            // Skeleton while loading
            if isLoading {
                BookmarkSkeletonView(safeAreaInsets: safeAreaInsets)
                    .frame(width: screenSize.width, height: screenSize.height)
            }
            
            // Play/Pause Overlay - Centered
            if showPlayIcon {
                Image(systemName: "play.fill")
                    .font(.system(size: 60))
                    .foregroundColor(.white.opacity(0.8))
                    .shadow(radius: 4)
                    .transition(.opacity.combined(with: .scale))
                    .allowsHitTesting(false)
            }
            
            // Overlay Controls
            VStack(spacing: 0) {
                Spacer()
                
                HStack(alignment: .bottom, spacing: 12) {
                    // Left Side: Text Info
                    VStack(alignment: .leading, spacing: 8) {
                        // Bookmarked badge
                        HStack(spacing: 4) {
                            Image(systemName: "bookmark.fill")
                                .font(.system(size: 12))
                            Text("Saved")
                                .font(.system(size: 12, weight: .semibold))
                        }
                        .foregroundStyle(.black)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 4)
                        .background(Color.yellow)
                        .cornerRadius(12)

                        if let createdAt = reel.createdAt, !createdAt.isEmpty {
                            ReelRelativeTimestampView(createdAt: createdAt)
                        }
                        
                        if let title = reel.title, !title.isEmpty {
                            Text(title)
                                .font(.headline)
                                .fontWeight(.bold)
                                .foregroundColor(.white)
                                .lineLimit(2)
                        }
                        
                        if let description = reel.description, !description.isEmpty {
                            Text(description)
                                .font(.subheadline)
                                .foregroundColor(.white.opacity(0.9))
                                .lineLimit(2)
                        }
                        
                        HStack(spacing: 4) {
                            Image(systemName: "music.note")
                            Text("Original Audio")
                                .font(.caption)
                        }
                        .foregroundColor(.white.opacity(0.7))
                        .padding(.top, 4)
                    }
                    .shadow(color: .black.opacity(0.5), radius: 2, x: 0, y: 1)
                    
                    Spacer(minLength: 8)
                    
                    // Right Side: Action Buttons
                    VStack(spacing: 20) {
                        ActionButton(icon: "heart.fill", text: "\(reel.likesCount ?? 0)", isSelected: reel.isLiked ?? false) {
                            // Like action
                        }
                        
                        ActionButton(icon: "bubble.right.fill", text: "\(reel.commentsCount ?? 0)") {
                            showComments = true
                        }
                        
                        // Remove bookmark button
                        ActionButton(icon: "bookmark.fill", text: "Remove", isSelected: true) {
                            Task {
                                await viewModel.toggleBookmark(reel: reel)
                            }
                        }
                        
                        ActionButton(icon: "arrowshape.turn.up.right.fill", text: "Share") {
                            // Share action
                        }
                    }
                }
                .padding(.horizontal, 16)
                .padding(.bottom, bottomPadding)
            }
        }
        .frame(width: screenSize.width, height: screenSize.height)
        .clipped()
        .onAppear {
            setupPlayer()
        }
        .onDisappear {
            player?.pause()
            isPlaying = false
            showPlayIcon = false
        }
        .sheet(isPresented: $showComments) {
            if #available(iOS 16.0, *) {
                CommentsSheet(reelId: reel.id) { _ in }
                    .presentationDetents([.medium, .large])
                    .presentationDragIndicator(.visible)
            } else {
                CommentsSheet(reelId: reel.id) { _ in }
            }
        }
    }
    
    private func setupPlayer() {
        let newPlayer = viewModel.getPlayer(for: reel)
        self.player = newPlayer
        
        // Observe player status
        if let currentItem = newPlayer.currentItem {
            currentItem.publisher(for: \.status)
                .receive(on: DispatchQueue.main)
                .sink { status in
                    if status == .readyToPlay {
                        withAnimation(.easeOut(duration: 0.3)) {
                            isLoading = false
                        }
                    }
                }
                .store(in: &cancellables)
        }
        
        try? AVAudioSession.sharedInstance().setCategory(.ambient, mode: .moviePlayback)
        try? AVAudioSession.sharedInstance().setActive(true)
        
        if isPlaying {
            newPlayer.play()
        }
        
        // Fallback: hide skeleton after delay
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
            withAnimation {
                isLoading = false
            }
        }
    }
}

// MARK: - Bookmark Skeleton View
struct BookmarkSkeletonView: View {
    let safeAreaInsets: EdgeInsets
    @State private var isAnimating = false

    @Environment(\.colorScheme) private var colorScheme
    
    private var bottomPadding: CGFloat {
        max(safeAreaInsets.bottom, 34) + 70
    }
    
    var body: some View {
        ZStack {
            Color.reelsBackground
            
            // Center loading spinner
            VStack(spacing: 16) {
                ZStack {
                    Circle()
                        .stroke(Color.gray.opacity(0.3), lineWidth: 4)
                        .frame(width: 50, height: 50)
                    
                    Circle()
                        .trim(from: 0, to: 0.7)
                        .stroke(
                            LinearGradient(
                                colors: [.yellow, .orange],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                            style: StrokeStyle(lineWidth: 4, lineCap: .round)
                        )
                        .frame(width: 50, height: 50)
                        .rotationEffect(.degrees(isAnimating ? 360 : 0))
                }
                
                Text("Loading...")
                    .font(.caption)
                    .foregroundStyle(.gray)
            }
            
            // Bottom skeleton placeholders
            VStack {
                Spacer()
                HStack(alignment: .bottom, spacing: 12) {
                    VStack(alignment: .leading, spacing: 10) {
                        // Badge skeleton
                        RoundedRectangle(cornerRadius: 12)
                            .fill(Color.yellow.opacity(0.3))
                            .frame(width: 70, height: 24)
                        
                        // Title skeleton
                        RoundedRectangle(cornerRadius: 4)
                            .fill(Color.white.opacity(0.2))
                            .frame(width: 200, height: 18)
                        
                        // Description skeleton
                        RoundedRectangle(cornerRadius: 4)
                            .fill(Color.white.opacity(0.15))
                            .frame(width: 160, height: 14)
                    }
                    
                    Spacer(minLength: 8)
                    
                    // Action buttons skeleton
                    VStack(spacing: 20) {
                        ForEach(0..<4, id: \.self) { _ in
                            VStack(spacing: 6) {
                                Circle()
                                    .fill(Color.white.opacity(0.2))
                                    .frame(width: 32, height: 32)
                                RoundedRectangle(cornerRadius: 2)
                                    .fill(Color.white.opacity(0.15))
                                    .frame(width: 24, height: 10)
                            }
                        }
                    }
                }
                .padding(.horizontal, 16)
                .padding(.bottom, bottomPadding)
            }
        }
        .onAppear {
            withAnimation(.linear(duration: 1).repeatForever(autoreverses: false)) {
                isAnimating = true
            }
        }
    }
}

*/

// MARK: - Explore-Identical Helpers (Saved Reels)

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

private struct ReelCellView: View {
    let reel: Reel
    @ObservedObject var viewModel: BookmarksViewModel
    let containerSize: CGSize
    let safeAreaInsets: EdgeInsets
    let isActive: Bool

    @Environment(\.colorScheme) private var colorScheme

    @State private var player: AVPlayer?
    @State private var isPlaying = true
    @State private var showPlayIcon = false
    @State private var showComments = false

    private var bottomOverlayPadding: CGFloat {
        max(safeAreaInsets.bottom, 16) + 120
    }

    var body: some View {
        ZStack {
            Color.reelsBackground

            ZStack {
                if let player {
                    PlayerView(player: player)
                        .contentShape(Rectangle())
                        .onTapGesture { togglePlayback() }
                        .onReceive(NotificationCenter.default.publisher(for: .AVPlayerItemDidPlayToEndTime, object: player.currentItem)) { _ in
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

            if showPlayIcon {
                Image(systemName: "play.fill")
                    .font(.system(size: 64, weight: .semibold))
                    .foregroundColor(.white.opacity(0.85))
                    .shadow(color: .black.opacity(0.6), radius: 10, x: 0, y: 4)
                    .transition(.opacity.combined(with: .scale))
                    .allowsHitTesting(false)
            }

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
                    .padding(.bottom, 12)
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

    @Environment(\.colorScheme) private var colorScheme

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

#Preview {
    BookmarksView()
}
