import Foundation

enum APIError: LocalizedError {
    case invalidURL
    case invalidResponse(statusCode: Int)
    case decodingError
    case networkError(Error)
    case unauthorized

    var errorDescription: String? {
        switch self {
        case .invalidURL: return "Invalid URL"
        case .invalidResponse(let code): return "Server error (\(code))"
        case .decodingError: return "Failed to decode response"
        case .networkError(let e): return e.localizedDescription
        case .unauthorized: return "Authentication failed"
        }
    }
}

private struct MessageBody: Encodable { let message: String }

private struct WritingBody: Encodable {
    let text: String
    let improve: Bool
    let rewrite: Bool
    let fixGrammar: Bool
    let shorten: Bool
    let translateTo: String?
    let style: String?
    enum CodingKeys: String, CodingKey {
        case text
        case improve, rewrite, shorten
        case fixGrammar = "fix_grammar"
        case translateTo = "translate_to"
        case style
    }
}

struct DolaMessageResponse: Decodable {
    let assistantMessage: String
    enum CodingKeys: String, CodingKey {
        case assistantMessage = "assistant_message"
    }
}

struct PixverseVideoCreated: Decodable {
    let videoId: Int
    enum CodingKeys: String, CodingKey { case videoId = "video_id" }
}

struct PixverseStatusResponse: Decodable {
    let status: String
    let videoUrl: String?
    enum CodingKeys: String, CodingKey {
        case status
        case videoUrl = "video_url"
    }
}

struct PixverseTemplate: Decodable, Identifiable {
    let id: Int
    let name: String
}

actor APIClient {
    static let shared = APIClient()

    private let baseURL: URL = {
        guard let url = URL(string: APIConfig.baseURL) else {
            preconditionFailure("baseURL is malformed")
        }
        return url
    }()

    private let session: URLSession

    init(session: URLSession = .shared) {
        self.session = session
    }

    // MARK: - Chat (Dola)

    func sendChatMessage(_ message: String, chatID: String, userID: String) async throws -> DolaMessageResponse {
        guard var components = URLComponents(
            url: baseURL.appendingPathComponent("dola/chats/\(chatID)/messages"),
            resolvingAgainstBaseURL: true
        ) else { throw APIError.invalidURL }
        components.queryItems = [
            URLQueryItem(name: "user_id", value: userID),
            URLQueryItem(name: "app_id", value: APIConfig.appID)
        ]
        guard let url = components.url else { throw APIError.invalidURL }
        return try await performJSON(method: "POST", url: url, body: MessageBody(message: message), responseType: DolaMessageResponse.self)
    }

    // MARK: - Writing (Dola)

    func processWriting(
        text: String,
        action: WritingAction,
        style: WritingStyle,
        language: WritingLanguage,
        userID: String
    ) async throws -> WritingResponse {
        guard var components = URLComponents(
            url: baseURL.appendingPathComponent("ai-writing"),
            resolvingAgainstBaseURL: true
        ) else { throw APIError.invalidURL }
        components.queryItems = [
            URLQueryItem(name: "user_id", value: userID),
            URLQueryItem(name: "app_id", value: APIConfig.appID)
        ]
        guard let url = components.url else { throw APIError.invalidURL }

        let body = WritingBody(
            text: text,
            improve: action == .improve,
            rewrite: action == .rewrite,
            fixGrammar: action == .grammar,
            shorten: action == .shorten,
            translateTo: language == .english ? nil : language.rawValue,
            style: style == .original ? nil : style.rawValue
        )
        return try await performJSON(method: "POST", url: url, body: body, responseType: WritingResponse.self)
    }

    // MARK: - Video (Pixverse)

    func createVideo(imageData: Data, templateID: Int, userID: String) async throws -> PixverseVideoCreated {
        guard var components = URLComponents(
            url: baseURL.appendingPathComponent("pixverse/api/v1/template2video"),
            resolvingAgainstBaseURL: true
        ) else { throw APIError.invalidURL }
        components.queryItems = [
            URLQueryItem(name: "user_id", value: userID),
            URLQueryItem(name: "app_id", value: APIConfig.appID)
        ]
        guard let url = components.url else { throw APIError.invalidURL }

        let boundary = UUID().uuidString
        var body = Data()
        try body.appendUTF8("--\(boundary)\r\n")
        try body.appendUTF8("Content-Disposition: form-data; name=\"image\"; filename=\"photo.jpg\"\r\n")
        try body.appendUTF8("Content-Type: image/jpeg\r\n\r\n")
        body.append(imageData)
        try body.appendUTF8("\r\n")
        try body.appendUTF8("--\(boundary)\r\n")
        try body.appendUTF8("Content-Disposition: form-data; name=\"template_id\"\r\n\r\n")
        try body.appendUTF8("\(templateID)\r\n")
        try body.appendUTF8("--\(boundary)\r\n")
        try body.appendUTF8("Content-Disposition: form-data; name=\"quality\"\r\n\r\n")
        try body.appendUTF8("1080p\r\n")
        try body.appendUTF8("--\(boundary)--\r\n")

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("multipart/form-data; boundary=\(boundary)", forHTTPHeaderField: "Content-Type")
        request.setValue("Bearer \(APIConfig.bearerToken)", forHTTPHeaderField: "Authorization")
        request.httpBody = body

        return try await perform(request: request, responseType: PixverseVideoCreated.self)
    }

    func videoStatus(videoID: Int, userID: String) async throws -> PixverseStatusResponse {
        guard var components = URLComponents(
            url: baseURL.appendingPathComponent("pixverse/api/v1/status"),
            resolvingAgainstBaseURL: true
        ) else { throw APIError.invalidURL }
        components.queryItems = [
            URLQueryItem(name: "id", value: "\(videoID)"),
            URLQueryItem(name: "user_id", value: userID),
            URLQueryItem(name: "app_id", value: APIConfig.appID)
        ]
        guard let url = components.url else { throw APIError.invalidURL }
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.setValue("Bearer \(APIConfig.bearerToken)", forHTTPHeaderField: "Authorization")
        return try await perform(request: request, responseType: PixverseStatusResponse.self)
    }

    func fetchTemplates() async throws -> [PixverseTemplate] {
        let url = baseURL.appendingPathComponent("pixverse/api/v1/get_templates/\(APIConfig.appID)")
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.setValue("Bearer \(APIConfig.bearerToken)", forHTTPHeaderField: "Authorization")
        return try await perform(request: request, responseType: [PixverseTemplate].self)
    }

    // MARK: - Private

    private func performJSON<Body: Encodable, Response: Decodable>(
        method: String,
        url: URL,
        body: Body,
        responseType: Response.Type
    ) async throws -> Response {
        var request = URLRequest(url: url)
        request.httpMethod = method
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("Bearer \(APIConfig.bearerToken)", forHTTPHeaderField: "Authorization")
        request.httpBody = try JSONEncoder().encode(body)
        return try await perform(request: request, responseType: responseType)
    }

    private func perform<Response: Decodable>(
        request: URLRequest,
        responseType: Response.Type
    ) async throws -> Response {
        do {
            let (data, response) = try await session.data(for: request)
            guard let http = response as? HTTPURLResponse else { throw APIError.invalidResponse(statusCode: 0) }
            if http.statusCode == 401 { throw APIError.unauthorized }
            guard (200...299).contains(http.statusCode) else {
                throw APIError.invalidResponse(statusCode: http.statusCode)
            }
            return try JSONDecoder().decode(responseType, from: data)
        } catch let error as APIError {
            throw error
        } catch is DecodingError {
            throw APIError.decodingError
        } catch {
            throw APIError.networkError(error)
        }
    }
}

private extension Data {
    mutating func appendUTF8(_ string: String) throws {
        guard let data = string.data(using: .utf8) else {
            throw APIError.invalidURL
        }
        append(data)
    }
}
