//
//  TeacherCourseLessonsViewModel.swift
//  projectDAM
//
//  Created on 11/24/2025.
//

import Foundation
import SwiftUI
import Combine

@MainActor
final class TeacherCourseLessonsViewModel: ObservableObject {
    // MARK: - Published State
    @Published private(set) var isLoading: Bool = false
    @Published private(set) var errorMessage: String?
    @Published private(set) var remoteBlocks: [TeacherLessonContentBlock] = []
    @Published private(set) var appendedBlocks: [TeacherLessonContentBlock] = []
    @Published private(set) var displayItems: [TeacherLessonRenderableItem] = []
    @Published private(set) var parserWarnings: [String] = []
    @Published private(set) var offlineFallbackUsed: Bool = false
    @Published var showAddLessonSheet: Bool = false
    @Published var addLessonForm = AddLessonForm()
    @Published private(set) var lastUpdatedLabel: String?
    
    // MARK: - Dependencies
    private let contentService: TeacherCourseContentServiceProtocol
    private let authService: AuthServiceProtocol
    private let urlSession: URLSession
    private let fileManager = FileManager.default
    private let parser = TeacherLessonContentParser()
    private let assetCacheDirectory: URL
    private var resolvedCourseTypeSlug: String?
    private var effectiveAccess: TeacherCourseContentAccess
    let course: TeacherCourse
    let classItem: TeacherClass
    
    // MARK: - Initialization
    init(
        course: TeacherCourse,
        classItem: TeacherClass,
        contentService: TeacherCourseContentServiceProtocol,
        authService: AuthServiceProtocol,
        urlSession: URLSession = .shared
    ) {
        self.course = course
        self.classItem = classItem
        self.contentService = contentService
        self.authService = authService
        self.urlSession = urlSession
        self.effectiveAccess = course.defaultLessonAccess
        let caches = fileManager.urls(for: .cachesDirectory, in: .userDomainMask).first ?? URL(fileURLWithPath: NSTemporaryDirectory())
        let directory = caches.appendingPathComponent("teacher-lesson-assets", isDirectory: true)
        if !fileManager.fileExists(atPath: directory.path) {
            try? fileManager.createDirectory(at: directory, withIntermediateDirectories: true)
        }
        self.assetCacheDirectory = directory
    }
    
    // MARK: - Derived State
    var displayedBlocks: [TeacherLessonContentBlock] { remoteBlocks + appendedBlocks }
    var displayedRenderableItems: [TeacherLessonRenderableItem] { displayItems }
    
    var courseTitle: String { course.name }
    var courseSubtitle: String { classItem.title }
    var studentCountLabel: String { "\(course.studentCount) enrolled" }
    
    // MARK: - Lifecycle
    func loadContent(force: Bool = false) async {
        guard !isLoading else { return }
        if !force, remoteBlocks.isEmpty == false { return }
        isLoading = true
        errorMessage = nil
        offlineFallbackUsed = false
        await fetchContent(access: effectiveAccess, allowFallback: true)
    }
    
    func refresh() async {
        remoteBlocks = []
        appendedBlocks = []
        resolvedCourseTypeSlug = nil
        await loadContent(force: true)
    }
    
    func submitDraftBlock() {
        guard let draftedBlock = addLessonForm.buildBlock() else {
            errorMessage = "Please fill in the highlighted fields before adding the lesson block."
            return
        }
        appendedBlocks.append(draftedBlock)
        rebuildRenderableItems()
        addLessonForm = AddLessonForm()
        showAddLessonSheet = false
    }
    
    func clearError() {
        errorMessage = nil
    }
    
    // MARK: - Helpers
    private func formatLastUpdated(from content: TeacherCourseLessonContent) -> String? {
        guard let stamp = content.lastUpdatedAt else { return nil }
        return "Updated " + stamp
    }

    private func fetchContent(access: TeacherCourseContentAccess, allowFallback: Bool) async {
        do {
            let content = try await contentService.fetchLessonContent(courseId: course.id, access: access)
            apply(content: content, access: access, fromCache: false)
        } catch {
            if allowFallback && shouldFallback(for: error) {
                let fallback: TeacherCourseContentAccess = access == .publicCourse ? .privateCourse : .publicCourse
                effectiveAccess = fallback
                await fetchContent(access: fallback, allowFallback: false)
                return
            }
            if let cached = contentService.cachedContent(courseId: course.id, access: access) {
                apply(content: cached, access: access, fromCache: true)
                errorMessage = error.localizedDescription
            } else {
                isLoading = false
                errorMessage = error.localizedDescription
            }
        }
    }
    
    private func apply(content: TeacherCourseLessonContent, access: TeacherCourseContentAccess, fromCache: Bool) {
        remoteBlocks = content.contentBlocks
        appendedBlocks = []
        lastUpdatedLabel = formatLastUpdated(from: content)
        resolvedCourseTypeSlug = (content.courseType?.trimmingCharacters(in: .whitespacesAndNewlines)).flatMap { $0.isEmpty ? nil : $0 } ?? access.blogSegment
        offlineFallbackUsed = fromCache
        isLoading = false
        rebuildRenderableItems()
    }
    
    private func rebuildRenderableItems() {
        let result = parser.parse(blocks: displayedBlocks)
        displayItems = result.items
        parserWarnings = result.warnings
    }
    
    func imageData(for reference: LessonMediaReference) async throws -> Data {
        if let cached = try? Data(contentsOf: cacheURL(for: reference, suggestedExtension: nil)) {
            return cached
        }
        let data = try await fetchAssetData(for: reference)
        try? data.write(to: cacheURL(for: reference, suggestedExtension: nil), options: .atomic)
        return data
    }
    
    func documentURL(for reference: LessonMediaReference, fileExtension: String?) async -> URL? {
        let url = cacheURL(for: reference, suggestedExtension: fileExtension)
        if fileManager.fileExists(atPath: url.path) {
            return url
        }
        do {
            let data = try await fetchAssetData(for: reference)
            try data.write(to: url, options: .atomic)
            return url
        } catch {
            errorMessage = error.localizedDescription
            return nil
        }
    }
    
    private func fetchAssetData(for reference: LessonMediaReference) async throws -> Data {
        guard let request = makeAssetRequest(for: reference) else {
            throw LessonAssetError.invalidRequest
        }
        let (data, response) = try await urlSession.data(for: request)
        guard let http = response as? HTTPURLResponse, 200..<300 ~= http.statusCode else {
            throw LessonAssetError.networkFailure
        }
        return data
    }
    
    private func makeAssetRequest(for reference: LessonMediaReference) -> URLRequest? {
        guard let url = assetURL(for: reference) else { return nil }
        var request = URLRequest(url: url)
        request.cachePolicy = .returnCacheDataElseLoad
        if let token = authService.getAuthToken() {
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }
        return request
    }
    
    private func assetURL(for reference: LessonMediaReference) -> URL? {
        var filename = reference.filename
        if reference.kind == .code && filename.hasSuffix(".code") == false {
            filename += ".code"
        }
        let encoded = filename.addingPercentEncoding(withAllowedCharacters: .urlPathAllowed) ?? filename
        let typeSlug = resolvedCourseTypeSlug ?? effectiveAccess.blogSegment
        var components = URLComponents(string: AppConfig.baseURL + "/blog/\(typeSlug)/\(encoded)")
        var items = [URLQueryItem(name: "courseId", value: course.id)]
        if effectiveAccess.requiresOwnership, let userId = authService.getCurrentUser()?.id {
            items.append(URLQueryItem(name: "userId", value: userId))
        }
        components?.queryItems = items
        return components?.url
    }
    
    private func cacheURL(for reference: LessonMediaReference, suggestedExtension: String?) -> URL {
        let safeName = reference.filename
            .replacingOccurrences(of: "/", with: "_")
            .replacingOccurrences(of: " ", with: "-")
        let prefix = "\(course.id)-\(reference.kind)"
        let base = assetCacheDirectory.appendingPathComponent("\(prefix)-\(safeName)")
        if let suggested = suggestedExtension, !suggested.isEmpty {
            return base.appendingPathExtension(suggested)
        }
        let existingExtension = (safeName as NSString).pathExtension
        return existingExtension.isEmpty ? base.appendingPathExtension("bin") : base
    }

    private func shouldFallback(for error: Error) -> Bool {
        guard let networkError = error as? NetworkError else { return false }
        if case let .serverError(_, message) = networkError {
            return message?.localizedCaseInsensitiveContains("wrong endpoint") == true
        }
        return false
    }
}

// MARK: - Add Lesson Form Model
struct AddLessonForm {
    var type: TeacherLessonContentType = .paragraph
    var title: String = ""
    var body: String = ""
    var secondaryText: String = ""
    var url: String = ""
    var filename: String = ""
    var language: String = ""
    var checklistRaw: String = ""
    
    var canSubmit: Bool {
        switch type {
        case .title, .subtitle, .paragraph, .boxedParagraph, .latex:
            return !body.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
        case .pdf:
            return !filename.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
        case .link:
            return !url.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty && !body.isEmpty
        case .checklist:
            return !checklistRaw.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
        case .code:
            return !filename.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || !body.isEmpty
        case .fullImage:
            return !filename.isEmpty
        case .divider, .unknown, .button, .simulation, .halfLeft, .halfRight:
            return true
        }
    }
    
    func buildBlock() -> TeacherLessonContentBlock? {
        guard canSubmit else { return nil }
        let trimmedBody = body.trimmingCharacters(in: .whitespacesAndNewlines)
        let trimmedSecondary = secondaryText.trimmingCharacters(in: .whitespacesAndNewlines)
        switch type {
        case .title, .subtitle, .paragraph, .boxedParagraph:
            return TeacherLessonContentBlock(type: type, text: trimmedBody)
        case .latex:
            let sanitized = trimmedBody.replacingOccurrences(of: "$", with: "").trimmingCharacters(in: .whitespacesAndNewlines)
            return TeacherLessonContentBlock(type: .latex, text: sanitized)
        case .pdf:
            return TeacherLessonContentBlock(type: .pdf, pdf: filename, pdfLabel: trimmedBody.isEmpty ? filename : trimmedBody)
        case .link:
            return TeacherLessonContentBlock(type: .link, text: trimmedBody, beforeText: trimmedSecondary, url: url)
        case .checklist:
            let items = checklistRaw
                .split(separator: "\n")
                .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
                .filter { !$0.isEmpty }
            return TeacherLessonContentBlock(type: .checklist, checklistItems: items)
        case .code:
            return TeacherLessonContentBlock(
                type: .code,
                text: trimmedBody,
                language: language,
                filename: filename
            )
        case .fullImage:
            return TeacherLessonContentBlock(type: .fullImage, image: filename, helperText: trimmedBody)
        case .divider:
            return TeacherLessonContentBlock(type: .divider)
        case .unknown, .button, .simulation, .halfLeft, .halfRight:
            return nil
        }
    }
}

enum LessonAssetError: LocalizedError {
    case invalidRequest
    case networkFailure
    
    var errorDescription: String? {
        switch self {
        case .invalidRequest:
            return "Unable to prepare download request for this resource."
        case .networkFailure:
            return "Unable to download the requested resource. Check your connection and permissions."
        }
    }
}
