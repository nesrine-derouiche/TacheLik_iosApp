import Foundation

struct GameQuestion: Identifiable {
    let id = UUID()
    let questionText: String
    let options: [String] // Should be exactly 3 options
    let correctOptionIndex: Int
}

class GameQuestionProvider {
    static let shared = GameQuestionProvider()
    
    private let sampleQuestions: [GameQuestion] = [
        GameQuestion(
            questionText: "Which method sets the title of a UIButton?",
            options: ["button.setTitle", "button.text", "button.label"],
            correctOptionIndex: 0
        ),
        GameQuestion(
            questionText: "How do you add a subview in UIKit?",
            options: ["view.append", "view.addSubview", "view.insert"],
            correctOptionIndex: 1
        ),
        GameQuestion(
            questionText: "Swift loop syntax?",
            options: ["loop i in 0..5", "for i in 0..<5", "repeat i to 5"],
            correctOptionIndex: 1
        ),
        GameQuestion(
            questionText: "Declare a constant in Swift?",
            options: ["var", "const", "let"],
            correctOptionIndex: 2
        ),
        GameQuestion(
            questionText: "Python function def?",
            options: ["func myFunc():", "def myFunc():", "function myFunc():"],
            correctOptionIndex: 1
        ),
        GameQuestion(
            questionText: "Derivative of x²?",
            options: ["x", "2x", "x²"],
            correctOptionIndex: 1
        ),
        GameQuestion(
            questionText: "Integral of 2x?",
            options: ["x²", "2x²", "x"],
            correctOptionIndex: 0
        ),
        GameQuestion(
            questionText: "Boolean True in Python?",
            options: ["true", "True", "TRUE"],
            correctOptionIndex: 1
        )
    ]
    
    func getRandomQuestion() -> GameQuestion {
        return sampleQuestions.randomElement()!
    }
}
