//
//  LessonService.swift
//  projectDAM
//
//  Created on 11/15/2025.
//

import Foundation

// MARK: - Lesson Access Type
enum LessonAccessType: String {
    case publicCourse = "public"
    case privateCourse = "private"
    
    var pathComponent: String { rawValue }
    var requiresOwnership: Bool { self == .privateCourse }
}

// MARK: - Lesson Service Protocol
protocol LessonServiceProtocol {
    func fetchLesson(courseId: String, accessType: LessonAccessType) async throws -> Lesson
}

// MARK: - Lesson Service Error
enum LessonServiceError: LocalizedError {
    case authenticationRequired
    
    var errorDescription: String? {
        switch self {
        case .authenticationRequired:
            return "You must be logged in to access this lesson."
        }
    }
}

// MARK: - Lesson Service Implementation
final class LessonService: LessonServiceProtocol {
    private let networkService: NetworkServiceProtocol
    private let authService: AuthServiceProtocol
    private let courseService: CourseServiceProtocol
    
    init(
        networkService: NetworkServiceProtocol,
        authService: AuthServiceProtocol,
        courseService: CourseServiceProtocol
    ) {
        self.networkService = networkService
        self.authService = authService
        self.courseService = courseService
    }
    
    func fetchLesson(courseId: String, accessType: LessonAccessType) async throws -> Lesson {
        async let courseTask = courseService.fetchCourse(id: courseId)
        async let videosTask = fetchVideos(for: courseId)
        async let contentTask = fetchCourseContentIfAvailable(courseId: courseId, accessType: accessType)
        
        let course = try await courseTask
        let videos = try await videosTask
        let courseContent = await contentTask
        
        let teacher = makeTeacher(from: course)
        let description = extractLessonDescription(from: courseContent) ?? course.description
        
        return Lesson(
            id: course.id,
            title: course.name,
            description: description,
            teacher: teacher,
            videos: videos,
            courseId: course.id,
            createdDate: nil,
            updatedDate: nil
        )
    }
    
    // MARK: - Networking Helpers
    private func fetchVideos(for courseId: String) async throws -> [VideoContent] {
        let encodedCourseId = courseId.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? courseId
        let endpoint = "/video/course-id?courseId=\(encodedCourseId)"
        let response: VideosResponse = try await networkService.request(
            endpoint: endpoint,
            method: .GET,
            body: nil,
            headers: nil
        )
        
        var orderSeed = 0
        var contents: [VideoContent] = []
        for video in response.videos {
            contents.append(contentsOf: mapVideoContent(from: video, orderSeed: &orderSeed))
        }
        return contents
    }
    
    private func fetchCourseContentIfAvailable(courseId: String, accessType: LessonAccessType) async -> CourseContentData? {
        do {
            let encodedCourseId = courseId.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? courseId
            var endpoint = "/course-content/\(accessType.pathComponent)/course-id?courseId=\(encodedCourseId)"
            var headers: [String: String]? = nil
            
            if accessType.requiresOwnership {
                guard let token = authService.getAuthToken(), let userId = authService.getCurrentUser()?.id else {
                    throw LessonServiceError.authenticationRequired
                }
                let encodedUserId = userId.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? userId
                endpoint.append("&userId=\(encodedUserId)")
                headers = ["Authorization": "Bearer \(token)"]
            }
            
            let response: CourseContentResponse = try await networkService.request(
                endpoint: endpoint,
                method: .GET,
                body: nil,
                headers: headers
            )
            guard response.success ?? true else { return nil }
            return response.courseContent?.content
        } catch {
            if AppConfig.enableLogging {
                print("⚠️ [LessonService] Course content fetch failed: \(error)")
            }
            return nil
        }
    }
    
    // MARK: - Mapping Helpers
    private func mapVideoContent(from dto: VideoDTO, orderSeed: inout Int) -> [VideoContent] {
        var mapped: [VideoContent] = []
        orderSeed += 1
        mapped.append(VideoContent(
            id: dto.id,
            title: dto.title,
            duration: Int(dto.time ?? 0),
            videoUrl: dto.videoUID ?? "",
            thumbnailUrl: dto.thumbnailURL,
            description: dto.description,
            orderIndex: orderSeed
        ))
        
        if let subVideos = dto.subVideos {
            for sub in subVideos {
                orderSeed += 1
                mapped.append(VideoContent(
                    id: sub.id,
                    title: sub.title,
                    duration: Int(sub.time ?? 0),
                    videoUrl: sub.videoUID ?? "",
                    thumbnailUrl: nil,
                    description: sub.description,
                    orderIndex: orderSeed
                ))
            }
        }
        
        return mapped
    }
    
    private func makeTeacher(from course: Course) -> Teacher {
        Teacher(
            id: course.author.id,
            name: course.author.username,
            email: course.author.email,
            bio: nil,
            profileImage: course.author.image,
            socialLinks: nil
        )
    }
    
    private func extractLessonDescription(from content: CourseContentData?) -> String? {
        if let description = content?.descriptionText, !description.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            return description
        }
        guard let firstTextual = content?.contentList?.first(where: { isTextualType($0.type) && ($0.content?.isEmpty == false) }) else {
            return nil
        }
        return firstTextual.content
    }
    
    private func isTextualType(_ type: String?) -> Bool {
        guard let value = type?.lowercased() else { return false }
        return ["paragraph", "boxed-paragraph", "title", "subtitle"].contains(value)
    }
}

// MARK: - Mock Lesson Service (Preview/Test)
struct MockLessonService: LessonServiceProtocol {
    var lesson: Lesson = .sampleLesson
    func fetchLesson(courseId: String, accessType: LessonAccessType) async throws -> Lesson {
        try await Task.sleep(nanoseconds: 400_000_000)
        return lesson
    }
}

// MARK: - API Response Models
private struct VideosResponse: Decodable {
    let videos: [VideoDTO]
    let success: Bool
}

private struct VideoDTO: Decodable {
    let id: String
    let title: String
    let description: String?
    let time: Double?
    let videoUID: String?
    let videoOrder: Int
    let thumbnailURL: String?
    let subVideos: [SubVideoDTO]?
    
    enum CodingKeys: String, CodingKey {
        case id, title, description, time
        case videoUID = "video_uid"
        case videoOrder = "video_order"
        case thumbnailURL = "thumbnail_url"
        case subVideos = "sub_videos"
    }
}

private struct SubVideoDTO: Decodable {
    let id: String
    let title: String
    let description: String?
    let time: Double?
    let videoUID: String?
    let videoOrder: Int
    
    enum CodingKeys: String, CodingKey {
        case id, title, description, time
        case videoUID = "video_uid"
        case videoOrder = "video_order"
    }
}

private struct CourseContentResponse: Decodable {
    let courseContent: CourseContentDTO?
    let success: Bool?
    let message: String?
}

private struct CourseContentDTO: Decodable {
    let content: CourseContentData?
}

private struct CourseContentData: Decodable {
    let contentList: [CourseContentBlock]?
    let descriptionText: String?
    
    enum CodingKeys: String, CodingKey {
        case contentList
        case description
        case overview
        case summary
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        contentList = try container.decodeIfPresent([CourseContentBlock].self, forKey: .contentList)
        if let description = try container.decodeIfPresent(String.self, forKey: .description) {
            descriptionText = description
        } else if let overview = try container.decodeIfPresent(String.self, forKey: .overview) {
            descriptionText = overview
        } else if let summary = try container.decodeIfPresent(String.self, forKey: .summary) {
            descriptionText = summary
        } else {
            descriptionText = nil
        }
    }
}

private struct CourseContentBlock: Decodable {
    let type: String?
    let content: String?
}
