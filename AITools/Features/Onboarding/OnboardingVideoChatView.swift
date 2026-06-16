import SwiftUI

@MainActor
final class OnboardingVideoChatViewModel: ObservableObject {
    @Published var showFirstUserMsg = false
    @Published var showAIReply = false
    @Published var showVideoPrompt = false
    @Published var isTyping = false
    @Published var showVideoCard = false
    @Published var showTryButton = false

    func start() {
        Task {
            try? await Task.sleep(nanoseconds: 700_000_000)
            withAnimation(.easeInOut(duration: 0.3)) { showFirstUserMsg = true }

            try? await Task.sleep(nanoseconds: 400_000_000)
            withAnimation { isTyping = true }
            try? await Task.sleep(nanoseconds: 1_100_000_000)
            withAnimation(.easeInOut(duration: 0.3)) {
                isTyping = false
                showAIReply = true
            }

            try? await Task.sleep(nanoseconds: 600_000_000)
            withAnimation(.easeInOut(duration: 0.3)) { showVideoPrompt = true }

            try? await Task.sleep(nanoseconds: 400_000_000)
            withAnimation { isTyping = true }
            try? await Task.sleep(nanoseconds: 2_000_000_000)
            withAnimation(.easeInOut(duration: 0.3)) {
                isTyping = false
                showVideoCard = true
            }

            try? await Task.sleep(nanoseconds: 600_000_000)
            withAnimation(.easeInOut(duration: 0.4)) { showTryButton = true }
        }
    }
}

struct OnboardingVideoChatView: View {
    @StateObject private var viewModel = OnboardingVideoChatViewModel()
    @AppStorage("onboarding_completed") private var onboardingCompleted = false
    @State private var showPaywall = false

    var body: some View {
        ZStack {
            AppColors.background.ignoresSafeArea()

            VStack(spacing: 0) {
                navBar
                Divider().background(AppColors.separatorColor)
                messagesList
                if viewModel.showTryButton {
                    tryButton
                        .transition(.opacity.combined(with: .move(edge: .bottom)))
                }
            }
        }
        .navigationBarHidden(true)
        .onAppear { viewModel.start() }
        .fullScreenCover(isPresented: $showPaywall) {
            PaywallView(apphudService: ApphudService.shared)
                .environmentObject(ApphudService.shared)
        }
        .onChange(of: showPaywall) { isShowing in
            if !isShowing { onboardingCompleted = true }
        }
    }

    private var navBar: some View {
        HStack(spacing: 12) {
            ZStack {
                Circle()
                    .fill(AppColors.primaryGradient)
                    .frame(width: 36, height: 36)
                Image("ic_generate_b")
                    .resizable()
                    .renderingMode(.template)
                    .foregroundColor(.white)
                    .frame(width: 24, height: 24)
            }

            Text("AI Chat")
                .font(.system(size: 17, weight: .semibold))
                .foregroundColor(AppColors.textPrimary)

            Spacer()
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(AppColors.cardBackground)
    }

    private var messagesList: some View {
        ScrollViewReader { proxy in
            ScrollView(showsIndicators: false) {
                LazyVStack(alignment: .leading, spacing: 12) {
                    if viewModel.showFirstUserMsg {
                        MessageBubble(message: "Hi! I want to create a video", isUser: true)
                            .transition(.opacity.combined(with: .move(edge: .bottom)))
                            .id("msg1")
                    }

                    if viewModel.showAIReply {
                        MessageBubble(message: "Nice! Let me show you how it works", isUser: false)
                            .transition(.opacity.combined(with: .move(edge: .bottom)))
                            .id("msg2")
                    }

                    if viewModel.showVideoPrompt {
                        MessageBubble(
                            message: "Man with a sports car, explosion behind, cinematic, slow motion, realistic, 4K",
                            isUser: true
                        )
                        .transition(.opacity.combined(with: .move(edge: .bottom)))
                        .id("prompt")
                    }

                    if viewModel.isTyping {
                        TypingIndicator()
                            .id("typing")
                            .transition(.opacity)
                    }

                    if viewModel.showVideoCard {
                        videoResultCard
                            .transition(.opacity.combined(with: .move(edge: .bottom)))
                            .id("card")
                    }

                    Color.clear.frame(height: 1).id("bottom")
                }
                .padding(.vertical, 16)
                .animation(.easeInOut(duration: 0.3), value: viewModel.showFirstUserMsg)
                .animation(.easeInOut(duration: 0.3), value: viewModel.showAIReply)
                .animation(.easeInOut(duration: 0.3), value: viewModel.showVideoPrompt)
                .animation(.easeInOut(duration: 0.2), value: viewModel.isTyping)
                .animation(.easeInOut(duration: 0.3), value: viewModel.showVideoCard)
            }
            .onChange(of: viewModel.showFirstUserMsg) { _ in
                withAnimation { proxy.scrollTo("bottom", anchor: .bottom) }
            }
            .onChange(of: viewModel.showAIReply) { _ in
                withAnimation { proxy.scrollTo("bottom", anchor: .bottom) }
            }
            .onChange(of: viewModel.showVideoPrompt) { _ in
                withAnimation { proxy.scrollTo("bottom", anchor: .bottom) }
            }
            .onChange(of: viewModel.isTyping) { _ in
                withAnimation { proxy.scrollTo("bottom", anchor: .bottom) }
            }
            .onChange(of: viewModel.showVideoCard) { _ in
                withAnimation { proxy.scrollTo("bottom", anchor: .bottom) }
            }
            .onChange(of: viewModel.showTryButton) { _ in
                withAnimation { proxy.scrollTo("bottom", anchor: .bottom) }
            }
        }
    }

    private var videoResultCard: some View {
        VStack(alignment: .leading, spacing: 8) {
            ZStack {
                Image("onboarding_video_preview")
                    .resizable()
                    .scaledToFill()
                    .frame(maxWidth: .infinity)
                    .frame(height: 220)
                    .clipped()
                    .cornerRadius(16)

                Circle()
                    .fill(Color.black.opacity(0.5))
                    .frame(width: 52, height: 52)
                    .overlay(
                        Image(systemName: "play.fill")
                            .font(.system(size: 20))
                            .foregroundColor(.white)
                            .offset(x: 2)
                    )
            }
            .padding(.horizontal, 16)

            Text("See how easy that was?\nNow try it yourself")
                .font(.system(size: 15, weight: .semibold))
                .foregroundColor(AppColors.textPrimary)
                .padding(.horizontal, 14)
                .padding(.vertical, 10)
                .background(AppColors.cardBackground)
                .clipShape(VideoRoundedCorner(radius: 18, corners: [.topLeft, .topRight, .bottomRight]))
                .padding(.horizontal, 16)

            Spacer(minLength: 60)
        }
    }

    private var tryButton: some View {
        Button(action: { showPaywall = true }) {
            Text("Try it now")
                .font(.system(size: 17, weight: .semibold))
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .frame(height: 54)
                .background(AppColors.primaryGradient)
                .cornerRadius(27)
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 16)
        .background(AppColors.background)
    }
}

private struct VideoRoundedCorner: Shape {
    var radius: CGFloat
    var corners: UIRectCorner

    func path(in rect: CGRect) -> Path {
        let path = UIBezierPath(
            roundedRect: rect,
            byRoundingCorners: corners,
            cornerRadii: CGSize(width: radius, height: radius)
        )
        return Path(path.cgPath)
    }
}
