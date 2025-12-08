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
    
    init(lesson: Lesson) {
        _viewModel = StateObject(wrappedValue: GenerateReelViewModel(lesson: lesson))
    }
    
    var body: some View {
        NavigationView {
            ZStack {
                Color(.systemGroupedBackground)
                    .ignoresSafeArea()
                
                if viewModel.isGenerating {
                    loadingView
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
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
        }
    }
    
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
    
    private var headerSection: some View {
        VStack(spacing: 12) {
            Image(systemName: "wand.and.stars")
                .font(.system(size: 44))
                .foregroundStyle(
                    LinearGradient(
                        colors: [.purple, .brandPrimary],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
            
            Text("Turn Lessons into Reels")
                .font(.system(size: 22, weight: .bold))
            
            Text("Select a video from this lesson and our AI will automatically identify the best highlights to create an engaging short reel.")
                .font(.system(size: 15))
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 32)
        }
    }
    
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
    
    private var generateButton: some View {
        Button {
            Task {
                await viewModel.generateReel()
            }
        } label: {
            HStack(spacing: 8) {
                if viewModel.isGenerating {
                    ProgressView()
                        .tint(.white)
                }
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
    
    private var loadingView: some View {
        VStack(spacing: 32) {
            ZStack {
                Circle()
                    .stroke(Color.gray.opacity(0.2), lineWidth: 8)
                    .frame(width: 80, height: 80)
                
                Circle()
                    .trim(from: 0, to: 0.7)
                    .stroke(
                        LinearGradient(colors: [.purple, .brandPrimary], startPoint: .top, endPoint: .bottom),
                        style: StrokeStyle(lineWidth: 8, lineCap: .round)
                    )
                    .frame(width: 80, height: 80)
                    .rotationEffect(.degrees(360))
                    .animation(Animation.linear(duration: 1.5).repeatForever(autoreverses: false), value: viewModel.isGenerating)
            }
            
            VStack(spacing: 8) {
                Text("Creating Magic...")
                    .font(.system(size: 20, weight: .bold))
                Text("Our AI is analyzing the video to find the best moments.")
                    .font(.system(size: 15))
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 40)
            }
        }
    }
    
    private var successView: some View {
        VStack(spacing: 24) {
            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 64))
                .foregroundStyle(.green)
                .scaleEffect(1.1)
                .animation(.spring(response: 0.4, dampingFraction: 0.6), value: viewModel.showSuccess)
            
            Text("Reels Generated!")
                .font(.system(size: 24, weight: .bold))
            
            Text("Your new reels are ready and have been added to the feed.")
                .font(.system(size: 16))
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
            
            Button {
                dismiss()
                // In a real app, we might want to navigate to the Explore tab directly
                // For now, dismissing allows the user to continue or go there manually
            } label: {
                Text("View in Feed")
                    .fontWeight(.bold)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.brandPrimary)
                    .foregroundStyle(.white)
                    .cornerRadius(16)
            }
            .padding(.horizontal, 32)
        }
        .padding(32)
    }
}

#Preview {
    ReelGenerationView(lesson: .sampleLesson)
}
