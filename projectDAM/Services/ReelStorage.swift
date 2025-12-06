//
//  ReelStorage.swift
//  projectDAM
//
//  Shared storage for reels - allows teacher to create and students to view
//  Persists reels to UserDefaults for 1 day
//

import Foundation

// MARK: - Reel Storage Manager
final class ReelStorage {
    
    // MARK: - Singleton
    static let shared = ReelStorage()
    
    // MARK: - Constants
    private let storageKey = "created_reels_storage"
    private let expiryKey = "created_reels_expiry"
    private let expiryDuration: TimeInterval = 24 * 60 * 60 // 1 day in seconds
    
    // MARK: - Storage
    private var createdReels: [Reel] = []
    
    private init() {
        loadFromStorage()
    }
    
    // MARK: - Persistence Methods
    
    private func loadFromStorage() {
        // Check if data has expired
        if let expiryDate = UserDefaults.standard.object(forKey: expiryKey) as? Date {
            if Date() > expiryDate {
                // Data expired, clear it
                clearCreatedReels()
                return
            }
        }
        
        // Load reels from UserDefaults
        if let data = UserDefaults.standard.data(forKey: storageKey) {
            do {
                let decoder = JSONDecoder()
                createdReels = try decoder.decode([Reel].self, from: data)
                print("✅ [ReelStorage] Loaded \(createdReels.count) reels from storage")
            } catch {
                print("❌ [ReelStorage] Failed to decode reels: \(error)")
                createdReels = []
            }
        }
    }
    
    private func saveToStorage() {
        do {
            let encoder = JSONEncoder()
            let data = try encoder.encode(createdReels)
            UserDefaults.standard.set(data, forKey: storageKey)
            
            // Set expiry date to 1 day from now
            let expiryDate = Date().addingTimeInterval(expiryDuration)
            UserDefaults.standard.set(expiryDate, forKey: expiryKey)
            
            print("✅ [ReelStorage] Saved \(createdReels.count) reels to storage (expires: \(expiryDate))")
        } catch {
            print("❌ [ReelStorage] Failed to encode reels: \(error)")
        }
    }
    
    // MARK: - Public Methods
    
    /// Get all reels (created by teacher + mock)
    func getAllReels() -> [Reel] {
        // Return teacher-created reels first, then mock reels
        return createdReels + Reel.mockReels
    }
    
    /// Create a new reel from a course with video info (called by teacher)
    func createReelFromCourse(
        courseId: String,
        courseName: String,
        teacherName: String,
        teacherId: String,
        videoId: String? = nil,
        videoUrl: String? = nil,
        thumbnailUrl: String? = nil
    ) -> Reel {
        let newReel = Reel(
            id: "reel_\(UUID().uuidString.prefix(8))",
            title: "60s Highlight: \(courseName)",
            description: "AI-generated highlight from \(courseName) - the best moments in 60 seconds!",
            videoUid: videoId ?? "vid_\(UUID().uuidString.prefix(8))",
            videoUrl: videoUrl,
            thumbnailUrl: thumbnailUrl,
            aiImageUrl: nil,
            duration: 60,
            type: .lessonClip,
            status: .active,
            viewsCount: 0,
            likesCount: 0,
            sharesCount: 0,
            isLiked: false,
            author: ReelAuthor(
                id: teacherId,
                name: teacherName,
                profileImage: nil,
                role: "teacher"
            ),
            course: ReelCourseInfo(
                id: courseId,
                name: courseName,
                thumbnail: thumbnailUrl
            ),
            aiMetadata: ReelAIMetadata(
                promptUsed: "Extract 60-second highlight from course video",
                modelVersion: "gemini-1.5-pro",
                generatedAt: ISO8601DateFormatter().string(from: Date())
            ),
            sourceVideoTimestamp: 0,
            createdAt: ISO8601DateFormatter().string(from: Date()),
            updatedAt: nil
        )
        
        // Add to the beginning of the list (newest first)
        createdReels.insert(newReel, at: 0)
        
        // Save to persistent storage
        saveToStorage()
        
        // Post notification so ReelsViewModel can refresh
        NotificationCenter.default.post(name: .reelCreated, object: newReel)
        
        return newReel
    }
    
    /// Clear all created reels
    func clearCreatedReels() {
        createdReels.removeAll()
        UserDefaults.standard.removeObject(forKey: storageKey)
        UserDefaults.standard.removeObject(forKey: expiryKey)
        print("🗑️ [ReelStorage] Cleared all created reels")
    }
    
    /// Get count of created reels
    var createdReelsCount: Int {
        createdReels.count
    }
}

// MARK: - Notification Names
extension Notification.Name {
    static let reelCreated = Notification.Name("reelCreated")
}
