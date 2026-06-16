import Foundation
import SwiftUI

@MainActor
final class HomeViewModel: ObservableObject {
    @Published var searchText = ""
    @Published var selectedTool: String?

    nonisolated init() {}

    func getTool(by id: String) -> AIToolInfo? {
        switch id {
        case "video":
            return AIToolInfo(
                id: "video",
                title: "Turn Photo into Video",
                subtitle: "Animate • Templates",
                action: "Ready in seconds",
                icon: "sparkles"
            )
        case "writing":
            return AIToolInfo(
                id: "writing",
                title: "Fix & Improve Writing",
                subtitle: "Rewrite • Fix grammar",
                action: nil,
                icon: "wand.and.stars"
            )
        case "summarize":
            return AIToolInfo(
                id: "summarize",
                title: "Understand Faster",
                subtitle: "Summarize • Key points",
                action: nil,
                icon: "book.fill"
            )
        default:
            return nil
        }
    }
}

struct AIToolInfo {
    let id: String
    let title: String
    let subtitle: String
    let action: String?
    let icon: String
}
