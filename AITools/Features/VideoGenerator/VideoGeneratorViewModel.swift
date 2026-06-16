import Foundation
import SwiftUI
import PhotosUI

struct VideoCategory: Identifiable {
    let id: String
    let name: String
}

struct VideoTemplate: Identifiable {
    let id: String
    let apiTemplateID: Int
    let name: String
    let colors: [Color]

    static let mockData: [VideoTemplate] = [
        VideoTemplate(id: "clay", apiTemplateID: 1, name: "Clay Fool",
                      colors: [Color(hex: "#3D1A6B"), Color(hex: "#1A0A3D")]),
        VideoTemplate(id: "neon", apiTemplateID: 2, name: "Neon Dreams",
                      colors: [Color(hex: "#0A2A5D"), Color(hex: "#0A1030")]),
        VideoTemplate(id: "retro", apiTemplateID: 3, name: "Retro Wave",
                      colors: [Color(hex: "#5D1A3D"), Color(hex: "#2D0A1A")]),
        VideoTemplate(id: "future", apiTemplateID: 4, name: "Future City",
                      colors: [Color(hex: "#1A3D5D"), Color(hex: "#0A1A2D")]),
        VideoTemplate(id: "fantasy", apiTemplateID: 5, name: "Fantasy Land",
                      colors: [Color(hex: "#2D5D1A"), Color(hex: "#0A2D0A")]),
        VideoTemplate(id: "dark", apiTemplateID: 6, name: "Dark Matter",
                      colors: [Color(hex: "#3D1A1A"), Color(hex: "#1A0A0A")]),
    ]
}

@MainActor
final class VideoGeneratorViewModel: ObservableObject {
    @Published var selectedCategoryId = "popular"
    let categories: [VideoCategory] = [
        VideoCategory(id: "popular", name: "Popular"),
        VideoCategory(id: "funny", name: "Funny"),
        VideoCategory(id: "sad", name: "Sad"),
        VideoCategory(id: "trends", name: "Trends"),
        VideoCategory(id: "dark", name: "Dark"),
    ]
    let templates = VideoTemplate.mockData

    @Published var selectedTemplate: VideoTemplate? = nil

    // Photo slots
    @Published var photoItem1: PhotosPickerItem? = nil
    @Published var photoItem2: PhotosPickerItem? = nil
    @Published var photoItem3: PhotosPickerItem? = nil
    @Published var selectedPhoto1: UIImage? = nil
    @Published var selectedPhoto2: UIImage? = nil
    @Published var selectedPhoto3: UIImage? = nil
    @Published var isLoadingPhoto1 = false
    @Published var isLoadingPhoto2 = false
    @Published var isLoadingPhoto3 = false

    @Published var format = "16:9"
    @Published var quality = "1080p"

    @Published var isGenerating = false
    @Published var errorMessage: String? = nil
    @Published var generationStatus: VideoGenerationStatus = .idle
    @Published var generatedVideoURL: String? = nil
    @Published var elapsedSeconds = 0

    private var timerTask: Task<Void, Never>?
    private let apiClient = APIClient.shared
    private let apphudService = ApphudService.shared

    nonisolated init() {}

    nonisolated deinit {
        timerTask?.cancel()
    }

    var primaryPhoto: UIImage? { selectedPhoto1 ?? selectedPhoto2 ?? selectedPhoto3 }
    var canCreate: Bool { primaryPhoto != nil && !isLoadingPhoto1 && !isLoadingPhoto2 && !isLoadingPhoto3 }

    func selectTemplate(_ template: VideoTemplate) {
        selectedTemplate = template
        clearAllPhotos()
    }

    func clearPhoto(_ slot: Int) {
        switch slot {
        case 1: selectedPhoto1 = nil; photoItem1 = nil
        case 2: selectedPhoto2 = nil; photoItem2 = nil
        case 3: selectedPhoto3 = nil; photoItem3 = nil
        default: break
        }
    }

    private func clearAllPhotos() {
        selectedPhoto1 = nil; photoItem1 = nil
        selectedPhoto2 = nil; photoItem2 = nil
        selectedPhoto3 = nil; photoItem3 = nil
    }

    func backToGallery() {
        selectedTemplate = nil
        clearAllPhotos()
        isGenerating = false
        stopTimer()
    }

    func reset() {
        backToGallery()
        selectedCategoryId = "popular"
    }

    func generateVideo() {
        guard canCreate, let photo = primaryPhoto, let template = selectedTemplate else { return }
        guard let imageData = photo.jpegData(compressionQuality: 0.8) else { return }

        timerTask?.cancel()
        elapsedSeconds = 0

        Task {
            isGenerating = true
            generationStatus = .loading
            startTimer()
            defer {
                isGenerating = false
                stopTimer()
            }

            do {
                let userID = apphudService.userID
                let created = try await apiClient.createVideo(
                    imageData: imageData,
                    templateID: template.apiTemplateID,
                    userID: userID
                )

                var statusResponse: PixverseStatusResponse
                var attempts = 0
                let maxAttempts = 40 // 2 minutes max

                repeat {
                    try await Task.sleep(nanoseconds: 3_000_000_000)
                    statusResponse = try await apiClient.videoStatus(
                        videoID: created.videoId,
                        userID: userID
                    )
                    attempts += 1
                } while (statusResponse.status == "processing" || statusResponse.status == "queued" || statusResponse.status == "pending") && attempts < maxAttempts

                if statusResponse.status == "completed", let url = statusResponse.videoUrl {
                    generationStatus = .success(videoURL: url)
                    generatedVideoURL = url
                } else if attempts >= maxAttempts {
                    generationStatus = .error("Generation timed out. Please try again.")
                    errorMessage = "Generation timed out. Please try again."
                } else {
                    generationStatus = .error("Generation failed: \(statusResponse.status)")
                    errorMessage = "Generation failed: \(statusResponse.status)"
                }
            } catch {
                generationStatus = .error(error.localizedDescription)
                errorMessage = error.localizedDescription
            }
        }
    }

    func loadPhoto(slot: Int, from item: PhotosPickerItem) async {
        setLoading(slot, true)
        if let data = try? await item.loadTransferable(type: Data.self),
           data.count < 20_000_000,
           let image = UIImage(data: data) {
            setPhoto(slot, image)
        }
        setLoading(slot, false)
    }

    private func setLoading(_ slot: Int, _ value: Bool) {
        switch slot {
        case 1: isLoadingPhoto1 = value
        case 2: isLoadingPhoto2 = value
        case 3: isLoadingPhoto3 = value
        default: break
        }
    }

    private func setPhoto(_ slot: Int, _ image: UIImage) {
        switch slot {
        case 1: selectedPhoto1 = image
        case 2: selectedPhoto2 = image
        case 3: selectedPhoto3 = image
        default: break
        }
    }

    private func startTimer() {
        timerTask = Task {
            while !Task.isCancelled {
                try? await Task.sleep(nanoseconds: 1_000_000_000)
                if !Task.isCancelled { elapsedSeconds += 1 }
            }
        }
    }

    private func stopTimer() {
        timerTask?.cancel()
        timerTask = nil
    }
}
