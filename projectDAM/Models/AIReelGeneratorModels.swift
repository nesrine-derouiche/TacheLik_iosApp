//
//  AIReelGeneratorModels.swift
//  projectDAM
//
//  Models for AI Reel Generator feature
//

import Foundation

// MARK: - Clip Suggestion from AI
struct ClipSuggestion: Codable, Identifiable {
    var id: String { "\(startTime)-\(endTime)" }
    let startTime: Int
    let endTime: Int
    let title: String
    let description: String
    let score: Int
    let reason: String
    
    enum CodingKeys: String, CodingKey {
        case startTime = "startTime"
        case endTime = "endTime"
        case title
        case description
        case score
        case reason
    }
    
    var duration: Int {
        endTime - startTime
    }
    
    var engagementScore: Double {
        Double(score) / 100.0
    }
    
    var formattedStartTime: String {
        formatTime(startTime)
    }
    
    var formattedEndTime: String {
        formatTime(endTime)
    }
    
    var formattedDuration: String {
        formatTime(duration)
    }
    
    private func formatTime(_ seconds: Int) -> String {
        let minutes = seconds / 60
        let secs = seconds % 60
        return String(format: "%d:%02d", minutes, secs)
    }
}

// MARK: - Video Analysis Result
struct VideoAnalysisResult: Codable {
    let success: Bool
    let videoId: String
    let videoTitle: String
    let totalDuration: Int
    let suggestedClips: [ClipSuggestion]
    let error: String?
    
    enum CodingKeys: String, CodingKey {
        case success
        case videoId = "videoId"
        case videoTitle = "videoTitle"
        case totalDuration = "totalDuration"
        case suggestedClips = "suggestedClips"
        case error
    }
}

// MARK: - Video for Reel Generation
struct VideoForReel: Codable, Identifiable {
    let id: String
    let title: String
    let description: String?
    let duration: Int
    let courseId: String?
    let courseName: String?
    let videoUid: String
    let thumbnailUrl: String?
    
    enum CodingKeys: String, CodingKey {
        case id
        case title
        case description
        case duration
        case courseId = "courseId"
        case courseName = "courseName"
        case videoUid = "videoUid"
        case thumbnailUrl = "thumbnailUrl"
    }
    
    var formattedDuration: String {
        let minutes = duration / 60
        let seconds = duration % 60
        return String(format: "%d:%02d", minutes, seconds)
    }
}

// MARK: - Course for Reel Generation
struct CourseForReel: Codable, Identifiable {
    let id: String
    let title: String
    let thumbnailUrl: String?
    let description: String?
    let videosCount: Int
    
    enum CodingKeys: String, CodingKey {
        case id
        case title
        case thumbnailUrl = "thumbnailUrl"
        case description
        case videosCount = "videosCount"
    }
}

// MARK: - API Responses
struct VideoAnalysisResponse: Codable {
    let success: Bool
    let data: VideoAnalysisResult?
    let message: String?
}

struct VideosForReelResponse: Codable {
    let success: Bool
    let videos: [VideoForReel]
}

struct CoursesForReelResponse: Codable {
    let success: Bool
    let courses: [CourseForReel]
}

struct CreateReelFromClipResponse: Codable {
    let success: Bool
    let reel: Reel?
    let message: String?
}

struct QuickCreateReelResponse: Codable {
    let success: Bool
    let reel: Reel?
    let usedClip: ClipSuggestion?
    let allSuggestedClips: [ClipSuggestion]?
    let message: String?
}

struct AutoGenerateResponse: Codable {
    let success: Bool
    let totalVideos: Int
    let totalReels: Int
    let reels: [Reel]
    let errors: [String]
}

// MARK: - Create Reel Request
struct CreateReelFromClipRequest: Codable {
    let videoId: String
    let clip: ClipSuggestionRequest
}

struct ClipSuggestionRequest: Codable {
    let startTime: Int
    let endTime: Int
    let title: String
    let description: String
    let score: Int
    let reason: String
}
