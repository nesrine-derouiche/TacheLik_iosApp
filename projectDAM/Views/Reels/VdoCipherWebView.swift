//
//  VdoCipherWebView.swift
//  projectDAM
//
//  WebView wrapper for playing VdoCipher and YouTube videos in Reels
//

import SwiftUI
import WebKit

// MARK: - VdoCipher Reel Player (fetches OTP dynamically)
struct VdoCipherReelPlayer: View {
    let videoId: String
    let isActive: Bool
    var thumbnailUrl: URL? = nil
    
    @State private var playbackUrl: String?
    @State private var isLoading = true
    @State private var error: String?
    @State private var showFallback = false
    
    var body: some View {
        ZStack {
            if showFallback {
                // Fallback: Show animated thumbnail
                VdoCipherFallbackView(thumbnailUrl: thumbnailUrl, isActive: isActive)
            } else if isLoading {
                // Loading state with thumbnail background
                ZStack {
                    if let thumbUrl = thumbnailUrl {
                        AsyncImage(url: thumbUrl) { image in
                            image.resizable().aspectRatio(contentMode: .fill)
                        } placeholder: {
                            Color.black
                        }
                        .overlay(Color.black.opacity(0.5))
                    }
                    
                    VStack(spacing: 16) {
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle(tint: .white))
                            .scaleEffect(1.5)
                        Text("Loading video...")
                            .font(.caption)
                            .foregroundColor(.white.opacity(0.8))
                    }
                }
            } else if let url = playbackUrl, let videoURL = URL(string: url) {
                VdoCipherWebView(url: videoURL, autoPlay: isActive)
            } else {
                // Error state - show fallback
                VdoCipherFallbackView(thumbnailUrl: thumbnailUrl, isActive: isActive)
            }
        }
        .task {
            await loadPlaybackUrl()
        }
        .onChange(of: isActive) { active in
            if active && playbackUrl == nil && !showFallback {
                Task {
                    await loadPlaybackUrl()
                }
            }
        }
    }
    
    private func loadPlaybackUrl() async {
        guard isActive else { return }
        
        isLoading = true
        error = nil
        
        do {
            let vdoService = DIContainer.shared.vdoCipherService
            let url = try await vdoService.getPlaybackUrl(videoId: videoId)
            print("✅ [VdoCipherReelPlayer] Got playback URL for \(videoId)")
            await MainActor.run {
                playbackUrl = url
                isLoading = false
            }
        } catch {
            print("❌ [VdoCipherReelPlayer] Failed to get playback URL for \(videoId): \(error)")
            await MainActor.run {
                self.error = "Video unavailable"
                self.showFallback = true
                isLoading = false
            }
        }
    }
}

// MARK: - VdoCipher Fallback View (animated thumbnail)
struct VdoCipherFallbackView: View {
    let thumbnailUrl: URL?
    let isActive: Bool
    
    @State private var pulseScale: CGFloat = 1.0
    
    var body: some View {
        ZStack {
            // Background
            if let url = thumbnailUrl {
                AsyncImage(url: url) { image in
                    image
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                } placeholder: {
                    gradientBackground
                }
            } else {
                gradientBackground
            }
            
            // Gradient overlay
            LinearGradient(
                colors: [Color.black.opacity(0.3), Color.clear, Color.black.opacity(0.5)],
                startPoint: .top,
                endPoint: .bottom
            )
            
            // Play icon
            VStack(spacing: 16) {
                Image(systemName: "play.circle.fill")
                    .font(.system(size: 70))
                    .foregroundStyle(.white.opacity(0.9))
                    .scaleEffect(pulseScale)
                    .shadow(color: .black.opacity(0.3), radius: 10)
                
                Text("60s Course Highlight")
                    .font(.caption)
                    .fontWeight(.semibold)
                    .foregroundColor(.white)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 8)
                    .background(Capsule().fill(Color.black.opacity(0.5)))
            }
        }
        .onAppear {
            if isActive {
                withAnimation(.easeInOut(duration: 0.8).repeatForever(autoreverses: true)) {
                    pulseScale = 1.15
                }
            }
        }
        .onChange(of: isActive) { active in
            if active {
                withAnimation(.easeInOut(duration: 0.8).repeatForever(autoreverses: true)) {
                    pulseScale = 1.15
                }
            } else {
                pulseScale = 1.0
            }
        }
    }
    
    private var gradientBackground: some View {
        LinearGradient(
            colors: [Color.purple.opacity(0.8), Color.blue.opacity(0.6), Color.indigo.opacity(0.9)],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }
}

// MARK: - VdoCipher Web View (60 second reel clip)
struct VdoCipherWebView: UIViewRepresentable {
    let url: URL
    let autoPlay: Bool
    var startTime: Int = 0   // Start time in seconds
    let duration: Int = 60   // 60 second reel
    
    func makeUIView(context: Context) -> WKWebView {
        let configuration = WKWebViewConfiguration()
        configuration.allowsInlineMediaPlayback = true
        configuration.mediaTypesRequiringUserActionForPlayback = []
        
        let webView = WKWebView(frame: .zero, configuration: configuration)
        webView.isOpaque = false
        webView.backgroundColor = .black
        webView.scrollView.isScrollEnabled = false
        webView.scrollView.bounces = false
        
        return webView
    }
    
    func updateUIView(_ webView: WKWebView, context: Context) {
        // VdoCipher player with 60-second limit
        let html = """
        <!DOCTYPE html>
        <html>
        <head>
            <meta name="viewport" content="width=device-width, initial-scale=1.0, maximum-scale=1.0, user-scalable=no">
            <style>
                * { margin: 0; padding: 0; box-sizing: border-box; }
                html, body { 
                    width: 100%; 
                    height: 100%; 
                    background: #000; 
                    overflow: hidden;
                }
                iframe {
                    position: absolute;
                    top: 0;
                    left: 0;
                    width: 100%;
                    height: 100%;
                    border: none;
                }
                #progress-bar {
                    position: absolute;
                    bottom: 80px;
                    left: 20px;
                    right: 20px;
                    height: 3px;
                    background: rgba(255,255,255,0.3);
                    border-radius: 2px;
                    z-index: 100;
                }
                #progress-fill {
                    height: 100%;
                    background: linear-gradient(90deg, #9333ea, #ec4899, #f97316);
                    border-radius: 2px;
                    width: 0%;
                    transition: width 1s linear;
                }
                #time-display {
                    position: absolute;
                    bottom: 90px;
                    right: 20px;
                    color: white;
                    font-family: -apple-system, sans-serif;
                    font-size: 12px;
                    z-index: 100;
                }
            </style>
        </head>
        <body>
            <iframe 
                id="vdo-player"
                src="\(url.absoluteString)&autoplay=\(autoPlay ? "true" : "false")&t=\(startTime)"
                allow="autoplay; fullscreen; encrypted-media"
                allowfullscreen>
            </iframe>
            <div id="progress-bar"><div id="progress-fill"></div></div>
            <div id="time-display">0:00 / 1:00</div>
            <script>
                var startTime = \(startTime);
                var duration = \(duration);
                var elapsed = 0;
                
                // Simple timer-based progress (VdoCipher doesn't expose easy JS API)
                setInterval(function() {
                    elapsed++;
                    if (elapsed > duration) {
                        elapsed = 0;
                        // Reload iframe to restart
                        var iframe = document.getElementById('vdo-player');
                        iframe.src = iframe.src;
                    }
                    
                    var progress = (elapsed / duration) * 100;
                    document.getElementById('progress-fill').style.width = progress + '%';
                    
                    var mins = Math.floor(elapsed / 60);
                    var secs = elapsed % 60;
                    document.getElementById('time-display').innerText = 
                        mins + ':' + (secs < 10 ? '0' : '') + secs + ' / 1:00';
                }, 1000);
            </script>
        </body>
        </html>
        """
        
        webView.loadHTMLString(html, baseURL: nil)
    }
}

// MARK: - YouTube Web View (for YouTube reels)
struct YouTubeWebView: UIViewRepresentable {
    let videoId: String
    let autoPlay: Bool
    
    func makeUIView(context: Context) -> WKWebView {
        let configuration = WKWebViewConfiguration()
        configuration.allowsInlineMediaPlayback = true
        configuration.mediaTypesRequiringUserActionForPlayback = []
        
        let webView = WKWebView(frame: .zero, configuration: configuration)
        webView.isOpaque = false
        webView.backgroundColor = .black
        webView.scrollView.isScrollEnabled = false
        webView.scrollView.bounces = false
        
        return webView
    }
    
    func updateUIView(_ webView: WKWebView, context: Context) {
        let html = """
        <!DOCTYPE html>
        <html>
        <head>
            <meta name="viewport" content="width=device-width, initial-scale=1.0, maximum-scale=1.0, user-scalable=no">
            <style>
                * { margin: 0; padding: 0; box-sizing: border-box; }
                html, body { 
                    width: 100%; 
                    height: 100%; 
                    background: #000; 
                    overflow: hidden;
                }
                iframe {
                    position: absolute;
                    top: 0;
                    left: 0;
                    width: 100%;
                    height: 100%;
                    border: none;
                }
            </style>
        </head>
        <body>
            <iframe 
                src="https://www.youtube.com/embed/\(videoId)?autoplay=\(autoPlay ? "1" : "0")&playsinline=1&controls=0&modestbranding=1&rel=0&mute=0&loop=1&playlist=\(videoId)"
                allow="autoplay; fullscreen; encrypted-media"
                allowfullscreen>
            </iframe>
        </body>
        </html>
        """
        
        webView.loadHTMLString(html, baseURL: nil)
    }
}

// MARK: - Better YouTube Player for Reels (uses YouTube IFrame API)
struct ReelYouTubePlayerView: View {
    let videoId: String
    let isActive: Bool
    var startTime: Int = 0  // Start time in seconds (default: beginning)
    let duration: Int = 60  // Reel duration: 60 seconds
    
    @State private var showFallback = false
    
    var body: some View {
        ZStack {
            if showFallback {
                // Fallback: Show thumbnail with play button that opens in Safari
                YouTubeThumbnailView(videoId: videoId)
            } else {
                YouTubeReelPlayer(
                    videoId: videoId,
                    autoPlay: isActive,
                    startTime: startTime,
                    duration: duration,
                    onError: {
                        showFallback = true
                    }
                )
            }
        }
    }
}

// MARK: - YouTube Thumbnail Fallback
struct YouTubeThumbnailView: View {
    let videoId: String
    
    var body: some View {
        ZStack {
            // YouTube thumbnail
            AsyncImage(url: URL(string: "https://img.youtube.com/vi/\(videoId)/maxresdefault.jpg")) { phase in
                switch phase {
                case .success(let image):
                    image
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                case .failure:
                    // Try lower quality thumbnail
                    AsyncImage(url: URL(string: "https://img.youtube.com/vi/\(videoId)/hqdefault.jpg")) { innerPhase in
                        switch innerPhase {
                        case .success(let img):
                            img.resizable().aspectRatio(contentMode: .fill)
                        default:
                            Color.black
                        }
                    }
                default:
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle(tint: .white))
                }
            }
            
            // Play button overlay
            VStack(spacing: 12) {
                Image(systemName: "play.fill")
                    .font(.system(size: 50))
                    .foregroundColor(.white)
                    .padding(25)
                    .background(Circle().fill(Color.red))
                    .shadow(radius: 10)
                
                Text("Tap to watch on YouTube")
                    .font(.caption)
                    .foregroundColor(.white)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 8)
                    .background(Capsule().fill(Color.black.opacity(0.6)))
            }
        }
        .onTapGesture {
            if let url = URL(string: "https://www.youtube.com/watch?v=\(videoId)") {
                UIApplication.shared.open(url)
            }
        }
    }
}

// MARK: - YouTube Reel Player (60 second clip)
struct YouTubeReelPlayer: UIViewRepresentable {
    let videoId: String
    let autoPlay: Bool
    let startTime: Int      // Start time in seconds
    let duration: Int       // Duration in seconds (60 for reels)
    var onError: (() -> Void)?
    
    func makeCoordinator() -> Coordinator {
        Coordinator(onError: onError)
    }
    
    func makeUIView(context: Context) -> WKWebView {
        let configuration = WKWebViewConfiguration()
        configuration.allowsInlineMediaPlayback = true
        configuration.mediaTypesRequiringUserActionForPlayback = []
        
        let webView = WKWebView(frame: .zero, configuration: configuration)
        webView.isOpaque = false
        webView.backgroundColor = .black
        webView.scrollView.isScrollEnabled = false
        webView.scrollView.bounces = false
        webView.navigationDelegate = context.coordinator
        
        return webView
    }
    
    func updateUIView(_ webView: WKWebView, context: Context) {
        let endTime = startTime + duration
        
        // YouTube IFrame API with 60-second limit
        let html = """
        <!DOCTYPE html>
        <html>
        <head>
            <meta name="viewport" content="width=device-width, initial-scale=1.0, maximum-scale=1.0, user-scalable=no">
            <style>
                * { margin: 0; padding: 0; box-sizing: border-box; }
                html, body { width: 100%; height: 100%; background: #000; overflow: hidden; }
                #player { position: absolute; top: 0; left: 0; width: 100%; height: 100%; }
                #progress-bar {
                    position: absolute;
                    bottom: 80px;
                    left: 20px;
                    right: 20px;
                    height: 3px;
                    background: rgba(255,255,255,0.3);
                    border-radius: 2px;
                    z-index: 100;
                }
                #progress-fill {
                    height: 100%;
                    background: linear-gradient(90deg, #9333ea, #ec4899, #f97316);
                    border-radius: 2px;
                    width: 0%;
                    transition: width 0.5s linear;
                }
                #time-display {
                    position: absolute;
                    bottom: 90px;
                    right: 20px;
                    color: white;
                    font-family: -apple-system, sans-serif;
                    font-size: 12px;
                    z-index: 100;
                }
            </style>
        </head>
        <body>
            <div id="player"></div>
            <div id="progress-bar"><div id="progress-fill"></div></div>
            <div id="time-display">0:00 / 1:00</div>
            <script src="https://www.youtube.com/iframe_api"></script>
            <script>
                var player;
                var startTime = \(startTime);
                var duration = \(duration);
                var checkInterval;
                
                function onYouTubeIframeAPIReady() {
                    player = new YT.Player('player', {
                        videoId: '\(videoId)',
                        playerVars: {
                            'autoplay': \(autoPlay ? 1 : 0),
                            'playsinline': 1,
                            'controls': 0,
                            'modestbranding': 1,
                            'rel': 0,
                            'start': startTime,
                            'origin': 'https://tache-lik.tn',
                            'showinfo': 0,
                            'iv_load_policy': 3
                        },
                        events: {
                            'onReady': onPlayerReady,
                            'onStateChange': onPlayerStateChange,
                            'onError': onPlayerError
                        }
                    });
                }
                
                function onPlayerReady(event) {
                    event.target.seekTo(startTime, true);
                    \(autoPlay ? "event.target.playVideo();" : "")
                    startTimeCheck();
                }
                
                function onPlayerStateChange(event) {
                    if (event.data == YT.PlayerState.PLAYING) {
                        startTimeCheck();
                    }
                }
                
                function startTimeCheck() {
                    if (checkInterval) clearInterval(checkInterval);
                    checkInterval = setInterval(function() {
                        if (player && player.getCurrentTime) {
                            var currentTime = player.getCurrentTime();
                            var elapsed = currentTime - startTime;
                            
                            // Update progress bar
                            var progress = Math.min((elapsed / duration) * 100, 100);
                            document.getElementById('progress-fill').style.width = progress + '%';
                            
                            // Update time display
                            var mins = Math.floor(elapsed / 60);
                            var secs = Math.floor(elapsed % 60);
                            document.getElementById('time-display').innerText = 
                                mins + ':' + (secs < 10 ? '0' : '') + secs + ' / 1:00';
                            
                            // Loop back after 60 seconds
                            if (elapsed >= duration) {
                                player.seekTo(startTime, true);
                                player.playVideo();
                            }
                        }
                    }, 500);
                }
                
                function onPlayerError(event) {
                    window.webkit.messageHandlers.youtubeError.postMessage(event.data);
                }
            </script>
        </body>
        </html>
        """
        
        // Add message handler for errors
        let contentController = webView.configuration.userContentController
        contentController.removeScriptMessageHandler(forName: "youtubeError")
        contentController.add(context.coordinator, name: "youtubeError")
        
        webView.loadHTMLString(html, baseURL: URL(string: "https://tache-lik.tn"))
    }
    
    class Coordinator: NSObject, WKNavigationDelegate, WKScriptMessageHandler {
        var onError: (() -> Void)?
        
        init(onError: (() -> Void)?) {
            self.onError = onError
        }
        
        func userContentController(_ userContentController: WKUserContentController, didReceive message: WKScriptMessage) {
            if message.name == "youtubeError" {
                print("⚠️ YouTube error: \(message.body)")
                DispatchQueue.main.async {
                    self.onError?()
                }
            }
        }
        
        func webView(_ webView: WKWebView, didFail navigation: WKNavigation!, withError error: Error) {
            print("⚠️ WebView navigation failed: \(error)")
            onError?()
        }
    }
}
