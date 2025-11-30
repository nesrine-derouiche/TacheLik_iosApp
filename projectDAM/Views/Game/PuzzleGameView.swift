//
//  PuzzleGameView.swift
//  projectDAM
//
//  Interactive drag-and-drop puzzle game view
//

import SwiftUI
import UniformTypeIdentifiers

struct PuzzleGameView: View {
    let courseId: String
    let difficulty: PuzzleDifficulty
    
    @Environment(\.dismiss) private var dismiss
    @StateObject private var gameManager = PuzzleGameManager()
    @State private var showingResult = false
    @State private var lastCheckCorrect = false
    
    var body: some View {
        ZStack {
            // Background
            LinearGradient(
                colors: [Color(hex: "1a1a2e"), Color(hex: "16213e")],
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()
            
            if gameManager.isLoading {
                loadingView
            } else if let error = gameManager.errorMessage {
                errorView(error: error)
            } else if gameManager.isGameComplete {
                gameCompleteView
            } else if let puzzle = gameManager.currentPuzzle {
                puzzleContent(puzzle: puzzle)
            }
        }
        .task {
            await gameManager.loadPuzzles(courseId: courseId, difficulty: difficulty)
        }
    }
    
    // MARK: - Loading View
    private var loadingView: some View {
        VStack(spacing: 24) {
            ZStack {
                Circle()
                    .stroke(Color.white.opacity(0.2), lineWidth: 4)
                    .frame(width: 80, height: 80)
                
                Circle()
                    .trim(from: 0, to: 0.7)
                    .stroke(Color.brandPrimary, style: StrokeStyle(lineWidth: 4, lineCap: .round))
                    .frame(width: 80, height: 80)
                    .rotationEffect(.degrees(-90))
                    .animation(.linear(duration: 1).repeatForever(autoreverses: false), value: true)
                
                Image(systemName: "puzzlepiece.fill")
                    .font(.system(size: 32))
                    .foregroundColor(.brandPrimary)
            }
            
            Text("Generating Puzzles...")
                .font(.system(size: 22, weight: .bold))
                .foregroundColor(.white)
            
            Text("AI is creating unique puzzles from your course content")
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(.white.opacity(0.6))
                .multilineTextAlignment(.center)
                .padding(.horizontal, 40)
        }
    }
    
    // MARK: - Error View
    private func errorView(error: String) -> some View {
        VStack(spacing: 24) {
            Image(systemName: "exclamationmark.triangle.fill")
                .font(.system(size: 60))
                .foregroundColor(.red)
            
            Text("Failed to Load Puzzles")
                .font(.system(size: 22, weight: .bold))
                .foregroundColor(.white)
            
            Text(error)
                .font(.system(size: 14))
                .foregroundColor(.white.opacity(0.6))
                .multilineTextAlignment(.center)
                .padding(.horizontal, 40)
            
            HStack(spacing: 16) {
                Button {
                    dismiss()
                } label: {
                    Text("Close")
                        .font(.headline)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                        .background(Color.white.opacity(0.2))
                        .cornerRadius(12)
                }
                
                Button {
                    Task {
                        await gameManager.loadPuzzles(courseId: courseId, difficulty: difficulty)
                    }
                } label: {
                    Text("Retry")
                        .font(.headline)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                        .background(Color.brandPrimary)
                        .cornerRadius(12)
                }
            }
            .padding(.horizontal, 40)
        }
    }
    
    // MARK: - Game Complete View
    private var gameCompleteView: some View {
        VStack(spacing: 32) {
            // Trophy
            ZStack {
                Circle()
                    .fill(Color.yellow.opacity(0.2))
                    .frame(width: 140, height: 140)
                
                Image(systemName: "trophy.fill")
                    .font(.system(size: 70))
                    .foregroundColor(.yellow)
            }
            
            Text("Puzzle Complete!")
                .font(.system(size: 32, weight: .bold))
                .foregroundColor(.white)
            
            // Score
            VStack(spacing: 8) {
                Text("Your Score")
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(.white.opacity(0.6))
                
                Text("\(gameManager.score) / \(gameManager.totalScore)")
                    .font(.system(size: 48, weight: .bold))
                    .foregroundColor(.brandPrimary)
                
                let percentage = gameManager.totalScore > 0
                    ? Int((Double(gameManager.score) / Double(gameManager.totalScore)) * 100)
                    : 0
                
                Text("\(percentage)% Correct")
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundColor(percentage >= 70 ? .green : .orange)
            }
            
            // Actions
            VStack(spacing: 12) {
                Button {
                    Task {
                        await gameManager.loadPuzzles(courseId: courseId, difficulty: difficulty)
                    }
                } label: {
                    HStack {
                        Image(systemName: "arrow.clockwise")
                        Text("Play Again")
                    }
                    .font(.headline)
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                    .background(Color.brandPrimary)
                    .cornerRadius(14)
                }
                
                Button {
                    dismiss()
                } label: {
                    Text("Done")
                        .font(.headline)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(Color.white.opacity(0.2))
                        .cornerRadius(14)
                }
            }
            .padding(.horizontal, 40)
        }
    }
    
    // MARK: - Puzzle Content
    private func puzzleContent(puzzle: PuzzleDefinition) -> some View {
        VStack(spacing: 0) {
            // Top Bar
            topBar(puzzle: puzzle)
            
            ScrollView(showsIndicators: false) {
                VStack(spacing: 24) {
                    // Instructions
                    instructionsCard(puzzle: puzzle)
                    
                    // Drop Zones (Grid)
                    dropZonesGrid(puzzle: puzzle)
                    
                    // Draggable Pieces
                    piecesSection(puzzle: puzzle)
                    
                    // Check Button
                    checkButton
                }
                .padding(20)
            }
        }
        .alert("Result", isPresented: $showingResult) {
            Button("Continue") {
                gameManager.nextPuzzle()
            }
        } message: {
            Text(lastCheckCorrect ? "🎉 Correct! Well done!" : "❌ Not quite right. Try the next one!")
        }
    }
    
    // MARK: - Top Bar
    private func topBar(puzzle: PuzzleDefinition) -> some View {
        HStack {
            Button {
                dismiss()
            } label: {
                Image(systemName: "xmark")
                    .font(.system(size: 18, weight: .bold))
                    .foregroundColor(.white)
                    .padding(10)
                    .background(Color.white.opacity(0.15))
                    .clipShape(Circle())
            }
            
            Spacer()
            
            // Progress indicator
            VStack(spacing: 4) {
                Text("Puzzle \(gameManager.currentPuzzleIndex + 1)/\(gameManager.puzzles.count)")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(.white)
                
                ProgressView(value: gameManager.progress)
                    .tint(.brandPrimary)
                    .frame(width: 100)
            }
            
            Spacer()
            
            // Score
            VStack(spacing: 2) {
                Text("Score")
                    .font(.system(size: 10, weight: .medium))
                    .foregroundColor(.white.opacity(0.6))
                Text("\(gameManager.score)")
                    .font(.system(size: 18, weight: .bold))
                    .foregroundColor(.brandPrimary)
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(Color.white.opacity(0.1))
            .cornerRadius(10)
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 16)
        .background(Color.black.opacity(0.3))
    }
    
    // MARK: - Instructions Card
    private func instructionsCard(puzzle: PuzzleDefinition) -> some View {
        VStack(spacing: 12) {
            HStack {
                Image(systemName: "lightbulb.fill")
                    .foregroundColor(.yellow)
                Text("Instructions")
                    .font(.system(size: 14, weight: .bold))
                    .foregroundColor(.white)
                Spacer()
                
                // Difficulty badge
                Text(puzzle.difficulty.displayName)
                    .font(.system(size: 11, weight: .bold))
                    .foregroundColor(.white)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 4)
                    .background(difficultyColor(puzzle.difficulty))
                    .cornerRadius(8)
            }
            
            Text(puzzle.instructions)
                .font(.system(size: 15, weight: .medium))
                .foregroundColor(.white.opacity(0.9))
                .multilineTextAlignment(.leading)
        }
        .padding(16)
        .background(Color.white.opacity(0.1))
        .cornerRadius(16)
    }
    
    // MARK: - Drop Zones Grid
    private func dropZonesGrid(puzzle: PuzzleDefinition) -> some View {
        let grid = puzzle.layout.grid ?? PuzzleLayoutGrid(rows: 2, cols: 2)
        
        return VStack(spacing: 12) {
            Text("Drop Zones")
                .font(.system(size: 14, weight: .bold))
                .foregroundColor(.white.opacity(0.7))
                .frame(maxWidth: .infinity, alignment: .leading)
            
            LazyVGrid(
                columns: Array(repeating: GridItem(.flexible(), spacing: 12), count: grid.cols),
                spacing: 12
            ) {
                ForEach(puzzle.layout.zones) { zone in
                    DropZoneView(
                        zone: zone,
                        placedPiece: pieceInZone(zone.id, puzzle: puzzle),
                        onDrop: { pieceId in
                            gameManager.placePiece(pieceId: pieceId, inZone: zone.id)
                        }
                    )
                }
            }
        }
    }
    
    // MARK: - Pieces Section
    private func piecesSection(puzzle: PuzzleDefinition) -> some View {
        VStack(spacing: 12) {
            Text("Available Pieces")
                .font(.system(size: 14, weight: .bold))
                .foregroundColor(.white.opacity(0.7))
                .frame(maxWidth: .infinity, alignment: .leading)
            
            // Show pieces that are NOT placed yet
            let unplacedPieces = puzzle.shuffledPieces.filter { piece in
                gameManager.placements[piece.id] == nil
            }
            
            LazyVGrid(
                columns: [GridItem(.adaptive(minimum: 140), spacing: 12)],
                spacing: 12
            ) {
                ForEach(unplacedPieces) { piece in
                    DraggablePieceView(piece: piece)
                }
            }
            
            if unplacedPieces.isEmpty {
                Text("All pieces placed! Check your answer.")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(.green)
                    .padding(.vertical, 20)
            }
        }
    }
    
    // MARK: - Check Button
    private var checkButton: some View {
        Button {
            lastCheckCorrect = gameManager.checkCurrentPuzzle()
            showingResult = true
        } label: {
            HStack {
                Image(systemName: "checkmark.circle.fill")
                Text("Check Answer")
            }
            .font(.system(size: 17, weight: .bold))
            .foregroundColor(.white)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 18)
            .background(Color.brandPrimary)
            .cornerRadius(14)
        }
        .padding(.top, 8)
    }
    
    // MARK: - Helper Methods
    private func pieceInZone(_ zoneId: String, puzzle: PuzzleDefinition) -> PuzzlePiece? {
        for (pieceId, placedZoneId) in gameManager.placements {
            if placedZoneId == zoneId {
                return puzzle.pieces.first { $0.id == pieceId }
            }
        }
        return nil
    }
    
    private func difficultyColor(_ difficulty: PuzzleDifficulty) -> Color {
        switch difficulty {
        case .easy: return .green
        case .medium: return .orange
        case .hard: return .red
        }
    }
}

// MARK: - Drop Zone View
private struct DropZoneView: View {
    let zone: PuzzleLayoutZone
    let placedPiece: PuzzlePiece?
    let onDrop: (String) -> Void
    
    var body: some View {
        VStack(spacing: 8) {
            Text(zone.label)
                .font(.system(size: 12, weight: .bold))
                .foregroundColor(.white.opacity(0.7))
            
            ZStack {
                RoundedRectangle(cornerRadius: 12)
                    .strokeBorder(
                        style: StrokeStyle(lineWidth: 2, dash: placedPiece == nil ? [8] : [])
                    )
                    .foregroundColor(placedPiece != nil ? .brandPrimary : .white.opacity(0.3))
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(placedPiece != nil ? Color.brandPrimary.opacity(0.2) : Color.white.opacity(0.05))
                    )
                
                if let piece = placedPiece {
                    Text(piece.content)
                        .font(.system(size: 13, weight: .medium, design: .monospaced))
                        .foregroundColor(.white)
                        .padding(8)
                        .multilineTextAlignment(.center)
                } else {
                    Image(systemName: "plus")
                        .font(.system(size: 20, weight: .light))
                        .foregroundColor(.white.opacity(0.3))
                }
            }
            .frame(height: 70)
        }
        .onDrop(of: [.text], isTargeted: nil) { providers in
            if let provider = providers.first {
                _ = provider.loadObject(ofClass: String.self) { pieceId, _ in
                    if let pieceId = pieceId {
                        DispatchQueue.main.async {
                            onDrop(pieceId)
                        }
                    }
                }
            }
            return true
        }
    }
}

// MARK: - Draggable Piece View
private struct DraggablePieceView: View {
    let piece: PuzzlePiece
    
    var body: some View {
        Text(piece.content)
            .font(.system(size: 13, weight: .medium, design: pieceFont))
            .foregroundColor(.white)
            .padding(.horizontal, 14)
            .padding(.vertical, 12)
            .frame(maxWidth: .infinity)
            .background(pieceBackground)
            .cornerRadius(12)
            .shadow(color: Color.black.opacity(0.3), radius: 4, x: 0, y: 2)
            .onDrag {
                NSItemProvider(object: piece.id as NSString)
            }
    }
    
    private var pieceFont: Font.Design {
        switch piece.pieceType {
        case .codeSnippet, .mathExpression:
            return .monospaced
        default:
            return .default
        }
    }
    
    private var pieceBackground: some ShapeStyle {
        LinearGradient(
            colors: [pieceColor, pieceColor.opacity(0.7)],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }
    
    private var pieceColor: Color {
        switch piece.pieceType {
        case .codeSnippet: return Color(hex: "3B82F6")
        case .mathExpression: return Color(hex: "8B5CF6")
        case .textSnippet: return Color(hex: "10B981")
        case .diagramNode: return Color(hex: "F59E0B")
        }
    }
}
