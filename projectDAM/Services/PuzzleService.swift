//
//  PuzzleService.swift
//  projectDAM
//
//  Service to fetch AI-generated puzzles
//

import Foundation
import Combine

// MARK: - Puzzle Service Protocol
protocol PuzzleServiceProtocol {
    func generatePuzzles(courseId: String, difficulty: PuzzleDifficulty, count: Int) async throws -> [PuzzleDefinition]
}

// MARK: - Puzzle Service Implementation
final class PuzzleService: PuzzleServiceProtocol {
    
    private let networkService: NetworkServiceProtocol
    private let authService: AuthServiceProtocol
    
    init(networkService: NetworkServiceProtocol, authService: AuthServiceProtocol) {
        self.networkService = networkService
        self.authService = authService
    }
    
    /// Generate AI puzzles from course content
    func generatePuzzles(courseId: String, difficulty: PuzzleDifficulty = .medium, count: Int = 3) async throws -> [PuzzleDefinition] {
        guard let token = authService.getAuthToken() else {
            throw NetworkError.unauthorized
        }
        
        if AppConfig.enableLogging {
            print("📡 [PuzzleService] Generating puzzles for course \(courseId) with difficulty \(difficulty.rawValue)")
        }
        
        let request = GeneratePuzzlesRequest(
            courseId: courseId,
            difficulty: difficulty.rawValue,
            count: count
        )
        
        let body = try JSONEncoder().encode(request)
        
        let response: PuzzlesResponse = try await networkService.request(
            endpoint: "/puzzle/ai/from-course",
            method: .POST,
            body: body,
            headers: [
                "Authorization": "Bearer \(token)",
                "Content-Type": "application/json"
            ]
        )
        
        if AppConfig.enableLogging {
            print("✅ [PuzzleService] Generated \(response.puzzles.count) puzzles")
        }
        
        return response.puzzles
    }
}

// MARK: - Puzzle Game State Manager
@MainActor
final class PuzzleGameManager: ObservableObject {
    
    // MARK: - Published Properties
    @Published var puzzles: [PuzzleDefinition] = []
    @Published var currentPuzzleIndex: Int = 0
    @Published var isLoading: Bool = false
    @Published var errorMessage: String?
    @Published var score: Int = 0
    @Published var totalScore: Int = 0
    @Published var isGameComplete: Bool = false
    
    // Current puzzle placements (pieceId -> zoneId)
    @Published var placements: [String: String] = [:]
    
    // MARK: - Computed Properties
    var currentPuzzle: PuzzleDefinition? {
        guard currentPuzzleIndex < puzzles.count else { return nil }
        return puzzles[currentPuzzleIndex]
    }
    
    var progress: Double {
        guard !puzzles.isEmpty else { return 0 }
        return Double(currentPuzzleIndex) / Double(puzzles.count)
    }
    
    var puzzlesRemaining: Int {
        max(0, puzzles.count - currentPuzzleIndex)
    }
    
    // MARK: - Dependencies
    private let puzzleService: PuzzleServiceProtocol
    
    // MARK: - Initialization
    init(puzzleService: PuzzleServiceProtocol = PuzzleService(
        networkService: DIContainer.shared.networkService,
        authService: DIContainer.shared.authService
    )) {
        self.puzzleService = puzzleService
    }
    
    // MARK: - Public Methods
    
    func loadPuzzles(courseId: String, difficulty: PuzzleDifficulty = .medium) async {
        isLoading = true
        errorMessage = nil
        
        do {
            puzzles = try await puzzleService.generatePuzzles(
                courseId: courseId,
                difficulty: difficulty,
                count: 5
            )
            
            // Calculate total possible score
            totalScore = puzzles.reduce(0) { $0 + $1.solution.scoring.maxScore }
            
            currentPuzzleIndex = 0
            placements = [:]
            score = 0
            isGameComplete = false
            
            print("✅ [PuzzleGameManager] Loaded \(puzzles.count) puzzles with max score \(totalScore)")
            
        } catch {
            errorMessage = error.localizedDescription
            print("❌ [PuzzleGameManager] Error: \(error.localizedDescription)")
        }
        
        isLoading = false
    }
    
    func placePiece(pieceId: String, inZone zoneId: String) {
        // Remove piece from any previous zone
        placements = placements.filter { $0.value != zoneId && $0.key != pieceId }
        // Place in new zone
        placements[pieceId] = zoneId
    }
    
    func removePiece(pieceId: String) {
        placements.removeValue(forKey: pieceId)
    }
    
    func checkCurrentPuzzle() -> Bool {
        guard let puzzle = currentPuzzle else { return false }
        
        var correctCount = 0
        
        for mapping in puzzle.solution.mappings {
            if placements[mapping.pieceId] == mapping.zoneId {
                correctCount += 1
            }
        }
        
        let puzzleScore = correctCount * puzzle.solution.scoring.scorePerCorrect
        score += puzzleScore
        
        return correctCount == puzzle.solution.mappings.count
    }
    
    func nextPuzzle() {
        placements = [:]
        
        if currentPuzzleIndex < puzzles.count - 1 {
            currentPuzzleIndex += 1
        } else {
            isGameComplete = true
        }
    }
    
    func reset() {
        puzzles = []
        currentPuzzleIndex = 0
        placements = [:]
        score = 0
        totalScore = 0
        isGameComplete = false
        errorMessage = nil
    }
}
