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
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        GeometryReader { geometry in
            let screenWidth = geometry.size.width
            let screenHeight = geometry.size.height
            let safeArea = geometry.safeAreaInsets
            
            ZStack {
                Color.black.ignoresSafeArea()
                
                if viewModel.isLoading && viewModel.bookmarkedReels.isEmpty {
                    loadingView
                } else if let error = viewModel.error, viewModel.bookmarkedReels.isEmpty {
                    errorView(message: error)
                } else if viewModel.bookmarkedReels.isEmpty {
                    emptyStateView
                } else {
                    reelsFeedView(
                        screenWidth: screenWidth,
                        screenHeight: screenHeight,
                        safeArea: safeArea
                    )
                }
                
                // Custom Top Bar
                VStack {
                    topBar(safeAreaTop: safeArea.top)
                    Spacer()
                }
            }
            .frame(width: screenWidth, height: screenHeight)
        }
        .navigationBarHidden(true)
        .ignoresSafeArea()
        .onAppear {
            Task {
                await viewModel.loadBookmarks()
            }
        }
        .onDisappear {
            viewModel.cleanup()
        }
        .statusBar(hidden: true)
    }
    
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
                .foregroundStyle(.gray)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
    
    // MARK: - Error View
    private func errorView(message: String) -> some View {
        VStack(spacing: 24) {
            Image(systemName: "exclamationmark.triangle.fill")
                .font(.system(size: 50))
                .foregroundStyle(.orange)
            
            VStack(spacing: 8) {
                Text("Oops!")
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundStyle(.white)
                
                Text(message)
                    .font(.subheadline)
                    .foregroundStyle(.gray)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 40)
            }
            
            Button {
                Task {
                    await viewModel.loadBookmarks()
                }
            } label: {
                HStack(spacing: 8) {
                    Image(systemName: "arrow.clockwise")
                    Text("Try Again")
                }
                .fontWeight(.semibold)
                .foregroundStyle(.white)
                .padding(.horizontal, 24)
                .padding(.vertical, 12)
                .background(Color.brandPrimary)
                .cornerRadius(12)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
    
    // MARK: - Empty State View
    private var emptyStateView: some View {
        VStack(spacing: 24) {
            ZStack {
                Circle()
                    .fill(Color.yellow.opacity(0.15))
                    .frame(width: 100, height: 100)
                
                Image(systemName: "bookmark")
                    .font(.system(size: 44))
                    .foregroundStyle(.yellow)
            }
            
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
            
            Button {
                dismiss()
            } label: {
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
            Color.black
            
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
    
    private var bottomPadding: CGFloat {
        max(safeAreaInsets.bottom, 34) + 70
    }
    
    var body: some View {
        ZStack {
            Color.black
            
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

#Preview {
    BookmarksView()
}
