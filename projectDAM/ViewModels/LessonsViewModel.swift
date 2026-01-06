//
//  LessonsViewModel.swift
//  projectDAM
//
//  Created on 11/15/2025.
//

import Foundation
import SwiftUI
import Combine

@MainActor
final class LessonsViewModel: ObservableObject {
    // MARK: - Published State
    @Published private(set) var lesson: Lesson?
    @Published private(set) var isLoading: Bool = false
    @Published private(set) var errorMessage: String?
    @Published private(set) var visibleVideos: [VideoContent] = []
    @Published private(set) var lastUpdated: Date?
    
    // MARK: - Public Props
    let courseId: String
    let accessType: LessonAccessType
    let isOwned: Bool
    
    // MARK: - Dependencies
    private let lessonService: LessonServiceProtocol
    
    // MARK: - Pagination
    private var allVideos: [VideoContent] = []
    private let initialBatchSize = 4
    private let batchSize = 3

    // MARK: - Request Coordination
    private var loadGeneration: Int = 0
    
    // MARK: - Initialization
    init(
        courseId: String,
        accessType: LessonAccessType,
        isOwned: Bool,
        lessonService: LessonServiceProtocol
    ) {
        self.courseId = courseId
        self.accessType = accessType
        self.isOwned = isOwned
        self.lessonService = lessonService
    }
    
    // MARK: - Derived State
    var hasMoreVideos: Bool {
        visibleVideos.count < allVideos.count
    }
    
    var lessonTitle: String {
        lesson?.title ?? "Lesson"
    }
    
    var isLockedPaidCourse: Bool {
        accessType == .privateCourse && !isOwned
    }
    
    // MARK: - Public Methods
    func loadLesson(force: Bool = false) async {
        if Task.isCancelled { return }
        guard !isLoading else { return }

        let isInitialLoad = (lesson == nil)
        if !force, !isInitialLoad { return }

        isLoading = true
        loadGeneration += 1
        let currentGeneration = loadGeneration

        if isInitialLoad {
            errorMessage = nil
        }

        defer {
            if loadGeneration == currentGeneration {
                isLoading = false
            }
        }

        do {
            let fetchedLesson = try await lessonService.fetchLesson(courseId: courseId, accessType: accessType)
            if Task.isCancelled { return }
            guard loadGeneration == currentGeneration else { return }

            lesson = fetchedLesson
            lastUpdated = Date()
            prepareVideos(from: fetchedLesson.videos)
        } catch is CancellationError {
            // SwiftUI can cancel refresh/tasks during transitions; don't show a user-visible error.
            return
        } catch {
            // Only show a blocking error if there's no cached content on screen.
            if isInitialLoad {
                errorMessage = error.localizedDescription
            }
        }
    }
    
    func retry() async {
        await loadLesson(force: true)
    }
    
    func loadMoreVideosIfNeeded(currentVideoId: String?) {
        guard hasMoreVideos else { return }
        guard let currentVideoId = currentVideoId,
              let currentIndex = visibleVideos.firstIndex(where: { $0.id == currentVideoId }) else {
            appendNextBatch()
            return
        }
        
        let threshold = max(0, visibleVideos.count - 2)
        if currentIndex >= threshold {
            appendNextBatch()
        }
    }
    
    func resetSelection() {
        // Helper for the view to ensure selection matches available videos
    }
    
    // MARK: - Private Helpers
    private func prepareVideos(from videos: [VideoContent]) {
        allVideos = videos.sorted { $0.orderIndex < $1.orderIndex }
        visibleVideos = []
        appendBatch(count: initialBatchSize)
    }
    
    private func appendNextBatch() {
        appendBatch(count: batchSize)
    }
    
    private func appendBatch(count: Int) {
        guard !allVideos.isEmpty else {
            visibleVideos = []
            return
        }
        let nextCount = min(visibleVideos.count + count, allVideos.count)
        visibleVideos = Array(allVideos.prefix(nextCount))
    }
}
