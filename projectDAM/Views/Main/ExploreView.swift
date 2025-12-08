import SwiftUI
import AVKit

struct ExploreView: View {
    @StateObject private var viewModel = ReelsViewModel()
    
    @State private var currentReelId: String?
    @State private var seenReelIds: Set<String> = []

    var body: some View {
        GeometryReader { geometry in
            let screenWidth = geometry.size.width
            let screenHeight = geometry.size.height
            let safeArea = geometry.safeAreaInsets
            
            ZStack {
                Color.black.ignoresSafeArea()
                
                if viewModel.isLoading && viewModel.reels.isEmpty {
                    loadingView
                } else if let error = viewModel.error, viewModel.reels.isEmpty {
                    errorView(message: error)
                } else {
                    reelsFeedView(
                        screenWidth: screenWidth,
                        screenHeight: screenHeight,
                        safeArea: safeArea
                    )
                }
            }
            .frame(width: screenWidth, height: screenHeight)
        }
        .ignoresSafeArea()
        .onAppear {
            Task {
                await viewModel.loadInitialReels()
            }
        }
        .statusBar(hidden: true)
    }
    
    // MARK: - Loading View
    private var loadingView: some View {
        VStack {
            ProgressView()
                .tint(.white)
                .scaleEffect(1.5)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.black)
    }
    
    // MARK: - Error View
    private func errorView(message: String) -> some View {
        VStack(spacing: 20) {
            Image(systemName: "exclamationmark.triangle")
                .font(.largeTitle)
                .foregroundColor(.white)
            Text(message)
                .foregroundColor(.white)
                .multilineTextAlignment(.center)
                .padding()
            Button("Retry") {
                Task { await viewModel.loadInitialReels() }
            }
            .padding()
            .background(Color.white)
            .foregroundColor(.black)
            .cornerRadius(8)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.black)
    }
    
    // MARK: - Reels Feed View
    private func reelsFeedView(screenWidth: CGFloat, screenHeight: CGFloat, safeArea: EdgeInsets) -> some View {
        TabView(selection: $currentReelId) {
            ForEach(viewModel.reels) { reel in
                ZStack {
                    if reel.id == "END_OF_FEED" {
                        EndOfFeedView()
                            .frame(width: screenWidth, height: screenHeight)
                    } else {
                        ReelView(
                            reel: reel,
                            viewModel: viewModel,
                            safeAreaInsets: safeArea,
                            screenSize: CGSize(width: screenWidth, height: screenHeight)
                        )
                        .onAppear {
                            Task {
                                await viewModel.loadMoreReels(currentItemId: reel.id)
                            }
                        }
                    }
                }
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
        .onChange(of: currentReelId) { newId in
            if let id = newId, let index = viewModel.reels.firstIndex(where: { $0.id == id }) {
                viewModel.managePreloading(currentIndex: index)
            }
        }
        .onChange(of: viewModel.reels) { newReels in
            if let firstReel = newReels.first {
                if currentReelId == nil {
                    currentReelId = firstReel.id
                    viewModel.managePreloading(currentIndex: 0)
                } else if currentReelId != firstReel.id && !seenReelIds.contains(firstReel.id) {
                    withAnimation(.easeInOut(duration: 0.3)) {
                        currentReelId = firstReel.id
                    }
                    viewModel.managePreloading(currentIndex: 0)
                    seenReelIds.insert(firstReel.id)
                    print("[ExploreView] 🎬 Scrolled to newly generated reel: \(firstReel.id)")
                }
            }
        }
    }
}


struct EndOfFeedView: View {
    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: "sparkles")
            .font(.system(size: 60))
            .foregroundColor(.yellow)
            
            Text("You’re all caught up ✨")
                .font(.title)
                .fontWeight(.bold)
                .foregroundColor(.white)
            
            Text("More reels coming soon!")
                .font(.body)
                .foregroundColor(.gray)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.black)
    }
}

// MARK: - Reel View Components

struct ReelView: View {
    let reel: Reel
    @ObservedObject var viewModel: ReelsViewModel
    let safeAreaInsets: EdgeInsets
    let screenSize: CGSize
    
    @State private var player: AVPlayer?
    @State private var isPlaying = true
    @State private var showPlayIcon = false
    @State private var showComments = false
    
    // Calculate responsive dimensions
    private var videoContainerSize: CGSize {
        screenSize
    }
    
    // Bottom padding that accounts for tab bar and safe area
    private var bottomPadding: CGFloat {
        max(safeAreaInsets.bottom, 34) + 90
    }
    
    var body: some View {
        ZStack {
            Color.black
            
            // Video Player - Centered container
            GeometryReader { geo in
                if let player = player {
                    PlayerView(player: player)
                        .frame(width: geo.size.width, height: geo.size.height)
                        .contentShape(Rectangle())
                        .onAppear {
                            if isPlaying { 
                                player.play() 
                            }
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
                } else {
                    ReelSkeletonView(safeAreaInsets: safeAreaInsets)
                        .frame(width: geo.size.width, height: geo.size.height)
                }
            }
            
            // Play/Pause Overlay Icon - Centered
            if showPlayIcon {
                Image(systemName: "play.fill")
                    .font(.system(size: 60))
                    .foregroundColor(.white.opacity(0.8))
                    .shadow(radius: 4)
                    .transition(.opacity.combined(with: .scale))
                    .allowsHitTesting(false)
            }
            
            // Overlay Controls - Positioned at bottom
            VStack(spacing: 0) {
                Spacer()
                
                HStack(alignment: .bottom, spacing: 12) {
                    // Left Side: Text Info
                    VStack(alignment: .leading, spacing: 8) {
                        HStack(spacing: 8) {
                            Image(systemName: "person.circle.fill")
                                .resizable()
                                .frame(width: 32, height: 32)
                                .foregroundColor(.white)
                            
                            Text(reel.title ?? "Unknown User")
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
                        
                        HStack(spacing: 4) {
                            Image(systemName: "music.note")
                            Text("Original Audio")
                                .font(.caption)
                        }
                        .foregroundColor(.white)
                        .padding(.top, 4)
                    }
                    .shadow(color: .black.opacity(0.5), radius: 2, x: 0, y: 1)
                    
                    Spacer(minLength: 8)
                    
                    // Right Side: Action Buttons
                    VStack(spacing: 20) {
                        // Like Button
                        ActionButton(
                            icon: "heart.fill",
                            text: "\(reel.likesCount ?? 0)",
                            isSelected: reel.isLiked ?? false
                        ) {
                            Task {
                                await viewModel.toggleLike(reel: reel)
                            }
                        }
                        
                        // Comments Button
                        ActionButton(
                            icon: "bubble.right.fill",
                            text: "\(reel.commentsCount ?? 0)"
                        ) {
                            showComments = true
                        }
                        
                        // Enhanced Bookmark Button with visual feedback
                        BookmarkButton(
                            isBookmarked: reel.isBookmarked ?? false,
                            onToggle: {
                                Task {
                                    await viewModel.toggleBookmark(reel: reel)
                                }
                            }
                        )
                        
                        // Share Button
                        ActionButton(
                            icon: "arrowshape.turn.up.right.fill",
                            text: "Share"
                        ) {
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
            // Log the bookmark state when reel appears
            print("[ReelView] 🎬 Reel ID: \(reel.id), Bookmark State: \(reel.isBookmarked ?? false ? "⭐ SAVED" : "❌ Not Saved")")
            isPlaying = true
            showPlayIcon = false
            setupPlayer()
        }
        .onDisappear {
            player?.pause()
            isPlaying = false 
            showPlayIcon = false
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
        
        try? AVAudioSession.sharedInstance().setCategory(.ambient, mode: .moviePlayback)
        try? AVAudioSession.sharedInstance().setActive(true)
        
        if isPlaying {
            player.play()
        }
    }
}

// Lightweight Shimmer/Skeleton Loading View
struct ReelSkeletonView: View {
    let safeAreaInsets: EdgeInsets
    @State private var isAnimating = false
    
    private var bottomPadding: CGFloat {
        max(safeAreaInsets.bottom, 34) + 90
    }
    
    var body: some View {
        ZStack {
            Color.black
            
            // Center loading indicator
            VStack(spacing: 16) {
                ZStack {
                    Circle()
                        .stroke(Color.gray.opacity(0.3), lineWidth: 4)
                        .frame(width: 50, height: 50)
                    
                    Circle()
                        .trim(from: 0, to: 0.7)
                        .stroke(
                            LinearGradient(
                                colors: [.brandPrimary, .purple],
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
            
            // Bottom skeleton
            VStack {
                Spacer()
                HStack(alignment: .bottom, spacing: 12) {
                    VStack(alignment: .leading, spacing: 10) {
                        HStack(spacing: 8) {
                            Circle()
                                .fill(Color.white.opacity(0.2))
                                .frame(width: 32, height: 32)
                            
                            RoundedRectangle(cornerRadius: 4)
                                .fill(Color.white.opacity(0.2))
                                .frame(width: 120, height: 16)
                        }
                        
                        RoundedRectangle(cornerRadius: 4)
                            .fill(Color.white.opacity(0.15))
                            .frame(width: 200, height: 14)
                        
                        RoundedRectangle(cornerRadius: 4)
                            .fill(Color.white.opacity(0.15))
                            .frame(width: 150, height: 14)
                    }
                    
                    Spacer(minLength: 8)
                    
                    VStack(spacing: 20) {
                        ForEach(0..<4, id: \.self) { _ in
                            VStack(spacing: 6) {
                                Circle()
                                    .fill(Color.white.opacity(0.2))
                                    .frame(width: 28, height: 28)
                                RoundedRectangle(cornerRadius: 2)
                                    .fill(Color.white.opacity(0.15))
                                    .frame(width: 20, height: 10)
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

struct ActionButton: View {
    let icon: String
    let text: String
    var isSelected: Bool = false
    let action: () -> Void
    
    @State private var isPressed = false
    
    // Determine if this is a heart or bookmark button
    private var isHeartButton: Bool {
        icon == "heart.fill"
    }
    
    private var isBookmarkButton: Bool {
        icon == "bookmark.fill" || icon == "bookmark"
    }
    
    private var selectedColor: Color {
        if isHeartButton { return .red }
        if isBookmarkButton { return .yellow }
        return .brandPrimary
    }
    
    var body: some View {
        Button {
            // Haptic feedback
            let impactMed = UIImpactFeedbackGenerator(style: .medium)
            impactMed.impactOccurred()
            action()
        } label: {
            VStack(spacing: 6) {
                ZStack {
                    // Glow effect for selected state
                    if isSelected && (isHeartButton || isBookmarkButton) {
                        Circle()
                            .fill(selectedColor.opacity(0.3))
                            .frame(width: 44, height: 44)
                            .blur(radius: 8)
                    }
                    
                    Image(systemName: icon)
                        .font(.system(size: 28, weight: isSelected ? .bold : .regular))
                        .foregroundColor(isSelected ? selectedColor : .white)
                        .scaleEffect(isSelected ? 1.15 : 1.0)
                        .scaleEffect(isPressed ? 0.85 : 1.0)
                }
                .frame(width: 44, height: 44)
                .animation(.spring(response: 0.3, dampingFraction: 0.5), value: isSelected)
                .animation(.spring(response: 0.2, dampingFraction: 0.6), value: isPressed)
                
                Text(text)
                    .font(.caption)
                    .fontWeight(isSelected ? .semibold : .regular)
                    .foregroundColor(isSelected ? selectedColor : .white)
                    .monospacedDigit()
            }
            .shadow(color: .black.opacity(0.5), radius: 2, x: 0, y: 1)
        }
        .buttonStyle(.plain)
        .simultaneousGesture(
            DragGesture(minimumDistance: 0)
                .onChanged { _ in
                    if !isPressed { isPressed = true }
                }
                .onEnded { _ in
                    isPressed = false
                }
        )
    }
}

// Custom Player using AVPlayerLayer for robust AspectFill with proper centering
struct PlayerView: UIViewRepresentable {
    var player: AVPlayer
    
    func makeUIView(context: Context) -> PlayerUIView {
        let view = PlayerUIView(player: player)
        return view
    }
    
    func updateUIView(_ uiView: PlayerUIView, context: Context) {
        if uiView.player !== player {
            uiView.player = player
        }
        uiView.playerLayer.videoGravity = .resizeAspectFill
    }
    
    // Inner UIView subclass to handle layer layout with proper centering
    class PlayerUIView: UIView {
        var player: AVPlayer? {
            get { return playerLayer.player }
            set { playerLayer.player = newValue }
        }
        
        override class var layerClass: AnyClass {
            return AVPlayerLayer.self
        }
        
        var playerLayer: AVPlayerLayer {
            return layer as! AVPlayerLayer
        }
        
        init(player: AVPlayer) {
            super.init(frame: .zero)
            self.player = player
            self.backgroundColor = .black
            self.playerLayer.videoGravity = .resizeAspectFill
            self.contentMode = .scaleAspectFill
            self.clipsToBounds = true
            self.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        }
        
        required init?(coder: NSCoder) {
            fatalError("init(coder:) has not been implemented")
        }
        
        override func layoutSubviews() {
            super.layoutSubviews()
            CATransaction.begin()
            CATransaction.setDisableActions(true)
            playerLayer.frame = bounds
            CATransaction.commit()
        }
    }
}

// MARK: - Enhanced Bookmark Button with Visual Feedback
struct BookmarkButton: View {
    let isBookmarked: Bool
    let onToggle: () -> Void
    
    @State private var isPressed = false
    @State private var showSavedIndicator = false
    @State private var pulseAnimation = false
    
    var body: some View {
        Button {
            // Haptic feedback
            let generator = UIImpactFeedbackGenerator(style: .medium)
            generator.impactOccurred()
            
            // Log the current state before toggling
            print("[BookmarkButton] 📌 Current state: \(isBookmarked ? "Bookmarked" : "Not Bookmarked"), toggling...")
            
            // Show saved indicator when bookmarking
            if !isBookmarked {
                withAnimation(.spring(response: 0.4, dampingFraction: 0.6)) {
                    showSavedIndicator = true
                    pulseAnimation = true
                }
                
                // Hide indicator after delay
                DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                    withAnimation(.easeOut(duration: 0.3)) {
                        showSavedIndicator = false
                    }
                }
            }
            
            onToggle()
        } label: {
            VStack(spacing: 4) {
                ZStack {
                    // Prominent glow effect when bookmarked - ALWAYS visible
                    if isBookmarked {
                        Circle()
                            .fill(
                                RadialGradient(
                                    colors: [.yellow.opacity(0.5), .orange.opacity(0.2), .clear],
                                    center: .center,
                                    startRadius: 5,
                                    endRadius: 30
                                )
                            )
                            .frame(width: 60, height: 60)
                            .blur(radius: 6)
                            .scaleEffect(pulseAnimation ? 1.3 : 1.1)
                    }
                    
                    // Bookmark icon with stronger visual distinction
                    Image(systemName: isBookmarked ? "bookmark.fill" : "bookmark")
                        .font(.system(size: 30, weight: isBookmarked ? .bold : .regular))
                        .foregroundStyle(
                            isBookmarked ?
                            LinearGradient(
                                colors: [.yellow, .orange, .yellow],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ) :
                            LinearGradient(
                                colors: [.white.opacity(0.9), .white.opacity(0.7)],
                                startPoint: .top,
                                endPoint: .bottom
                            )
                        )
                        .scaleEffect(isBookmarked ? 1.2 : 1.0)
                        .scaleEffect(isPressed ? 0.85 : 1.0)
                        .rotation3DEffect(
                            .degrees(isBookmarked ? 360 : 0),
                            axis: (x: 0, y: 1, z: 0)
                        )
                        .shadow(
                            color: isBookmarked ? .yellow.opacity(0.6) : .black.opacity(0.3),
                            radius: isBookmarked ? 6 : 2,
                            x: 0,
                            y: 2
                        )
                    
                    // Success checkmark overlay - temporary
                    if showSavedIndicator {
                        Circle()
                            .fill(
                                LinearGradient(
                                    colors: [.yellow, .orange],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                            .frame(width: 20, height: 20)
                            .overlay(
                                Image(systemName: "checkmark")
                                    .font(.system(size: 11, weight: .black))
                                    .foregroundColor(.black)
                            )
                            .offset(x: 18, y: -18)
                            .shadow(color: .yellow.opacity(0.5), radius: 4)
                            .transition(.scale.combined(with: .opacity))
                    }
                    
                    // Persistent "SAVED" badge on bookmarked reels - ALWAYS visible
                    if isBookmarked && !showSavedIndicator {
                        VStack(spacing: 0) {
                            Circle()
                                .fill(
                                    LinearGradient(
                                        colors: [.yellow, .orange],
                                        startPoint: .top,
                                        endPoint: .bottom
                                    )
                                )
                                .frame(width: 16, height: 16)
                                .overlay(
                                    Image(systemName: "checkmark.circle.fill")
                                        .font(.system(size: 16, weight: .bold))
                                        .foregroundColor(.yellow)
                                        .background(
                                            Circle()
                                                .fill(Color.black)
                                                .frame(width: 10, height: 10)
                                        )
                                )
                        }
                        .offset(x: 18, y: -18)
                        .shadow(color: .yellow.opacity(0.4), radius: 3)
                    }
                }
                .frame(width: 50, height: 50)
                .animation(.spring(response: 0.4, dampingFraction: 0.6), value: isBookmarked)
                .animation(.spring(response: 0.2, dampingFraction: 0.6), value: isPressed)
                .animation(.easeInOut(duration: 1.0).repeatForever(autoreverses: true), value: pulseAnimation)
                
                // Enhanced text label with background for saved state
                ZStack {
                    if isBookmarked {
                        // Background pill for "Saved" text
                        Capsule()
                            .fill(
                                LinearGradient(
                                    colors: [.yellow.opacity(0.3), .orange.opacity(0.3)],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                            .frame(width: 52, height: 18)
                            .blur(radius: 1)
                    }
                    
                    Text(isBookmarked ? "Saved" : "Save")
                        .font(.caption)
                        .fontWeight(isBookmarked ? .black : .semibold)
                        .foregroundStyle(
                            isBookmarked ?
                            LinearGradient(
                                colors: [.yellow, .orange, .yellow],
                                startPoint: .leading,
                                endPoint: .trailing
                            ) :
                            LinearGradient(
                                colors: [.white, .white.opacity(0.8)],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .shadow(
                            color: isBookmarked ? .black.opacity(0.5) : .black.opacity(0.3),
                            radius: 2,
                            x: 0,
                            y: 1
                        )
                        .scaleEffect(isBookmarked ? 1.05 : 1.0)
                }
                .transition(.opacity)
            }
            .padding(.vertical, 4)
            .background(
                // Subtle background for the entire button when bookmarked
                isBookmarked ?
                RoundedRectangle(cornerRadius: 12)
                    .fill(
                        LinearGradient(
                            colors: [.yellow.opacity(0.15), .orange.opacity(0.1)],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
                    .blur(radius: 2) : nil
            )
        }
        .buttonStyle(.plain)
        .simultaneousGesture(
            DragGesture(minimumDistance: 0)
                .onChanged { _ in
                    if !isPressed { isPressed = true }
                }
                .onEnded { _ in
                    isPressed = false
                }
        )
        .onChange(of: isBookmarked) { oldValue, newValue in
            print("[BookmarkButton] 🔄 State changed: \(oldValue) → \(newValue)")
            if newValue {
                // Trigger pulse animation when bookmarked
                pulseAnimation = true
                DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
                    pulseAnimation = false
                }
            } else {
                pulseAnimation = false
            }
        }
        .onAppear {
            print("[BookmarkButton] 👁️ Appeared with state: \(isBookmarked ? "Bookmarked ⭐" : "Not Bookmarked")")
            // Start pulse animation if already bookmarked
            if isBookmarked {
                pulseAnimation = true
            }
        }
    }
}

#Preview {
    ExploreView()
}
