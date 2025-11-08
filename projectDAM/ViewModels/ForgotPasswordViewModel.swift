//
//  ForgotPasswordViewModel.swift
//  projectDAM
//
//  Created on 11/8/2025.
//

import Foundation
import Combine

@MainActor
class ForgotPasswordViewModel: ObservableObject {
    @Published var email = ""
    @Published var isLoading = false
    @Published var errorMessage: String?
    @Published var showError = false
    @Published var showSuccess = false
    
    private let authService: AuthServiceProtocol
    
    init(authService: AuthServiceProtocol = DIContainer.shared.authService) {
        self.authService = authService
    }
    
    func sendResetLink() async {
        // Validate email
        let emailValidation = Validators.validateEmail(email)
        if !emailValidation.isValid {
            errorMessage = emailValidation.errorMessage
            showError = true
            return
        }
        
        isLoading = true
        errorMessage = nil
        
        do {
            try await authService.requestPasswordReset(email: email)
            isLoading = false
            showSuccess = true
            print("✅ Password reset link sent to: \(email)")
        } catch {
            isLoading = false
            errorMessage = error.localizedDescription
            showError = true
            print("❌ Failed to send reset link: \(error.localizedDescription)")
        }
    }
}
