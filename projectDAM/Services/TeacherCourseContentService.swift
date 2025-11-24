//
//  TeacherCourseContentService.swift
//  projectDAM
//
//  Created on 11/24/2025.
//

import Foundation

protocol TeacherCourseContentServiceProtocol {
    func fetchLessonContent(courseId: String, access: TeacherCourseContentAccess) async throws -> TeacherCourseLessonContent
    func cachedContent(courseId: String, access: TeacherCourseContentAccess) -> TeacherCourseLessonContent?
}

final class TeacherCourseContentService: TeacherCourseContentServiceProtocol {
    private let networkService: NetworkServiceProtocol
    private let authService: AuthServiceProtocol
    private let cache: TeacherCourseContentCaching
    
    init(networkService: NetworkServiceProtocol, authService: AuthServiceProtocol, cache: TeacherCourseContentCaching) {
        self.networkService = networkService
        self.authService = authService
        self.cache = cache
    }
    
    func fetchLessonContent(courseId: String, access: TeacherCourseContentAccess) async throws -> TeacherCourseLessonContent {
        guard let token = authService.getAuthToken() else {
            throw NetworkError.unauthorized
        }
        let userId = authService.getCurrentUser()?.id
        if access.requiresOwnership && userId == nil {
            throw NetworkError.unauthorized
        }
        let encodedCourseId = courseId.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? courseId
        var endpoint = "/course-content/\(access.endpointSegment)/course-id?courseId=\(encodedCourseId)"
        if access.requiresOwnership, let userId {
            let encodedUserId = userId.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? userId
            endpoint += "&userId=\(encodedUserId)"
        }
        let response: TeacherCourseContentResponse = try await networkService.request(
            endpoint: endpoint,
            method: .GET,
            body: nil,
            headers: ["Authorization": "Bearer \(token)"]
        )
        guard response.success ?? true else {
            throw NetworkError.serverError(422, response.message ?? "Unable to load course lessons")
        }
        guard let content = response.courseContent?.content else {
            throw NetworkError.serverError(404, "Course content not found")
        }
        cache.store(content, courseId: courseId, access: access)
        return content
    }
    
    func cachedContent(courseId: String, access: TeacherCourseContentAccess) -> TeacherCourseLessonContent? {
        cache.cached(courseId: courseId, access: access)
    }
}

struct MockTeacherCourseContentService: TeacherCourseContentServiceProtocol {
    var stubContent: TeacherCourseLessonContent
    
    init() {
        stubContent = TeacherCourseLessonContent(
            contentBlocks: [
                TeacherLessonContentBlock(
                    type: .title,
                    text: "Prototype Lesson",
                    beforeText: nil,
                    afterText: nil,
                    image: nil,
                    pdf: nil,
                    pdfLabel: nil,
                    url: nil,
                    checklistItems: nil,
                    language: nil,
                    filename: nil,
                    helperText: nil,
                    accent: nil
                ),
                TeacherLessonContentBlock(
                    type: .paragraph,
                    text: "Use the Add Lesson button to append more content blocks.",
                    beforeText: nil,
                    afterText: nil,
                    image: nil,
                    pdf: nil,
                    pdfLabel: nil,
                    url: nil,
                    checklistItems: nil,
                    language: nil,
                    filename: nil,
                    helperText: nil,
                    accent: nil
                )
            ],
            courseType: "private",
            lastUpdatedBy: "",
            lastUpdatedAt: nil,
            courseSummary: ""
        )
    }
    
    func fetchLessonContent(courseId: String, access: TeacherCourseContentAccess) async throws -> TeacherCourseLessonContent {
        try await Task.sleep(nanoseconds: 200_000_000)
        return stubContent
    }

    func cachedContent(courseId: String, access: TeacherCourseContentAccess) -> TeacherCourseLessonContent? {
        stubContent
    }
}

private struct TeacherCourseContentResponse: Decodable {
    let courseContent: TeacherCourseContentEnvelope?
    let success: Bool?
    let message: String?
}

private struct TeacherCourseContentEnvelope: Decodable {
    let content: TeacherCourseLessonContent?
}

