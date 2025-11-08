import SwiftUI

// MARK: - Login View
/// UI for user authentication - follows MVVM pattern
struct LoginView: View {
    @StateObject private var viewModel = DIContainer.shared.makeLoginViewModel()
    @State private var showAlert = false
    
    var body: some View {
        ZStack {
            // Beautiful gradient background
            LinearGradient.brandHeader
                .ignoresSafeArea()
            
            ScrollView(showsIndicators: false) {
                VStack(spacing: 32) {
                    Spacer()
                        .frame(height: 40)
                    
                    // Tache-lik Logo
                    Image("tache_lik_logo_white_red")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 140, height: 140)
                        .rotationEffect(.degrees(-45))
                        .shadow(color: Color.black.opacity(0.2), radius: 15, x: 0, y: 8)
                    
                    VStack(spacing: 8) {
                        Text("Welcome Back!")
                            .font(.system(size: 34, weight: .bold))
                            .foregroundColor(.white)
                        
                        Text("Sign in to continue your learning journey")
                            .font(.system(size: 16, weight: .medium))
                            .foregroundColor(.white.opacity(0.9))
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 40)
                    }
                    
                    // Login Card
                    VStack(spacing: 20) {
                        CustomTextField(
                            icon: "envelope.fill",
                            placeholder: "Email",
                            text: $viewModel.email,
                            isSecure: false,
                            isValid: viewModel.email.isEmpty || Validators.isValidEmail(viewModel.email),
                            errorMessage: Validators.validateEmail(viewModel.email).errorMessage
                        )
                        
                        CustomTextField(
                            icon: "lock.fill",
                            placeholder: "Password",
                            text: $viewModel.password,
                            isSecure: !viewModel.showPassword,
                            showPassword: $viewModel.showPassword,
                            isValid: viewModel.password.isEmpty || Validators.isValidPassword(viewModel.password),
                            errorMessage: Validators.validatePassword(viewModel.password).errorMessage
                        )
                        
                        Button(action: {
                            showAlert = true
                        }) {
                            Text("Forgot Password?")
                                .font(.system(size: 14, weight: .semibold))
                                .foregroundColor(.brandPrimary)
                        }
                        .frame(maxWidth: .infinity, alignment: .trailing)
                        
                        Button(action: {
                            Task {
                                await viewModel.login()
                            }
                        }) {
                            if viewModel.isLoading {
                                ProgressView()
                                    .progressViewStyle(CircularProgressViewStyle(tint: .white))
                            } else {
                                HStack(spacing: 8) {
                                    Text("Sign In")
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
                                colors: [Color.brandPrimary, Color.brandSecondary],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .cornerRadius(16)
                        .shadow(color: Color.brandPrimary.opacity(0.4), radius: 12, x: 0, y: 6)
                        .disabled(viewModel.isLoading || !viewModel.isFormValid)
                        
                        HStack(spacing: 6) {
                            Text("Don't have an account?")
                                .font(.system(size: 15, weight: .medium))
                                .foregroundColor(.secondary)
                            NavigationLink("Sign Up") {
                                RegisterView()
                            }
                            .font(.system(size: 15, weight: .bold))
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
        .alert("Password Reset", isPresented: $showAlert) {
            Button("OK", role: .cancel) { }
        } message: {
            Text("Password reset link sent to your email")
        }
        .alert("Error", isPresented: .constant(viewModel.errorMessage != nil)) {
            Button("OK", role: .cancel) {
                viewModel.clearError()
            }
        } message: {
            if let errorMessage = viewModel.errorMessage {
                Text(errorMessage)
            }
        }
    }
}
