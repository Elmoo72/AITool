import Foundation
import SwiftUI

@MainActor
final class AIWritingViewModel: ObservableObject {
    @Published var inputText = ""
    @Published var selectedAction: WritingAction = .improve
    @Published var selectedStyle: WritingStyle = .original
    @Published var selectedLanguage: WritingLanguage = .english
    @Published var resultText: String?
    @Published var isLoading = false
    @Published var errorMessage: String?
    @Published var characterCount = 0

    private let apiClient = APIClient.shared
    private let apphudService = ApphudService.shared
    private let maxCharacters = 400

    nonisolated init() {}

    func updateText(_ text: String) {
        if text.count <= maxCharacters {
            inputText = text
            characterCount = text.count
        }
    }

    func generate() {
        let text = inputText.trimmingCharacters(in: .whitespaces)
        guard !text.isEmpty else { return }

        Task {
            isLoading = true
            defer { isLoading = false }

            do {
                let response = try await apiClient.processWriting(
                    text: text,
                    action: selectedAction,
                    style: selectedStyle,
                    language: selectedLanguage,
                    userID: apphudService.userID
                )
                withAnimation(.easeInOut(duration: 0.3)) {
                    self.resultText = response.resultText
                }
            } catch {
                errorMessage = error.localizedDescription
            }
        }
    }

    func clearResult() {
        resultText = nil
        errorMessage = nil
    }
}
