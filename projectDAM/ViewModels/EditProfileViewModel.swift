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
    @Published var about: String
    @Published var firstName: String
    @Published var lastName: String
    @Published var github: String
    @Published var linkedin: String
    @Published var facebook: String
    @Published var twitter: String
    @Published var website: String
    @Published var youtube: String
    @Published var selectedImageData: Data?
    @Published var selectedImageMimeType: String?
    @Published var selectedImageFileName: String?
    @Published var isLoadingTeacherData: Bool = false
    @Published var isSaving: Bool = false
    @Published var alert: EditProfileAlert?
    
    // MARK: - Immutable Properties
    let email: String
    let role: User.UserRole
    let userId: String
    let isTeacher: Bool
    let creationDate: String?
    let existingImageURL: String?
    
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
        self.about = ""
        self.firstName = ""
        self.lastName = ""
        self.github = ""
        self.linkedin = ""
        self.facebook = ""
        self.twitter = ""
        self.website = ""
        self.youtube = ""
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
    
    var twitterValidation: ValidationResult {
        Validators.validateSocialLink(twitter, type: .twitter)
    }
    
    var canSave: Bool {
        usernameValidation.isValid &&
        firstNameValidation.isValid &&
        lastNameValidation.isValid &&
        githubValidation.isValid &&
        linkedinValidation.isValid &&
        facebookValidation.isValid &&
        twitterValidation.isValid &&
        !isSaving
    }
    
    var formattedCreationDate: String? {
        guard let creationDate else { return nil }
        let isoFormatter = ISO8601DateFormatter()
        if let date = isoFormatter.date(from: creationDate) {
            let formatter = DateFormatter()
            formatter.dateStyle = .long
            formatter.timeStyle = .none
            return formatter.string(from: date)
        }
        return creationDate
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
            }
            if !isTeacher {
                firstName = ""
                lastName = ""
                bio = ""
                github = ""
                linkedin = ""
                facebook = ""
                twitter = ""
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
    
    func saveChanges() async {
        guard canSave else {
            presentFirstValidationError()
            return
        }
        
        isSaving = true
        defer { isSaving = false }
        
        do {
            let request = buildRequest()
            let userResponse = try await profileService.updateProfile(userId: userId, request: request)
            guard userResponse.success == true else {
                throw EditProfileFlowError.backend(userResponse.message ?? "Failed to update profile.")
            }
            if isTeacher {
                let teacherResponse = try await profileService.updateTeacherProfile(userId: userId, request: request)
                guard teacherResponse.success == true else {
                    throw EditProfileFlowError.backend(teacherResponse.message ?? "Failed to update teacher information.")
                }
            }
            try await authService.refreshUserData()
            if let refreshedUser = authService.getCurrentUser() {
                username = refreshedUser.username
            }
            if isTeacher {
                await loadTeacherProfileIfNeeded()
            }
            alert = EditProfileAlert(
                title: "Profile Updated",
                message: "Your profile information has been saved successfully."
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
    private func buildRequest() -> EditProfileRequest {
        EditProfileRequest(
            username: username.trimmingCharacters(in: .whitespacesAndNewlines),
            about: about,
            bio: bio,
            firstName: isTeacher ? firstName.trimmingCharacters(in: .whitespacesAndNewlines) : nil,
            lastName: isTeacher ? lastName.trimmingCharacters(in: .whitespacesAndNewlines) : nil,
            linkedin: linkedin,
            facebook: facebook,
            twitter: twitter,
            github: github,
            website: website,
            youtube: youtube,
            profileImageData: selectedImageData,
            imageFileName: selectedImageFileName,
            imageMimeType: selectedImageMimeType
        )
    }
    
    private func presentFirstValidationError() {
        if !usernameValidation.isValid {
            alert = EditProfileAlert(title: "Invalid Username", message: usernameValidation.errorMessage ?? "Please provide a valid username.")
            return
        }
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
            return
        }
        if !twitterValidation.isValid {
            alert = EditProfileAlert(title: "Invalid Twitter Link", message: twitterValidation.errorMessage ?? "Please provide a valid Twitter link.")
        }
    }
}
