//
//  AIReelGeneratorService.swift
//  projectDAM
//
//  Service for AI-powered reel generation from lesson videos
//

import Foundation

// MARK: - AI Reel Generator Service Protocol
protocol AIReelGeneratorServiceProtocol {
    func getAvailableVideos() async throws -> [VideoForReel]
    func getAuthorCourses() async throws -> [CourseForReel]
    func analyzeVideo(videoId: String) async throws -> VideoAnalysisResult
    func createReelFromClip(videoId: String, clip: ClipSuggestion) async throws -> Reel
    func quickCreateReel(videoId: String, clipIndex: Int?) async throws -> QuickCreateReelResponse
    func autoGenerateForCourse(courseId: String, maxReelsPerVideo: Int) async throws -> AutoGenerateResponse
}

// MARK: - AI Reel Generator Service Implementation
final class AIReelGeneratorService: AIReelGeneratorServiceProtocol {
    
    private let networkService: NetworkServiceProtocol
    private let authService: AuthServiceProtocol
    
    init(networkService: NetworkServiceProtocol, authService: AuthServiceProtocol) {
        self.networkService = networkService
        self.authService = authService
    }
    
    func getAvailableVideos() async throws -> [VideoForReel] {
        let endpoint = "/reel-generator/videos"
        
        if AppConfig.enableLogging {
            print("📡 [AIReelGenerator] Fetching available videos")
        }
        
        let response: VideosForReelResponse = try await networkService.request(
            endpoint: endpoint,
            method: .GET,
            body: nil,
            headers: nil
        )
        
        if AppConfig.enableLogging {
            print("✅ [AIReelGenerator] Received \(response.videos.count) videos")
        }
        
        return response.videos
    }
    
    func getAuthorCourses() async throws -> [CourseForReel] {
        let endpoint = "/reel-generator/courses"
        
        if AppConfig.enableLogging {
            print("📡 [AIReelGenerator] Fetching author courses")
        }
        
        let response: CoursesForReelResponse = try await networkService.request(
            endpoint: endpoint,
            method: .GET,
            body: nil,
            headers: nil
        )
        
        if AppConfig.enableLogging {
            print("✅ [AIReelGenerator] Received \(response.courses.count) courses")
        }
        
        return response.courses
    }
    
    func analyzeVideo(videoId: String) async throws -> VideoAnalysisResult {
        let endpoint = "/reel-generator/analyze/\(videoId)"
        
        if AppConfig.enableLogging {
            print("📡 [AIReelGenerator] Analyzing video \(videoId)")
        }
        
        let response: VideoAnalysisResponse = try await networkService.request(
            endpoint: endpoint,
            method: .POST,
            body: nil,
            headers: nil
        )
        
        guard let data = response.data else {
            throw NSError(domain: "AIReelGenerator", code: -1, userInfo: [
                NSLocalizedDescriptionKey: response.message ?? "Failed to analyze video"
            ])
        }
        
        if AppConfig.enableLogging {
            print("✅ [AIReelGenerator] Found \(data.suggestedClips.count) clips")
        }
        
        return data
    }
    
    func createReelFromClip(videoId: String, clip: ClipSuggestion) async throws -> Reel {
        let endpoint = "/reel-generator/create"
        
        if AppConfig.enableLogging {
            print("📡 [AIReelGenerator] Creating reel from clip")
        }
        
        let requestBody = CreateReelFromClipRequest(
            videoId: videoId,
            clip: ClipSuggestionRequest(
                startTime: clip.startTime,
                endTime: clip.endTime,
                title: clip.title,
                description: clip.description,
                score: clip.score,
                reason: clip.reason
            )
        )
        
        let requestData = try JSONEncoder().encode(requestBody)
        
        let response: CreateReelFromClipResponse = try await networkService.request(
            endpoint: endpoint,
            method: .POST,
            body: requestData,
            headers: nil
        )
        
        guard let reel = response.reel else {
            throw NSError(domain: "AIReelGenerator", code: -1, userInfo: [
                NSLocalizedDescriptionKey: response.message ?? "Failed to create reel"
            ])
        }
        
        if AppConfig.enableLogging {
            print("✅ [AIReelGenerator] Created reel: \(reel.id)")
        }
        
        return reel
    }
    
    func quickCreateReel(videoId: String, clipIndex: Int? = nil) async throws -> QuickCreateReelResponse {
        let endpoint = "/reel-generator/quick-create/\(videoId)"
        
        if AppConfig.enableLogging {
            print("📡 [AIReelGenerator] Quick creating reel from video \(videoId)")
        }
        
        struct QuickCreateRequest: Codable {
            let clipIndex: Int?
        }
        
        let requestData = try JSONEncoder().encode(QuickCreateRequest(clipIndex: clipIndex))
        
        let response: QuickCreateReelResponse = try await networkService.request(
            endpoint: endpoint,
            method: .POST,
            body: requestData,
            headers: nil
        )
        
        if AppConfig.enableLogging {
            if let reel = response.reel {
                print("✅ [AIReelGenerator] Quick created reel: \(reel.id)")
            }
        }
        
        return response
    }
    
    func autoGenerateForCourse(courseId: String, maxReelsPerVideo: Int = 2) async throws -> AutoGenerateResponse {
        let endpoint = "/reel-generator/auto-generate/\(courseId)"
        
        if AppConfig.enableLogging {
            print("📡 [AIReelGenerator] Auto-generating reels for course \(courseId)")
        }
        
        struct AutoGenerateRequest: Codable {
            let maxReelsPerVideo: Int
        }
        
        let requestData = try JSONEncoder().encode(AutoGenerateRequest(maxReelsPerVideo: maxReelsPerVideo))
        
        let response: AutoGenerateResponse = try await networkService.request(
            endpoint: endpoint,
            method: .POST,
            body: requestData,
            headers: nil
        )
        
        if AppConfig.enableLogging {
            print("✅ [AIReelGenerator] Auto-generated \(response.totalReels) reels from \(response.totalVideos) videos")
        }
        
        return response
    }
}

// MARK: - Mock Service for Previews
final class MockAIReelGeneratorService: AIReelGeneratorServiceProtocol {
    
    func getAvailableVideos() async throws -> [VideoForReel] {
        try await Task.sleep(nanoseconds: 500_000_000)
        return [
            VideoForReel(id: "v1", title: "Introduction to Algebra", description: "Learn algebra basics", duration: 600, courseId: "c1", courseName: "Mathematics 101", videoUid: "uid1", thumbnailUrl: nil),
            VideoForReel(id: "v2", title: "Physics Fundamentals", description: "Understanding physics", duration: 900, courseId: "c2", courseName: "Physics Basics", videoUid: "uid2", thumbnailUrl: nil),
            VideoForReel(id: "v3", title: "Chemistry Lab", description: "Chemical reactions", duration: 720, courseId: "c3", courseName: "Chemistry 101", videoUid: "uid3", thumbnailUrl: nil),
        ]
    }
    
    func getAuthorCourses() async throws -> [CourseForReel] {
        try await Task.sleep(nanoseconds: 300_000_000)
        return [
            CourseForReel(id: "c1", title: "Mathematics 101", thumbnailUrl: nil, description: "Learn math", videosCount: 10),
            CourseForReel(id: "c2", title: "Physics Basics", thumbnailUrl: nil, description: "Learn physics", videosCount: 8),
            CourseForReel(id: "c3", title: "Chemistry 101", thumbnailUrl: nil, description: "Learn chemistry", videosCount: 12),
        ]
    }
    
    func analyzeVideo(videoId: String) async throws -> VideoAnalysisResult {
        try await Task.sleep(nanoseconds: 1_000_000_000)
        return VideoAnalysisResult(
            success: true,
            videoId: videoId,
            videoTitle: "Sample Video",
            totalDuration: 600,
            suggestedClips: [
                ClipSuggestion(startTime: 0, endTime: 60, title: "Introduction Hook", description: "Engaging opening", score: 90, reason: "Great attention grabber"),
                ClipSuggestion(startTime: 180, endTime: 240, title: "Key Concept", description: "Main topic explained", score: 85, reason: "Core content"),
                ClipSuggestion(startTime: 480, endTime: 540, title: "Summary", description: "Quick recap", score: 80, reason: "Perfect for review"),
            ],
            error: nil
        )
    }
    
    func createReelFromClip(videoId: String, clip: ClipSuggestion) async throws -> Reel {
        try await Task.sleep(nanoseconds: 500_000_000)
        return Reel.mockReels[0]
    }
    
    func quickCreateReel(videoId: String, clipIndex: Int?) async throws -> QuickCreateReelResponse {
        try await Task.sleep(nanoseconds: 1_500_000_000)
        return QuickCreateReelResponse(
            success: true,
            reel: Reel.mockReels[0],
            usedClip: ClipSuggestion(startTime: 0, endTime: 60, title: "Quick Reel", description: "Auto-generated", score: 85, reason: "AI selected"),
            allSuggestedClips: nil,
            message: nil
        )
    }
    
    func autoGenerateForCourse(courseId: String, maxReelsPerVideo: Int) async throws -> AutoGenerateResponse {
        try await Task.sleep(nanoseconds: 2_000_000_000)
        return AutoGenerateResponse(
            success: true,
            totalVideos: 3,
            totalReels: 6,
            reels: Reel.mockReels,
            errors: []
        )
    }
}
