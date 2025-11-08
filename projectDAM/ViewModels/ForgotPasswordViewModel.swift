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
    @Published var resetCode = ""
    @Published var newPassword = ""
    @Published var confirmPassword = ""
    @Published var isLoading = false
    @Published var isVerifying = false
    @Published var errorMessage = ""
    @Published var showCodeInput = false
    @Published var canResend = false
    @Published var resendCountdown = 60
    @Published var passwordResetSuccess = false
    
    private let authService: AuthServiceProtocol
    private var resendTimer: Timer?
    
    init(authService: AuthServiceProtocol = DIContainer.shared.authService) {
        self.authService = authService
    }
    
    func requestResetCode() async {
        // Validate email
        let emailValidation = Validators.validateEmail(email)
        if !emailValidation.isValid {
            errorMessage = emailValidation.errorMessage ?? "Invalid email"
            return
        }
        
        isLoading = true
        errorMessage = ""
        
        do {
            try await authService.requestPasswordResetCode(email: email)
            isLoading = false
            showCodeInput = true
            startResendTimer()
            print("✅ Password reset code sent to: \(email)")
        } catch {
            isLoading = false
            errorMessage = "Failed to send code: \(error.localizedDescription)"
            print("❌ Failed to send reset code: \(error.localizedDescription)")
        }
    }
    
    func verifyCodeAndResetPassword() async {
        guard resetCode.count == 6 else {
            errorMessage = "Please enter the 6-digit code"
            return
        }
        
        // Validate passwords
        let passwordValidation = Validators.validatePassword(newPassword)
        if !passwordValidation.isValid {
            errorMessage = passwordValidation.errorMessage ?? "Invalid password"
            return
        }
        
        if newPassword != confirmPassword {
            errorMessage = "Passwords do not match"
            return
        }
        
        isVerifying = true
        errorMessage = ""
        
        do {
            try await authService.resetPasswordWithCode(
                email: email,
                code: resetCode,
                newPassword: newPassword
            )
            isVerifying = false
            passwordResetSuccess = true
            print("✅ Password reset successfully")
        } catch let error as NetworkError {
            isVerifying = false
            switch error {
            case .serverError(_, let message):
                errorMessage = message ?? "Failed to reset password"
            default:
                errorMessage = "Failed to reset password"
            }
            print("❌ Failed to reset password: \(error)")
        } catch {
            isVerifying = false
            errorMessage = "Failed to reset password: \(error.localizedDescription)"
            print("❌ Failed to reset password: \(error.localizedDescription)")
        }
    }
    
    func resendCode() async {
        guard canResend else { return }
        
        isLoading = true
        errorMessage = ""
        resetCode = "" // Clear previous code
        
        do {
            try await authService.requestPasswordResetCode(email: email)
            isLoading = false
            startResendTimer()
            print("✅ Password reset code resent to: \(email)")
        } catch {
            isLoading = false
            errorMessage = "Failed to resend code: \(error.localizedDescription)"
            print("❌ Failed to resend code: \(error.localizedDescription)")
        }
    }
    
    private func startResendTimer() {
        canResend = false
        resendCountdown = 60
        
        resendTimer?.invalidate()
        resendTimer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
            guard let self = self else { return }
            
            Task { @MainActor in
                if self.resendCountdown > 0 {
                    self.resendCountdown -= 1
                } else {
                    self.canResend = true
                    self.resendTimer?.invalidate()
                }
            }
        }
    }
    
    deinit {
        resendTimer?.invalidate()
    }
}
