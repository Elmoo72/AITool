import Foundation

enum WritingAction: String, Codable, CaseIterable {
    case improve = "Improve"
    case rewrite = "Rewrite"
    case grammar = "Fix grammar"
    case shorten = "Shorten"
}

enum WritingStyle: String, Codable, CaseIterable {
    case original = "Original"
    case professional = "Professional"
    case casual = "Casual"
    case creative = "Creative"
}

enum WritingLanguage: String, Codable, CaseIterable {
    case english = "English"
    case spanish = "Spanish"
    case french = "French"
    case german = "German"
    case russian = "Russian"
}

struct WritingResponse: Codable {
    let resultText: String
    enum CodingKeys: String, CodingKey {
        case resultText = "result_text"
    }
}
