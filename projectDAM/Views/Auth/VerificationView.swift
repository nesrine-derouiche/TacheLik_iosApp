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
    @State private var verificationCode = ""
    @State private var isVerifying = false
    @State private var isResending = false
    @State private var showSuccessMessage = false
    @State private var hasAutoSent = false
    @State private var viewDidAppear = false
    @State private var showErrorAlert = false
    @State private var errorMessage = ""
    @State private var canResend = false
    @State private var resendCooldown = 60
    
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
                        
                        Text("Enter the 6-digit code sent to")
                            .font(.system(size: 16, weight: .medium))
                            .foregroundColor(.secondary)
                        
                        Text(userEmail)
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(.brandPrimary)
                    }
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 40)
                    
                    VStack(spacing: 20) {
                        // Code Input
                        VStack(spacing: 16) {
                            CodeInputView(code: $verificationCode) {
                                // Auto-verify when code is complete
                                verifyCode()
                            }
                            .disabled(isVerifying)
                            .opacity(isVerifying ? 0.6 : 1.0)
                            
                            if isVerifying {
                                HStack(spacing: 8) {
                                    ProgressView()
                                        .progressViewStyle(CircularProgressViewStyle(tint: .brandPrimary))
                                    Text("Verifying...")
                                        .font(.system(size: 14, weight: .medium))
                                        .foregroundColor(.brandPrimary)
                                }
                            } else if !errorMessage.isEmpty {
                                Text(errorMessage)
                                    .font(.system(size: 14, weight: .medium))
                                    .foregroundColor(.red)
                                    .multilineTextAlignment(.center)
                            }
                            
                            Text("Code expires in 10 minutes")
                                .font(.system(size: 14, weight: .medium))
                                .foregroundColor(.secondary)
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
                        Button(action: resendVerificationCode) {
                            HStack(spacing: 12) {
                                if isResending {
                                    ProgressView()
                                        .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                } else {
                                    Image(systemName: "arrow.clockwise")
                                        .font(.system(size: 16, weight: .semibold))
                                    Text(canResend ? "Resend Code" : "Resend in \(resendCooldown)s")
                                        .font(.system(size: 16, weight: .semibold))
                                }
                            }
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(
                                LinearGradient.brandPrimaryGradient
                                    .opacity((isResending || !canResend) ? 0.5 : 1.0)
                            )
                            .cornerRadius(12)
                        }
                        .disabled(isResending || !canResend)
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
            // Automatically send verification code when view appears
            if !viewDidAppear {
                viewDidAppear = true
                if !hasAutoSent {
                    hasAutoSent = true
                    // Delay slightly to ensure view is fully loaded
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                        resendVerificationCode()
                    }
                }
            }
        }
    }
    
    private func resendVerificationCode() {
        isResending = true
        errorMessage = ""
        verificationCode = ""
        
        Task {
            do {
                try await authService.requestEmailVerificationCode(email: userEmail)
                isResending = false
                showSuccessMessage = true
                
                // Start cooldown
                canResend = false
                resendCooldown = 60
                startCooldownTimer()
                
                print("✅ Verification code sent successfully")
                
                // Hide success message after 3 seconds
                try? await Task.sleep(nanoseconds: 3_000_000_000)
                showSuccessMessage = false
            } catch {
                isResending = false
                errorMessage = "Failed to send code: \(error.localizedDescription)"
                print("❌ Failed to send verification code: \(error.localizedDescription)")
            }
        }
    }
    
    private func verifyCode() {
        guard verificationCode.count == 6 else { return }
        
        isVerifying = true
        errorMessage = ""
        
        Task {
            do {
                try await authService.verifyEmailWithCode(email: userEmail, code: verificationCode)
                isVerifying = false
                
                // Check if user has pending invite code
                if let user = authService.getCurrentUser() {
                    await setInviteLinkIfPending(userId: user.id)
                }
                
                print("✅ Email verified successfully")
                // App will automatically navigate to home
            } catch {
                isVerifying = false
                errorMessage = "Invalid or expired code"
                verificationCode = ""
                print("❌ Failed to verify code: \(error.localizedDescription)")
            }
        }
    }
    
    private func startCooldownTimer() {
        Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { timer in
            if resendCooldown > 0 {
                resendCooldown -= 1
            } else {
                canResend = true
                timer.invalidate()
            }
        }
    }
    
    
    private func setInviteLinkIfPending(userId: String) async {
        // Check if there's a pending invite code
        guard let inviteCode = UserDefaults.standard.string(forKey: "pendingInviteCode") else {
            return
        }
        
        do {
            try await authService.setUserInvitedByLink(userId: userId, link: inviteCode)
            print("✅ Invite link set after verification")
        } catch {
            print("❌ Failed to set invite link: \(error.localizedDescription)")
            // Don't show error to user, this is a background operation
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
