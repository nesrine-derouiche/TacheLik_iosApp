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
                        
                        Image(systemName: "lock.rotation")
                            .font(.system(size: 50, weight: .medium))
                            .foregroundColor(.white)
                    }
                    .shadow(color: Color.black.opacity(0.2), radius: 15, x: 0, y: 8)
                    
                    VStack(spacing: 8) {
                        Text("Forgot Password?")
                            .font(.system(size: 34, weight: .bold))
                            .foregroundColor(.white)
                        
                        Text("Enter your email to receive a password reset link")
                            .font(.system(size: 16, weight: .medium))
                            .foregroundColor(.white.opacity(0.9))
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 40)
                    }
                    
                    // Reset Card
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
                        
                        Button(action: {
                            Task {
                                await viewModel.sendResetLink()
                            }
                        }) {
                            if viewModel.isLoading {
                                ProgressView()
                                    .progressViewStyle(CircularProgressViewStyle(tint: .white))
                            } else {
                                HStack(spacing: 8) {
                                    Text("Send Reset Link")
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
                    
                    Spacer()
                        .frame(height: 40)
                }
            }
        }
        .navigationBarHidden(true)
        .alert("Success", isPresented: $viewModel.showSuccess) {
            Button("OK") {
                dismiss()
            }
        } message: {
            Text("Password reset link has been sent to your email")
        }
        .alert("Error", isPresented: $viewModel.showError) {
            Button("OK", role: .cancel) { }
        } message: {
            if let errorMessage = viewModel.errorMessage {
                Text(errorMessage)
            }
        }
    }
}
