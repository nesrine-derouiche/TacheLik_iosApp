//
//  AIReelGeneratorView.swift
//  projectDAM
//
//  Teacher interface for generating Reels from lesson videos using AI
//

import SwiftUI

struct AIReelGeneratorView: View {
    @StateObject private var viewModel: AIReelGeneratorViewModel
    @Environment(\.dismiss) private var dismiss
    
    init() {
        let service = DIContainer.shared.resolve(AIReelGeneratorServiceProtocol.self)
        _viewModel = StateObject(wrappedValue: AIReelGeneratorViewModel(service: service))
    }
    
    var body: some View {
        NavigationStack {
            ZStack {
                // Background gradient
                LinearGradient(
                    colors: [Color(hex: "1a1a2e"), Color(hex: "16213e")],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 24) {
                        // Header Section
                        headerSection
                        
                        // Content based on state
                        switch viewModel.state {
                        case .loadingVideos:
                            loadingView(message: "Loading your videos...")
                            
                        case .analyzing:
                            loadingView(message: "AI is analyzing your video...")
                            
                        case .creating:
                            loadingView(message: "Creating reels...")
                            
                        case .error(let message):
                            errorView(message: message)
                            
                        case .success:
                            successView
                            
                        case .idle:
                            if viewModel.analysisResult != nil {
                                clipSelectionSection
                            } else {
                                contentSection
                            }
                        }
                    }
                    .padding()
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Close") {
                        dismiss()
                    }
                    .foregroundColor(.white)
                }
                
                if viewModel.analysisResult != nil {
                    ToolbarItem(placement: .navigationBarTrailing) {
                        Button("Reset") {
                            viewModel.reset()
                        }
                        .foregroundColor(.orange)
                    }
                }
            }
            .task {
                await viewModel.loadVideos()
            }
            .alert("Success!", isPresented: $viewModel.showSuccessAlert) {
                Button("View Reels") {
                    viewModel.reset()
                }
                Button("Create More", role: .cancel) {
                    viewModel.reset()
                }
            } message: {
                Text(viewModel.successMessage)
            }
        }
    }
    
    // MARK: - Header Section
    private var headerSection: some View {
        VStack(spacing: 12) {
            // AI Icon
            ZStack {
                Circle()
                    .fill(LinearGradient(
                        colors: [.purple, .pink],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ))
                    .frame(width: 80, height: 80)
                
                Image(systemName: "wand.and.stars")
                    .font(.system(size: 36))
                    .foregroundColor(.white)
            }
            
            Text("AI Reel Generator")
                .font(.title2.bold())
                .foregroundColor(.white)
            
            Text("Transform your lesson videos into engaging short-form content")
                .font(.subheadline)
                .foregroundColor(.gray)
                .multilineTextAlignment(.center)
        }
        .padding(.top)
    }
    
    // MARK: - Content Section
    private var contentSection: some View {
        VStack(spacing: 24) {
            // Quick Actions
            quickActionsSection
            
            // Videos List
            if !viewModel.videos.isEmpty {
                videosSection
            }
            
            // Courses for Auto-Generate
            if !viewModel.courses.isEmpty {
                coursesSection
            }
        }
    }
    
    // MARK: - Quick Actions
    private var quickActionsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Quick Actions")
                .font(.headline)
                .foregroundColor(.white)
            
            HStack(spacing: 12) {
                QuickActionCard(
                    icon: "sparkles",
                    title: "Auto Generate",
                    subtitle: "AI picks best moments",
                    color: .purple
                ) {
                    // Auto generate from first course
                    if let firstCourse = viewModel.courses.first {
                        Task {
                            await viewModel.autoGenerateForCourse(firstCourse)
                        }
                    }
                }
                
                QuickActionCard(
                    icon: "video.badge.waveform",
                    title: "Manual Select",
                    subtitle: "Choose your clips",
                    color: .blue
                ) {
                    // Just scroll to videos section
                }
            }
        }
    }
    
    // MARK: - Videos Section
    private var videosSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Your Videos")
                    .font(.headline)
                    .foregroundColor(.white)
                
                Spacer()
                
                Text("\(viewModel.videos.count) available")
                    .font(.caption)
                    .foregroundColor(.gray)
            }
            
            ForEach(viewModel.videos) { video in
                VideoCard(video: video) {
                    Task {
                        await viewModel.analyzeVideo(video)
                    }
                } onQuickCreate: {
                    Task {
                        await viewModel.quickCreateReel(from: video)
                    }
                }
            }
        }
    }
    
    // MARK: - Courses Section
    private var coursesSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Auto-Generate by Course")
                .font(.headline)
                .foregroundColor(.white)
            
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 12) {
                    ForEach(viewModel.courses) { course in
                        CourseCard(course: course) {
                            Task {
                                await viewModel.autoGenerateForCourse(course)
                            }
                        }
                    }
                }
            }
        }
    }
    
    // MARK: - Clip Selection Section
    private var clipSelectionSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            if let video = viewModel.selectedVideo {
                HStack {
                    VStack(alignment: .leading) {
                        Text("Analyzing")
                            .font(.caption)
                            .foregroundColor(.gray)
                        Text(video.title)
                            .font(.headline)
                            .foregroundColor(.white)
                    }
                    Spacer()
                }
            }
            
            if let analysis = viewModel.analysisResult {
                Text("AI Suggested Clips")
                    .font(.headline)
                    .foregroundColor(.white)
                
                ForEach(analysis.suggestedClips) { clip in
                    ClipSuggestionCard(
                        clip: clip,
                        isSelected: viewModel.selectedClips.contains(clip.id)
                    ) {
                        viewModel.toggleClipSelection(clip)
                    }
                }
                
                // Create Button
                if !viewModel.selectedClips.isEmpty {
                    Button {
                        Task {
                            await viewModel.createReelsFromSelectedClips()
                        }
                    } label: {
                        HStack {
                            Image(systemName: "wand.and.stars")
                            Text("Create \(viewModel.selectedClips.count) Reel(s)")
                        }
                        .font(.headline)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(
                            LinearGradient(
                                colors: [.purple, .pink],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .cornerRadius(12)
                    }
                }
            }
        }
    }
    
    // MARK: - Loading View
    private func loadingView(message: String) -> some View {
        VStack(spacing: 20) {
            ProgressView()
                .scaleEffect(1.5)
                .tint(.purple)
            
            Text(message)
                .font(.subheadline)
                .foregroundColor(.gray)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 60)
    }
    
    // MARK: - Error View
    private func errorView(message: String) -> some View {
        VStack(spacing: 16) {
            Image(systemName: "exclamationmark.triangle.fill")
                .font(.system(size: 48))
                .foregroundColor(.red)
            
            Text(message)
                .font(.subheadline)
                .foregroundColor(.gray)
                .multilineTextAlignment(.center)
            
            Button("Try Again") {
                Task {
                    await viewModel.loadVideos()
                }
            }
            .foregroundColor(.white)
            .padding(.horizontal, 24)
            .padding(.vertical, 12)
            .background(Color.blue)
            .cornerRadius(8)
        }
        .padding(.vertical, 40)
    }
    
    // MARK: - Success View
    private var successView: some View {
        VStack(spacing: 20) {
            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 64))
                .foregroundColor(.green)
            
            Text(viewModel.successMessage)
                .font(.headline)
                .foregroundColor(.white)
                .multilineTextAlignment(.center)
            
            if !viewModel.createdReels.isEmpty {
                Text("Created Reels:")
                    .font(.subheadline)
                    .foregroundColor(.gray)
                
                ForEach(viewModel.createdReels) { reel in
                    HStack {
                        Image(systemName: "play.rectangle.fill")
                            .foregroundColor(.purple)
                        Text(reel.title)
                            .foregroundColor(.white)
                        Spacer()
                        Text("\(reel.duration)s")
                            .font(.caption)
                            .foregroundColor(.gray)
                    }
                    .padding()
                    .background(Color.white.opacity(0.1))
                    .cornerRadius(8)
                }
            }
            
            Button("Create More Reels") {
                viewModel.reset()
            }
            .foregroundColor(.white)
            .padding(.horizontal, 24)
            .padding(.vertical, 12)
            .background(
                LinearGradient(
                    colors: [.purple, .pink],
                    startPoint: .leading,
                    endPoint: .trailing
                )
            )
            .cornerRadius(8)
        }
        .padding(.vertical, 40)
    }
}

// MARK: - Supporting Views

struct QuickActionCard: View {
    let icon: String
    let title: String
    let subtitle: String
    let color: Color
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(alignment: .leading, spacing: 8) {
                Image(systemName: icon)
                    .font(.title2)
                    .foregroundColor(color)
                
                Text(title)
                    .font(.subheadline.bold())
                    .foregroundColor(.white)
                
                Text(subtitle)
                    .font(.caption)
                    .foregroundColor(.gray)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding()
            .background(Color.white.opacity(0.1))
            .cornerRadius(12)
        }
    }
}

struct VideoCard: View {
    let video: VideoForReel
    let onAnalyze: () -> Void
    let onQuickCreate: () -> Void
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 12) {
                // Thumbnail
                AsyncImage(url: URL(string: video.thumbnailUrl ?? "")) { phase in
                    switch phase {
                    case .success(let image):
                        image
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                    default:
                        Rectangle()
                            .fill(Color.gray.opacity(0.3))
                            .overlay(
                                Image(systemName: "video.fill")
                                    .foregroundColor(.gray)
                            )
                    }
                }
                .frame(width: 80, height: 60)
                .cornerRadius(8)
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(video.title)
                        .font(.subheadline.bold())
                        .foregroundColor(.white)
                        .lineLimit(2)
                    
                    Text(formatDuration(video.duration))
                        .font(.caption)
                        .foregroundColor(.gray)
                }
                
                Spacer()
            }
            
            HStack(spacing: 12) {
                Button(action: onAnalyze) {
                    Label("Analyze", systemImage: "wand.and.rays")
                        .font(.caption.bold())
                        .foregroundColor(.purple)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(Color.purple.opacity(0.2))
                        .cornerRadius(6)
                }
                
                Button(action: onQuickCreate) {
                    Label("Quick Create", systemImage: "bolt.fill")
                        .font(.caption.bold())
                        .foregroundColor(.orange)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(Color.orange.opacity(0.2))
                        .cornerRadius(6)
                }
            }
        }
        .padding()
        .background(Color.white.opacity(0.1))
        .cornerRadius(12)
    }
    
    private func formatDuration(_ seconds: Int) -> String {
        let minutes = seconds / 60
        let secs = seconds % 60
        return String(format: "%d:%02d", minutes, secs)
    }
}

struct CourseCard: View {
    let course: CourseForReel
    let onGenerate: () -> Void
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            AsyncImage(url: URL(string: course.thumbnailUrl ?? "")) { phase in
                switch phase {
                case .success(let image):
                    image
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                default:
                    Rectangle()
                        .fill(Color.gray.opacity(0.3))
                        .overlay(
                            Image(systemName: "book.fill")
                                .foregroundColor(.gray)
                        )
                }
            }
            .frame(width: 140, height: 80)
            .cornerRadius(8)
            
            Text(course.title)
                .font(.caption.bold())
                .foregroundColor(.white)
                .lineLimit(2)
            
            Text("\(course.videosCount) videos")
                .font(.caption2)
                .foregroundColor(.gray)
            
            Button(action: onGenerate) {
                Text("Auto Generate")
                    .font(.caption2.bold())
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 6)
                    .background(
                        LinearGradient(
                            colors: [.purple, .pink],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .cornerRadius(6)
            }
        }
        .frame(width: 140)
        .padding(10)
        .background(Color.white.opacity(0.1))
        .cornerRadius(12)
    }
}

struct ClipSuggestionCard: View {
    let clip: ClipSuggestion
    let isSelected: Bool
    let onToggle: () -> Void
    
    var body: some View {
        Button(action: onToggle) {
            HStack(spacing: 12) {
                // Selection indicator
                Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                    .foregroundColor(isSelected ? .green : .gray)
                    .font(.title2)
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(clip.title)
                        .font(.subheadline.bold())
                        .foregroundColor(.white)
                    
                    Text(clip.reason)
                        .font(.caption)
                        .foregroundColor(.gray)
                        .lineLimit(2)
                    
                    HStack(spacing: 16) {
                        Label("\(formatTime(clip.startTime))-\(formatTime(clip.endTime))", systemImage: "clock")
                        Label("Score: \(Int(clip.engagementScore * 100))%", systemImage: "star.fill")
                    }
                    .font(.caption2)
                    .foregroundColor(.purple)
                }
                
                Spacer()
            }
            .padding()
            .background(isSelected ? Color.purple.opacity(0.2) : Color.white.opacity(0.1))
            .cornerRadius(12)
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(isSelected ? Color.purple : Color.clear, lineWidth: 2)
            )
        }
    }
    
    private func formatTime(_ seconds: Int) -> String {
        let minutes = seconds / 60
        let secs = seconds % 60
        return String(format: "%d:%02d", minutes, secs)
    }
}

// MARK: - Preview

#Preview {
    AIReelGeneratorView()
}
