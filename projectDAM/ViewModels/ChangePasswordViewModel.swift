import Foundation
import SwiftUI
import Combine

@MainActor
class ChangePasswordViewModel: ObservableObject {
    @Published var currentPassword = ""
    @Published var newPassword = ""
    @Published var confirmPassword = ""
    @Published var errorMessage = ""
    @Published var successMessage = false
    @Published var isLoading = false
    @Published var showSuccessAlert = false
    
    private let profileService: ProfileServiceProtocol
    private let authService: AuthServiceProtocol
    
    init(
        profileService: ProfileServiceProtocol = DIContainer.shared.profileService,
        authService: AuthServiceProtocol = DIContainer.shared.authService
    ) {
        self.profileService = profileService
        self.authService = authService
    }
    
    func changePassword() async {
        // Clear previous messages
        errorMessage = ""
        successMessage = false
        
        // Validate inputs
        guard !currentPassword.isEmpty else {
            errorMessage = "Please enter your current password"
            return
        }
        
        guard Validators.isValidPassword(newPassword) else {
            errorMessage = "New password must be at least 8 characters"
            return
        }
        
        guard newPassword == confirmPassword else {
            errorMessage = "Passwords do not match"
            return
        }
        
        guard let userId = authService.getCurrentUser()?.id else {
            errorMessage = "User not found. Please login again."
            return
        }
        
        isLoading = true
        
        do {
            let response = try await profileService.updatePassword(
                userId: userId,
                currentPassword: currentPassword,
                newPassword: newPassword
            )
            
            isLoading = false
            
            if response.success == true {
                successMessage = true
                showSuccessAlert = true
                
                // Clear fields
                currentPassword = ""
                newPassword = ""
                confirmPassword = ""
            } else {
                errorMessage = response.message ?? "Failed to change password"
            }
        } catch {
            isLoading = false
            
            if let networkError = error as? NetworkError {
                switch networkError {
                case .serverError(_, let message):
                    errorMessage = message ?? "Failed to change password"
                case .unauthorized:
                    errorMessage = "Session expired. Please login again."
                case .invalidResponse, .invalidURL, .noData:
                    errorMessage = "Network error. Please check your connection."
                case .decodingError:
                    errorMessage = "Failed to process response. Please try again."
                }
            } else {
                errorMessage = error.localizedDescription
            }
        }
    }
}
