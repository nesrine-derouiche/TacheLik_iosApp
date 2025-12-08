import SwiftUI
import AVKit

struct ExploreView: View {
    @StateObject private var viewModel = ReelsViewModel()
    
    @State private var currentReelId: String?
    @State private var seenReelIds: Set<String> = []

    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()
            
            if viewModel.isLoading && viewModel.reels.isEmpty {
                VStack {
                    ProgressView()
                        .tint(.white)
                        .scaleEffect(1.5)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .background(Color.black)
            } else if let error = viewModel.error, viewModel.reels.isEmpty {
                VStack(spacing: 20) {
                    Image(systemName: "exclamationmark.triangle")
                        .font(.largeTitle)
                        .foregroundColor(.white)
                    Text(error)
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
            } else {
                GeometryReader { proxy in
                    let width = proxy.size.width
                    let height = proxy.size.height
                    
                    TabView(selection: $currentReelId) { 
                        ForEach(viewModel.reels) { reel in
                            ZStack {
                                if reel.id == "END_OF_FEED" {
                                    EndOfFeedView()
                                } else {
                                    ReelView(reel: reel, viewModel: viewModel, safeAreaInsets: proxy.safeAreaInsets, screenSize: CGSize(width: width, height: height))
                                        .onAppear {
                                            Task {
                                                await viewModel.loadMoreReels(currentItemId: reel.id)
                                            }
                                        }
                                }
                            }
                            // Inner rotation (Counter-rotate content)
                            .frame(width: width, height: height)
                            .rotationEffect(.degrees(-90))
                            .frame(width: height, height: width)
                            .tag(Optional(reel.id))
                        }
                    }
                    // Outer frame (Matches rotated dimensions)
                    .frame(width: height, height: width)
                    .rotationEffect(.degrees(90), anchor: .center)
                    // Reset to screen dimensions and force center position
                    .frame(width: width, height: height)
                    .position(x: width / 2, y: height / 2)
                    .tabViewStyle(.page(indexDisplayMode: .never))
                    .indexViewStyle(.page(backgroundDisplayMode: .never))
                    .onChange(of: currentReelId) { newId in
                         if let id = newId, let index = viewModel.reels.firstIndex(where: { $0.id == id }) {
                             viewModel.managePreloading(currentIndex: index)
                         }
                    }
                    .onChange(of: viewModel.reels) { newReels in
                        // Check if we have new reels at the front (from generation)
                        if let firstReel = newReels.first {
                            // If currentReelId is nil (initial load), set to first reel
                            if currentReelId == nil {
                                currentReelId = firstReel.id
                                viewModel.managePreloading(currentIndex: 0)
                            } 
                            // If the first reel changed (new reels inserted at front), scroll to it
                            else if currentReelId != firstReel.id && !seenReelIds.contains(firstReel.id) {
                                // This is a newly generated reel - scroll to show it
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
                .ignoresSafeArea()
            }
        }
        .ignoresSafeArea()
        .onAppear {
            Task {
                await viewModel.loadInitialReels()
            }
        }
        .statusBar(hidden: true)
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
    
    var body: some View {
        ZStack {
            // Video Player
            if let player = player {
                PlayerView(player: player)
                    .frame(width: screenSize.width, height: screenSize.height)
                    .clipped()
                    .edgesIgnoringSafeArea(.all)
                    .onAppear {
                        if isPlaying { 
                            player.play() 
                        }
                        NotificationCenter.default.addObserver(forName: .AVPlayerItemDidPlayToEndTime, object: player.currentItem, queue: .main) { _ in
                            player.seek(to: .zero)
                            if isPlaying { player.play() }
                        }
                    }
                    .onDisappear {
                        // Don't invalidate, just pause if it's the active one.
                        // The VM manages lifecycle.
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
                    .frame(width: screenSize.width, height: screenSize.height)
            }
            
            // Play/Pause Overlay Icon
            if showPlayIcon {
                Image(systemName: "play.fill")
                    .font(.system(size: 60))
                    .foregroundColor(.white.opacity(0.8))
                    .shadow(radius: 4)
                    .transition(.opacity.combined(with: .scale))
                    .allowsHitTesting(false) // Let taps pass through to the gesture
            }
            
            // Overlay Controls
            VStack {
                Spacer()
                
                HStack(alignment: .bottom) {
                    // Left Side: Text Info
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
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
                        
                         // Music/Audio placeholder
                        HStack {
                            Image(systemName: "music.note")
                            Text("Original Audio")
                                .font(.caption)
                        }
                        .foregroundColor(.white)
                        .padding(.top, 4)
                    }
                    .shadow(color: .black.opacity(0.5), radius: 2, x: 0, y: 1)
                    
                    Spacer()
                    
                    // Right Side: Action Buttons
                    VStack(spacing: 20) {
                        ActionButton(icon: "heart.fill", text: "\(reel.likesCount ?? 0)", isSelected: reel.isLiked ?? false) {
                            Task {
                                await viewModel.toggleLike(reel: reel)
                            }
                        }
                        
                        ActionButton(icon: "bubble.right.fill", text: "\(reel.commentsCount ?? 0)") {
                            showComments = true
                        }
                        
                        ActionButton(icon: reel.isBookmarked == true ? "bookmark.fill" : "bookmark", text: reel.isBookmarked == true ? "Saved" : "Save", isSelected: reel.isBookmarked ?? false) {
                            Task {
                                await viewModel.toggleBookmark(reel: reel)
                            }
                        }
                        
                        ActionButton(icon: "arrowshape.turn.up.right.fill", text: "Share") {
                             // Share action
                        }
                    }
                    .padding(.bottom, 10) // Internal spacing for buttons
                }
                .padding(.horizontal)
                // Dynamic bottom padding: Fail-safe logic. Max(safeArea, 34) + 110pt
                .padding(.bottom, max(safeAreaInsets.bottom, 34) + 110)
            }
        }
        .frame(width: screenSize.width, height: screenSize.height)
        .clipped()
        .onAppear {
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
        // Get cached player or create new one via VM
        let player = viewModel.getPlayer(for: reel)
        self.player = player
        
        // Configure audio
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
    
    var body: some View {
        ZStack {
            Color.black.edgesIgnoringSafeArea(.all)
            
            VStack {
                Spacer()
                HStack(alignment: .bottom) {
                    VStack(alignment: .leading, spacing: 10) {
                        // Avatar + Name Skeleton
                        HStack {
                            Circle()
                                .fill(Color.white.opacity(0.3))
                                .frame(width: 32, height: 32)
                            
                            RoundedRectangle(cornerRadius: 4)
                                .fill(Color.white.opacity(0.3))
                                .frame(width: 120, height: 16)
                        }
                        // Description Skeleton
                        RoundedRectangle(cornerRadius: 4)
                            .fill(Color.white.opacity(0.3))
                            .frame(width: 200, height: 14)
                        
                        RoundedRectangle(cornerRadius: 4)
                            .fill(Color.white.opacity(0.3))
                            .frame(width: 150, height: 14)
                    }
                    Spacer()
                    
                    // Buttons Skeleton
                    VStack(spacing: 20) {
                        ForEach(0..<4) { _ in
                            VStack(spacing: 6) {
                                Circle()
                                    .fill(Color.white.opacity(0.3))
                                    .frame(width: 28, height: 28)
                                RoundedRectangle(cornerRadius: 2)
                                    .fill(Color.white.opacity(0.3))
                                    .frame(width: 20, height: 10)
                            }
                        }
                    }
                    .padding(.bottom, 10)
                }
                .padding(.horizontal)
                // Match ReelView padding
                .padding(.bottom, max(safeAreaInsets.bottom, 34) + 110)
            }
        }
        .opacity(isAnimating ? 0.5 : 1.0)
        .onAppear {
            withAnimation(Animation.easeInOut(duration: 0.8).repeatForever(autoreverses: true)) {
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

// Custom Player using AVPlayerLayer for robust AspectFill
struct PlayerView: UIViewRepresentable {
    var player: AVPlayer
    
    func makeUIView(context: Context) -> PlayerUIView {
        let view = PlayerUIView(player: player)
        return view
    }
    
    func updateUIView(_ uiView: PlayerUIView, context: Context) {
        uiView.player = player
        uiView.playerLayer.videoGravity = .resizeAspectFill
    }
    
    // Inner UIView subclass to handle layer layout
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
            // Optimize for video playback
            self.backgroundColor = .black 
            self.playerLayer.videoGravity = .resizeAspectFill 
        }
        
        required init?(coder: NSCoder) {
            fatalError("init(coder:) has not been implemented")
        }
        
        override func layoutSubviews() {
            super.layoutSubviews()
            // Explicitly ensuring frame match (though layerClass usually handles this)
            playerLayer.frame = bounds
        }
    }
}

#Preview {
    ExploreView()
}
