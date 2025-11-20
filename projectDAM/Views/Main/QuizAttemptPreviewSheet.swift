import SwiftUI

struct QuizAttemptPreviewSheet: View {
    let quiz: QuizSummary
    let attempt: QuizAttemptSummary
    let onRetake: () -> Void

    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                VStack(alignment: .leading, spacing: 8) {
                    Text(quiz.title)
                        .font(.system(size: 18, weight: .semibold))
                        .multilineTextAlignment(.leading)
                    Text(quiz.description)
                        .font(.system(size: 14))
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.leading)
                }
                .frame(maxWidth: .infinity, alignment: .leading)

                ZStack {
                    Circle()
                        .fill(
                            LinearGradient(
                                colors: [Color.brandPrimary, Color.brandPrimary.opacity(0.7)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 120, height: 120)
                        .shadow(color: Color.brandPrimary.opacity(0.3), radius: 16, x: 0, y: 8)

                    VStack(spacing: 4) {
                        Text("\(attempt.score)%")
                            .font(.system(size: 32, weight: .black))
                            .foregroundColor(.white)
                        Text("Last score")
                            .font(.system(size: 13, weight: .semibold))
                            .foregroundColor(.white.opacity(0.9))
                    }
                }
                .padding(.top, 8)

                Text("You already took this quiz. You can review your score or retake it to try for a better result.")
                    .font(.system(size: 14))
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 8)

                Spacer()

                VStack(spacing: 10) {
                    Button {
                        dismiss()
                        onRetake()
                    } label: {
                        HStack {
                            Text("Retake Quiz")
                                .font(.system(size: 16, weight: .semibold))
                            Spacer()
                            Image(systemName: "arrow.clockwise")
                                .font(.system(size: 16, weight: .semibold))
                        }
                        .foregroundColor(.white)
                        .padding(.vertical, 12)
                        .padding(.horizontal, 16)
                        .background(Color.brandPrimary)
                        .cornerRadius(18)
                    }

                    Button {
                        dismiss()
                    } label: {
                        Text("Close")
                            .font(.system(size: 15, weight: .semibold))
                            .foregroundColor(.secondary)
                    }
                }
            }
            .padding(20)
            .background(Color(.systemGroupedBackground).ignoresSafeArea())
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Close") { dismiss() }
                }
            }
        }
    }
}
