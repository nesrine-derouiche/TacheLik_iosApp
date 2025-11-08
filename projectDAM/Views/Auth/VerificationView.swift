//
//  VerificationView.swift
//  projectDAM
//
//  Created on 11/8/2025.
//

import SwiftUI

struct VerificationView: View {
    @AppStorage("isLoggedIn") private var isLoggedIn = false
    @EnvironmentObject var sessionManager: SessionManager
    @State private var isResending = false
    @State private var showSuccessMessage = false
    @State private var hasAutoSent = false
    @State private var viewDidAppear = false
    @State private var showErrorAlert = false
    @State private var errorMessage = ""
    
    private let authService = DIContainer.shared.authService
    
    private var userEmail: String {
        authService.getCurrentUser()?.email ?? ""
    }
    
    var body: some View {
        ZStack {
            // Background gradient
            LinearGradient(
                colors: [Color.brandPrimary.opacity(0.1), Color.brandSecondary.opacity(0.05)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()
            
            ScrollView {
                VStack(spacing: 30) {
                    Spacer()
                        .frame(height: 60)
                    
                    // Verification icon
                    ZStack {
                        Circle()
                            .fill(Color.brandPrimary.opacity(0.1))
                            .frame(width: 120, height: 120)
                        
                        Image(systemName: "envelope.badge.shield.half.filled")
                            .font(.system(size: 60, weight: .bold))
                            .foregroundStyle(LinearGradient.brandPrimaryGradient)
                    }
                    
                    VStack(spacing: 12) {
                        Text("Verify Your Email")
                            .font(.system(size: 28, weight: .bold))
                            .foregroundColor(.primary)
                        
                        Text("We've sent a verification link to")
                            .font(.system(size: 16, weight: .medium))
                            .foregroundColor(.secondary)
                        
                        Text(userEmail)
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(.brandPrimary)
                    }
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 40)
                    
                    VStack(spacing: 20) {
                        // Instructions
                        VStack(alignment: .leading, spacing: 16) {
                            InstructionRow(
                                number: "1",
                                text: "Check your email inbox"
                            )
                            InstructionRow(
                                number: "2",
                                text: "Click the verification link"
                            )
                            InstructionRow(
                                number: "3",
                                text: "Return to the app and refresh"
                            )
                        }
                        .padding(24)
                        .background(Color(.systemBackground))
                        .cornerRadius(16)
                        .shadow(color: Color.black.opacity(0.05), radius: 10, x: 0, y: 4)
                        .padding(.horizontal, 40)
                        
                        // Success message
                        if showSuccessMessage {
                            HStack(spacing: 12) {
                                Image(systemName: "checkmark.circle.fill")
                                    .foregroundColor(.green)
                                Text("Verification email sent!")
                                    .font(.system(size: 14, weight: .medium))
                                    .foregroundColor(.green)
                            }
                            .padding()
                            .background(Color.green.opacity(0.1))
                            .cornerRadius(12)
                            .padding(.horizontal, 40)
                        }
                        
                        // Resend Button
                        Button(action: resendVerificationEmail) {
                            HStack(spacing: 12) {
                                if isResending {
                                    ProgressView()
                                        .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                } else {
                                    Image(systemName: "arrow.clockwise")
                                        .font(.system(size: 16, weight: .semibold))
                                    Text("Resend Verification Email")
                                        .font(.system(size: 16, weight: .semibold))
                                }
                            }
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(
                                LinearGradient.brandPrimaryGradient
                                    .opacity(isResending ? 0.5 : 1.0)
                            )
                            .cornerRadius(12)
                        }
                        .disabled(isResending)
                        .padding(.horizontal, 40)
                        
                        // Refresh Button
                        Button(action: refreshUserData) {
                            HStack(spacing: 12) {
                                Image(systemName: "arrow.triangle.2.circlepath")
                                    .font(.system(size: 16, weight: .semibold))
                                Text("I've Verified - Refresh")
                                    .font(.system(size: 16, weight: .semibold))
                            }
                            .foregroundColor(.brandPrimary)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.brandPrimary.opacity(0.1))
                            .cornerRadius(12)
                        }
                        .padding(.horizontal, 40)
                        
                        // Logout Button
                        Button(action: {
                            sessionManager.logout()
                            isLoggedIn = false
                        }) {
                            Text("Logout")
                                .font(.system(size: 15, weight: .medium))
                                .foregroundColor(.secondary)
                        }
                        .padding(.top, 8)
                    }
                    
                    Spacer()
                }
            }
        }
        .onAppear {
            // Automatically send verification email when view appears
            if !viewDidAppear {
                viewDidAppear = true
                if !hasAutoSent {
                    hasAutoSent = true
                    // Delay slightly to ensure view is fully loaded
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                        resendVerificationEmail()
                    }
                }
            }
        }
        .alert("Error", isPresented: $showErrorAlert) {
            Button("OK", role: .cancel) { }
        } message: {
            Text(errorMessage)
        }
    }
    
    private func resendVerificationEmail() {
        isResending = true
        showSuccessMessage = false
        
        Task {
            do {
                try await authService.requestEmailVerification()
                isResending = false
                showSuccessMessage = true
                
                print("✅ Verification email sent successfully")
                
                // Hide success message after 3 seconds
                try? await Task.sleep(nanoseconds: 3_000_000_000)
                showSuccessMessage = false
            } catch let error as NetworkError {
                isResending = false
                handleError(error)
            } catch {
                isResending = false
                errorMessage = "Failed to send verification email: \(error.localizedDescription)"
                showErrorAlert = true
                print("❌ Failed to send verification email: \(error.localizedDescription)")
            }
        }
    }
    
    private func handleError(_ error: NetworkError) {
        switch error {
        case .serverError(let code, let message):
            if code == 429 {
                errorMessage = "Too many requests. Please wait a moment before trying again."
            } else if let message = message {
                errorMessage = message
            } else {
                errorMessage = "Server error (\(code)). Please try again later."
            }
        case .unauthorized:
            errorMessage = "Session expired. Please login again."
            isLoggedIn = false
        case .invalidURL:
            errorMessage = "Invalid server URL. Please contact support."
        case .noData:
            errorMessage = "No response from server. Please check your connection."
        case .decodingError:
            errorMessage = "Invalid response from server. Please try again."
        case .invalidResponse:
            errorMessage = "Invalid response from server. Please try again."
        }
        showErrorAlert = true
        print("❌ Failed to send verification email: \(errorMessage)")
    }
    
    private func refreshUserData() {
        Task {
            do {
                try await authService.refreshUserData()
                // The app will automatically navigate if user is now verified
            } catch {
                print("❌ Failed to refresh user data: \(error.localizedDescription)")
            }
        }
    }
}

struct InstructionRow: View {
    let number: String
    let text: String
    
    var body: some View {
        HStack(spacing: 16) {
            ZStack {
                Circle()
                    .fill(LinearGradient.brandPrimaryGradient)
                    .frame(width: 32, height: 32)
                
                Text(number)
                    .font(.system(size: 14, weight: .bold))
                    .foregroundColor(.white)
            }
            
            Text(text)
                .font(.system(size: 15, weight: .medium))
                .foregroundColor(.primary)
            
            Spacer()
        }
    }
}
