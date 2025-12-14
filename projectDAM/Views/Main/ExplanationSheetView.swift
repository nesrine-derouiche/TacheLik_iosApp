import SwiftUI

struct ExplanationSheetView: View {
    @ObservedObject var viewModel: QuizResultViewModel
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                // Header
                HStack(spacing: 12) {
                    Image(systemName: "sparkles")
                        .font(.system(size: 28))
                        .foregroundColor(Color(hex: "8B5CF6"))
                    
                    Text("AI Explanation")
                        .font(.title2)
                        .fontWeight(.bold)
                }
                .padding(.top)
                
                // Loading State
                if viewModel.isLoadingExplanation {
                    VStack(spacing: 16) {
                        ProgressView()
                            .scaleEffect(1.5)
                            .tint(Color(hex: "8B5CF6"))
                        
                        Text("AI is analyzing your mistakes...")
                            .font(.subheadline)
                            .foregroundColor(.gray)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 40)
                }
                
                // Error State
                if let error = viewModel.explanationError {
                    HStack(spacing: 12) {
                        Image(systemName: "exclamationmark.triangle.fill")
                            .foregroundColor(.red)
                        
                        Text(error)
                            .font(.subheadline)
                            .foregroundColor(.red)
                    }
                    .padding()
                    .background(Color.red.opacity(0.1))
                    .cornerRadius(12)
                }
                
                // Success State
                if let explanation = viewModel.explanation {
                    // Overall Feedback
                    if let feedback = explanation.explanation {
                        VStack(alignment: .leading, spacing: 8) {
                            HStack(spacing: 8) {
                                Image(systemName: "lightbulb.fill")
                                    .foregroundColor(Color(hex: "8B5CF6"))
                                
                                Text("Overall Feedback")
                                    .font(.headline)
                                    .foregroundColor(Color(hex: "8B5CF6"))
                            }
                            
                            Text(feedback)
                                .font(.subheadline)
                                .foregroundColor(.primary)
                        }
                        .padding(20)
                        .background(Color(hex: "F3E8FF"))
                        .cornerRadius(16)
                    }
                    
                    // Mistakes
                    if let mistakes = explanation.mistakes {
                        ForEach(mistakes) { mistake in
                            MistakeCardView(mistake: mistake)
                        }
                    }
                }
                
                Spacer(minLength: 40)
            }
            .padding(.horizontal, 24)
        }
    }
}

// MARK: - Mistake Card View
struct MistakeCardView: View {
    let mistake: MistakeExplanation
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Question
            Text(mistake.questionText)
                .font(.headline)
                .foregroundColor(.primary)
            
            Divider()
            
            // Your Answer
            VStack(alignment: .leading, spacing: 4) {
                Text("Your Answer:")
                    .font(.caption)
                    .foregroundColor(.gray)
                
                Text(mistake.yourAnswer)
                    .font(.subheadline)
                    .foregroundColor(.red)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
                    .background(Color.red.opacity(0.1))
                    .cornerRadius(8)
            }
            
            // Correct Answer
            VStack(alignment: .leading, spacing: 4) {
                Text("Correct Answer:")
                    .font(.caption)
                    .foregroundColor(.gray)
                
                Text(mistake.correctAnswer)
                    .font(.subheadline)
                    .foregroundColor(.green)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
                    .background(Color.green.opacity(0.1))
                    .cornerRadius(8)
            }
            
            // Explanation
            VStack(alignment: .leading, spacing: 4) {
                Text("Explanation:")
                    .font(.caption)
                    .foregroundColor(.gray)
                
                Text(mistake.explanation)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
        }
        .padding(20)
        .background(Color(.systemBackground))
        .cornerRadius(16)
        .shadow(color: .black.opacity(0.05), radius: 2, x: 0, y: 1)
    }
}
