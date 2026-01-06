import SwiftUI

struct ChangePasswordView: View {
    @Environment(\.dismiss) private var dismiss
    @StateObject private var viewModel = ChangePasswordViewModel()
    @State private var showCurrentPassword = false
    @State private var showNewPassword = false
    @State private var showConfirmPassword = false
    
    var body: some View {
        GeometryReader { geometry in
            ScrollView(showsIndicators: false) {
                VStack(spacing: 24) {
                    // Header Icon
                    ZStack {
                        Circle()
                            .fill(
                                LinearGradient(
                                    colors: [Color.orange.opacity(0.2), Color.orange.opacity(0.1)],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                            .frame(width: 100, height: 100)
                        
                        Image(systemName: "lock.shield.fill")
                            .font(.system(size: 50, weight: .medium))
                            .foregroundColor(.orange)
                    }
                    .shadow(color: Color.orange.opacity(0.2), radius: 15, x: 0, y: 8)
                    .padding(.top, 20)
                    
                    VStack(spacing: 8) {
                        Text("Change Password")
                            .font(.system(size: 28, weight: .bold))
                        
                        Text("Enter your current password and choose a new one")
                            .font(.system(size: 15, weight: .medium))
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 40)
                    }
                    
                    // Password Form Card
                    VStack(spacing: 20) {
                        VStack(spacing: 16) {
                            // Current Password
                            CustomTextField(
                                icon: "lock.fill",
                                placeholder: "Current Password",
                                text: $viewModel.currentPassword,
                                isSecure: true,
                                showPassword: $showCurrentPassword,
                                isValid: viewModel.currentPassword.isEmpty || !viewModel.currentPassword.isEmpty,
                                errorMessage: nil
                            )
                            
                            // New Password
                            CustomTextField(
                                icon: "lock.fill",
                                placeholder: "New Password",
                                text: $viewModel.newPassword,
                                isSecure: true,
                                showPassword: $showNewPassword,
                                isValid: viewModel.newPassword.isEmpty || Validators.isValidPassword(viewModel.newPassword),
                                errorMessage: Validators.validatePassword(viewModel.newPassword).errorMessage
                            )
                            
                            // Confirm Password
                            CustomTextField(
                                icon: "lock.fill",
                                placeholder: "Confirm New Password",
                                text: $viewModel.confirmPassword,
                                isSecure: true,
                                showPassword: $showConfirmPassword,
                                isValid: viewModel.confirmPassword.isEmpty || viewModel.newPassword == viewModel.confirmPassword,
                                errorMessage: viewModel.confirmPassword.isEmpty || viewModel.newPassword == viewModel.confirmPassword ? nil : "Passwords do not match"
                            )
                        }
                        
                        if !viewModel.errorMessage.isEmpty {
                            HStack(spacing: 8) {
                                Image(systemName: "exclamationmark.triangle.fill")
                                    .font(.system(size: 14, weight: .semibold))
                                Text(viewModel.errorMessage)
                                    .font(.system(size: 14, weight: .medium))
                            }
                            .foregroundColor(.red)
                            .padding(12)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .background(Color.red.opacity(0.1))
                            .cornerRadius(12)
                        }
                        
                        if viewModel.successMessage {
                            HStack(spacing: 8) {
                                Image(systemName: "checkmark.circle.fill")
                                    .font(.system(size: 14, weight: .semibold))
                                Text("Password changed successfully!")
                                    .font(.system(size: 14, weight: .medium))
                            }
                            .foregroundColor(.green)
                            .padding(12)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .background(Color.green.opacity(0.1))
                            .cornerRadius(12)
                        }
                        
                        // Change Password Button
                        Button(action: {
                            Task {
                                await viewModel.changePassword()
                            }
                        }) {
                            if viewModel.isLoading {
                                HStack(spacing: 8) {
                                    ProgressView()
                                        .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                    Text("Changing...")
                                        .font(.system(size: 17, weight: .semibold))
                                        .foregroundColor(.white)
                                }
                            } else {
                                HStack(spacing: 8) {
                                    Text("Change Password")
                                        .font(.system(size: 17, weight: .semibold))
                                    Image(systemName: "arrow.right")
                                        .font(.system(size: 14, weight: .bold))
                                }
                                .foregroundColor(.white)
                            }
                        }
                        .frame(maxWidth: .infinity)
                        .frame(height: 54)
                        .background(
                            LinearGradient(
                                colors: [Color.orange, Color.orange.opacity(0.8)],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                            .opacity(isButtonDisabled ? 0.5 : 1.0)
                        )
                        .cornerRadius(16)
                        .shadow(color: Color.orange.opacity(0.4), radius: 12, x: 0, y: 6)
                        .disabled(isButtonDisabled)
                    }
                    .padding(28)
                    .background(Color.appSurface)
                    .cornerRadius(24)
                    .overlay(
                        RoundedRectangle(cornerRadius: 24, style: .continuous)
                            .stroke(Color.appBorder.opacity(0.9), lineWidth: 1)
                    )
                    .shadow(color: Color.black.opacity(0.18), radius: 18, x: 0, y: 10)
                    .padding(.horizontal, 20)
                    
                    Spacer()
                }
                .padding(.vertical, 20)
                .padding(.bottom, DS.barHeight + 8)
            }
            .background(Color.appGroupedBackground)
        }
        .navigationTitle("Change Password")
        .navigationBarTitleDisplayMode(.inline)
        .alert("Success", isPresented: $viewModel.showSuccessAlert) {
            Button("OK") {
                dismiss()
            }
        } message: {
            Text("Your password has been changed successfully.")
        }
    }
    
    private var isButtonDisabled: Bool {
        viewModel.isLoading ||
        viewModel.currentPassword.isEmpty ||
        !Validators.isValidPassword(viewModel.newPassword) ||
        viewModel.newPassword != viewModel.confirmPassword
    }
}

#Preview {
    NavigationView {
        ChangePasswordView()
    }
}
