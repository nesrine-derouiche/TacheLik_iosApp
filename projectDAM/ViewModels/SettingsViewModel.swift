//
//  SettingsViewModel.swift
//  projectDAM
//
//  Created on 11/7/2025.
//

import Foundation
import SwiftUI
import Combine

// MARK: - Settings View Model
/// Manages settings screen state and user preferences
@MainActor
final class SettingsViewModel: ObservableObject {
    
    // MARK: - Published Properties
    @Published var currentUser: User?
    @Published var isDarkMode: Bool = false
    @Published var isLoading: Bool = false
    @Published var showLogoutConfirmation: Bool = false
    @Published var errorMessage: String?
    @AppStorage("isLoggedIn") var isLoggedIn: Bool = true
    
    // MARK: - Dependencies
    private let authService: AuthServiceProtocol
    
    // MARK: - Initialization
    init(authService: AuthServiceProtocol) {
        self.authService = authService
        self.currentUser = authService.getCurrentUser()
        self.loadPreferences()
    }
    
    // MARK: - Public Methods
    
    /// Logout user
    func logout() async {
        isLoading = true
        
        do {
            try await authService.logout()
            isLoggedIn = false
            print("✅ Logout successful")
        } catch {
            errorMessage = error.localizedDescription
            print("❌ Logout failed: \(error.localizedDescription)")
        }
        
        isLoading = false
    }
    
    /// Toggle dark mode
    func toggleDarkMode() {
        isDarkMode.toggle()
        savePreferences()
    }
    
    /// Get user initials for avatar
    var userInitials: String {
        guard let name = currentUser?.name else { return "?" }
        let components = name.components(separatedBy: " ")
        let initials = components.compactMap { $0.first }.prefix(2)
        return String(initials).uppercased()
    }
    
    // MARK: - Private Methods
    
    private func loadPreferences() {
        isDarkMode = UserDefaults.standard.bool(forKey: "isDarkMode")
    }
    
    private func savePreferences() {
        UserDefaults.standard.set(isDarkMode, forKey: "isDarkMode")
    }
}
