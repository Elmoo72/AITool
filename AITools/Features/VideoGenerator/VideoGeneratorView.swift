import SwiftUI
import PhotosUI
import AVKit

@MainActor
struct VideoGeneratorView: View {
    @StateObject private var viewModel = VideoGeneratorViewModel()
    @Environment(\.dismiss) var dismiss
    @EnvironmentObject var apphudService: ApphudService
    @State private var showPaywall = false
    @State private var showResultSheet = false
    @State private var shouldRegenerate = false
    @State private var showFormatPicker = false
    @State private var showQualityPicker = false

    var body: some View {
        ZStack {
            AppColors.background.ignoresSafeArea()

            if let template = viewModel.selectedTemplate {
                templateDetailView(template: template)
                    .transition(.move(edge: .trailing))
            } else {
                galleryView
                    .transition(.move(edge: .leading))
            }
        }
        .animation(.easeInOut(duration: 0.25), value: viewModel.selectedTemplate?.id)
        .navigationBarHidden(true)
        .onAppear {
            if !apphudService.hasActiveSubscription {
                showPaywall = true
            }
        }
        .fullScreenCover(isPresented: $showPaywall) {
            PaywallView(apphudService: apphudService)
                .environmentObject(apphudService)
        }
        .alert("Error", isPresented: Binding(
            get: { viewModel.errorMessage != nil },
            set: { if !$0 { viewModel.errorMessage = nil } }
        )) {
            Button("Retry") {
                viewModel.errorMessage = nil
                viewModel.generateVideo()
            }
            Button("Cancel", role: .cancel) { viewModel.errorMessage = nil }
        } message: {
            Text(viewModel.errorMessage ?? "")
        }
        .fullScreenCover(isPresented: $showResultSheet, onDismiss: {
            if shouldRegenerate {
                shouldRegenerate = false
                viewModel.generateVideo()
            }
        }) {
            if let urlString = viewModel.generatedVideoURL, let url = URL(string: urlString) {
                VideoResultView(
                    videoURL: url,
                    onClose: {
                        shouldRegenerate = false
                        showResultSheet = false
                        viewModel.backToGallery()
                    },
                    onReplace: {
                        shouldRegenerate = true
                        showResultSheet = false
                    }
                )
            }
        }
        .onChange(of: viewModel.generationStatus) { newStatus in
            if case .success = newStatus { showResultSheet = true }
        }
    }

    private var galleryView: some View {
        VStack(spacing: 0) {
            galleryNavBar
            categoryTabs
            templateGrid
        }
    }

    private var galleryNavBar: some View {
        HStack(spacing: 12) {
            Button(action: { dismiss() }) {
                Image("ic_back")
                    .renderingMode(.template)
                    .resizable()
                    .frame(width: 20, height: 20)
                    .foregroundColor(.white)
                    .frame(width: 32, height: 32)
            }

            ZStack {
                Circle()
                    .fill(
                        LinearGradient(
                            colors: [Color(hex: "#E91E8C"), Color(hex: "#7B2FBE")],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 36, height: 36)
                Image(systemName: "person.crop.circle.fill")
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(.white)
            }

            VStack(alignment: .leading, spacing: 1) {
                Text("AI Video")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(AppColors.textPrimary)
                Text(Date().formatted(.dateTime.day().month(.twoDigits).year()))
                    .font(.system(size: 12))
                    .foregroundColor(AppColors.textSecondary)
            }

            Spacer()

            Button(action: { viewModel.reset() }) {
                Image("ic_refresh")
                    .renderingMode(.template)
                    .resizable()
                    .frame(width: 20, height: 20)
                    .foregroundColor(AppColors.textSecondary)
                    .frame(width: 32, height: 32)
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(AppColors.cardBackground)
    }

    private var categoryTabs: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                ForEach(viewModel.categories) { category in
                    Button(action: { viewModel.selectedCategoryId = category.id }) {
                        Text(category.name)
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(
                                viewModel.selectedCategoryId == category.id
                                    ? .white : AppColors.textSecondary
                            )
                            .padding(.horizontal, 16)
                            .padding(.vertical, 8)
                            .background(
                                Group {
                                    if viewModel.selectedCategoryId == category.id {
                                        AppColors.primaryGradient
                                    } else {
                                        Color.clear
                                    }
                                }
                            )
                            .cornerRadius(20)
                    }
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
        }
        .background(AppColors.background)
    }

    private var templateGrid: some View {
        let columns = [GridItem(.flexible(), spacing: 8), GridItem(.flexible(), spacing: 8)]

        return ScrollView(showsIndicators: false) {
            LazyVGrid(columns: columns, spacing: 8) {
                ForEach(viewModel.templates) { template in
                    Button(action: { viewModel.selectTemplate(template) }) {
                        TemplateThumbnail(template: template)
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.horizontal, 16)
            .padding(.bottom, 24)
        }
    }

    private func templateDetailView(template: VideoTemplate) -> some View {
        ZStack {
            VStack(spacing: 0) {
                HStack {
                    Button(action: { viewModel.backToGallery() }) {
                        Image("ic_back")
                            .renderingMode(.template)
                            .resizable()
                            .frame(width: 20, height: 20)
                            .foregroundColor(.white)
                            .frame(width: 32, height: 32)
                    }

                    Spacer()

                    Text(template.name)
                        .font(.system(size: 17, weight: .semibold))
                        .foregroundColor(AppColors.textPrimary)

                    Spacer()

                    Color.clear.frame(width: 32, height: 32)
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 12)

                ScrollView(showsIndicators: false) {
                    VStack(spacing: 0) {
                        templateCarousel(template: template)
                            .padding(.bottom, 20)

                        VStack(spacing: 0) {
                            photoSlotRow
                                .padding(.horizontal, 16)
                                .padding(.bottom, 20)

                            settingsRows
                        }

                        Spacer().frame(height: 100)
                    }
                }

                createButton
            }

            if viewModel.isGenerating {
                generatingOverlay
                    .transition(.opacity)
            }

            if showFormatPicker || showQualityPicker {
                Color.black.opacity(0.55)
                    .ignoresSafeArea()
                    .background(.ultraThinMaterial.opacity(0.2))
                    .transition(.opacity)
                    .onTapGesture {
                        withAnimation(.easeInOut(duration: 0.2)) {
                            showFormatPicker = false
                            showQualityPicker = false
                        }
                    }
            }

            if showFormatPicker {
                pickerContainer(formatPickerPopup)
                    .transition(.opacity.combined(with: .scale(scale: 0.95, anchor: .bottomTrailing)))
            }

            if showQualityPicker {
                pickerContainer(qualityPickerPopup)
                    .transition(.opacity.combined(with: .scale(scale: 0.95, anchor: .bottomTrailing)))
            }
        }
        .animation(.easeInOut(duration: 0.2), value: showFormatPicker)
        .animation(.easeInOut(duration: 0.2), value: showQualityPicker)
        .animation(.easeInOut(duration: 0.3), value: viewModel.isGenerating)
    }

    private func pickerContainer<Content: View>(_ content: Content) -> some View {
        VStack(spacing: 0) {
            Spacer()
            HStack(spacing: 0) {
                Spacer()
                content
                    .padding(.trailing, 16)
            }
        }
        .padding(.bottom, 211)
        .ignoresSafeArea()
    }

    private var generatingOverlay: some View {
        ZStack {
            AppColors.background.ignoresSafeArea()

            VStack(spacing: 16) {
                Image("video_generating_blob")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 260, height: 260)

                Text("Generating…")
                    .font(.system(size: 20, weight: .semibold))
                    .foregroundColor(AppColors.textPrimary)
                    .frame(width: 124, height: 24)

                Text("We're creating the best result for you")
                    .font(.system(size: 16, weight: .regular))
                    .foregroundColor(AppColors.textSecondary)
                    .multilineTextAlignment(.center)
                    .frame(width: 344)

            }
        }
    }

    private func templateCarousel(template: VideoTemplate) -> some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 10) {
                ForEach(0..<3) { i in
                    let isCenter = i == 0
                    let width: CGFloat = isCenter ? 260 : 190
                    let height: CGFloat = isCenter ? 340 : 280

                    ZStack {
                        RoundedRectangle(cornerRadius: 16)
                            .fill(
                                LinearGradient(
                                    colors: isCenter
                                        ? template.colors
                                        : template.colors.map { $0.opacity(0.6) },
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )

                        if isCenter, let photo = viewModel.primaryPhoto {
                            Image(uiImage: photo)
                                .resizable()
                                .scaledToFill()
                                .frame(width: width, height: height)
                                .clipShape(RoundedRectangle(cornerRadius: 16))
                        } else {
                            Image(systemName: "person.fill")
                                .font(.system(size: isCenter ? 60 : 40))
                                .foregroundColor(.white.opacity(0.3))
                        }
                    }
                    .frame(width: width, height: height)
                    .clipShape(RoundedRectangle(cornerRadius: 16))
                }
            }
            .padding(.horizontal, 16)
        }
    }

    private var photoSlotRow: some View {
        HStack(spacing: 12) {
            photoSlot(slot: 1, item: $viewModel.photoItem1, photo: viewModel.selectedPhoto1, isLoading: viewModel.isLoadingPhoto1)
            photoSlot(slot: 2, item: $viewModel.photoItem2, photo: viewModel.selectedPhoto2, isLoading: viewModel.isLoadingPhoto2)
            photoSlot(slot: 3, item: $viewModel.photoItem3, photo: viewModel.selectedPhoto3, isLoading: viewModel.isLoadingPhoto3)
            Spacer()
        }
    }

    private func photoSlot(slot: Int, item: Binding<PhotosPickerItem?>, photo: UIImage?, isLoading: Bool) -> some View {
        ZStack(alignment: .topTrailing) {
            PhotosPicker(selection: item, matching: .images) {
                ZStack {
                    RoundedRectangle(cornerRadius: 12)
                        .fill(AppColors.cardBackground)
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(AppColors.primaryGradient, lineWidth: 1.5)
                        )
                        .frame(width: 72, height: 72)

                    if isLoading {
                        SpinnerView(size: 24)
                    } else if let photo {
                        Image(uiImage: photo)
                            .resizable()
                            .scaledToFill()
                            .frame(width: 72, height: 72)
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                    } else {
                        Image(systemName: "plus")
                            .font(.system(size: 22, weight: .medium))
                            .foregroundColor(AppColors.primaryGradientStart)
                    }
                }
            }
            .onChange(of: item.wrappedValue) { newItem in
                guard let newItem else { return }
                Task { await viewModel.loadPhoto(slot: slot, from: newItem) }
            }

            if photo != nil && !isLoading {
                Button(action: { viewModel.clearPhoto(slot) }) {
                    Image(systemName: "xmark.circle.fill")
                        .font(.system(size: 18))
                        .foregroundColor(.white)
                        .background(Color.black.opacity(0.6), in: Circle())
                }
                .offset(x: 6, y: -6)
            }
        }
    }

    private var settingsRows: some View {
        VStack(spacing: 0) {
            Button(action: {
                withAnimation(.easeInOut(duration: 0.2)) { showFormatPicker.toggle() }
            }) {
                HStack {
                    Text("Format")
                        .font(.system(size: 16))
                        .foregroundColor(AppColors.textSecondary)
                    Spacer()
                    Text(viewModel.format)
                        .font(.system(size: 16))
                        .foregroundColor(AppColors.textPrimary)
                    Image(systemName: "chevron.right")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(AppColors.textSecondary)
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 16)
            }
            .buttonStyle(.plain)

            Divider()
                .background(AppColors.separatorColor)
                .padding(.horizontal, 16)

            Button(action: {
                withAnimation(.easeInOut(duration: 0.2)) { showQualityPicker.toggle() }
            }) {
                HStack {
                    Text("Quality")
                        .font(.system(size: 16))
                        .foregroundColor(AppColors.textSecondary)
                    Spacer()
                    Text(viewModel.quality)
                        .font(.system(size: 16))
                        .foregroundColor(AppColors.textPrimary)
                    Image(systemName: "chevron.right")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(AppColors.textSecondary)
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 16)
            }
            .buttonStyle(.plain)
        }
        .background(AppColors.cardBackground)
    }

    private var qualityPickerPopup: some View {
        let qualities = ["540p", "720p", "1080p", "4K"]
        let gradient = LinearGradient(
            colors: [Color(hex: "#7B8FF5"), Color(hex: "#E91E8C")],
            startPoint: .leading, endPoint: .trailing
        )

        return VStack(spacing: 0) {
            ForEach(Array(qualities.enumerated()), id: \.element) { index, q in
                Button(action: {
                    viewModel.quality = q
                    withAnimation(.easeInOut(duration: 0.2)) { showQualityPicker = false }
                }) {
                    let isSelected = viewModel.quality == q
                    HStack {
                        Text(q)
                            .font(.system(size: 16, weight: .regular))
                            .foregroundStyle(
                                isSelected
                                    ? AnyShapeStyle(gradient)
                                    : AnyShapeStyle(Color.white)
                            )
                        Spacer()
                    }
                    .padding(.horizontal, 20)
                    .frame(height: 44)
                }
                .buttonStyle(.plain)

                if index < qualities.count - 1 {
                    Divider()
                        .background(Color.white.opacity(0.08))
                        .padding(.horizontal, 12)
                }
            }
        }
        .frame(width: 175)
        .background(
            Color(hex: "#1F191F").opacity(0.4)
                .background(.ultraThinMaterial)
        )
        .clipShape(RoundedRectangle(cornerRadius: 24))
        .shadow(color: .black.opacity(0.5), radius: 24, x: 0, y: 8)
    }

    private var formatPickerPopup: some View {
        // (w, h) of the aspect-ratio preview box, all fitting max 36×36
        let formats: [(label: String, w: CGFloat, h: CGFloat)] = [
            ("16:9", 36, 20),
            ("9:16", 20, 36),
            ("1:1",  28, 28),
        ]
        let gradient = LinearGradient(
            colors: [Color(hex: "#7B8FF5"), Color(hex: "#E91E8C")],
            startPoint: .leading, endPoint: .trailing
        )

        return VStack(spacing: 0) {
            ForEach(Array(formats.enumerated()), id: \.element.label) { index, fmt in
                Button(action: {
                    viewModel.format = fmt.label
                    withAnimation(.easeInOut(duration: 0.2)) { showFormatPicker = false }
                }) {
                    let isSelected = viewModel.format == fmt.label
                    HStack(spacing: 8) {
                        Text(fmt.label)
                            .font(.system(size: 16, weight: .regular))
                            .foregroundStyle(
                                isSelected
                                    ? AnyShapeStyle(gradient)
                                    : AnyShapeStyle(Color.white)
                            )
                        RoundedRectangle(cornerRadius: 4)
                            .stroke(
                                isSelected
                                    ? AnyShapeStyle(gradient)
                                    : AnyShapeStyle(Color.white.opacity(0.6)),
                                lineWidth: 1.5
                            )
                            .frame(width: fmt.w, height: fmt.h)
                        Spacer()
                    }
                    .padding(.horizontal, 20)
                    .frame(height: 44)
                }
                .buttonStyle(.plain)

                if index < formats.count - 1 {
                    Divider()
                        .background(Color.white.opacity(0.08))
                        .padding(.horizontal, 12)
                }
            }
        }
        .frame(width: 175)
        .background(
            ZStack {
                Color(hex: "#0B070E")
                Color.white.opacity(0.04)
            }
            .background(.ultraThinMaterial)
        )
        .clipShape(RoundedRectangle(cornerRadius: 24))
        .shadow(color: .black.opacity(0.5), radius: 24, x: 0, y: 8)
    }

    private var createButton: some View {
        VStack(spacing: 0) {
            Divider().background(AppColors.separatorColor)
            Button(action: { viewModel.generateVideo() }) {
                ZStack {
                    RoundedRectangle(cornerRadius: 14)
                        .fill(
                            viewModel.canCreate
                                ? LinearGradient(
                                    colors: [Color(hex: "#7B8FF5"), Color(hex: "#E91E8C")],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                  )
                                : LinearGradient(
                                    colors: [AppColors.cardBackground, AppColors.cardBackground],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                  )
                        )

                    if viewModel.isGenerating {
                        SpinnerView(size: 28)
                    } else {
                        Text("Create")
                            .font(.system(size: 17, weight: .semibold))
                            .foregroundColor(
                                viewModel.canCreate ? .white : AppColors.textSecondary
                            )
                    }
                }
                .frame(height: 54)
            }
            .disabled(!viewModel.canCreate || viewModel.isGenerating)
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
        }
        .background(AppColors.background)
    }
}

private struct TemplateThumbnail: View {
    let template: VideoTemplate

    var body: some View {
        ZStack(alignment: .bottomLeading) {
            Image("template_placeholder")
                .resizable()
                .scaledToFill()
                .overlay(
                    LinearGradient(
                        colors: [.clear, template.colors[1].opacity(0.75)],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )

            Text(template.name)
                .font(.system(size: 13, weight: .semibold))
                .foregroundColor(.white)
                .padding(.horizontal, 10)
                .padding(.bottom, 10)
        }
        .frame(height: 180)
        .clipShape(RoundedRectangle(cornerRadius: 14))
    }
}

private struct VideoResultView: View {
    let videoURL: URL
    let onClose: () -> Void
    let onReplace: () -> Void

    @State private var player: AVPlayer
    @State private var isSaving = false
    @State private var showSavedToast = false
    @State private var saveError: String?

    init(videoURL: URL, onClose: @escaping () -> Void, onReplace: @escaping () -> Void) {
        self.videoURL = videoURL
        self.onClose = onClose
        self.onReplace = onReplace
        _player = State(initialValue: AVPlayer(url: videoURL))
    }

    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()

            VStack(spacing: 0) {
                // Nav bar
                HStack {
                    Button(action: onClose) {
                        Image("ic_back")
                            .renderingMode(.template)
                            .resizable()
                            .frame(width: 20, height: 20)
                            .foregroundColor(.white)
                            .frame(width: 32, height: 32)
                    }

                    Spacer()

                    Text("Result")
                        .font(.system(size: 17, weight: .semibold))
                        .foregroundColor(.white)

                    Spacer()

                    Color.clear.frame(width: 32, height: 32)
                }
                .padding(.horizontal, 16)
                .padding(.top, 12)
                .padding(.bottom, 8)

                // Video preview
                ZStack(alignment: .topTrailing) {
                    VideoPlayer(player: player)
                        .clipShape(RoundedRectangle(cornerRadius: 20))
                        .padding(.horizontal, 16)
                        .onAppear { player.play() }

                    Button(action: onReplace) {
                        HStack(spacing: 4) {
                            Image(systemName: "arrow.triangle.2.circlepath")
                                .font(.system(size: 12, weight: .medium))
                            Text("Replace")
                                .font(.system(size: 13, weight: .medium))
                        }
                        .foregroundColor(.black)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 7)
                        .background(Color.white)
                        .clipShape(Capsule())
                    }
                    .padding(.top, 12)
                    .padding(.trailing, 28)
                }

                Spacer()

                // Bottom buttons
                HStack(spacing: 12) {
                    Button(action: share) {
                        Text("Share")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .frame(height: 54)
                            .background(Color.white.opacity(0.15))
                            .clipShape(RoundedRectangle(cornerRadius: 14))
                    }

                    Button(action: download) {
                        Group {
                            if isSaving {
                                ProgressView().tint(.white)
                            } else {
                                Text("Download")
                                    .font(.system(size: 16, weight: .semibold))
                                    .foregroundColor(.white)
                            }
                        }
                        .frame(maxWidth: .infinity)
                        .frame(height: 54)
                        .background(
                            LinearGradient(
                                colors: [Color(hex: "#7B8FF5"), Color(hex: "#E91E8C")],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .clipShape(RoundedRectangle(cornerRadius: 14))
                    }
                    .disabled(isSaving)
                }
                .padding(.horizontal, 16)
                .padding(.bottom, 40)
            }

            if showSavedToast {
                savedToast
                    .transition(.opacity.combined(with: .scale(scale: 0.95)))
            }
        }
        .animation(.easeInOut(duration: 0.25), value: showSavedToast)
        .alert("Download Failed", isPresented: .init(
            get: { saveError != nil },
            set: { if !$0 { saveError = nil } }
        )) {
            Button("OK") { saveError = nil }
        } message: {
            Text(saveError ?? "")
        }
    }

    private var savedToast: some View {
        VStack(spacing: 8) {
            Image("ic_saved_check")
                .resizable()
                .scaledToFit()
                .frame(width: 40, height: 40)

            Text("Video has been saved\nto your gallery")
                .font(.system(size: 16, weight: .regular))
                .foregroundColor(.white)
                .multilineTextAlignment(.center)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 24)
        .frame(width: 239)
        .background(
            Color(hex: "#1F191F").opacity(0.4)
                .background(.ultraThinMaterial)
        )
        .clipShape(RoundedRectangle(cornerRadius: 24))
    }

    private func share() {
        let activity = UIActivityViewController(activityItems: [videoURL], applicationActivities: nil)
        guard let scene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
              let root = scene.windows.first?.rootViewController else { return }
        var top = root
        while let presented = top.presentedViewController { top = presented }
        top.present(activity, animated: true)
    }

    private func download() {
        isSaving = true
        Task {
            do {
                let (localURL, _) = try await URLSession.shared.download(from: videoURL)
                let destURL = FileManager.default.temporaryDirectory.appendingPathComponent("result.mp4")
                try? FileManager.default.removeItem(at: destURL)
                try FileManager.default.moveItem(at: localURL, to: destURL)
                UISaveVideoAtPathToSavedPhotosAlbum(destURL.path, nil, nil, nil)
                isSaving = false
                showSavedToast = true
                try? await Task.sleep(nanoseconds: 3_000_000_000)
                showSavedToast = false
            } catch {
                isSaving = false
                saveError = error.localizedDescription
            }
        }
    }
}

#Preview {
    NavigationStack {
        VideoGeneratorView()
            .environmentObject(ApphudService.shared)
    }
}
