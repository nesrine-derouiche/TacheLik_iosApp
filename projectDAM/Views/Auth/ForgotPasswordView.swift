//
//  ForgotPasswordView.swift
//  projectDAM
//
//  Created on 11/8/2025.
//

import SwiftUI

struct ForgotPasswordView: View {
    @Environment(\.dismiss) private var dismiss
    @StateObject private var viewModel = ForgotPasswordViewModel()
    
    var body: some View {
        ZStack {
            // Beautiful gradient background
            LinearGradient.brandHeader
                .ignoresSafeArea()
            
            ScrollView(showsIndicators: false) {
                VStack(spacing: 32) {
                    Spacer()
                        .frame(height: 40)
                    
                    // Header Icon
                    ZStack {
                        Circle()
                            .fill(Color.white.opacity(0.2))
                            .frame(width: 100, height: 100)
                        
                        Image(systemName: viewModel.showCodeInput ? "lock.shield" : "lock.rotation")
                            .font(.system(size: 50, weight: .medium))
                            .foregroundColor(.white)
                    }
                    .shadow(color: Color.black.opacity(0.2), radius: 15, x: 0, y: 8)
                    
                    VStack(spacing: 8) {
                        Text(viewModel.showPasswordInput ? "New Password" : viewModel.showCodeInput ? "Verify Code" : "Forgot Password?")
                            .font(.system(size: 34, weight: .bold))
                            .foregroundColor(.white)
                        
                        Text(viewModel.showPasswordInput ? "Enter your new password" : viewModel.showCodeInput ? "Enter the code sent to \(viewModel.email)" : "Enter your email to receive a reset code")
                            .font(.system(size: 16, weight: .medium))
                            .foregroundColor(.white.opacity(0.9))
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 40)
                    }
                    
                    if viewModel.showPasswordInput {
                        // Password Reset Card
                        passwordResetCard
                    } else if viewModel.showCodeInput {
                        // Code Verification Card
                        codeVerificationCard
                    } else {
                        // Email Input Card
                        emailInputCard
                    }
                    
                    Spacer()
                        .frame(height: 40)
                }
            }
        }
        .navigationBarHidden(true)
        .alert("Success", isPresented: $viewModel.passwordResetSuccess) {
            Button("OK") {
                dismiss()
            }
        } message: {
            Text("Your password has been reset successfully. You can now login with your new password.")
        }
    }
    
    private var emailInputCard: some View {
        VStack(spacing: 20) {
            CustomTextField(
                icon: "envelope.fill",
                placeholder: "Email",
                text: $viewModel.email,
                isSecure: false,
                isValid: viewModel.email.isEmpty || Validators.isValidEmail(viewModel.email),
                errorMessage: Validators.validateEmail(viewModel.email).errorMessage
            )
            .textInputAutocapitalization(.never)
            .keyboardType(.emailAddress)
            
            if !viewModel.errorMessage.isEmpty {
                Text(viewModel.errorMessage)
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(.red)
                    .multilineTextAlignment(.center)
            }
            
            Button(action: {
                Task {
                    await viewModel.requestResetCode()
                }
            }) {
                if viewModel.isLoading {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle(tint: .white))
                } else {
                    HStack(spacing: 8) {
                        Text("Send Reset Code")
                            .font(.system(size: 17, weight: .semibold))
                        Image(systemName: "paperplane.fill")
                            .font(.system(size: 14, weight: .bold))
                    }
                    .foregroundColor(.white)
                }
            }
            .frame(maxWidth: .infinity)
            .frame(height: 54)
            .background(
                LinearGradient(
                    colors: [Color.brandPrimary, Color.brandSecondary],
                    startPoint: .leading,
                    endPoint: .trailing
                )
                .opacity((viewModel.isLoading || !Validators.isValidEmail(viewModel.email)) ? 0.5 : 1.0)
            )
            .cornerRadius(16)
            .shadow(color: Color.brandPrimary.opacity(0.4), radius: 12, x: 0, y: 6)
            .disabled(viewModel.isLoading || !Validators.isValidEmail(viewModel.email))
            
            Button(action: {
                dismiss()
            }) {
                HStack(spacing: 6) {
                    Image(systemName: "arrow.left")
                        .font(.system(size: 14, weight: .semibold))
                    Text("Back to Login")
                        .font(.system(size: 15, weight: .semibold))
                }
                .foregroundColor(.brandPrimary)
            }
            .padding(.top, 8)
        }
        .padding(28)
        .background(Color(.systemBackground))
        .cornerRadius(28)
        .shadow(color: Color.black.opacity(0.15), radius: 20, x: 0, y: 10)
        .padding(.horizontal, 24)
    }
    
    private var codeVerificationCard: some View {
        VStack(spacing: 20) {
            // Code Input
            VStack(spacing: 16) {
                CodeInputView(code: $viewModel.resetCode) {
                    // Auto-verify when code is complete
                    Task {
                        await viewModel.verifyCode()
                    }
                }
                .disabled(viewModel.isVerifying)
                .opacity(viewModel.isVerifying ? 0.6 : 1.0)
                
                if viewModel.isVerifying {
                    HStack(spacing: 8) {
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle(tint: .brandPrimary))
                        Text("Verifying...")
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(.brandPrimary)
                    }
                } else if !viewModel.errorMessage.isEmpty {
                    Text(viewModel.errorMessage)
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(.red)
                        .multilineTextAlignment(.center)
                }
                
                Text("Code expires in 10 minutes")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(.secondary)
            }
            .padding(24)
            .background(Color(.secondarySystemBackground))
            .cornerRadius(16)
            
            // Resend Code Button
            Button(action: {
                Task {
                    await viewModel.resendCode()
                }
            }) {
                HStack(spacing: 8) {
                    if viewModel.isLoading {
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle(tint: .brandPrimary))
                    } else {
                        Image(systemName: "arrow.clockwise")
                            .font(.system(size: 14, weight: .semibold))
                    }
                    Text(viewModel.canResend ? "Resend Code" : "Resend in \(viewModel.resendCountdown)s")
                        .font(.system(size: 15, weight: .semibold))
                }
                .foregroundColor(viewModel.canResend ? .brandPrimary : .secondary)
            }
            .disabled(!viewModel.canResend || viewModel.isLoading)
            
            Button(action: {
                dismiss()
            }) {
                HStack(spacing: 6) {
                    Image(systemName: "arrow.left")
                        .font(.system(size: 14, weight: .semibold))
                    Text("Back to Login")
                        .font(.system(size: 15, weight: .semibold))
                }
                .foregroundColor(.brandPrimary)
            }
            .padding(.top, 8)
        }
        .padding(28)
        .background(Color(.systemBackground))
        .cornerRadius(28)
        .shadow(color: Color.black.opacity(0.15), radius: 20, x: 0, y: 10)
        .padding(.horizontal, 24)
    }
    
    private var passwordResetCard: some View {
        VStack(spacing: 20) {
            // Password Fields
            VStack(spacing: 16) {
                CustomTextField(
                    icon: "lock.fill",
                    placeholder: "New Password",
                    text: $viewModel.newPassword,
                    isSecure: true,
                    isValid: viewModel.newPassword.isEmpty || Validators.isValidPassword(viewModel.newPassword),
                    errorMessage: Validators.validatePassword(viewModel.newPassword).errorMessage
                )
                
                CustomTextField(
                    icon: "lock.fill",
                    placeholder: "Confirm Password",
                    text: $viewModel.confirmPassword,
                    isSecure: true,
                    isValid: viewModel.confirmPassword.isEmpty || viewModel.newPassword == viewModel.confirmPassword,
                    errorMessage: viewModel.confirmPassword.isEmpty || viewModel.newPassword == viewModel.confirmPassword ? nil : "Passwords do not match"
                )
            }
            
            if !viewModel.errorMessage.isEmpty {
                Text(viewModel.errorMessage)
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(.red)
                    .multilineTextAlignment(.center)
            }
            
            // Reset Password Button
            Button(action: {
                Task {
                    await viewModel.resetPassword()
                }
            }) {
                if viewModel.isVerifying {
                    HStack(spacing: 8) {
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle(tint: .white))
                        Text("Resetting...")
                            .font(.system(size: 17, weight: .semibold))
                            .foregroundColor(.white)
                    }
                } else {
                    Text("Reset Password")
                        .font(.system(size: 17, weight: .semibold))
                        .foregroundColor(.white)
                }
            }
            .frame(maxWidth: .infinity)
            .frame(height: 54)
            .background(
                LinearGradient(
                    colors: [Color.brandPrimary, Color.brandSecondary],
                    startPoint: .leading,
                    endPoint: .trailing
                )
                .opacity(isResetButtonDisabled ? 0.5 : 1.0)
            )
            .cornerRadius(16)
            .shadow(color: Color.brandPrimary.opacity(0.4), radius: 12, x: 0, y: 6)
            .disabled(isResetButtonDisabled)
            
            Button(action: {
                dismiss()
            }) {
                HStack(spacing: 6) {
                    Image(systemName: "arrow.left")
                        .font(.system(size: 14, weight: .semibold))
                    Text("Back to Login")
                        .font(.system(size: 15, weight: .semibold))
                }
                .foregroundColor(.brandPrimary)
            }
            .padding(.top, 8)
        }
        .padding(28)
        .background(Color(.systemBackground))
        .cornerRadius(28)
        .shadow(color: Color.black.opacity(0.15), radius: 20, x: 0, y: 10)
        .padding(.horizontal, 24)
    }
    
    private var isResetButtonDisabled: Bool {
        viewModel.isVerifying ||
        !Validators.isValidPassword(viewModel.newPassword) ||
        viewModel.newPassword != viewModel.confirmPassword
    }
}
