//
//  GenerateReelViewModel.swift
//  projectDAM
//
//  Created by Antigravity on 12/07/2025.
//

import Foundation
import SwiftUI
import Combine


// MARK: - Generation Error Types
enum ReelGenerationError: LocalizedError {
    case noVideoSelected
    case networkError(underlying: Error)
    case serverError(statusCode: Int, message: String)
    case noReelsGenerated
    case malformedResponse
    case missingFilePath(reelId: String)
    case timeout
    case unknown(Error)
    
    var errorDescription: String? {
        switch self {
        case .noVideoSelected:
            return "Please select a video to generate a reel."
        case .networkError:
            return "Network connection failed. Please check your internet and try again."
        case .serverError(let code, let message):
            return "Server error (\(code)): \(message)"
        case .noReelsGenerated:
            return "No suitable moments found in this video. Try a different video."
        case .malformedResponse:
            return "Received an invalid response from the server."
        case .missingFilePath(let reelId):
            return "Generated reel \(reelId) is missing file path."
        case .timeout:
            return "The request timed out. AI processing may take a while - please try again."
        case .unknown:
            return "An unexpected error occurred. Please try again."
        }
    }
    
    var icon: String {
        switch self {
        case .noVideoSelected:
            return "hand.tap"
        case .networkError:
            return "wifi.slash"
        case .serverError:
            return "exclamationmark.icloud"
        case .noReelsGenerated:
            return "video.slash"
        case .malformedResponse:
            return "doc.questionmark"
        case .missingFilePath:
            return "folder.badge.questionmark"
        case .timeout:
            return "clock.badge.exclamationmark"
        case .unknown:
            return "exclamationmark.triangle"
        }
    }
    
    var isRetryable: Bool {
        switch self {
        case .networkError, .serverError, .timeout, .unknown, .malformedResponse:
            return true
        case .noVideoSelected, .noReelsGenerated, .missingFilePath:
            return false
        }
    }
}

// MARK: - Generation Stage
enum GenerationStage: String, CaseIterable {
    case preparing = "Preparing..."
    case uploading = "Sending to AI..."
    case analyzing = "Analyzing video..."
    case extracting = "Finding best moments..."
    case processing = "Processing clips..."
    case finalizing = "Finalizing reels..."
    
    var icon: String {
        switch self {
        case .preparing: return "gearshape.fill"
        case .uploading: return "icloud.and.arrow.up.fill"
        case .analyzing: return "brain.head.profile"
        case .extracting: return "sparkles"
        case .processing: return "wand.and.rays"
        case .finalizing: return "checkmark.seal.fill"
        }
    }
    
    var progress: Double {
        switch self {
        case .preparing: return 0.1
        case .uploading: return 0.2
        case .analyzing: return 0.4
        case .extracting: return 0.6
        case .processing: return 0.8
        case .finalizing: return 0.95
        }
    }
}

@MainActor
class GenerateReelViewModel: ObservableObject {
    // MARK: - Published Properties
    @Published var selectedVideoId: String?
    @Published var isGenerating: Bool = false
    @Published var generationError: ReelGenerationError?
    @Published var generatedReels: [Reel] = []
    @Published var showSuccess: Bool = false
    @Published var currentStage: GenerationStage = .preparing
    @Published var elapsedTime: TimeInterval = 0
    
    // MARK: - Properties
    let lesson: Lesson
    private let reelsService: ReelsServiceProtocol
    private var stageTimer: Timer?
    private var elapsedTimer: Timer?
    private(set) var generationStartTime: Date?
    
    // MARK: - Initialization
    init(lesson: Lesson, reelsService: ReelsServiceProtocol = DIContainer.shared.reelsService) {
        self.lesson = lesson
        self.reelsService = reelsService
    }
    
    // MARK: - Computed Properties
    var canGenerate: Bool {
        return selectedVideoId != nil && !isGenerating
    }
    
    var hasError: Bool {
        return generationError != nil
    }
    
    var errorMessage: String? {
        return generationError?.errorDescription
    }
    
    var formattedElapsedTime: String {
        let minutes = Int(elapsedTime) / 60
        let seconds = Int(elapsedTime) % 60
        return String(format: "%d:%02d", minutes, seconds)
    }
    
    var generationDuration: TimeInterval? {
        guard let start = generationStartTime else { return nil }
        return Date().timeIntervalSince(start)
    }
    
    // MARK: - Public Methods
    func generateReel() async {
        guard let videoId = selectedVideoId else {
            generationError = .noVideoSelected
            return
        }
        
        // Reset state
        isGenerating = true
        generationError = nil
        generatedReels = []
        showSuccess = false
        currentStage = .preparing
        elapsedTime = 0
        generationStartTime = Date()
        
        // Start timers
        startTimers()
        
        logGeneration("🎬 Starting reel generation", details: ["videoId": videoId])
        
        do {
            // Simulate stage progression (actual progress comes from API in real implementation)
            currentStage = .uploading
            
            let reels = try await reelsService.generateReels(videoId: videoId)
            
            currentStage = .finalizing
            
            // Validate response
            guard !reels.isEmpty else {
                throw ReelGenerationError.noReelsGenerated
            }
            
            // Validate each reel has filePath
            for reel in reels {
                if reel.filePath == nil || reel.filePath?.isEmpty == true {
                    logGeneration("⚠️ Reel missing filePath", details: ["reelId": reel.id])
                    throw ReelGenerationError.missingFilePath(reelId: reel.id)
                }
            }
            
            generatedReels = reels
            
            // Log success
            let duration = Date().timeIntervalSince(generationStartTime ?? Date())
            logGeneration("✅ Generation succeeded", details: [
                "duration": String(format: "%.2fs", duration),
                "reelCount": "\(reels.count)",
                "reelIds": reels.map { $0.id }.joined(separator: ", ")
            ])
            
            // Push to feed manager
            if !generatedReels.isEmpty {
                ReelFeedManager.shared.addGeneratedReels(generatedReels)
            }
            
            showSuccess = true
            
        } catch let error as ReelGenerationError {
            handleError(error)
        } catch let error as NetworkError {
            handleNetworkError(error)
        } catch {
            handleError(.unknown(error))
        }
        
        // Cleanup
        stopTimers()
        isGenerating = false
    }
    
    func retry() async {
        generationError = nil
        await generateReel()
    }
    
    func selectVideo(_ id: String) {
        // Clear error when selecting new video
        generationError = nil
        
        if selectedVideoId == id {
            selectedVideoId = nil
        } else {
            selectedVideoId = id
        }
    }
    
    func clearError() {
        generationError = nil
    }
    
    // MARK: - Private Methods
    private func startTimers() {
        // Elapsed time timer
        elapsedTimer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
            Task { @MainActor [weak self] in
                guard let self = self, let startTime = self.generationStartTime else { return }
                self.elapsedTime = Date().timeIntervalSince(startTime)
            }
        }
        
        // Stage progression timer (simulated based on typical AI processing times)
        stageTimer = Timer.scheduledTimer(withTimeInterval: 3.0, repeats: true) { [weak self] _ in
            Task { @MainActor [weak self] in
                self?.advanceStage()
            }
        }
    }
    
    private func stopTimers() {
        stageTimer?.invalidate()
        stageTimer = nil
        elapsedTimer?.invalidate()
        elapsedTimer = nil
    }
    
    private func advanceStage() {
        let stages = GenerationStage.allCases
        guard let currentIndex = stages.firstIndex(of: currentStage) else { return }
        
        let nextIndex = currentIndex + 1
        if nextIndex < stages.count - 1 { // Don't auto-advance to finalizing
            currentStage = stages[nextIndex]
        }
    }
    
    private func handleError(_ error: ReelGenerationError) {
        generationError = error
        
        let duration = Date().timeIntervalSince(generationStartTime ?? Date())
        logGeneration("❌ Generation failed", details: [
            "error": error.errorDescription ?? "Unknown",
            "duration": String(format: "%.2fs", duration),
            "videoId": selectedVideoId ?? "none"
        ])
    }
    
    private func handleNetworkError(_ error: NetworkError) {
        switch error {
        case .serverError(let code, let message):
            generationError = .serverError(statusCode: code, message: message ?? "Unknown server error")
        case .noData:
            generationError = .malformedResponse
        case .decodingError:
            generationError = .malformedResponse
        default:
            generationError = .networkError(underlying: error)
        }
        
        let duration = Date().timeIntervalSince(generationStartTime ?? Date())
        logGeneration("❌ Network error", details: [
            "error": error.localizedDescription,
            "duration": String(format: "%.2fs", duration)
        ])
    }
    
    private func logGeneration(_ message: String, details: [String: String] = [:]) {
        let timestamp = ISO8601DateFormatter().string(from: Date())
        var logMessage = "[GenerateReelViewModel] [\(timestamp)] \(message)"
        
        if !details.isEmpty {
            let detailString = details.map { "\($0.key)=\($0.value)" }.joined(separator: ", ")
            logMessage += " | \(detailString)"
        }
        
        print(logMessage)
    }
}
