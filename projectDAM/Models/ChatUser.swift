import Foundation

struct ChatUser: Codable, Equatable {
    let id: String
    let username: String?
    let firstName: String?
    let lastName: String?
    let isTeacher: Bool?
    let image: String? // Base64 string
    
    enum CodingKeys: String, CodingKey {
        case id
        case username
        case firstName = "first_name"
        case lastName = "last_name"
        case isTeacher = "is_teacher"
        case image
    }
    
    var displayName: String {
        if isTeacher == true, let first = firstName, let last = lastName {
            return "\(first) \(last)"
        }
        return username ?? "User"
    }
}
