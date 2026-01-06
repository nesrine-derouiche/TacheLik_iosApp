//
//  GeneratedReelStreamView.swift
//  projectDAM
//
//  Created by Antigravity on 12/08/2025.
//

import SwiftUI
import AVKit
import Combine

/// A view that displays AI-generated reels with Explore-style UI/UX.
/// Supports single or multiple reels with navigation between them.
struct GeneratedReelStreamView: View {
    let reels: [Reel]
    @Environment(\.dismiss) private var dismiss
    
    @State private var currentIndex: Int = 0
    @State private var showComments = false
    
    init(reel: Reel) {
        self.reels = [reel]
    }
    
    init(reels: [Reel]) {
        self.reels = reels
    }
    
    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()
            
            if reels.isEmpty {
                emptyStateView
            } else {
                GeometryReader { proxy in
                    ZStack {
                        // Current Reel Display
                        GeneratedReelPlayerView(
                            reel: reels[currentIndex],
                            safeAreaInsets: proxy.safeAreaInsets,
                            screenSize: proxy.size,
                            showComments: $showComments
                        )
                        
                        // Top Bar with Counter
                        VStack {
                            topBar(safeArea: proxy.safeAreaInsets)
                            Spacer()
                        }
                        
                        // Bottom Navigation Button
                        VStack {
                            Spacer()
                            navigationButton(safeArea: proxy.safeAreaInsets)
                        }
                    }
                }
                .ignoresSafeArea()
            }
        }
        .statusBar(hidden: true)
        .sheet(isPresented: $showComments) {
            if currentIndex < reels.count {
                if #available(iOS 16.0, *) {
                    CommentsSheet(reelId: reels[currentIndex].id) { _ in }
                        .presentationDetents([.medium, .large])
                        .presentationDragIndicator(.visible)
                } else {
                    CommentsSheet(reelId: reels[currentIndex].id) { _ in }
                }
            }
        }
    }
    
    // MARK: - Top Bar
    private func topBar(safeArea: EdgeInsets) -> some View {
        HStack {
            // Close Button
            Button {
                dismiss()
            } label: {
                Image(systemName: "xmark")
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundStyle(.white)
                    .frame(width: 36, height: 36)
                    .background(Color.black.opacity(0.5))
                    .clipShape(Circle())
            }
            
            Spacer()
            
            // Reel Counter (if multiple)
            if reels.count > 1 {
                HStack(spacing: 6) {
                    Image(systemName: "sparkles")
                        .font(.system(size: 14))
                    Text("\(currentIndex + 1) of \(reels.count)")
                        .font(.system(size: 14, weight: .semibold))
                }
                .foregroundStyle(.white)
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(Color.black.opacity(0.5))
                .clipShape(Capsule())
            }
            
            Spacer()
            
            // Placeholder for symmetry
            Color.clear
                .frame(width: 36, height: 36)
        }
        .padding(.horizontal, 16)
        .padding(.top, safeArea.top + 8)
    }
    
    // MARK: - Navigation Button
    private func navigationButton(safeArea: EdgeInsets) -> some View {
        Group {
            if reels.count > 1 && currentIndex < reels.count - 1 {
                // Continue to next reel
                Button {
                    withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                        currentIndex += 1
                    }
                } label: {
                    HStack(spacing: 10) {
                        Text("Continue")
                            .font(.system(size: 17, weight: .bold))
                        Image(systemName: "arrow.right")
                            .font(.system(size: 16, weight: .semibold))
                    }
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                    .background(
                        LinearGradient(
                            colors: [.brandPrimary, .purple],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .cornerRadius(16)
                    .shadow(color: .brandPrimary.opacity(0.4), radius: 10, x: 0, y: 5)
                }
                .padding(.horizontal, 20)
                .padding(.bottom, safeArea.bottom + 20)
            } else {
                // Last reel or single reel - show Explore button
                Button {
                    // Add all reels to feed manager
                    ReelFeedManager.shared.addGeneratedReels(reels)
                    dismiss()
                } label: {
                    HStack(spacing: 12) {
                        ZStack {
                            Circle()
                                .fill(Color.white.opacity(0.2))
                                .frame(width: 40, height: 40)
                            Image(systemName: "safari.fill")
                                .font(.system(size: 18, weight: .semibold))
                        }
                        
                        VStack(alignment: .leading, spacing: 2) {
                            Text("Explore Reels")
                                .font(.system(size: 16, weight: .bold))
                            Text("See your reels in the feed")
                                .font(.system(size: 12))
                                .opacity(0.8)
                        }
                        
                        Spacer()
                        
                        Image(systemName: "chevron.right")
                            .font(.system(size: 14, weight: .semibold))
                            .opacity(0.7)
                    }
                    .foregroundStyle(.white)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 14)
                    .background(
                        LinearGradient(
                            colors: [
                                Color(red: 0.4, green: 0.2, blue: 0.9),
                                Color.purple
                            ],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .cornerRadius(16)
                    .shadow(color: Color.purple.opacity(0.4), radius: 10, x: 0, y: 5)
                }
                .padding(.horizontal, 20)
                .padding(.bottom, safeArea.bottom + 20)
            }
        }
    }
    
    // MARK: - Empty State View
    private var emptyStateView: some View {
        VStack(spacing: 24) {
            // Success icon
            ZStack {
                Circle()
                    .fill(Color.green.opacity(0.15))
                    .frame(width: 100, height: 100)
                
                Image(systemName: "checkmark.circle.fill")
                    .font(.system(size: 60))
                    .foregroundStyle(.green)
            }
            
            VStack(spacing: 8) {
                Text("Processing Complete")
                    .font(.system(size: 24, weight: .bold))
                    .foregroundStyle(.white)
                
                Text("No suitable moments were found in this video.\nTry a different video for better results.")
                    .font(.system(size: 16))
                    .foregroundStyle(.gray)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 32)
            }
            
            // Explore button
            Button {
                dismiss()
            } label: {
                HStack(spacing: 10) {
                    Image(systemName: "safari.fill")
                    Text("Explore Feed")
                        .fontWeight(.bold)
                }
                .foregroundStyle(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 16)
                .background(
                    LinearGradient(
                        colors: [.brandPrimary, .purple],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
                .cornerRadius(16)
            }
            .padding(.horizontal, 40)
            .padding(.top, 16)
        }
    }
}

// MARK: - Generated Reel Player View (Matches ExploreView's ReelView)
struct GeneratedReelPlayerView: View {
    let reel: Reel
    let safeAreaInsets: EdgeInsets
    let screenSize: CGSize
    @Binding var showComments: Bool
    
    @State private var player: AVPlayer?
    @State private var isPlaying = true
    @State private var showPlayIcon = false
    @State private var isLoading = true
    
    var body: some View {
        ZStack {
            // Video Player or Skeleton
            if let player = player, !isLoading {
                PlayerView(player: player)
                    .frame(width: screenSize.width, height: screenSize.height)
                    .clipped()
                    .edgesIgnoringSafeArea(.all)
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
            } else {
                GeneratedReelSkeletonView(safeAreaInsets: safeAreaInsets)
                    .frame(width: screenSize.width, height: screenSize.height)
            }
            
            // Play/Pause Overlay Icon
            if showPlayIcon {
                Image(systemName: "play.fill")
                    .font(.system(size: 60))
                    .foregroundColor(.white.opacity(0.8))
                    .shadow(radius: 4)
                    .transition(.opacity.combined(with: .scale))
                    .allowsHitTesting(false)
            }
            
            // Overlay Controls
            VStack {
                Spacer()
                
                HStack(alignment: .bottom) {
                    // Left Side: Text Info
                    VStack(alignment: .leading, spacing: 8) {
                        // AI Generated Badge
                        HStack(spacing: 10) {
                            HStack {
                                Image(systemName: "sparkles")
                                    .font(.system(size: 12))
                                Text("AI Generated")
                                    .font(.system(size: 12, weight: .semibold))
                            }
                            .foregroundStyle(.white)
                            .padding(.horizontal, 10)
                            .padding(.vertical, 4)
                            .background(
                                LinearGradient(
                                    colors: [.purple, .brandPrimary],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                            .cornerRadius(12)

                            Spacer(minLength: 8)

                            if let createdAt = reel.createdAt, !createdAt.isEmpty {
                                ReelRelativeTimestampView(createdAt: createdAt)
                            }
                        }
                        
                        if let title = reel.title, !title.isEmpty {
                            Text(title)
                                .font(.headline)
                                .fontWeight(.bold)
                                .foregroundColor(.white)
                        }
                        
                        if let description = reel.description, !description.isEmpty {
                            Text(description)
                                .font(.subheadline)
                                .foregroundColor(.white)
                                .lineLimit(2)
                        }
                        
                        // Clip duration
                        if let start = reel.startTime, let end = reel.endTime {
                            HStack {
                                Image(systemName: "clock")
                                Text("\(start) - \(end)")
                                    .font(.caption)
                            }
                            .foregroundColor(.white.opacity(0.8))
                            .padding(.top, 4)
                        }
                    }
                    .shadow(color: .black.opacity(0.5), radius: 2, x: 0, y: 1)
                    
                    Spacer()
                    
                    // Right Side: Action Buttons
                    VStack(spacing: 20) {
                        ActionButton(icon: "heart.fill", text: "\(reel.likesCount ?? 0)", isSelected: reel.isLiked ?? false) {
                            // Like action
                        }
                        
                        ActionButton(icon: "bubble.right.fill", text: "\(reel.commentsCount ?? 0)") {
                            showComments = true
                        }
                        
                        ActionButton(icon: "bookmark.fill", text: "Save") {
                            // Bookmark action
                        }
                        
                        ActionButton(icon: "arrowshape.turn.up.right.fill", text: "Share") {
                            // Share action
                        }
                    }
                    .padding(.bottom, 10)
                }
                .padding(.horizontal)
                .padding(.bottom, max(safeAreaInsets.bottom, 34) + 90) // Extra space for nav button
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
        }
    }
    
    private func setupPlayer() {
        // Build stream URL from filePath
        guard let url = buildStreamURL() else {
            print("[GeneratedReelPlayerView] ❌ Failed to build stream URL for reel: \(reel.id)")
            return
        }
        
        print("[GeneratedReelPlayerView] 🎬 Loading stream: \(url)")
        
        let playerItem = AVPlayerItem(url: url)
        let newPlayer = AVPlayer(playerItem: playerItem)
        
        // Observe when ready to play
        playerItem.observe(\.status, options: [.new]) { item, _ in
            DispatchQueue.main.async {
                if item.status == .readyToPlay {
                    self.isLoading = false
                    if self.isPlaying {
                        self.player?.play()
                    }
                }
            }
        }
        
        // Loop video
        NotificationCenter.default.addObserver(
            forName: .AVPlayerItemDidPlayToEndTime,
            object: playerItem,
            queue: .main
        ) { _ in
            newPlayer.seek(to: .zero)
            if self.isPlaying {
                newPlayer.play()
            }
        }
        
        // Configure audio
        try? AVAudioSession.sharedInstance().setCategory(.ambient, mode: .moviePlayback)
        try? AVAudioSession.sharedInstance().setActive(true)
        
        self.player = newPlayer
    }
    
    private func buildStreamURL() -> URL? {
        guard let filePath = reel.filePath else { return nil }
        
        // Strip "reels/" prefix if present
        let filename: String
        if let lastComponent = filePath.components(separatedBy: "/").last, !lastComponent.isEmpty {
            filename = lastComponent
        } else {
            return nil
        }
        
        let urlString = "\(AppConfig.baseURL)/reels/stream/\(filename)"
        return URL(string: urlString)
    }
}

// MARK: - Generated Reel Skeleton View
struct GeneratedReelSkeletonView: View {
    let safeAreaInsets: EdgeInsets
    @State private var isAnimating = false
    
    var body: some View {
        ZStack {
            Color.black.edgesIgnoringSafeArea(.all)
            
            // Center loading indicator
            VStack(spacing: 16) {
                ZStack {
                    Circle()
                        .stroke(Color.gray.opacity(0.3), lineWidth: 4)
                        .frame(width: 60, height: 60)
                    
                    Circle()
                        .trim(from: 0, to: 0.7)
                        .stroke(
                            LinearGradient(
                                colors: [.purple, .brandPrimary],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                            style: StrokeStyle(lineWidth: 4, lineCap: .round)
                        )
                        .frame(width: 60, height: 60)
                        .rotationEffect(.degrees(isAnimating ? 360 : 0))
                }
                
                Text("Loading reel...")
                    .font(.subheadline)
                    .foregroundStyle(.gray)
            }
            
            // Bottom skeleton overlay
            VStack {
                Spacer()
                HStack(alignment: .bottom) {
                    VStack(alignment: .leading, spacing: 10) {
                        // AI Badge Skeleton
                        RoundedRectangle(cornerRadius: 12)
                            .fill(Color.white.opacity(0.2))
                            .frame(width: 100, height: 24)
                        
                        // Title Skeleton
                        RoundedRectangle(cornerRadius: 4)
                            .fill(Color.white.opacity(0.2))
                            .frame(width: 180, height: 18)
                        
                        // Description Skeleton
                        RoundedRectangle(cornerRadius: 4)
                            .fill(Color.white.opacity(0.2))
                            .frame(width: 200, height: 14)
                        
                        RoundedRectangle(cornerRadius: 4)
                            .fill(Color.white.opacity(0.2))
                            .frame(width: 150, height: 14)
                    }
                    Spacer()
                    
                    // Buttons Skeleton
                    VStack(spacing: 20) {
                        ForEach(0..<4) { _ in
                            VStack(spacing: 6) {
                                Circle()
                                    .fill(Color.white.opacity(0.2))
                                    .frame(width: 28, height: 28)
                                RoundedRectangle(cornerRadius: 2)
                                    .fill(Color.white.opacity(0.2))
                                    .frame(width: 20, height: 10)
                            }
                        }
                    }
                    .padding(.bottom, 10)
                }
                .padding(.horizontal)
                .padding(.bottom, max(safeAreaInsets.bottom, 34) + 90)
            }
        }
        .onAppear {
            withAnimation(.linear(duration: 1).repeatForever(autoreverses: false)) {
                isAnimating = true
            }
        }
    }
}

// MARK: - Preview
#Preview("Single Reel") {
    GeneratedReelStreamView(reel: Reel(
        id: "preview-1",
        originalVideoUrl: "https://youtube.com/watch?v=abc",
        title: "Amazing AI-Generated Reel",
        description: "This is a preview of how the generated reel will look.",
        filePath: "reels/reel_preview_1.mp4",
        videoId: "video-123",
        startTime: "00:01:30",
        endTime: "00:02:15",
        createdAt: nil,
        likesCount: 42,
        commentsCount: 7,
        isLiked: false,
        isBookmarked: false
    ))
}

#Preview("Multiple Reels") {
    GeneratedReelStreamView(reels: [
        Reel(id: "reel-1", originalVideoUrl: nil, title: "First Highlight", description: "The best moment from the intro", filePath: "reels/reel_1.mp4", videoId: "v1", startTime: "00:00:30", endTime: "00:01:00", createdAt: nil, likesCount: 10, commentsCount: 2, isLiked: false, isBookmarked: false),
        Reel(id: "reel-2", originalVideoUrl: nil, title: "Second Highlight", description: "An exciting part about algorithms", filePath: "reels/reel_2.mp4", videoId: "v1", startTime: "00:05:00", endTime: "00:05:45", createdAt: nil, likesCount: 25, commentsCount: 5, isLiked: true, isBookmarked: true),
        Reel(id: "reel-3", originalVideoUrl: nil, title: "Third Highlight", description: "The conclusion summary", filePath: "reels/reel_3.mp4", videoId: "v1", startTime: "00:12:00", endTime: "00:12:30", createdAt: nil, likesCount: 18, commentsCount: 3, isLiked: false, isBookmarked: false)
    ])
}

#Preview("Empty State") {
    GeneratedReelStreamView(reels: [])
}
