//
//  TeacherCourseContentCache.swift
//  projectDAM
//
//  Created on 11/24/2025.
//

import Foundation

protocol TeacherCourseContentCaching {
    func store(_ content: TeacherCourseLessonContent, courseId: String, access: TeacherCourseContentAccess)
    func cached(courseId: String, access: TeacherCourseContentAccess) -> TeacherCourseLessonContent?
}

/// Simple disk cache for course content payloads to support offline usage
final class TeacherCourseContentCache: TeacherCourseContentCaching {
    static let shared = TeacherCourseContentCache()
    
    private let fileManager = FileManager.default
    private let rootURL: URL
    private let encoder = JSONEncoder()
    private let decoder = JSONDecoder()
    private let queue = DispatchQueue(label: "tn.tachelik.teacher-course-content-cache", qos: .utility)
    
    private init() {
        let caches = fileManager.urls(for: .cachesDirectory, in: .userDomainMask).first ?? URL(fileURLWithPath: NSTemporaryDirectory())
        rootURL = caches.appendingPathComponent("teacher-course-content", isDirectory: true)
        if !fileManager.fileExists(atPath: rootURL.path) {
            try? fileManager.createDirectory(at: rootURL, withIntermediateDirectories: true)
        }
    }
    
    func store(_ content: TeacherCourseLessonContent, courseId: String, access: TeacherCourseContentAccess) {
        queue.async {
            do {
                let data = try self.encoder.encode(content)
                try data.write(to: self.fileURL(courseId: courseId, access: access), options: .atomic)
            } catch {
                print("⚠️ [TeacherCourseContentCache] Failed to persist content for course \(courseId): \(error)")
            }
        }
    }
    
    func cached(courseId: String, access: TeacherCourseContentAccess) -> TeacherCourseLessonContent? {
        var result: TeacherCourseLessonContent?
        queue.sync {
            let url = fileURL(courseId: courseId, access: access)
            guard fileManager.fileExists(atPath: url.path) else { return }
            guard let data = try? Data(contentsOf: url) else { return }
            result = try? decoder.decode(TeacherCourseLessonContent.self, from: data)
        }
        return result
    }
    
    private func fileURL(courseId: String, access: TeacherCourseContentAccess) -> URL {
        let sanitized = courseId.replacingOccurrences(of: "/", with: "_")
        return rootURL.appendingPathComponent("\(sanitized)-\(access.endpointSegment).json")
    }
}

extension TeacherCourseContentService {
    convenience init(networkService: NetworkServiceProtocol, authService: AuthServiceProtocol) {
        self.init(networkService: networkService, authService: authService, cache: TeacherCourseContentCache.shared)
    }
}
