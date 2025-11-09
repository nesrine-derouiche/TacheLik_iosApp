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
                            isSecure: true,
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
                        
                        VStack(alignment: .leading, spacing: 6) {
                            Text("Password must have:")
                                .font(.system(size: 11, weight: .semibold))
                                .foregroundColor(.secondary)
                            
                            // Minimum 8 characters
                            PasswordRequirementRow(
                                text: "At least 8 characters",
                                isMet: viewModel.password.count >= 8,
                                isRequired: true
                            )
                            
                            // At least one number
                            PasswordRequirementRow(
                                text: "At least one number",
                                isMet: viewModel.password.range(of: "[0-9]", options: .regularExpression) != nil,
                                isRequired: true
                            )
                            
                            // At least one letter
                            PasswordRequirementRow(
                                text: "At least one letter",
                                isMet: viewModel.password.range(of: "[A-Za-z]", options: .regularExpression) != nil,
                                isRequired: true
                            )
                            
                            if !Validators.getPasswordImprovements().isEmpty {
                                Text("For stronger password:")
                                    .font(.system(size: 11, weight: .semibold))
                                    .foregroundColor(.secondary)
                                    .padding(.top, 4)
                                
                                // Uppercase letter (optional)
                                PasswordRequirementRow(
                                    text: "Add uppercase letter for stronger password",
                                    isMet: viewModel.password.range(of: "[A-Z]", options: .regularExpression) != nil,
                                    isRequired: false
                                )
                                
                                // Special character (optional)
                                PasswordRequirementRow(
                                    text: "Add special character for stronger password",
                                    isMet: viewModel.password.range(of: "[!@#$%^&*()_+\\-=\\[\\]{};':\"\\\\|,.<>\\/?]", options: .regularExpression) != nil,
                                    isRequired: false
                                )
                            }
                        }
                        .padding(.horizontal, 16)
                    }
                    
                    CustomTextField(
                        icon: "lock.shield",
                        placeholder: "Confirm Password",
                        text: $viewModel.confirmPassword,
                        isSecure: true,
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
                                isSecure: false,
                                isValid: viewModel.inviteCode.isEmpty || viewModel.inviteLinkValid || viewModel.isCheckingInviteLink
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
                
                HStack(spacing: 4) {
                    Text("Already have an account?")
                        .foregroundColor(.secondary)
                    Button("Login") {
                        dismiss()
                    }
                    .buttonStyle(.plain)
                    .foregroundColor(.blue)
                }
            }
            .padding()
        }
        .alert("Error", isPresented: $viewModel.showError) {
            Button("OK", role: .cancel) { }
        } message: {
            if let errorMessage = viewModel.errorMessage {
                Text(errorMessage)
            }
        }
        .alert("Success", isPresented: $viewModel.registrationSuccess) {
            Button("OK") {
                isLoggedIn = true
                dismiss()
            }
        } message: {
            Text("Account created successfully!")
        }
    }
}

// MARK: - Password Requirement Row
struct PasswordRequirementRow: View {
    let text: String
    let isMet: Bool
    let isRequired: Bool
    
    var body: some View {
        HStack(spacing: 6) {
            Image(systemName: isMet ? "checkmark.circle.fill" : (isRequired ? "circle" : "star.circle"))
                .font(.system(size: 12, weight: .semibold))
                .foregroundColor(iconColor)
            
            Text(text)
                .font(.system(size: 11))
                .foregroundColor(textColor)
                .strikethrough(isMet, color: .brandSuccess)
        }
        .animation(.spring(response: 0.3, dampingFraction: 0.7), value: isMet)
    }
    
    private var iconColor: Color {
        if isMet {
            return .brandSuccess
        } else if isRequired {
            return .secondary
        } else {
            return .brandWarning
        }
    }
    
    private var textColor: Color {
        if isMet {
            return .brandSuccess
        } else {
            return .secondary
        }
    }
}