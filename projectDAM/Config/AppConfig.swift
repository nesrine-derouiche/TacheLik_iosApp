//
//  AppConfig.swift
//  projectDAM
//
//  Created on 11/8/2025.
//

import Foundation

/// Application configuration management
struct AppConfig {
    
    // MARK: - API Configuration
    
    /// Base URL for API requests
    static var baseURL: String {
        // Try to get from Info.plist first (for production builds)
        if let url = Bundle.main.object(forInfoDictionaryKey: "API_BASE_URL") as? String,
           !url.isEmpty,
           !url.contains("$(") { // Check if the value was actually resolved
            return url
        }
        
        // Fallback to production URL
        return "https://dev.api.tache-lik.tn/api"
    }
    
    /// Socket.IO server URL (without /api path)
    static var socketURL: String {
        // Remove /api suffix from base URL for socket connection
        let apiURL = baseURL
        if apiURL.hasSuffix("/api") {
            return String(apiURL.dropLast(4))
        }
        return apiURL
    }
    
    /// Server URL for email verification links (frontend URL)
    static var serverURL: String {
        // Try to get from Info.plist first
        if let url = Bundle.main.object(forInfoDictionaryKey: "SERVER_URL") as? String,
           !url.isEmpty,
           !url.contains("$(") { // Check if the value was actually resolved
            return url
        }
        
        // Fallback to default development URL
        return "http://localhost:3000"
    }
    
    /// API timeout interval in seconds
    static let requestTimeout: TimeInterval = 30
    
    // MARK: - Environment
    
    /// Current environment (Debug/Release)
    static var isDebug: Bool {
        #if DEBUG
        return true
        #else
        return false
        #endif
    }
    
    /// App version
    static var appVersion: String {
        Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String ?? "1.0.0"
    }
    
    /// Build number
    static var buildNumber: String {
        Bundle.main.object(forInfoDictionaryKey: "CFBundleVersion") as? String ?? "1"
    }
    
    // MARK: - Feature Flags
    
    /// Enable detailed logging
    static var enableLogging: Bool {
        isDebug
    }
    
    /// Enable mock data for development
    static var useMockData: Bool {
        // Can be controlled via Info.plist or build configuration
        if let useMock = Bundle.main.object(forInfoDictionaryKey: "USE_MOCK_DATA") as? String {
            return useMock.lowercased() == "true" || useMock == "1"
        }
        return false
    }
    
    // MARK: - Helper Methods
    
    /// Print current configuration (for debugging)
    static func printConfiguration() {
        guard isDebug else { return }
        
        print("""
        ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
        📱 App Configuration
        ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
        Environment: \(isDebug ? "DEBUG" : "RELEASE")
        API Base URL: \(baseURL)
        Socket URL: \(socketURL)
        Version: \(appVersion) (\(buildNumber))
        Mock Data: \(useMockData ? "Enabled" : "Disabled")
        Logging: \(enableLogging ? "Enabled" : "Disabled")
        ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
        """)
    }
}
