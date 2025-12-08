//
//  GenerateReelViewModel.swift
//  projectDAM
//
//  Created by Antigravity on 12/07/2025.
//

import Foundation
import SwiftUI
import Combine

@MainActor
class GenerateReelViewModel: ObservableObject {
    @Published var selectedVideoId: String?
    @Published var isGenerating: Bool = false
    @Published var errorMessage: String?
    @Published var generatedReels: [Reel] = []
    @Published var showSuccess: Bool = false
    
    let lesson: Lesson
    private let reelsService: ReelsServiceProtocol
    
    init(lesson: Lesson, reelsService: ReelsServiceProtocol = DIContainer.shared.reelsService) {
        self.lesson = lesson
        self.reelsService = reelsService
    }
    
    var canGenerate: Bool {
        return selectedVideoId != nil && !isGenerating
    }
    
    func generateReel() async {
        guard let videoId = selectedVideoId else { return }
        
        isGenerating = true
        errorMessage = nil
        
        let startTime = Date()
        print("[GenerateReelViewModel] 🎬 Starting reel generation for videoId: \(videoId)")
        
        do {
            generatedReels = try await reelsService.generateReels(videoId: videoId)
            
            let duration = Date().timeIntervalSince(startTime)
            print("[GenerateReelViewModel] ✅ Generation succeeded in \(String(format: "%.2f", duration))s")
            print("[GenerateReelViewModel] 📊 Generated \(generatedReels.count) reels")
            
            // Log each reel's details for debugging
            for (index, reel) in generatedReels.enumerated() {
                let filename = reel.filePath?.components(separatedBy: "/").last ?? "MISSING"
                print("[GenerateReelViewModel] 📹 Reel \(index + 1): id=\(reel.id), filename=\(filename)")
            }
            
            // Push generated reels to the feed manager for immediate display
            if !generatedReels.isEmpty {
                await ReelFeedManager.shared.addGeneratedReels(generatedReels)
            }
            
            showSuccess = true
        } catch {
            let duration = Date().timeIntervalSince(startTime)
            print("[GenerateReelViewModel] ❌ Generation failed after \(String(format: "%.2f", duration))s: \(error)")
            errorMessage = error.localizedDescription
        }
        
        isGenerating = false
    }
    
    func selectVideo(_ id: String) {
        if selectedVideoId == id {
            selectedVideoId = nil
        } else {
            selectedVideoId = id
        }
    }
}
