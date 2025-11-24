//
//  TeacherLessonContentParser.swift
//  projectDAM
//
//  Created on 11/24/2025.
//

import Foundation

/// Normalized lesson content ready for UI rendering
enum TeacherLessonRenderableItem: Identifiable, Hashable {
    case title(id: UUID, text: String)
    case subtitle(id: UUID, text: String)
    case paragraph(id: UUID, text: String, style: ParagraphStyle)
    case latex(id: UUID, content: String)
    case checklist(id: UUID, items: [String])
    case image(id: UUID, reference: LessonMediaReference, caption: String?)
    case link(id: UUID, label: String, detail: String?, url: URL?)
    case pdf(id: UUID, reference: LessonMediaReference, label: String)
    case code(id: UUID, reference: LessonMediaReference, filename: String?, language: String?)
    case divider(id: UUID)
    case unknown(id: UUID, rawType: String, fallback: String?)
    
    enum ParagraphStyle: Hashable {
        case standard
        case boxed
    }
    
    var id: UUID {
        switch self {
        case .title(let id, _),
             .subtitle(let id, _),
             .paragraph(let id, _, _),
             .latex(let id, _),
             .checklist(let id, _),
             .image(let id, _, _),
             .link(let id, _, _, _),
             .pdf(let id, _, _),
             .code(let id, _, _, _),
             .divider(let id),
             .unknown(let id, _, _):
            return id
        }
    }
}

/// Media files (images, PDFs, code files) metadata
struct LessonMediaReference: Hashable {
    enum Kind: Hashable {
        case image
        case pdf
        case code
    }
    
    let kind: Kind
    let filename: String
    let blockId: UUID
}

struct TeacherLessonContentParser {
    struct Result {
        let items: [TeacherLessonRenderableItem]
        let warnings: [String]
    }
    
    func parse(blocks: [TeacherLessonContentBlock]) -> Result {
        var normalized: [TeacherLessonRenderableItem] = []
        var warnings: [String] = []
        for block in blocks {
            if let item = transform(block) {
                normalized.append(item)
            } else {
                warnings.append("Missing or invalid data for block type \(block.rawType)")
            }
        }
        return Result(items: normalized, warnings: warnings)
    }
    
    private func transform(_ block: TeacherLessonContentBlock) -> TeacherLessonRenderableItem? {
        switch block.type {
        case .title:
            guard let text = block.cleanedPrimaryText else { return nil }
            return .title(id: block.id, text: text)
        case .subtitle:
            guard let text = block.cleanedPrimaryText else { return nil }
            return .subtitle(id: block.id, text: text)
        case .paragraph:
            guard let text = block.cleanedPrimaryText else { return nil }
            return .paragraph(id: block.id, text: text, style: .standard)
        case .boxedParagraph:
            guard let text = block.cleanedPrimaryText else { return nil }
            return .paragraph(id: block.id, text: text, style: .boxed)
        case .latex:
            guard let raw = block.cleanedPrimaryText else { return nil }
            return .latex(id: block.id, content: sanitizeLatex(raw))
        case .checklist:
            let items = block.cleanedChecklist
            guard items.isEmpty == false else { return nil }
            return .checklist(id: block.id, items: items)
        case .link:
            if block.cleanedPrimaryText == nil && block.cleanedURL == nil {
                return nil
            }
            return .link(
                id: block.id,
                label: block.cleanedPrimaryText ?? "Link",
                detail: block.cleanedBeforeText,
                url: block.cleanedURL
            )
        case .pdf:
            guard let file = block.cleanedFileName else { return nil }
            let label = block.cleanedPdfLabel ?? file
            let reference = LessonMediaReference(kind: .pdf, filename: file, blockId: block.id)
            return .pdf(id: block.id, reference: reference, label: label)
        case .code:
            guard let file = block.cleanedFileName else { return nil }
            let reference = LessonMediaReference(kind: .code, filename: file, blockId: block.id)
            return .code(id: block.id, reference: reference, filename: block.filename, language: block.cleanedLanguage)
        case .fullImage:
            guard let file = block.cleanedFileName ?? block.image?.trimmingCharacters(in: .whitespacesAndNewlines),
                  !file.isEmpty else { return nil }
            let reference = LessonMediaReference(kind: .image, filename: file, blockId: block.id)
            return .image(id: block.id, reference: reference, caption: block.helperText?.trimmed)
        case .divider:
            return .divider(id: block.id)
        case .button, .simulation, .halfLeft, .halfRight:
            // Not yet supported in the teacher app – render as fallback text
            let fallback = block.cleanedPrimaryText ?? block.helperText?.trimmed
            return .unknown(id: block.id, rawType: block.rawType, fallback: fallback)
        case .unknown(let raw):
            let fallback = block.cleanedPrimaryText ?? block.helperText?.trimmed
            return .unknown(id: block.id, rawType: raw, fallback: fallback)
        }
    }
    
    private func sanitizeLatex(_ value: String) -> String {
        value
            .replacingOccurrences(of: "\\n", with: "\n")
            .trimmingCharacters(in: .whitespacesAndNewlines)
    }
}

private extension TeacherLessonContentBlock {
    var cleanedPrimaryText: String? { text?.trimmed }
    var cleanedBeforeText: String? { beforeText?.trimmed }
    var cleanedPdfLabel: String? { pdfLabel?.trimmed }
    var cleanedLanguage: String? { language?.trimmed }
    var cleanedFileName: String? {
        if let pdf = pdf?.trimmed, !pdf.isEmpty { return pdf }
        if let filename = filename?.trimmed, !filename.isEmpty { return filename }
        if let image = image?.trimmed, !image.isEmpty { return image }
        return nil
    }
    var cleanedChecklist: [String] {
        (checklistItems ?? [])
            .map { $0.trimmed }
            .filter { !$0.isEmpty }
    }
    var cleanedURL: URL? {
        guard let value = url?.trimmed, !value.isEmpty else { return nil }
        if let parsed = URL(string: value), parsed.scheme != nil {
            return parsed
        }
        return URL(string: "https://" + value)
    }
}

private extension String {
    var trimmed: String {
        trimmingCharacters(in: .whitespacesAndNewlines)
    }
}
