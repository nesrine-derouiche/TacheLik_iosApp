import SwiftUI

struct RegisterView: View {
    @Environment(\.dismiss) private var dismiss
    @StateObject private var viewModel = RegisterViewModel()
    @AppStorage("isLoggedIn") private var isLoggedIn = false
    @State private var showPassword = false
    @State private var showConfirmPassword = false
    
    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                Text("Create Account")
                    .font(.title2)
                    .fontWeight(.bold)
                    .padding(.top)
                
                VStack(spacing: 15) {
                    CustomTextField(
                        icon: "person",
                        placeholder: "Username",
                        text: $viewModel.username,
                        isSecure: false
                    )
                    
                    CustomTextField(
                        icon: "envelope",
                        placeholder: "Email",
                        text: $viewModel.email,
                        isSecure: false
                    )
                    .textInputAutocapitalization(.never)
                    .keyboardType(.emailAddress)
                    
                    CustomTextField(
                        icon: "lock",
                        placeholder: "Password (min 6 characters)",
                        text: $viewModel.password,
                        isSecure: !showPassword,
                        showPassword: $showPassword
                    )
                    
                    CustomTextField(
                        icon: "lock.shield",
                        placeholder: "Confirm Password",
                        text: $viewModel.confirmPassword,
                        isSecure: !showConfirmPassword,
                        showPassword: $showConfirmPassword
                    )
                    
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            CustomTextField(
                                icon: "ticket",
                                placeholder: "Invite Code (optional)",
                                text: $viewModel.inviteCode,
                                isSecure: false
                            )
                            .textInputAutocapitalization(.characters)
                            .onChange(of: viewModel.inviteCode) { newValue in
                                // Limit to 6 characters
                                if newValue.count > 6 {
                                    viewModel.inviteCode = String(newValue.prefix(6))
                                } else {
                                    // Check invite link when 6 characters entered
                                    Task {
                                        await viewModel.checkInviteLink()
                                    }
                                }
                            }
                            
                            if viewModel.isCheckingInviteLink {
                                ProgressView()
                                    .padding(.trailing, 8)
                            }
                        }
                        
                        if !viewModel.inviteLinkMessage.isEmpty {
                            Text(viewModel.inviteLinkMessage)
                                .font(.system(size: 12))
                                .foregroundColor(viewModel.inviteLinkSpecial ? .green : .red)
                                .padding(.horizontal, 16)
                        }
                        
                        Text("Optional - Get a reduction on your first purchase with a special invite code")
                            .font(.system(size: 11))
                            .foregroundColor(.secondary)
                            .padding(.horizontal, 16)
                    }
                }
                
                Button(action: {
                    Task {
                        await viewModel.register()
                    }
                }) {
                    if viewModel.isLoading {
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle(tint: .white))
                    } else {
                        Text("Create Account")
                            .fontWeight(.bold)
                    }
                }
                .frame(maxWidth: .infinity)
                .padding()
                .background(
                    LinearGradient.brandPrimaryGradient
                        .opacity(viewModel.isFormValid ? 1.0 : 0.5)
                )
                .foregroundColor(.white)
                .cornerRadius(12)
                .disabled(viewModel.isLoading || !viewModel.isFormValid)
                
                Button("Already have an account? Login") {
                    dismiss()
                }
                .foregroundColor(.blue)
            }
            .padding()
        }
        .alert("Registration Error", isPresented: $viewModel.showError) {
            Button("OK", role: .cancel) { }
        } message: {
            Text(viewModel.errorMessage ?? "An error occurred")
        }
        .onChange(of: viewModel.registrationSuccess) { success in
            if success {
                isLoggedIn = true
                dismiss()
            }
        }
    }
}