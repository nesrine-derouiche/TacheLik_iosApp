import Foundation

// MARK: - Profile Service Protocol
protocol ProfileServiceProtocol {
    func fetchTeacherProfile(userId: String) async throws -> TeacherProfile?
    func updateProfile(userId: String, request: EditProfileRequest) async throws -> UserUpdateResponse
    func updateTeacherProfile(userId: String, request: EditProfileRequest) async throws -> TeacherUpdateResponse
}

// MARK: - Profile Service Implementation
final class ProfileService: ProfileServiceProtocol {
    private let networkService: NetworkServiceProtocol
    private let authService: AuthServiceProtocol
    
    init(networkService: NetworkServiceProtocol, authService: AuthServiceProtocol) {
        self.networkService = networkService
        self.authService = authService
    }
    
    func fetchTeacherProfile(userId: String) async throws -> TeacherProfile? {
        let response: TeacherProfileResponse = try await networkService.request(
            endpoint: "/teacher/id?id=\(userId)",
            method: .GET,
            body: nil,
            headers: authHeaders()
        )
        return response.teacher
    }
    
    func updateProfile(userId: String, request: EditProfileRequest) async throws -> UserUpdateResponse {
        var multipart = MultipartFormData()
        
        // Only send username and image for user update
        if let username = request.username {
            let trimmed = username.trimmingCharacters(in: .whitespacesAndNewlines)
            multipart.addField(name: "username", value: trimmed)
        }

        if let imageData = request.profileImageData {
            multipart.addFile(
                fieldName: "image",
                fileName: request.imageFileName ?? "profile.jpg",
                mimeType: request.imageMimeType ?? "image/jpeg",
                data: imageData
            )
        }

        return try await networkService.upload(
            endpoint: "/user/update-user/\(userId)",
            method: .PUT,
            multipart: multipart,
            headers: authHeaders()
        )
    }
    
    func updateTeacherProfile(userId: String, request: EditProfileRequest) async throws -> TeacherUpdateResponse {
        var multipart = MultipartFormData()
        
        func addField(_ name: String, value: String?) {
            let trimmed = value?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
            multipart.addField(name: name, value: trimmed)
        }
        
        addField("first_name", value: request.firstName)
        addField("last_name", value: request.lastName)
        addField("bio", value: request.bio)
        addField("github", value: request.github)
        addField("linkedin", value: request.linkedin)
        addField("facebook", value: request.facebook)
        
        if let imageData = request.profileImageData {
            multipart.addFile(
                fieldName: "image",
                fileName: request.imageFileName ?? "profile.jpg",
                mimeType: request.imageMimeType ?? "image/jpeg",
                data: imageData
            )
        }
        
        return try await networkService.upload(
            endpoint: "/teacher/update-teacher/\(userId)",
            method: .PUT,
            multipart: multipart,
            headers: authHeaders()
        )
    }
    
    private func authHeaders() -> [String: String]? {
        guard let token = authService.getAuthToken() else { return nil }
        return ["Authorization": "Bearer \(token)"]
    }
}

// MARK: - Request Models
struct EditProfileRequest {
    let username: String?
    let bio: String?
    let firstName: String?
    let lastName: String?
    let linkedin: String?
    let facebook: String?
    let github: String?
    let profileImageData: Data?
    let imageFileName: String?
    let imageMimeType: String?
}

// MARK: - Response Models
struct UserUpdateResponse: Decodable {
    let user: UpdatedUser
    let success: Bool?
    let message: String?
}

struct UpdatedUser: Decodable {
    let image: String?
    let phone: String?
    let phoneNbVerified: Bool?
    let username: String?
    
    enum CodingKeys: String, CodingKey {
        case image, phone, username
        case phoneNbVerified = "phone_nb_verified"
    }
}

struct TeacherUpdateResponse: Decodable {
    let teacher: UpdatedTeacher?
    let success: Bool?
    let message: String?
}

struct UpdatedTeacher: Decodable {
    let firstName: String?
    let lastName: String?
    let bio: String?
    let github: String?
    let linkedin: String?
    let facebook: String?
    let image: String?
    let phone: String?
    
    enum CodingKeys: String, CodingKey {
        case bio, github, linkedin, facebook, image, phone
        case firstName = "first_name"
        case lastName = "last_name"
    }
}

struct TeacherProfileResponse: Decodable {
    let teacher: TeacherProfile?
    let success: Bool?
}

struct TeacherProfile: Decodable {
    let id: String?
    let firstName: String?
    let lastName: String?
    let image: String?
    let bio: String?
    let github: String?
    let linkedin: String?
    let facebook: String?
    
    enum CodingKeys: String, CodingKey {
        case id, image, bio, github, linkedin, facebook
        case firstName = "first_name"
        case lastName = "last_name"
    }
}
