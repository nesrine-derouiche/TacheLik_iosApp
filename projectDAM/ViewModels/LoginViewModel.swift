//
//  LoginViewModel.swift
//  projectDAM
//
//  Created on 11/7/2025.
//

import Foundation
import SwiftUI
import Combine

// MARK: - Login View Model
/// Handles authentication logic and state for LoginView
@MainActor
final class LoginViewModel: ObservableObject {
    
    // MARK: - Published Properties
    @Published var email: String = ""
    @Published var password: String = ""
    @Published var isLoading: Bool = false
    @Published var errorMessage: String?
    @Published var showPassword: Bool = false
    @AppStorage("isLoggedIn") var isLoggedIn: Bool = false
    
    // MARK: - Dependencies
    private let authService: AuthServiceProtocol
    
    // MARK: - Initialization
    init(authService: AuthServiceProtocol) {
        self.authService = authService
    }
    
    // MARK: - Public Methods
    
    /// Validates email format
    var isEmailValid: Bool {
        let emailRegex = "[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,64}"
        let emailPredicate = NSPredicate(format:"SELF MATCHES %@", emailRegex)
        return emailPredicate.evaluate(with: email)
    }
    
    /// Validates password (minimum 6 characters)
    var isPasswordValid: Bool {
        return password.count >= 6
    }
    
    /// Checks if form is valid
    var isFormValid: Bool {
        return isEmailValid && isPasswordValid
    }
    
    /// Login user
    func login() async {
        guard isFormValid else {
            errorMessage = "Please enter valid email and password"
            return
        }
        
        isLoading = true
        errorMessage = nil
        
        do {
            let user = try await authService.login(email: email, password: password)
            isLoggedIn = true
            print("✅ Login successful: \(user.name)")
        } catch {
            errorMessage = error.localizedDescription
            print("❌ Login failed: \(error.localizedDescription)")
        }
        
        isLoading = false
    }
    
    /// Register new user
    func register(name: String) async {
        guard isFormValid else {
            errorMessage = "Please enter valid email and password"
            return
        }
        
        isLoading = true
        errorMessage = nil
        
        do {
            let user = try await authService.register(email: email, password: password, name: name)
            isLoggedIn = true
            print("✅ Registration successful: \(user.name)")
        } catch {
            errorMessage = error.localizedDescription
            print("❌ Registration failed: \(error.localizedDescription)")
        }
        
        isLoading = false
    }
    
    /// Toggle password visibility
    func togglePasswordVisibility() {
        showPassword.toggle()
    }
    
    /// Clear error message
    func clearError() {
        errorMessage = nil
    }
}
