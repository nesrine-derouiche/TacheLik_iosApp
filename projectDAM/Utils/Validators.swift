//
//  Validators.swift
//  projectDAM
//
//  Created on 11/8/2025.
//

import Foundation

// MARK: - Validation Configuration
struct ValidationConfig {
    // MARK: - Email Configuration
    /// Allowed email domain suffixes
    /// Edit this list to add or remove allowed email domains
    static let allowedEmailDomains = [
        "esprit.tn",
        "esprim.tn"
    ]
    
    // MARK: - Password Configuration
    static let passwordMinLength = 8
    static let passwordRequiresNumber = true
    static let passwordRequiresLetter = true
    
    // Optional for stronger passwords
    static let passwordRequiresUppercase = false  // Set to true to require
    static let passwordRequiresSpecialChar = false  // Set to true to require
    
    // MARK: - Username Configuration
    static let usernameMaxLength = 15
    static let usernameAllowedPattern = "^[a-zA-Z0-9_]+$"  // Letters, numbers, underscore only
}

// MARK: - Validation Results
enum ValidationResult {
    case valid
    case invalid(String)
    
    var isValid: Bool {
        if case .valid = self {
            return true
        }
        return false
    }
    
    var errorMessage: String? {
        if case .invalid(let message) = self {
            return message
        }
        return nil
    }
}

// MARK: - Validators
struct Validators {
    
    // MARK: - Email Validation
    
    /// Validates email format and domain
    static func validateEmail(_ email: String) -> ValidationResult {
        // Check if empty
        guard !email.isEmpty else {
            return .invalid("Email is required")
        }
        
        // Trim whitespace
        let trimmedEmail = email.trimmingCharacters(in: .whitespacesAndNewlines)
        
        // Check basic email format
        let emailRegex = "[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,64}"
        let emailPredicate = NSPredicate(format: "SELF MATCHES %@", emailRegex)
        
        guard emailPredicate.evaluate(with: trimmedEmail) else {
            return .invalid("Invalid email format")
        }
        
        // Check if email ends with allowed domain
        let hasValidDomain = ValidationConfig.allowedEmailDomains.contains { domain in
            trimmedEmail.lowercased().hasSuffix("@\(domain)")
        }
        
        guard hasValidDomain else {
            let domainsString = ValidationConfig.allowedEmailDomains.map { domain in "@\(domain)" }.joined(separator: " or ")
            return .invalid("Email must end with \(domainsString)")
        }
        
        return .valid
    }
    
    /// Quick check if email is valid (for form validation)
    static func isValidEmail(_ email: String) -> Bool {
        return validateEmail(email).isValid
    }
    
    // MARK: - Password Validation
    
    /// Validates password strength
    static func validatePassword(_ password: String) -> ValidationResult {
        // Check if empty
        guard !password.isEmpty else {
            return .invalid("Password is required")
        }
        
        // Check minimum length
        guard password.count >= ValidationConfig.passwordMinLength else {
            return .invalid("Password must be at least \(ValidationConfig.passwordMinLength) characters")
        }
        
        // Check for at least one number
        if ValidationConfig.passwordRequiresNumber {
            let numberRegex = ".*[0-9]+.*"
            let numberPredicate = NSPredicate(format: "SELF MATCHES %@", numberRegex)
            guard numberPredicate.evaluate(with: password) else {
                return .invalid("Password must contain at least one number")
            }
        }
        
        // Check for at least one letter
        if ValidationConfig.passwordRequiresLetter {
            let letterRegex = ".*[A-Za-z]+.*"
            let letterPredicate = NSPredicate(format: "SELF MATCHES %@", letterRegex)
            guard letterPredicate.evaluate(with: password) else {
                return .invalid("Password must contain at least one letter")
            }
        }
        
        // Optional: Check for uppercase letter
        if ValidationConfig.passwordRequiresUppercase {
            let uppercaseRegex = ".*[A-Z]+.*"
            let uppercasePredicate = NSPredicate(format: "SELF MATCHES %@", uppercaseRegex)
            guard uppercasePredicate.evaluate(with: password) else {
                return .invalid("Password must contain at least one uppercase letter")
            }
        }
        
        // Optional: Check for special character
        if ValidationConfig.passwordRequiresSpecialChar {
            let specialCharRegex = ".*[!@#$%^&*()_+\\-=\\[\\]{};':\"\\\\|,.<>\\/?]+.*"
            let specialCharPredicate = NSPredicate(format: "SELF MATCHES %@", specialCharRegex)
            guard specialCharPredicate.evaluate(with: password) else {
                return .invalid("Password must contain at least one special character")
            }
        }
        
        return .valid
    }
    
    /// Quick check if password is valid (for form validation)
    static func isValidPassword(_ password: String) -> Bool {
        return validatePassword(password).isValid
    }
    
    /// Get password strength level (0-3)
    static func getPasswordStrength(_ password: String) -> Int {
        var strength = 0
        
        // Base requirements met
        if password.count >= ValidationConfig.passwordMinLength &&
           password.range(of: "[0-9]", options: .regularExpression) != nil &&
           password.range(of: "[A-Za-z]", options: .regularExpression) != nil {
            strength = 1  // Weak but valid
        }
        
        // Has uppercase
        if password.range(of: "[A-Z]", options: .regularExpression) != nil {
            strength = max(strength, 2)  // Medium
        }
        
        // Has special character
        if password.range(of: "[!@#$%^&*()_+\\-=\\[\\]{};':\"\\\\|,.<>\\/?]", options: .regularExpression) != nil {
            strength = 3  // Strong
        }
        
        return strength
    }
    
    /// Get password strength description
    static func getPasswordStrengthDescription(_ password: String) -> String {
        let strength = getPasswordStrength(password)
        switch strength {
        case 0: return "Too weak"
        case 1: return "Weak"
        case 2: return "Medium"
        case 3: return "Strong"
        default: return ""
        }
    }
    
    // MARK: - Username Validation
    
    /// Validates username format and length
    static func validateUsername(_ username: String) -> ValidationResult {
        // Check if empty
        guard !username.isEmpty else {
            return .invalid("Username is required")
        }
        
        // Trim whitespace
        let trimmedUsername = username.trimmingCharacters(in: .whitespacesAndNewlines)
        
        // Check maximum length
        guard trimmedUsername.count <= ValidationConfig.usernameMaxLength else {
            return .invalid("Username must be \(ValidationConfig.usernameMaxLength) characters or less")
        }
        
        // Check allowed characters (letters, numbers, underscore only)
        let usernamePredicate = NSPredicate(format: "SELF MATCHES %@", ValidationConfig.usernameAllowedPattern)
        guard usernamePredicate.evaluate(with: trimmedUsername) else {
            return .invalid("Username can only contain letters, numbers, and underscores")
        }
        
        return .valid
    }
    
    /// Quick check if username is valid (for form validation)
    static func isValidUsername(_ username: String) -> Bool {
        return validateUsername(username).isValid
    }
    
    // MARK: - Name Validation
    
    /// Validates that the name contains only letters and spaces
    static func validateName(_ name: String) -> ValidationResult {
        let trimmed = name.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else {
            return .invalid("This field is required")
        }
        let regex = "^[A-Za-zÀ-ÖØ-öø-ÿ\\s'-]{2,}$"
        let predicate = NSPredicate(format: "SELF MATCHES %@", regex)
        guard predicate.evaluate(with: trimmed) else {
            return .invalid("Use letters and spaces only")
        }
        return .valid
    }
    
    /// Quick check if name is valid
    static func isValidName(_ name: String) -> Bool {
        return validateName(name).isValid
    }
    
    // MARK: - Social Links Validation
    
    enum SocialPlatform {
        case github
        case linkedin
        case facebook
        case twitter
    }
    
    /// Validates that a social link matches the expected platform format. Empty strings are allowed.
    static func validateSocialLink(_ link: String, type: SocialPlatform) -> ValidationResult {
        let trimmed = link.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return .valid }
        
        let regex: String
        switch type {
        case .github:
            regex = "^https://github.com/[A-Za-z0-9-]+/?$"
        case .linkedin:
            regex = "^https://www.linkedin.com/in/[A-Za-z0-9-_%]+/?$"
        case .facebook:
            regex = "^https://www.facebook.com/[A-Za-z0-9.]+/?$"
        case .twitter:
            regex = "^https://(www\\.)?twitter.com/[A-Za-z0-9_]+/?$"
        }
        let predicate = NSPredicate(format: "SELF MATCHES %@", regex)
        guard predicate.evaluate(with: trimmed) else {
            return .invalid("Invalid URL format")
        }
        return .valid
    }
    
    // MARK: - Helper Methods
    
    /// Get all password requirements as a list
    static func getPasswordRequirements() -> [String] {
        var requirements: [String] = []
        
        requirements.append("At least \(ValidationConfig.passwordMinLength) characters")
        
        if ValidationConfig.passwordRequiresNumber {
            requirements.append("At least one number")
        }
        
        if ValidationConfig.passwordRequiresLetter {
            requirements.append("At least one letter")
        }
        
        if ValidationConfig.passwordRequiresUppercase {
            requirements.append("At least one uppercase letter")
        }
        
        if ValidationConfig.passwordRequiresSpecialChar {
            requirements.append("At least one special character (!@#$%^&*)")
        }
        
        return requirements
    }
    
    /// Get optional password improvements
    static func getPasswordImprovements() -> [String] {
        var improvements: [String] = []
        
        if !ValidationConfig.passwordRequiresUppercase {
            improvements.append("Add uppercase letter for stronger password")
        }
        
        if !ValidationConfig.passwordRequiresSpecialChar {
            improvements.append("Add special character for stronger password")
        }
        
        return improvements
    }
}
