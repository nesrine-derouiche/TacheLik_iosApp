//
//  ReelModels.swift
//  projectDAM
//
//  Data models for Reels feature
//

import Foundation

// MARK: - Reel Type Enum
enum ReelType: String, Codable, CaseIterable {
    case lessonClip = "lesson_clip"
    case aiPromo = "ai_promo"
    case coursePreview = "course_preview"
    case teacherIntro = "teacher_intro"
    
    var displayName: String {
        switch self {
        case .lessonClip: return "Lesson Clip"
        case .aiPromo: return "AI Promo"
        case .coursePreview: return "Course Preview"
        case .teacherIntro: return "Teacher Intro"
        }
    }
    
    var iconName: String {
        switch self {
        case .lessonClip: return "play.circle"
        case .aiPromo: return "sparkles"
        case .coursePreview: return "book.circle"
        case .teacherIntro: return "person.circle"
        }
    }
}

// MARK: - Reel Status Enum
enum ReelStatus: String, Codable {
    case draft
    case processing
    case active
    case archived
}

// MARK: - Reel Author Model
struct ReelAuthor: Codable, Identifiable {
    let id: String
    let name: String
    let profileImage: String?
    let role: String?
    
    enum CodingKeys: String, CodingKey {
        case id
        case name
        case profileImage = "profile_image"
        case role
    }
}

// MARK: - Reel Course Info
struct ReelCourseInfo: Codable, Identifiable {
    let id: String
    let name: String
    let thumbnail: String?
    
    enum CodingKeys: String, CodingKey {
        case id
        case name
        case thumbnail
    }
}

// MARK: - Reel AI Metadata
struct ReelAIMetadata: Codable {
    let promptUsed: String?
    let modelVersion: String?
    let generatedAt: String?
    
    enum CodingKeys: String, CodingKey {
        case promptUsed = "prompt_used"
        case modelVersion = "model_version"
        case generatedAt = "generated_at"
    }
}

// MARK: - Main Reel Model
struct Reel: Codable, Identifiable {
    let id: String
    let title: String
    let description: String?
    let videoUid: String?
    let videoUrl: String?
    let thumbnailUrl: String?
    let aiImageUrl: String?
    let duration: Int?
    let type: ReelType
    let status: ReelStatus
    var viewsCount: Int
    var likesCount: Int
    var sharesCount: Int
    var isLiked: Bool
    let author: ReelAuthor?
    let course: ReelCourseInfo?
    let aiMetadata: ReelAIMetadata?
    let sourceVideoTimestamp: Int?
    let createdAt: String
    let updatedAt: String?
    
    enum CodingKeys: String, CodingKey {
        case id
        case title
        case description
        case videoUid = "video_uid"
        case videoUrl = "video_url"
        case thumbnailUrl = "thumbnail_url"
        case aiImageUrl = "ai_image_url"
        case duration
        case type
        case status
        case viewsCount = "views_count"
        case likesCount = "likes_count"
        case sharesCount = "shares_count"
        case isLiked = "is_liked"
        case author
        case course
        case aiMetadata = "ai_metadata"
        case sourceVideoTimestamp = "source_video_timestamp"
        case createdAt = "created_at"
        case updatedAt = "updated_at"
    }
    
    // MARK: - Computed Properties
    
    var videoURL: URL? {
        guard let urlString = videoUrl else { return nil }
        return URL(string: urlString)
    }
    
    var thumbnailImageURL: URL? {
        guard let urlString = thumbnailUrl else { return nil }
        return URL(string: urlString)
    }
    
    var aiImageURL: URL? {
        guard let urlString = aiImageUrl else { return nil }
        return URL(string: urlString)
    }
    
    var displayImageURL: URL? {
        // Prefer AI image for ai_promo type, otherwise use thumbnail
        if type == .aiPromo, let aiUrl = aiImageURL {
            return aiUrl
        }
        return thumbnailImageURL
    }
    
    var hasVideo: Bool {
        return videoUrl != nil && !videoUrl!.isEmpty
    }
    
    /// Check if this is a VdoCipher video that needs WebView
    var isVdoCipherVideo: Bool {
        guard let url = videoUrl else { return false }
        return url.contains("vdocipher.com") || url.hasPrefix("vdocipher://")
    }
    
    /// Get VdoCipher video ID if stored with vdocipher:// scheme
    var vdoCipherVideoId: String? {
        guard let url = videoUrl, url.hasPrefix("vdocipher://") else { return nil }
        return String(url.dropFirst("vdocipher://".count))
    }
    
    /// Check if this is a YouTube video
    var isYouTubeVideo: Bool {
        guard let url = videoUrl else { return false }
        return url.contains("youtube.com") || url.contains("youtu.be")
    }
    
    /// Get YouTube video ID from embed URL
    var youtubeVideoId: String? {
        guard let url = videoUrl else { return nil }
        
        // Handle embed URL: https://www.youtube.com/embed/VIDEO_ID
        if url.contains("/embed/") {
            let parts = url.components(separatedBy: "/embed/")
            if parts.count > 1 {
                return parts[1].components(separatedBy: "?").first
            }
        }
        
        // Handle watch URL: https://www.youtube.com/watch?v=VIDEO_ID
        if let urlObj = URL(string: url),
           let components = URLComponents(url: urlObj, resolvingAgainstBaseURL: false),
           let queryItems = components.queryItems,
           let videoId = queryItems.first(where: { $0.name == "v" })?.value {
            return videoId
        }
        
        // Handle short URL: https://youtu.be/VIDEO_ID
        if url.contains("youtu.be/") {
            let parts = url.components(separatedBy: "youtu.be/")
            if parts.count > 1 {
                return parts[1].components(separatedBy: "?").first
            }
        }
        
        return nil
    }
    
    /// Check if this can be played with native AVPlayer
    var isNativePlayable: Bool {
        guard let url = videoUrl else { return false }
        // Only direct video file URLs can be played with AVPlayer
        return !isVdoCipherVideo && !isYouTubeVideo && (url.hasSuffix(".mp4") || url.hasSuffix(".m3u8") || url.hasSuffix(".mov"))
    }
    
    var formattedDuration: String? {
        guard let duration = duration else { return nil }
        let minutes = duration / 60
        let seconds = duration % 60
        if minutes > 0 {
            return String(format: "%d:%02d", minutes, seconds)
        }
        return String(format: "0:%02d", seconds)
    }
    
    var shareURL: URL {
        return URL(string: "https://tachelik.tn/reels/\(id)")!
    }
}

// MARK: - API Response Models

struct ReelsFeedResponse: Codable {
    let success: Bool
    let reels: [Reel]
    let total: Int
    let page: Int
    let limit: Int
    let totalPages: Int
    
    enum CodingKeys: String, CodingKey {
        case success
        case reels
        case total
        case page
        case limit
        case totalPages = "total_pages"
    }
}

struct ReelsListResponse: Codable {
    let success: Bool
    let reels: [Reel]
}

struct SingleReelResponse: Codable {
    let success: Bool
    let reel: Reel
}

struct ViewRecordResponse: Codable {
    let success: Bool
    let message: String?
    let viewsCount: Int?
    
    enum CodingKeys: String, CodingKey {
        case success
        case message
        case viewsCount = "views_count"
    }
}

struct LikeToggleResponse: Codable {
    let success: Bool
    let liked: Bool
    let likesCount: Int
    
    enum CodingKeys: String, CodingKey {
        case success
        case liked
        case likesCount = "likes_count"
    }
}

// MARK: - Mock Data Extension
extension Reel {
    static var mockReels: [Reel] {
        [
            Reel(
                id: "reel_001",
                title: "Introduction to Algebra",
                description: "Learn the basics of algebraic expressions in this quick lesson clip.",
                videoUid: "vid_12345",
                videoUrl: "https://example.com/videos/algebra-intro.mp4",
                thumbnailUrl: "https://example.com/thumbnails/algebra.jpg",
                aiImageUrl: nil,
                duration: 45,
                type: .lessonClip,
                status: .active,
                viewsCount: 1250,
                likesCount: 342,
                sharesCount: 28,
                isLiked: false,
                author: ReelAuthor(id: "teacher_1", name: "Dr. Sarah Johnson", profileImage: nil, role: "teacher"),
                course: ReelCourseInfo(id: "course_1", name: "Mathematics 101", thumbnail: nil),
                aiMetadata: nil,
                sourceVideoTimestamp: 120,
                createdAt: "2024-01-15T10:30:00Z",
                updatedAt: nil
            ),
            Reel(
                id: "reel_002",
                title: "Master Physics Today!",
                description: "Discover the wonders of physics with our comprehensive course.",
                videoUid: nil,
                videoUrl: nil,
                thumbnailUrl: "https://example.com/thumbnails/physics-promo.jpg",
                aiImageUrl: "https://example.com/ai-images/physics-promo.jpg",
                duration: nil,
                type: .aiPromo,
                status: .active,
                viewsCount: 3420,
                likesCount: 892,
                sharesCount: 156,
                isLiked: true,
                author: nil,
                course: ReelCourseInfo(id: "course_2", name: "Physics Advanced", thumbnail: nil),
                aiMetadata: ReelAIMetadata(promptUsed: "Educational physics promotion", modelVersion: "v2.1", generatedAt: "2024-01-10"),
                sourceVideoTimestamp: nil,
                createdAt: "2024-01-10T14:00:00Z",
                updatedAt: nil
            ),
            Reel(
                id: "reel_003",
                title: "Chemistry Course Preview",
                description: "Take a sneak peek at what you will learn in our Chemistry course.",
                videoUid: "vid_67890",
                videoUrl: "https://example.com/videos/chemistry-preview.mp4",
                thumbnailUrl: "https://example.com/thumbnails/chemistry.jpg",
                aiImageUrl: nil,
                duration: 58,
                type: .coursePreview,
                status: .active,
                viewsCount: 2100,
                likesCount: 521,
                sharesCount: 89,
                isLiked: false,
                author: ReelAuthor(id: "teacher_2", name: "Prof. Ahmed Ben Ali", profileImage: nil, role: "teacher"),
                course: ReelCourseInfo(id: "course_3", name: "Chemistry Fundamentals", thumbnail: nil),
                aiMetadata: nil,
                sourceVideoTimestamp: nil,
                createdAt: "2024-01-12T09:00:00Z",
                updatedAt: nil
            )
        ]
    }
}
