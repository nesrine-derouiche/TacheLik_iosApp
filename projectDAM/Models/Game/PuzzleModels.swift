//
//  PuzzleModels.swift
//  projectDAM
//
//  AI-generated puzzle game models
//

import Foundation

// MARK: - Puzzle Types
enum PuzzleDomain: String, Codable {
    case programming = "PROGRAMMING"
    case mathematics = "MATHEMATICS"
    case theory = "THEORY"
}

enum PuzzleDifficulty: String, Codable, CaseIterable {
    case easy = "EASY"
    case medium = "MEDIUM"
    case hard = "HARD"
    
    var displayName: String {
        switch self {
        case .easy: return "Easy"
        case .medium: return "Medium"
        case .hard: return "Hard"
        }
    }
    
    var color: String {
        switch self {
        case .easy: return "green"
        case .medium: return "orange"
        case .hard: return "red"
        }
    }
}

enum PuzzleBoardType: String, Codable {
    case grid = "GRID"
    case freeform = "FREEFORM"
}

enum PuzzlePieceType: String, Codable {
    case codeSnippet = "CODE_SNIPPET"
    case mathExpression = "MATH_EXPRESSION"
    case textSnippet = "TEXT_SNIPPET"
    case diagramNode = "DIAGRAM_NODE"
}

// MARK: - Puzzle Course Context
struct PuzzleCourseContext: Codable {
    let courseId: String
    let courseName: String
    let classTitle: String?
    let categoryName: String?
}

// MARK: - Puzzle Layout
struct PuzzleLayoutGrid: Codable {
    let rows: Int
    let cols: Int
}

struct PuzzleLayoutZone: Codable, Identifiable {
    let id: String
    let label: String
    let row: Int
    let col: Int
    let rowSpan: Int
    let colSpan: Int
}

struct PuzzleLayout: Codable {
    let boardType: PuzzleBoardType
    let grid: PuzzleLayoutGrid?
    let zones: [PuzzleLayoutZone]
}

// MARK: - Puzzle Piece
struct PuzzlePiece: Codable, Identifiable {
    let id: String
    let content: String
    let pieceType: PuzzlePieceType
    let isDistractor: Bool
}

// MARK: - Puzzle Solution
struct PuzzleSolutionMapping: Codable {
    let pieceId: String
    let zoneId: String
}

struct PuzzleScoring: Codable {
    let scorePerCorrect: Int
    let maxScore: Int
}

struct PuzzleSolution: Codable {
    let mappings: [PuzzleSolutionMapping]
    let scoring: PuzzleScoring
}

// MARK: - Puzzle Definition
struct PuzzleDefinition: Codable, Identifiable {
    let id: String
    let puzzleType: String
    let domain: PuzzleDomain
    let courseContext: PuzzleCourseContext
    let difficulty: PuzzleDifficulty
    let instructions: String
    let layout: PuzzleLayout
    let pieces: [PuzzlePiece]
    let solution: PuzzleSolution
    let metadata: [String: String]?
    
    // Helper computed properties
    var correctPieces: [PuzzlePiece] {
        pieces.filter { !$0.isDistractor }
    }
    
    var distractorPieces: [PuzzlePiece] {
        pieces.filter { $0.isDistractor }
    }
    
    var shuffledPieces: [PuzzlePiece] {
        pieces.shuffled()
    }
}

// MARK: - API Response
struct PuzzlesResponse: Codable {
    let success: Bool
    let puzzles: [PuzzleDefinition]
}

// MARK: - Generate Puzzles Request
struct GeneratePuzzlesRequest: Codable {
    let courseId: String
    let difficulty: String
    let count: Int
}

// MARK: - AI Game Type
enum AIGameType: String, CaseIterable, Identifiable {
    case quiz = "quiz"
    case puzzle = "puzzle"
    case codeRunner = "codeRunner"
    
    var id: String { rawValue }
    
    var displayName: String {
        switch self {
        case .quiz: return "Quick Quiz"
        case .puzzle: return "Puzzle Challenge"
        case .codeRunner: return "Code Runner"
        }
    }
    
    var icon: String {
        switch self {
        case .quiz: return "questionmark.circle.fill"
        case .puzzle: return "puzzlepiece.fill"
        case .codeRunner: return "play.circle.fill"
        }
    }
    
    var description: String {
        switch self {
        case .quiz: return "Answer AI-generated questions"
        case .puzzle: return "Drag and drop to solve"
        case .codeRunner: return "Run and answer while playing"
        }
    }
    
    var gradientColors: [String] {
        switch self {
        case .quiz: return ["#4F46E5", "#7C3AED"]
        case .puzzle: return ["#059669", "#10B981"]
        case .codeRunner: return ["#DC2626", "#F97316"]
        }
    }
}
