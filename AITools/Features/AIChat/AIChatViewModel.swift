import Foundation
import SwiftUI

@MainActor
final class AIChatViewModel: ObservableObject {
    @Published var messages: [ChatMessage] = []
    @Published var inputText = ""
    @Published var isLoading = false
    @Published var errorMessage: String?
    @Published var sessions: [ChatSession] = []

    private let apiClient = APIClient.shared
    private let apphudService = ApphudService.shared
    private let chatID = UUID().uuidString
    private let sessionsKey = "chat_sessions"

    nonisolated init() {}

    func onAppear() {
        loadSessions()
    }

    private let maxMessageLength = 10_000

    func sendMessage() {
        let text = inputText.trimmingCharacters(in: .whitespaces)
        guard !text.isEmpty, text.count <= maxMessageLength else { return }

        inputText = ""

        let userMessage = ChatMessage(text: text, isUser: true)
        messages.append(userMessage)

        Task {
            isLoading = true
            defer { isLoading = false }

            do {
                let response = try await apiClient.sendChatMessage(text, chatID: chatID, userID: apphudService.userID)
                let aiMessage = ChatMessage(text: response.assistantMessage, isUser: false)
                withAnimation(.easeInOut(duration: 0.3)) {
                    self.messages.append(aiMessage)
                }
            } catch {
                errorMessage = error.localizedDescription
                let errorMsg = ChatMessage(
                    text: "Sorry, I encountered an error. Please try again.",
                    isUser: false
                )
                withAnimation(.easeInOut(duration: 0.3)) {
                    self.messages.append(errorMsg)
                }
            }
        }
    }

    func regenerateLastResponse() {
        guard let lastUserMessage = messages.last(where: { $0.isUser })?.text else { return }
        if let lastAI = messages.indices.last(where: { !messages[$0].isUser }) {
            messages.remove(at: lastAI)
        }
        Task {
            isLoading = true
            defer { isLoading = false }
            do {
                let response = try await apiClient.sendChatMessage(lastUserMessage, chatID: chatID, userID: apphudService.userID)
                let aiMessage = ChatMessage(text: response.assistantMessage, isUser: false)
                withAnimation(.easeInOut(duration: 0.3)) {
                    self.messages.append(aiMessage)
                }
            } catch {
                let errorMsg = ChatMessage(text: "Sorry, I encountered an error. Please try again.", isUser: false)
                withAnimation(.easeInOut(duration: 0.3)) {
                    self.messages.append(errorMsg)
                }
            }
        }
    }

    func clearChat() {
        saveCurrentSession()
        messages.removeAll()
        errorMessage = nil
    }

    func loadSession(_ session: ChatSession) {
        saveCurrentSession()
        messages = session.messages
    }

    func deleteSession(_ session: ChatSession) {
        sessions.removeAll { $0.id == session.id }
        saveSessions()
    }

    private func saveCurrentSession() {
        guard !messages.isEmpty else { return }
        let session = ChatSession(messages: messages, createdAt: messages.first?.timestamp ?? Date())
        sessions.insert(session, at: 0)
        saveSessions()
    }

    private func saveSessions() {
        let sessions = self.sessions
        Task.detached(priority: .utility) {
            guard let data = try? JSONEncoder().encode(sessions) else { return }
            let fileURL = FileManager.default
                .urls(for: .documentDirectory, in: .userDomainMask)[0]
                .appendingPathComponent("chat_sessions.json")
            try? data.write(to: fileURL, options: [.atomic, .completeFileProtection])
        }
    }

    private func loadSessions() {
        Task {
            let decoded = await Task.detached(priority: .utility) {
                let fileURL = FileManager.default
                    .urls(for: .documentDirectory, in: .userDomainMask)[0]
                    .appendingPathComponent("chat_sessions.json")
                guard let data = try? Data(contentsOf: fileURL),
                      let decoded = try? JSONDecoder().decode([ChatSession].self, from: data)
                else { return [ChatSession]() }
                return decoded
            }.value
            sessions = decoded
        }
    }
}
