//
//  TeacherCourseContentModels.swift
//  projectDAM
//
//  Created on 11/24/2025.
//

import Foundation

// MARK: - Rich Course Lesson Content
struct TeacherCourseLessonContent: Codable {
    let contentBlocks: [TeacherLessonContentBlock]
    let courseType: String?
    let lastUpdatedBy: String?
    let lastUpdatedAt: String?
    let courseSummary: String?
    
    enum CodingKeys: String, CodingKey {
        case contentList
        case courseType
        case lastUpdatedBy
        case lastUpdatedAt
        case courseSummary = "summary"
        case overview
        case description
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        contentBlocks = try container.decodeIfPresent([TeacherLessonContentBlock].self, forKey: .contentList) ?? []
        courseType = try container.decodeIfPresent(String.self, forKey: .courseType)
        lastUpdatedBy = try container.decodeIfPresent(String.self, forKey: .lastUpdatedBy)
        lastUpdatedAt = try container.decodeIfPresent(String.self, forKey: .lastUpdatedAt)
        if let summary = try container.decodeIfPresent(String.self, forKey: .courseSummary) {
            courseSummary = summary
        } else if let overview = try container.decodeIfPresent(String.self, forKey: .overview) {
            courseSummary = overview
        } else if let description = try container.decodeIfPresent(String.self, forKey: .description) {
            courseSummary = description
        } else {
            courseSummary = nil
        }
    }

    init(
        contentBlocks: [TeacherLessonContentBlock],
        courseType: String? = nil,
        lastUpdatedBy: String? = nil,
        lastUpdatedAt: String? = nil,
        courseSummary: String? = nil
    ) {
        self.contentBlocks = contentBlocks
        self.courseType = courseType
        self.lastUpdatedBy = lastUpdatedBy
        self.lastUpdatedAt = lastUpdatedAt
        self.courseSummary = courseSummary
    }
}

extension TeacherCourseLessonContent {
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(contentBlocks, forKey: .contentList)
        try container.encodeIfPresent(courseType, forKey: .courseType)
        try container.encodeIfPresent(lastUpdatedBy, forKey: .lastUpdatedBy)
        try container.encodeIfPresent(lastUpdatedAt, forKey: .lastUpdatedAt)
        if let summary = courseSummary {
            try container.encode(summary, forKey: .courseSummary)
        }
    }
}

// MARK: - Lesson Content Block
struct TeacherLessonContentBlock: Identifiable, Codable {
    let id: UUID
    let rawType: String
    let type: TeacherLessonContentType
    let text: String?
    let beforeText: String?
    let afterText: String?
    let image: String?
    let pdf: String?
    let pdfLabel: String?
    let url: String?
    let checklistItems: [String]?
    let language: String?
    let filename: String?
    let helperText: String?
    let accent: String?
    
    enum CodingKeys: String, CodingKey {
        case type
        case content
        case beforeContent
        case afterContent
        case image
        case pdf
        case pdfLabel
        case url
        case items
        case language
        case filename
        case helperText
        case accent
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = UUID()
        rawType = (try? container.decode(String.self, forKey: .type)) ?? "unknown"
        type = TeacherLessonContentType(rawType)
        text = try container.decodeIfPresent(String.self, forKey: .content)
        beforeText = try container.decodeIfPresent(String.self, forKey: .beforeContent)
        afterText = try container.decodeIfPresent(String.self, forKey: .afterContent)
        image = try container.decodeIfPresent(String.self, forKey: .image)
        pdf = try container.decodeIfPresent(String.self, forKey: .pdf)
        pdfLabel = try container.decodeIfPresent(String.self, forKey: .pdfLabel)
        url = try container.decodeIfPresent(String.self, forKey: .url)
        checklistItems = try container.decodeIfPresent([String].self, forKey: .items)
        language = try container.decodeIfPresent(String.self, forKey: .language)
        filename = try container.decodeIfPresent(String.self, forKey: .filename)
        helperText = try container.decodeIfPresent(String.self, forKey: .helperText)
        accent = try container.decodeIfPresent(String.self, forKey: .accent)
    }
}

extension TeacherLessonContentBlock {
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(type, forKey: .type)
        try container.encodeIfPresent(text, forKey: .content)
        try container.encodeIfPresent(beforeText, forKey: .beforeContent)
        try container.encodeIfPresent(afterText, forKey: .afterContent)
        try container.encodeIfPresent(image, forKey: .image)
        try container.encodeIfPresent(pdf, forKey: .pdf)
        try container.encodeIfPresent(pdfLabel, forKey: .pdfLabel)
        try container.encodeIfPresent(url, forKey: .url)
        try container.encodeIfPresent(checklistItems, forKey: .items)
        try container.encodeIfPresent(language, forKey: .language)
        try container.encodeIfPresent(filename, forKey: .filename)
        try container.encodeIfPresent(helperText, forKey: .helperText)
        try container.encodeIfPresent(accent, forKey: .accent)
    }
}

extension TeacherLessonContentBlock {
    init(
        type: TeacherLessonContentType,
        text: String? = nil,
        beforeText: String? = nil,
        afterText: String? = nil,
        image: String? = nil,
        pdf: String? = nil,
        pdfLabel: String? = nil,
        url: String? = nil,
        checklistItems: [String]? = nil,
        language: String? = nil,
        filename: String? = nil,
        helperText: String? = nil,
        accent: String? = nil
    ) {
        self.id = UUID()
        self.rawType = type.rawValue
        self.type = type
        self.text = text
        self.beforeText = beforeText
        self.afterText = afterText
        self.image = image
        self.pdf = pdf
        self.pdfLabel = pdfLabel
        self.url = url
        self.checklistItems = checklistItems
        self.language = language
        self.filename = filename
        self.helperText = helperText
        self.accent = accent
    }
}

// MARK: - Content Type
enum TeacherLessonContentType: Hashable {
    case title
    case subtitle
    case paragraph
    case boxedParagraph
    case latex
    case checklist
    case code
    case link
    case pdf
    case fullImage
    case halfLeft
    case halfRight
    case button
    case simulation
    case divider
    case unknown(raw: String)
    
    init(_ raw: String) {
        let cleaned = TeacherLessonContentType.normalize(raw)
        switch cleaned {
        case "title": self = .title
        case "subtitle": self = .subtitle
        case "paragraph": self = .paragraph
        case "boxedparagraph", "boxed-paragraph": self = .boxedParagraph
        case "latex": self = .latex
        case "checklist": self = .checklist
        case "code": self = .code
        case "link": self = .link
        case "pdf": self = .pdf
        case "fullimage", "full-image": self = .fullImage
        case "halfleft", "half-left": self = .halfLeft
        case "halfright", "half-right": self = .halfRight
        case "button": self = .button
        case "simulation": self = .simulation
        case "divider": self = .divider
        case "": self = .unknown(raw: raw)
        default: self = .unknown(raw: raw)
        }
    }
    
    var rawValue: String {
        switch self {
        case .title: return "title"
        case .subtitle: return "subtitle"
        case .paragraph: return "paragraph"
        case .boxedParagraph: return "boxed-paragraph"
        case .latex: return "latex"
        case .checklist: return "checklist"
        case .code: return "code"
        case .link: return "link"
        case .pdf: return "pdf"
        case .fullImage: return "full-image"
        case .halfLeft: return "half-left"
        case .halfRight: return "half-right"
        case .button: return "button"
        case .simulation: return "simulation"
        case .divider: return "divider"
        case .unknown(let raw): return raw
        }
    }
    
    private static func normalize(_ raw: String) -> String {
        return raw
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .lowercased()
            .replacingOccurrences(of: "_", with: "")
            .replacingOccurrences(of: "-", with: "")
    }
}

extension TeacherLessonContentType: Codable {
    init(from decoder: Decoder) throws {
        let value = (try? decoder.singleValueContainer().decode(String.self)) ?? "unknown"
        self = TeacherLessonContentType(value)
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        try container.encode(rawValue)
    }
}
