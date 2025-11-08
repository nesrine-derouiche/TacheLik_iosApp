import SwiftUI

struct RegisterView: View {
    @Environment(\.dismiss) private var dismiss
    @StateObject private var viewModel = RegisterViewModel()
    @AppStorage("isLoggedIn") private var isLoggedIn = false
    @State private var showPassword = false
    @State private var showConfirmPassword = false
    
    var strengthColor: Color {
        switch viewModel.passwordStrength {
        case 0: return .gray
        case 1: return .red
        case 2: return .orange
        case 3: return .green
        default: return .gray
        }
    }
    
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
                        placeholder: "Username (max 15 chars)",
                        text: $viewModel.username,
                        isSecure: false,
                        isValid: viewModel.username.isEmpty || Validators.isValidUsername(viewModel.username),
                        errorMessage: Validators.validateUsername(viewModel.username).errorMessage
                    )
                    .onChange(of: viewModel.username) { newValue in
                        // Limit to 15 characters
                        if newValue.count > 15 {
                            viewModel.username = String(newValue.prefix(15))
                        }
                    }
                    
                    CustomTextField(
                        icon: "envelope",
                        placeholder: "Email",
                        text: $viewModel.email,
                        isSecure: false,
                        isValid: viewModel.email.isEmpty || Validators.isValidEmail(viewModel.email),
                        errorMessage: Validators.validateEmail(viewModel.email).errorMessage
                    )
                    .textInputAutocapitalization(.never)
                    .keyboardType(.emailAddress)
                    
                    VStack(alignment: .leading, spacing: 8) {
                        CustomTextField(
                            icon: "lock",
                            placeholder: "Password (min 8 characters)",
                            text: $viewModel.password,
                            isSecure: !showPassword,
                            showPassword: $showPassword,
                            isValid: viewModel.password.isEmpty || Validators.isValidPassword(viewModel.password),
                            errorMessage: Validators.validatePassword(viewModel.password).errorMessage
                        )
                        
                        if !viewModel.password.isEmpty {
                            // Password strength indicator
                            HStack(spacing: 8) {
                                ForEach(0..<3) { index in
                                    RoundedRectangle(cornerRadius: 2)
                                        .fill(index < viewModel.passwordStrength ? strengthColor : Color.gray.opacity(0.3))
                                        .frame(height: 4)
                                }
                            }
                            .padding(.horizontal, 16)
                            
                            if viewModel.passwordStrength > 0 {
                                Text(viewModel.passwordStrengthDescription)
                                    .font(.system(size: 12, weight: .semibold))
                                    .foregroundColor(strengthColor)
                                    .padding(.horizontal, 16)
                            }
                        }
                        
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Password must have:")
                                .font(.system(size: 11, weight: .semibold))
                                .foregroundColor(.secondary)
                            
                            ForEach(Validators.getPasswordRequirements(), id: \.self) { requirement in
                                HStack(spacing: 4) {
                                    Image(systemName: "checkmark.circle.fill")
                                        .font(.system(size: 10))
                                        .foregroundColor(.brandSuccess)
                                    Text(requirement)
                                        .font(.system(size: 11))
                                        .foregroundColor(.secondary)
                                }
                            }
                            
                            if !Validators.getPasswordImprovements().isEmpty {
                                Text("For stronger password:")
                                    .font(.system(size: 11, weight: .semibold))
                                    .foregroundColor(.secondary)
                                    .padding(.top, 4)
                                
                                ForEach(Validators.getPasswordImprovements(), id: \.self) { improvement in
                                    HStack(spacing: 4) {
                                        Image(systemName: "star.circle")
                                            .font(.system(size: 10))
                                            .foregroundColor(.brandWarning)
                                        Text(improvement)
                                            .font(.system(size: 11))
                                            .foregroundColor(.secondary)
                                    }
                                }
                            }
                        }
                        .padding(.horizontal, 16)
                    }
                    
                    CustomTextField(
                        icon: "lock.shield",
                        placeholder: "Confirm Password",
                        text: $viewModel.confirmPassword,
                        isSecure: !showConfirmPassword,
                        showPassword: $showConfirmPassword,
                        isValid: viewModel.confirmPassword.isEmpty || viewModel.password == viewModel.confirmPassword,
                        errorMessage: viewModel.confirmPassword.isEmpty ? nil : (viewModel.password == viewModel.confirmPassword ? nil : "Passwords do not match")
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