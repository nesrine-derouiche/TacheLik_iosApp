//
//  ClassesViewModel.swift
//  projectDAM
//
//  Created on 11/7/2025.
//

import Foundation
import SwiftUI
import Combine

// MARK: - Classes View Model
/// Manages classes screen state and groups classes by filter name
@MainActor
final class ClassesViewModel: ObservableObject {
    // MARK: - Nested Types
    struct FilterOption: Identifiable, Equatable {
        static let allID = "all"
        let id: String
        let title: String
        let sortOrder: Int
        let accentColor: Color?
    }
    
    struct ClassSectionViewData: Identifiable, Equatable {
        let id: String
        let title: String
        let color: Color
        let classes: [ClassCard]
        let sortOrder: Int
    }

    struct ClassCard: Identifiable, Equatable {
        let id: String
        let title: String
        let description: String
        let imageURLString: String?
        let sortOrder: Int
        let classItem: ClassItem // Store original ClassItem for navigation
    }
    
    // MARK: - Published State
    @Published private(set) var filters: [FilterOption] = []
    @Published private(set) var sections: [ClassSectionViewData] = []
    @Published private var visibleSectionCount: Int = 0
    @Published private var visibleClassCounts: [String: Int] = [:]
    @Published var isLoading: Bool = false
    @Published var errorMessage: String?
    
    // MARK: - Dependencies
    private let courseService: CourseServiceProtocol
    
    // MARK: - Lookup Tables
    private struct FilterMetadata {
        let id: String
        let title: String
        let color: Color
        let sortOrder: Int
    }
    
    private let fallbackColors: [Color] = [.blue, .purple, .orange, .green, .pink, .teal, .indigo]
    private let initialSectionBatchSize = 2
    private let sectionBatchSize = 2
    private let initialClassBatchSize = 3
    private let classBatchSize = 3
    private let knownFilters: [String: (title: String, color: Color, sortOrder: Int)] = [
        "1a": (title: "1A", color: .blue, sortOrder: 0),
        "2a": (title: "2A", color: .purple, sortOrder: 1),
        "3a": (title: "3A", color: .orange, sortOrder: 2),
        "3b": (title: "3B", color: .orange, sortOrder: 3),
        "3a & 3b": (title: "3A & 3B", color: .orange, sortOrder: 2),
        ".first": (title: "1A", color: .blue, sortOrder: 0),
        ".second": (title: "2A", color: .purple, sortOrder: 1),
        ".third": (title: "3A & 3B", color: .orange, sortOrder: 2)
    ]
    
    // MARK: - Initialization
    init(courseService: CourseServiceProtocol) {
        self.courseService = courseService
    }
    
    // MARK: - Public API
    func loadClasses(force: Bool = false) async {
        if isLoading { return }
        if !force && !sections.isEmpty { return }
        
        isLoading = true
        errorMessage = nil
        
        do {
            let classes = try await courseService.fetchClasses()
            let builtSections = buildSections(from: classes)
            let builtFilters = buildFilters(from: builtSections)
            sections = builtSections
            resetVisibleSections()
            resetVisibleClasses()
            filters = builtFilters
            print("✅ Classes loaded: \(classes.count) classes across \(builtSections.count) sections")
        } catch {
            errorMessage = error.localizedDescription
            print("❌ Failed to load classes: \(error.localizedDescription)")
        }
        
        isLoading = false
    }
    
    func sections(for filterID: String) -> [ClassSectionViewData] {
        let baseSections: [ClassSectionViewData]
        if filterID == FilterOption.allID {
            baseSections = Array(sections.prefix(visibleSectionCount))
        } else {
            baseSections = sections.filter { $0.id == filterID }
        }
        return baseSections
    }

    func hasData(for filterID: String) -> Bool {
        !sections(for: filterID).isEmpty
    }

    func visibleClasses(for sectionID: String) -> [ClassCard] {
        guard let section = sections.first(where: { $0.id == sectionID }) else { return [] }
        let limit = visibleClassCounts[sectionID] ?? section.classes.count
        return Array(section.classes.prefix(limit))
    }

    func previewClasses(for sectionID: String, limit: Int) -> [ClassCard] {
        let classes = visibleClasses(for: sectionID)
        return Array(classes.prefix(limit))
    }

    func canLoadMoreClasses(for sectionID: String) -> Bool {
        guard let section = sections.first(where: { $0.id == sectionID }) else { return false }
        let currentCount = visibleClassCounts[sectionID] ?? 0
        return currentCount < section.classes.count
    }

    func loadMoreSectionsIfNeeded(currentSectionID: String) {
        guard let currentIndex = sections.firstIndex(where: { $0.id == currentSectionID }) else { return }
        if currentIndex >= visibleSectionCount - 1 {
            let newCount = min(visibleSectionCount + sectionBatchSize, sections.count)
            if newCount > visibleSectionCount {
                withAnimation(.easeInOut(duration: 0.25)) {
                    visibleSectionCount = newCount
                }
            }
        }
    }

    func loadMoreClassesIfNeeded(sectionID: String, currentClassID: String) {
        guard let section = sections.first(where: { $0.id == sectionID }) else { return }
        let classes = section.classes
        guard let currentIndex = classes.firstIndex(where: { $0.id == currentClassID }) else { return }
        let currentVisibleCount = visibleClassCounts[sectionID] ?? initialClassBatchSize
        if currentIndex >= currentVisibleCount - 2 {
            let newCount = min(currentVisibleCount + classBatchSize, classes.count)
            if newCount > currentVisibleCount {
                withAnimation(.easeInOut(duration: 0.25)) {
                    visibleClassCounts[sectionID] = newCount
                }
            }
        }
    }

    // MARK: - Builders
    private func buildSections(from classes: [ClassItem]) -> [ClassSectionViewData] {
        var buckets: [String: (meta: FilterMetadata, items: [ClassItem])] = [:]
        
        for classItem in classes {
            let meta = metadata(for: classItem.filterName)
            var entry = buckets[meta.id] ?? (meta, [])
            entry.items.append(classItem)
            buckets[meta.id] = entry
        }
        
        var result: [ClassSectionViewData] = []
        for (_, bucket) in buckets {
            let sortedClasses = bucket.items.sorted { sortValue(for: $0) < sortValue(for: $1) }
            let cards = sortedClasses.map { classCard(from: $0) }
            result.append(
                ClassSectionViewData(
                    id: bucket.meta.id,
                    title: bucket.meta.title,
                    color: bucket.meta.color,
                    classes: cards,
                    sortOrder: bucket.meta.sortOrder
                )
            )
        }
        
        result.sort { lhs, rhs in
            if lhs.sortOrder == rhs.sortOrder {
                return lhs.title < rhs.title
            }
            return lhs.sortOrder < rhs.sortOrder
        }
        return result
    }
    
    // MARK: - Visibility Helpers
    private func resetVisibleSections() {
        visibleSectionCount = min(initialSectionBatchSize, sections.count)
    }
    
    private func resetVisibleClasses() {
        var counts: [String: Int] = [:]
        for section in sections {
            counts[section.id] = min(initialClassBatchSize, section.classes.count)
        }
        visibleClassCounts = counts
    }
    
    private func buildFilters(from sections: [ClassSectionViewData]) -> [FilterOption] {
        var options = sections.map { section in
            FilterOption(
                id: section.id,
                title: section.title,
                sortOrder: section.sortOrder,
                accentColor: section.color
            )
        }
        options.sort { lhs, rhs in
            if lhs.sortOrder == rhs.sortOrder {
                return lhs.title < rhs.title
            }
            return lhs.sortOrder < rhs.sortOrder
        }
        options.insert(
            FilterOption(id: FilterOption.allID, title: "All", sortOrder: Int.min, accentColor: nil),
            at: 0
        )
        return options
    }
    
    private func metadata(for rawFilterName: String) -> FilterMetadata {
        let trimmed = rawFilterName.trimmingCharacters(in: .whitespacesAndNewlines)
        let normalized = normalizedKey(for: trimmed)
        
        if let known = knownFilters[normalized] {
            return FilterMetadata(id: normalized, title: known.title, color: known.color, sortOrder: known.sortOrder)
        }
        
        let nonEmptyNormalized = normalized.isEmpty ? "other" : normalized
        let displayTitle = trimmed.isEmpty ? "Other" : trimmed
        let colorIndex = abs(nonEmptyNormalized.hashValue) % fallbackColors.count
        let color = fallbackColors[colorIndex]
        return FilterMetadata(
            id: nonEmptyNormalized,
            title: displayTitle,
            color: color,
            sortOrder: 100 + colorIndex
        )
    }
    
    private func normalizedKey(for value: String) -> String {
        value
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .lowercased()
    }
    
    private func sortValue(for classItem: ClassItem) -> Int {
        if let numericPart = classItem.classOrder.split(separator: "-").last,
           let number = Int(numericPart) {
            return number
        }
        return Int.max
    }
    
    private func classCard(from classItem: ClassItem) -> ClassCard {
        ClassCard(
            id: classItem.id,
            title: classItem.title,
            description: "Learn more about our \(classItem.title) class and discover how it can benefit you.",
            imageURLString: classItem.imageURLString,
            sortOrder: sortValue(for: classItem),
            classItem: classItem
        )
    }
}
