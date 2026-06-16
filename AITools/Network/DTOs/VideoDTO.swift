import Foundation

enum VideoGenerationStatus: Equatable {
    case idle
    case loading
    case success(videoURL: String)
    case error(String)
}
