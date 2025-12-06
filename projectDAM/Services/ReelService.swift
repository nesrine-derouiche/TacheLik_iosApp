//
//  ReelService.swift
//  projectDAM
//
//  API Service for Reels feature
//

import Foundation

// MARK: - Reel Service Protocol
protocol ReelServiceProtocol {
    func fetchReelsFeed(page: Int, limit: Int, type: ReelType?) async throws -> ReelsFeedResponse
    func fetchFeaturedReels(limit: Int) async throws -> [Reel]
    func fetchReel(id: String) async throws -> Reel
    func fetchReelsForCourse(courseId: String, limit: Int) async throws -> [Reel]
    func recordView(reelId: String) async throws
    func toggleLike(reelId: String) async throws -> Bool
    func recordShare(reelId: String) async throws
}

// MARK: - Reel Service Implementation
final class ReelService: ReelServiceProtocol {
    
    private let networkService: NetworkServiceProtocol
    
    init(networkService: NetworkServiceProtocol) {
        self.networkService = networkService
    }
    
    func fetchReelsFeed(page: Int, limit: Int, type: ReelType?) async throws -> ReelsFeedResponse {
        var endpoint = "/reel/feed?page=\(page)&limit=\(limit)"
        if let type = type {
            endpoint += "&type=\(type.rawValue)"
        }
        
        if AppConfig.enableLogging {
            print("📡 [ReelService] Fetching reels feed: \(endpoint)")
        }
        
        let response: ReelsFeedResponse = try await networkService.request(
            endpoint: endpoint,
            method: .GET,
            body: nil,
            headers: nil
        )
        
        if AppConfig.enableLogging {
            print("✅ [ReelService] Received \(response.reels.count) reels")
        }
        
        return response
    }
    
    func fetchFeaturedReels(limit: Int) async throws -> [Reel] {
        let endpoint = "/reel/featured?limit=\(limit)"
        
        if AppConfig.enableLogging {
            print("📡 [ReelService] Fetching featured reels")
        }
        
        let response: ReelsListResponse = try await networkService.request(
            endpoint: endpoint,
            method: .GET,
            body: nil,
            headers: nil
        )
        
        if AppConfig.enableLogging {
            print("✅ [ReelService] Received \(response.reels.count) featured reels")
        }
        
        return response.reels
    }
    
    func fetchReel(id: String) async throws -> Reel {
        let endpoint = "/reel/\(id)"
        
        if AppConfig.enableLogging {
            print("📡 [ReelService] Fetching reel: \(id)")
        }
        
        let response: SingleReelResponse = try await networkService.request(
            endpoint: endpoint,
            method: .GET,
            body: nil,
            headers: nil
        )
        
        return response.reel
    }
    
    func fetchReelsForCourse(courseId: String, limit: Int) async throws -> [Reel] {
        let endpoint = "/reel/course/\(courseId)?limit=\(limit)"
        
        if AppConfig.enableLogging {
            print("📡 [ReelService] Fetching reels for course: \(courseId)")
        }
        
        let response: ReelsListResponse = try await networkService.request(
            endpoint: endpoint,
            method: .GET,
            body: nil,
            headers: nil
        )
        
        return response.reels
    }
    
    func recordView(reelId: String) async throws {
        let endpoint = "/reel/\(reelId)/view"
        
        if AppConfig.enableLogging {
            print("📡 [ReelService] Recording view for reel: \(reelId)")
        }
        
        let _: ViewRecordResponse = try await networkService.request(
            endpoint: endpoint,
            method: .POST,
            body: nil,
            headers: nil
        )
    }
    
    func toggleLike(reelId: String) async throws -> Bool {
        let endpoint = "/reel/\(reelId)/like"
        
        if AppConfig.enableLogging {
            print("📡 [ReelService] Toggling like for reel: \(reelId)")
        }
        
        let response: LikeToggleResponse = try await networkService.request(
            endpoint: endpoint,
            method: .POST,
            body: nil,
            headers: nil
        )
        
        return response.liked
    }
    
    func recordShare(reelId: String) async throws {
        let endpoint = "/reel/\(reelId)/share"
        
        if AppConfig.enableLogging {
            print("📡 [ReelService] Recording share for reel: \(reelId)")
        }
        
        let _: ViewRecordResponse = try await networkService.request(
            endpoint: endpoint,
            method: .POST,
            body: nil,
            headers: nil
        )
    }
}

// MARK: - Mock Reel Service for Previews
final class MockReelService: ReelServiceProtocol {
    
    func fetchReelsFeed(page: Int, limit: Int, type: ReelType?) async throws -> ReelsFeedResponse {
        try await Task.sleep(nanoseconds: 500_000_000)
        
        return ReelsFeedResponse(
            success: true,
            reels: Reel.mockReels,
            total: Reel.mockReels.count,
            page: page,
            limit: limit,
            totalPages: 1
        )
    }
    
    func fetchFeaturedReels(limit: Int) async throws -> [Reel] {
        try await Task.sleep(nanoseconds: 300_000_000)
        return Array(Reel.mockReels.prefix(limit))
    }
    
    func fetchReel(id: String) async throws -> Reel {
        try await Task.sleep(nanoseconds: 200_000_000)
        return Reel.mockReels.first { $0.id == id } ?? Reel.mockReels[0]
    }
    
    func fetchReelsForCourse(courseId: String, limit: Int) async throws -> [Reel] {
        try await Task.sleep(nanoseconds: 300_000_000)
        return Array(Reel.mockReels.prefix(limit))
    }
    
    func recordView(reelId: String) async throws {
        // Mock - do nothing
    }
    
    func toggleLike(reelId: String) async throws -> Bool {
        return true
    }
    
    func recordShare(reelId: String) async throws {
        // Mock - do nothing
    }
}
