//
//  ReelGenerationView.swift
//  projectDAM
//
//  Created by Antigravity on 12/07/2025.
//

import SwiftUI

struct ReelGenerationView: View {
    @StateObject private var viewModel: GenerateReelViewModel
    @Environment(\.dismiss) private var dismiss
    @State private var showStreamView = false
    
    init(lesson: Lesson) {
        _viewModel = StateObject(wrappedValue: GenerateReelViewModel(lesson: lesson))
    }
    
    var body: some View {
        NavigationView {
            ZStack {
                // Background gradient
                backgroundGradient
                    .ignoresSafeArea()
                
                if viewModel.isGenerating {
                    advancedLoadingView
                } else if viewModel.hasError {
                    errorView
                } else if viewModel.showSuccess {
                    successView
                } else {
                    contentView
                }
            }
            .navigationTitle("Create AI Reel")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    if !viewModel.isGenerating {
                        ToolbarIconButton(
                            systemName: "xmark",
                            accessibilityLabel: "Cancel",
                            action: { dismiss() }
                        )
                    }
                }
            }
        }
        .fullScreenCover(isPresented: $showStreamView) {
            GeneratedReelStreamView(reels: viewModel.generatedReels)
        }
    }
    
    // MARK: - Background
    private var backgroundGradient: some View {
        LinearGradient(
            colors: [
                Color(.systemBackground),
                Color(.systemGroupedBackground)
            ],
            startPoint: .top,
            endPoint: .bottom
        )
    }
    
    // MARK: - Content View
    private var contentView: some View {
        VStack(spacing: 24) {
            headerSection
            
            VStack(alignment: .leading, spacing: 12) {
                Text("Select a Video")
                    .font(.system(size: 18, weight: .bold))
                    .padding(.horizontal, DS.paddingMD)
                
                ScrollView {
                    VStack(spacing: 16) {
                        ForEach(viewModel.lesson.videos) { video in
                            videoSelectionCard(video)
                        }
                    }
                    .padding(.horizontal, DS.paddingMD)
                }
            }
            
            Spacer()
            
            generateButton
        }
        .padding(.vertical, 24)
    }
    
    // MARK: - Header Section
    private var headerSection: some View {
        VStack(spacing: 12) {
            // Animated icon
            ZStack {
                Circle()
                    .fill(
                        LinearGradient(
                            colors: [.purple.opacity(0.2), .brandPrimary.opacity(0.2)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 80, height: 80)
                
                Image(systemName: "wand.and.stars")
                    .font(.system(size: 36))
                    .foregroundStyle(
                        LinearGradient(
                            colors: [.purple, .brandPrimary],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
            }
            
            Text("Turn Lessons into Reels")
                .font(.system(size: 22, weight: .bold))
            
            Text("Select a video from this lesson and our AI will automatically identify the best highlights to create an engaging short reel.")
                .font(.system(size: 15))
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 32)
        }
    }
    
    // MARK: - Video Selection Card
    private func videoSelectionCard(_ video: VideoContent) -> some View {
        let isSelected = viewModel.selectedVideoId == video.id
        
        return Button {
            withAnimation(.spring(response: 0.3)) {
                viewModel.selectVideo(video.id)
            }
        } label: {
            HStack(spacing: 16) {
                ZStack {
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color(.secondarySystemBackground))
                        .frame(width: 80, height: 60)
                    Image(systemName: "play.fill")
                        .foregroundStyle(.secondary)
                }
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(video.title)
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundStyle(.primary)
                        .lineLimit(2)
                    
                    Text(video.formattedDuration)
                        .font(.system(size: 13))
                        .foregroundStyle(.secondary)
                }
                
                Spacer()
                
                Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                    .font(.system(size: 24))
                    .foregroundStyle(isSelected ? Color.brandPrimary : Color.gray.opacity(0.3))
            }
            .padding(12)
            .background(Color(.systemBackground))
            .cornerRadius(16)
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(isSelected ? Color.brandPrimary : Color.clear, lineWidth: 2)
            )
            .shadow(color: Color.black.opacity(0.05), radius: 8, x: 0, y: 2)
        }
        .buttonStyle(.plain)
    }
    
    // MARK: - Generate Button
    private var generateButton: some View {
        Button {
            Task {
                await viewModel.generateReel()
            }
        } label: {
            HStack(spacing: 8) {
                Image(systemName: "sparkles")
                    .font(.system(size: 16))
                Text("Generate Reel")
                    .fontWeight(.bold)
            }
            .frame(maxWidth: .infinity)
            .padding()
            .background(
                viewModel.canGenerate
                ? LinearGradient(colors: [.brandPrimary, .purple], startPoint: .leading, endPoint: .trailing)
                : LinearGradient(colors: [.gray], startPoint: .leading, endPoint: .trailing)
            )
            .foregroundStyle(.white)
            .cornerRadius(16)
            .padding(.horizontal, DS.paddingMD)
        }
        .disabled(!viewModel.canGenerate)
        .opacity(viewModel.canGenerate ? 1 : 0.6)
    }
    
    // MARK: - Advanced Loading View
    private var advancedLoadingView: some View {
        VStack(spacing: 40) {
            Spacer()
            
            // Animated circular progress
            ZStack {
                // Background circle
                Circle()
                    .stroke(Color.gray.opacity(0.2), lineWidth: 8)
                    .frame(width: 120, height: 120)
                
                // Progress circle
                Circle()
                    .trim(from: 0, to: viewModel.currentStage.progress)
                    .stroke(
                        AngularGradient(
                            colors: [.purple, .brandPrimary, .purple],
                            center: .center
                        ),
                        style: StrokeStyle(lineWidth: 8, lineCap: .round)
                    )
                    .frame(width: 120, height: 120)
                    .rotationEffect(.degrees(-90))
                    .animation(.easeInOut(duration: 0.5), value: viewModel.currentStage)
                
                // Inner content
                VStack(spacing: 4) {
                    Image(systemName: viewModel.currentStage.icon)
                        .font(.system(size: 32))
                        .foregroundStyle(
                            LinearGradient(
                                colors: [.purple, .brandPrimary],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .symbolEffect(.pulse, isActive: true)
                    
                    Text("\(Int(viewModel.currentStage.progress * 100))%")
                        .font(.caption)
                        .fontWeight(.bold)
                        .foregroundStyle(.secondary)
                }
            }
            
            // Stage info
            VStack(spacing: 12) {
                Text(viewModel.currentStage.rawValue)
                    .font(.system(size: 22, weight: .bold))
                    .contentTransition(.numericText())
                
                Text("This may take a minute. Our AI is finding the best moments from your video.")
                    .font(.system(size: 15))
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 40)
                
                // Elapsed time
                HStack(spacing: 6) {
                    Image(systemName: "clock")
                        .font(.caption)
                    Text("Elapsed: \(viewModel.formattedElapsedTime)")
                        .font(.caption)
                        .monospacedDigit()
                }
                .foregroundStyle(.tertiary)
                .padding(.top, 8)
            }
            
            // Stage indicators
            HStack(spacing: 8) {
                ForEach(GenerationStage.allCases, id: \.self) { stage in
                    Circle()
                        .fill(stageIndicatorColor(for: stage))
                        .frame(width: 8, height: 8)
                        .scaleEffect(stage == viewModel.currentStage ? 1.3 : 1.0)
                        .animation(.spring(response: 0.3), value: viewModel.currentStage)
                }
            }
            .padding(.top, 16)
            
            Spacer()
            
            // Cancel hint
            Text("Please don't close this screen")
                .font(.caption)
                .foregroundStyle(.tertiary)
                .padding(.bottom, 32)
        }
    }
    
    private func stageIndicatorColor(for stage: GenerationStage) -> Color {
        let stages = GenerationStage.allCases
        guard let currentIndex = stages.firstIndex(of: viewModel.currentStage),
              let stageIndex = stages.firstIndex(of: stage) else {
            return .gray.opacity(0.3)
        }
        
        if stageIndex < currentIndex {
            return .green
        } else if stageIndex == currentIndex {
            return .brandPrimary
        } else {
            return .gray.opacity(0.3)
        }
    }
    
    // MARK: - Error View
    private var errorView: some View {
        VStack(spacing: 24) {
            Spacer()
            
            // Error icon with animation
            ZStack {
                Circle()
                    .fill(Color.orange.opacity(0.15))
                    .frame(width: 100, height: 100)
                
                Image(systemName: viewModel.generationError?.icon ?? "exclamationmark.triangle")
                    .font(.system(size: 44))
                    .foregroundStyle(.orange)
            }
            
            VStack(spacing: 8) {
                Text("Generation Failed")
                    .font(.system(size: 24, weight: .bold))
                
                Text(viewModel.errorMessage ?? "An unexpected error occurred.")
                    .font(.system(size: 16))
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 32)
            }
            
            // Action buttons
            VStack(spacing: 12) {
                if viewModel.generationError?.isRetryable == true {
                    Button {
                        Task {
                            await viewModel.retry()
                        }
                    } label: {
                        HStack(spacing: 8) {
                            Image(systemName: "arrow.clockwise")
                            Text("Try Again")
                        }
                        .fontWeight(.bold)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(
                            LinearGradient(
                                colors: [.brandPrimary, .purple],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .foregroundStyle(.white)
                        .cornerRadius(16)
                    }
                }
                
                Button {
                    viewModel.clearError()
                } label: {
                    HStack(spacing: 8) {
                        Image(systemName: "arrow.left")
                        Text("Choose Different Video")
                    }
                    .fontWeight(.semibold)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color(.systemGray5))
                    .foregroundStyle(.primary)
                    .cornerRadius(16)
                }
                
                Button {
                    dismiss()
                } label: {
                    Text("Cancel")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
                .padding(.top, 8)
            }
            .padding(.horizontal, 32)
            
            Spacer()
        }
    }
    
    // MARK: - Success View
    private var successView: some View {
        VStack(spacing: 24) {
            Spacer()
            
            // Success icon with animation
            ZStack {
                // Outer glow
                Circle()
                    .fill(Color.green.opacity(0.1))
                    .frame(width: 140, height: 140)
                
                Circle()
                    .fill(Color.green.opacity(0.15))
                    .frame(width: 100, height: 100)
                
                Image(systemName: "checkmark.circle.fill")
                    .font(.system(size: 64))
                    .foregroundStyle(.green)
                    .symbolEffect(.bounce, value: viewModel.showSuccess)
            }
            .scaleEffect(viewModel.showSuccess ? 1.0 : 0.5)
            .animation(.spring(response: 0.4, dampingFraction: 0.6), value: viewModel.showSuccess)
            
            VStack(spacing: 8) {
                Text("Reels Generated!")
                    .font(.system(size: 24, weight: .bold))
                
                Text("\(viewModel.generatedReels.count) reel\(viewModel.generatedReels.count != 1 ? "s" : "") created from your video")
                    .font(.system(size: 16))
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                
                if let elapsed = viewModel.generationStartTime {
                    let duration = Date().timeIntervalSince(elapsed)
                    Text("Completed in \(String(format: "%.0f", duration)) seconds")
                        .font(.caption)
                        .foregroundStyle(.tertiary)
                        .padding(.top, 4)
                }
            }
            
            Spacer()
            
            // Buttons
            VStack(spacing: 12) {
                // Primary: Watch Now
                Button {
                    showStreamView = true
                } label: {
                    HStack(spacing: 8) {
                        Image(systemName: "play.fill")
                            .font(.system(size: 16))
                        Text("Watch Now")
                            .fontWeight(.bold)
                    }
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(
                        LinearGradient(
                            colors: [.brandPrimary, .purple],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .foregroundStyle(.white)
                    .cornerRadius(16)
                    .shadow(color: .brandPrimary.opacity(0.3), radius: 10, x: 0, y: 5)
                }
                .disabled(viewModel.generatedReels.isEmpty)
                
                // Secondary: View in Feed
                Button {
                    dismiss()
                } label: {
                    HStack(spacing: 8) {
                        Image(systemName: "safari.fill")
                            .font(.system(size: 16))
                        Text("Explore Feed")
                            .fontWeight(.semibold)
                    }
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color(.systemGray5))
                    .foregroundStyle(.primary)
                    .cornerRadius(16)
                }
            }
            .padding(.horizontal, 32)
            .padding(.bottom, 32)
        }
    }
}

#Preview {
    ReelGenerationView(lesson: .sampleLesson)
}
