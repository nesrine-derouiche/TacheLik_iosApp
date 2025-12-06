//
//  AIReelGeneratorViewModel.swift
//  projectDAM
//
//  ViewModel for AI Reel Generator feature
//

import Foundation
import SwiftUI
import Combine

// MARK: - View State
enum AIReelGeneratorState {
    case idle
    case loadingVideos
    case analyzing
    case creating
    case success(String)
    case error(String)
}

// MARK: - ViewModel
@MainActor
final class AIReelGeneratorViewModel: ObservableObject {
    
    // MARK: - Published Properties
    @Published var state: AIReelGeneratorState = .idle
    @Published var videos: [VideoForReel] = []
    @Published var courses: [CourseForReel] = []
    @Published var selectedVideo: VideoForReel?
    @Published var analysisResult: VideoAnalysisResult?
    @Published var selectedClips: Set<String> = []
    @Published var createdReels: [Reel] = []
    @Published var showSuccessAlert = false
    @Published var successMessage = ""
    
    // MARK: - Private Properties
    private let service: AIReelGeneratorServiceProtocol
    
    // MARK: - Initialization
    init(service: AIReelGeneratorServiceProtocol) {
        self.service = service
    }
    
    // MARK: - Public Methods
    
    func loadVideos() async {
        state = .loadingVideos
        
        do {
            async let videosTask = service.getAvailableVideos()
            async let coursesTask = service.getAuthorCourses()
            
            let (loadedVideos, loadedCourses) = try await (videosTask, coursesTask)
            
            videos = loadedVideos
            courses = loadedCourses
            state = .idle
            
        } catch {
            state = .error("Failed to load videos: \(error.localizedDescription)")
        }
    }
    
    func analyzeVideo(_ video: VideoForReel) async {
        selectedVideo = video
        state = .analyzing
        analysisResult = nil
        selectedClips.removeAll()
        
        do {
            let result = try await service.analyzeVideo(videoId: video.id)
            analysisResult = result
            state = .idle
            
        } catch {
            state = .error("Failed to analyze video: \(error.localizedDescription)")
        }
    }
    
    func toggleClipSelection(_ clip: ClipSuggestion) {
        if selectedClips.contains(clip.id) {
            selectedClips.remove(clip.id)
        } else {
            selectedClips.insert(clip.id)
        }
    }
    
    func createReelsFromSelectedClips() async {
        guard let video = selectedVideo,
              let analysis = analysisResult else { return }
        
        state = .creating
        createdReels.removeAll()
        
        let clipsToCreate = analysis.suggestedClips.filter { selectedClips.contains($0.id) }
        
        for clip in clipsToCreate {
            do {
                let reel = try await service.createReelFromClip(videoId: video.id, clip: clip)
                createdReels.append(reel)
            } catch {
                print("❌ Failed to create reel: \(error)")
            }
        }
        
        if !createdReels.isEmpty {
            successMessage = "Successfully created \(createdReels.count) reel(s)!"
            showSuccessAlert = true
            state = .success(successMessage)
        } else {
            state = .error("Failed to create any reels")
        }
    }
    
    func quickCreateReel(from video: VideoForReel) async {
        state = .creating
        
        do {
            let response = try await service.quickCreateReel(videoId: video.id, clipIndex: 0)
            
            if let reel = response.reel {
                createdReels = [reel]
                successMessage = "Created reel: \(reel.title)"
                showSuccessAlert = true
                state = .success(successMessage)
            } else {
                state = .error(response.message ?? "Failed to create reel")
            }
            
        } catch {
            state = .error("Failed to quick create reel: \(error.localizedDescription)")
        }
    }
    
    func autoGenerateForCourse(_ course: CourseForReel) async {
        state = .creating
        
        do {
            let response = try await service.autoGenerateForCourse(courseId: course.id, maxReelsPerVideo: 2)
            
            createdReels = response.reels
            successMessage = "Generated \(response.totalReels) reels from \(response.totalVideos) videos!"
            showSuccessAlert = true
            state = .success(successMessage)
            
            if !response.errors.isEmpty {
                print("⚠️ Some errors occurred: \(response.errors)")
            }
            
        } catch {
            state = .error("Failed to auto-generate reels: \(error.localizedDescription)")
        }
    }
    
    func reset() {
        selectedVideo = nil
        analysisResult = nil
        selectedClips.removeAll()
        createdReels.removeAll()
        state = .idle
    }
}
