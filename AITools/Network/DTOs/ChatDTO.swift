import Foundation

struct ChatMessage: Identifiable, Codable {
    let id: UUID
    let text: String
    let isUser: Bool
    let timestamp: Date

    init(text: String, isUser: Bool) {
        self.id = UUID()
        self.text = text
        self.isUser = isUser
        self.timestamp = Date()
    }

    enum CodingKeys: String, CodingKey {
        case id, text, isUser, timestamp
    }
}

struct ChatSession: Identifiable, Codable {
    var id = UUID()
    var messages: [ChatMessage]
    var createdAt: Date

    var preview: String {
        String((messages.last?.text ?? "").prefix(60))
    }
}
