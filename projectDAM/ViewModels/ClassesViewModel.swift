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
    }
    
    // MARK: - Published State
    @Published private(set) var filters: [FilterOption] = []
    @Published private(set) var sections: [ClassSectionViewData] = []
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
            filters = builtFilters
            print("✅ Classes loaded: \(classes.count) classes across \(builtSections.count) sections")
        } catch {
            errorMessage = error.localizedDescription
            print("❌ Failed to load classes: \(error.localizedDescription)")
        }
        
        isLoading = false
    }
    
    func sections(for filterID: String) -> [ClassSectionViewData] {
        if filterID == FilterOption.allID {
            return sections
        }
        return sections.filter { $0.id == filterID }
    }
    
    func hasData(for filterID: String) -> Bool {
        !sections(for: filterID).isEmpty
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
            sortOrder: sortValue(for: classItem)
        )
    }
}
