import Foundation
import SwiftUI
import Combine

// MARK: - Edit Profile Alert
struct EditProfileAlert: Identifiable {
    let id = UUID()
    let title: String
    let message: String
}

// MARK: - Errors
private enum EditProfileFlowError: LocalizedError {
    case backend(String)
    case unknown
    
    var errorDescription: String? {
        switch self {
        case .backend(let message):
            return message
        case .unknown:
            return "Something went wrong. Please try again."
        }
    }
}

// MARK: - Edit Profile View Model
@MainActor
final class EditProfileViewModel: ObservableObject {
    // MARK: - Published Properties
    @Published var username: String
    @Published var bio: String
    @Published var firstName: String
    @Published var lastName: String
    @Published var github: String
    @Published var linkedin: String
    @Published var facebook: String
    @Published var selectedImageData: Data?
    @Published var selectedImageMimeType: String?
    @Published var selectedImageFileName: String?
    @Published var selectedTeacherImageData: Data?
    @Published var selectedTeacherImageMimeType: String?
    @Published var selectedTeacherImageFileName: String?
    @Published var isLoadingTeacherData: Bool = false
    @Published var isSavingPersonalInfo: Bool = false
    @Published var isSavingTeacherInfo: Bool = false
    @Published var alert: EditProfileAlert?
    
    // MARK: - Immutable Properties
    let email: String
    let role: User.UserRole
    let userId: String
    let isTeacher: Bool
    let creationDate: String?
    let existingImageURL: String?
    @Published var existingTeacherImageURL: String?
    
    // MARK: - Dependencies
    private let profileService: ProfileServiceProtocol
    private let authService: AuthServiceProtocol
    
    // MARK: - Initialization
    init(user: User, profileService: ProfileServiceProtocol, authService: AuthServiceProtocol) {
        self.userId = user.id
        self.email = user.email
        self.role = user.role
        self.isTeacher = user.isTeacher ?? false
        self.creationDate = user.creationDate
        self.existingImageURL = user.image
        self.profileService = profileService
        self.authService = authService
        
        self.username = user.username
        self.bio = ""
        self.firstName = ""
        self.lastName = ""
        self.github = ""
        self.linkedin = ""
        self.facebook = ""
    }
    
    // MARK: - Computed Validation States
    var usernameValidation: ValidationResult {
        Validators.validateUsername(username)
    }
    
    var firstNameValidation: ValidationResult {
        guard isTeacher else { return .valid }
        return Validators.validateName(firstName)
    }
    
    var lastNameValidation: ValidationResult {
        guard isTeacher else { return .valid }
        return Validators.validateName(lastName)
    }
    
    var githubValidation: ValidationResult {
        Validators.validateSocialLink(github, type: .github)
    }
    
    var linkedinValidation: ValidationResult {
        Validators.validateSocialLink(linkedin, type: .linkedin)
    }
    
    var facebookValidation: ValidationResult {
        Validators.validateSocialLink(facebook, type: .facebook)
    }
    
    var canSavePersonalInfo: Bool {
        usernameValidation.isValid && !isSavingPersonalInfo
    }
    
    var canSaveTeacherInfo: Bool {
        firstNameValidation.isValid &&
        lastNameValidation.isValid &&
        githubValidation.isValid &&
        linkedinValidation.isValid &&
        facebookValidation.isValid &&
        !isSavingTeacherInfo
    }
    
    var formattedCreationDate: String? {
        guard let raw = creationDate?.trimmingCharacters(in: .whitespacesAndNewlines),
              !raw.isEmpty
        else {
            return nil
        }

        guard let date = Self.parseISO8601Date(raw) else {
            return nil
        }

        return Self.formatCreationDate(date)
    }

    private static func parseISO8601Date(_ value: String) -> Date? {
        // Handles common backend formats like:
        // - 2025-10-19T14:32:59Z
        // - 2025-10-19T14:32:59.000Z
        // - 2025-10-19T14:32:59+01:00
        // - 2025-10-19T14:32:59.000+01:00

        let fractional = ISO8601DateFormatter()
        fractional.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        if let date = fractional.date(from: value) {
            return date
        }

        let nonFractional = ISO8601DateFormatter()
        nonFractional.formatOptions = [.withInternetDateTime]
        return nonFractional.date(from: value)
    }

    private static func formatCreationDate(_ date: Date) -> String {
        let dateFormatter = DateFormatter()
        dateFormatter.locale = .autoupdatingCurrent
        dateFormatter.timeZone = .autoupdatingCurrent
        dateFormatter.dateStyle = .medium
        dateFormatter.timeStyle = .none

        let timeFormatter = DateFormatter()
        timeFormatter.locale = .autoupdatingCurrent
        timeFormatter.timeZone = .autoupdatingCurrent
        timeFormatter.dateStyle = .none
        timeFormatter.timeStyle = .short

        return "\(dateFormatter.string(from: date)) • \(timeFormatter.string(from: date))"
    }
    
    // MARK: - Public Methods
    func loadTeacherProfileIfNeeded() async {
        guard isTeacher else { return }
        isLoadingTeacherData = true
        defer { isLoadingTeacherData = false }
        
        do {
            if let profile = try await profileService.fetchTeacherProfile(userId: userId) {
                firstName = profile.firstName ?? firstName
                lastName = profile.lastName ?? lastName
                bio = profile.bio ?? bio
                github = profile.github ?? github
                linkedin = profile.linkedin ?? linkedin
                facebook = profile.facebook ?? facebook
                existingTeacherImageURL = profile.image
            }
            if !isTeacher {
                firstName = ""
                lastName = ""
                bio = ""
                github = ""
                linkedin = ""
                facebook = ""
            }
        } catch let error as NetworkError {
            switch error {
            case .serverError(let code, _) where code == 404:
                // Teacher profile not found is acceptable for new teachers
                break
            default:
                alert = EditProfileAlert(
                    title: "Unable to Load Teacher Info",
                    message: error.localizedDescription
                )
            }
        } catch {
            alert = EditProfileAlert(
                title: "Unable to Load Teacher Info",
                message: error.localizedDescription
            )
        }
    }
    
    func setSelectedImage(data: Data, fileName: String?, mimeType: String?) {
        selectedImageData = data
        selectedImageFileName = fileName
        selectedImageMimeType = mimeType
    }
    
    func setSelectedTeacherImage(data: Data, fileName: String?, mimeType: String?) {
        selectedTeacherImageData = data
        selectedTeacherImageFileName = fileName
        selectedTeacherImageMimeType = mimeType
    }
    
    func savePersonalInfo() async {
        guard canSavePersonalInfo else {
            if !usernameValidation.isValid {
                alert = EditProfileAlert(title: "Invalid Username", message: usernameValidation.errorMessage ?? "Please provide a valid username.")
            }
            return
        }
        
        isSavingPersonalInfo = true
        defer { isSavingPersonalInfo = false }
        
        do {
            let request = buildPersonalInfoRequest()
            let userResponse = try await profileService.updateProfile(userId: userId, request: request)
            guard userResponse.success == true else {
                throw EditProfileFlowError.backend(userResponse.message ?? "Failed to update profile.")
            }
            try await authService.refreshUserData()
            if let refreshedUser = authService.getCurrentUser() {
                username = refreshedUser.username
            }
            alert = EditProfileAlert(
                title: "Profile Updated",
                message: "Your personal information has been saved successfully."
            )
        } catch let error as NetworkError {
            alert = EditProfileAlert(
                title: "Update Failed",
                message: error.errorDescription ?? "Network error"
            )
        } catch let error as EditProfileFlowError {
            alert = EditProfileAlert(
                title: "Update Failed",
                message: error.errorDescription ?? "Unknown error"
            )
        } catch {
            alert = EditProfileAlert(
                title: "Update Failed",
                message: error.localizedDescription
            )
        }
    }
    
    func saveTeacherInfo() async {
        guard isTeacher else { return }
        guard canSaveTeacherInfo else {
            presentTeacherValidationError()
            return
        }
        
        isSavingTeacherInfo = true
        defer { isSavingTeacherInfo = false }
        
        do {
            let request = buildTeacherInfoRequest()
            let teacherResponse = try await profileService.updateTeacherProfile(userId: userId, request: request)
            guard teacherResponse.success == true else {
                throw EditProfileFlowError.backend(teacherResponse.message ?? "Failed to update teacher information.")
            }
            await loadTeacherProfileIfNeeded()
            alert = EditProfileAlert(
                title: "Teacher Info Updated",
                message: "Your teacher information has been saved successfully."
            )
        } catch let error as NetworkError {
            alert = EditProfileAlert(
                title: "Update Failed",
                message: error.errorDescription ?? "Network error"
            )
        } catch let error as EditProfileFlowError {
            alert = EditProfileAlert(
                title: "Update Failed",
                message: error.errorDescription ?? "Unknown error"
            )
        } catch {
            alert = EditProfileAlert(
                title: "Update Failed",
                message: error.localizedDescription
            )
        }
    }
    
    // MARK: - Private Helpers
    private func buildPersonalInfoRequest() -> EditProfileRequest {
        EditProfileRequest(
            username: username.trimmingCharacters(in: .whitespacesAndNewlines),
            bio: nil,
            firstName: nil,
            lastName: nil,
            linkedin: nil,
            facebook: nil,
            github: nil,
            profileImageData: selectedImageData,
            imageFileName: selectedImageFileName,
            imageMimeType: selectedImageMimeType
        )
    }
    
    private func buildTeacherInfoRequest() -> EditProfileRequest {
        EditProfileRequest(
            username: nil,
            bio: bio,
            firstName: firstName.trimmingCharacters(in: .whitespacesAndNewlines),
            lastName: lastName.trimmingCharacters(in: .whitespacesAndNewlines),
            linkedin: linkedin,
            facebook: facebook,
            github: github,
            profileImageData: selectedTeacherImageData,
            imageFileName: selectedTeacherImageFileName,
            imageMimeType: selectedTeacherImageMimeType
        )
    }
    
    private func presentTeacherValidationError() {
        if !firstNameValidation.isValid {
            alert = EditProfileAlert(title: "Invalid First Name", message: firstNameValidation.errorMessage ?? "Please provide a valid first name.")
            return
        }
        if !lastNameValidation.isValid {
            alert = EditProfileAlert(title: "Invalid Last Name", message: lastNameValidation.errorMessage ?? "Please provide a valid last name.")
            return
        }
        if !githubValidation.isValid {
            alert = EditProfileAlert(title: "Invalid GitHub Link", message: githubValidation.errorMessage ?? "Please provide a valid GitHub link.")
            return
        }
        if !linkedinValidation.isValid {
            alert = EditProfileAlert(title: "Invalid LinkedIn Link", message: linkedinValidation.errorMessage ?? "Please provide a valid LinkedIn link.")
            return
        }
        if !facebookValidation.isValid {
            alert = EditProfileAlert(title: "Invalid Facebook Link", message: facebookValidation.errorMessage ?? "Please provide a valid Facebook link.")
        }
    }
}
