import SwiftUI

struct CustomTextField: View {
    let icon: String
    let placeholder: String
    @Binding var text: String
    let isSecure: Bool
    @Binding var showPassword: Bool
    var isValid: Bool = true
    var errorMessage: String? = nil
    @FocusState private var isFocused: Bool
    
    init(icon: String, placeholder: String, text: Binding<String>, isSecure: Bool, showPassword: Binding<Bool> = .constant(false), isValid: Bool = true, errorMessage: String? = nil) {
        self.icon = icon
        self.placeholder = placeholder
        self._text = text
        self.isSecure = isSecure
        self._showPassword = showPassword
        self.isValid = isValid
        self.errorMessage = errorMessage
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack(spacing: 12) {
                Image(systemName: icon)
                    .font(.system(size: 18, weight: .medium))
                    .foregroundColor(iconColor)
                    .frame(width: 24)
                
                Group {
                    if isSecure && !showPassword {
                        SecureField(placeholder, text: $text)
                            .focused($isFocused)
                    } else {
                        TextField(placeholder, text: $text)
                            .autocapitalization(.none)
                            .focused($isFocused)
                    }
                }
                .font(.system(size: 16, weight: .regular))
                
                if isSecure {
                    Button(action: { showPassword.toggle() }) {
                        Image(systemName: showPassword ? "eye.slash.fill" : "eye.fill")
                            .font(.system(size: 16, weight: .medium))
                            .foregroundColor(.secondary)
                    }
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 14)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(showError ? Color.red.opacity(0.05) : Color(.secondarySystemBackground))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(borderColor, lineWidth: 2)
            )
            .animation(.spring(response: 0.3, dampingFraction: 0.7), value: isFocused)
            .animation(.spring(response: 0.3, dampingFraction: 0.7), value: isValid)
            
            if showError, let errorMessage = errorMessage {
                Text(errorMessage)
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(.red)
                    .padding(.horizontal, 16)
                    .transition(.opacity)
            }
        }
    }
    
    private var showError: Bool {
        !text.isEmpty && !isValid
    }
    
    private var iconColor: Color {
        if showError {
            return .red
        } else if isFocused {
            return .brandPrimary
        } else {
            return .secondary
        }
    }
    
    private var borderColor: Color {
        if showError {
            return .red
        } else if isFocused {
            return .brandPrimary
        } else {
            return .clear
        }
    }
}
