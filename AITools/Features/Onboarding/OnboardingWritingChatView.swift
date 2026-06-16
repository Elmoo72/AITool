import SwiftUI

@MainActor
final class OnboardingWritingChatViewModel: ObservableObject {
    @Published var showFirstUserMsg = false
    @Published var showAIReply = false
    @Published var showWritingPrompt = false
    @Published var isTyping = false
    @Published var showResponseCard = false
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
            withAnimation(.easeInOut(duration: 0.3)) { showWritingPrompt = true }

            try? await Task.sleep(nanoseconds: 400_000_000)
            withAnimation { isTyping = true }
            try? await Task.sleep(nanoseconds: 1_800_000_000)
            withAnimation(.easeInOut(duration: 0.3)) {
                isTyping = false
                showResponseCard = true
            }

            try? await Task.sleep(nanoseconds: 600_000_000)
            withAnimation(.easeInOut(duration: 0.4)) { showTryButton = true }
        }
    }
}

struct OnboardingWritingChatView: View {
    @StateObject private var viewModel = OnboardingWritingChatViewModel()
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
                        MessageBubble(message: "Hi! I want to fix and improve my text", isUser: true)
                            .transition(.opacity.combined(with: .move(edge: .bottom)))
                            .id("msg1")
                    }

                    if viewModel.showAIReply {
                        MessageBubble(message: "Nice! Let me show you how it works", isUser: false)
                            .transition(.opacity.combined(with: .move(edge: .bottom)))
                            .id("msg2")
                    }

                    if viewModel.showWritingPrompt {
                        writingPromptBubble
                            .transition(.opacity.combined(with: .move(edge: .bottom)))
                            .id("prompt")
                    }

                    if viewModel.isTyping {
                        TypingIndicator()
                            .id("typing")
                            .transition(.opacity)
                    }

                    if viewModel.showResponseCard {
                        responseCard
                            .transition(.opacity.combined(with: .move(edge: .bottom)))
                            .id("card")
                    }

                    Color.clear.frame(height: 1).id("bottom")
                }
                .padding(.vertical, 16)
                .animation(.easeInOut(duration: 0.3), value: viewModel.showFirstUserMsg)
                .animation(.easeInOut(duration: 0.3), value: viewModel.showAIReply)
                .animation(.easeInOut(duration: 0.3), value: viewModel.showWritingPrompt)
                .animation(.easeInOut(duration: 0.2), value: viewModel.isTyping)
                .animation(.easeInOut(duration: 0.3), value: viewModel.showResponseCard)
            }
            .onChange(of: viewModel.showFirstUserMsg) { _ in
                withAnimation { proxy.scrollTo("bottom", anchor: .bottom) }
            }
            .onChange(of: viewModel.showAIReply) { _ in
                withAnimation { proxy.scrollTo("bottom", anchor: .bottom) }
            }
            .onChange(of: viewModel.showWritingPrompt) { _ in
                withAnimation { proxy.scrollTo("bottom", anchor: .bottom) }
            }
            .onChange(of: viewModel.isTyping) { _ in
                withAnimation { proxy.scrollTo("bottom", anchor: .bottom) }
            }
            .onChange(of: viewModel.showResponseCard) { _ in
                withAnimation { proxy.scrollTo("bottom", anchor: .bottom) }
            }
            .onChange(of: viewModel.showTryButton) { _ in
                withAnimation { proxy.scrollTo("bottom", anchor: .bottom) }
            }
        }
    }

    private var writingPromptBubble: some View {
        HStack(alignment: .bottom, spacing: 8) {
            Spacer(minLength: 60)
            VStack(alignment: .leading, spacing: 6) {
                Text("Rewrite this message to sound more professional")
                    .font(.system(size: 15, weight: .bold))
                    .foregroundColor(.white)

                Text("hey, can you send me the report asap? i kinda need it now because i have a meeting soon and don't really have time to wait, so please send it as fast as you can")
                    .font(.system(size: 14, weight: .regular))
                    .foregroundColor(.white.opacity(0.9))
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 12)
            .background(AppColors.primaryGradient)
            .cornerRadius(18)
            .cornerRadius(4, corners: .bottomRight)
        }
        .padding(.horizontal, 16)
        .transition(.opacity.combined(with: .move(edge: .bottom)))
    }

    private var responseCard: some View {
        VStack(alignment: .leading, spacing: 8) {
            VStack(alignment: .leading, spacing: 10) {
                Text("Here's your improved version")
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundColor(AppColors.textPrimary)

                Text("Hi, could you please share the report at your earliest convenience?\nI have a meeting coming up and would really appreciate it.")
                    .font(.system(size: 14))
                    .foregroundColor(AppColors.textPrimary)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .padding(16)
            .background(AppColors.cardBackground)
            .clipShape(WritingRoundedCorner(radius: 18, corners: [.topLeft, .topRight, .bottomRight]))

            Text("See how easy that was?\nNow try it yourself")
                .font(.system(size: 15, weight: .semibold))
                .foregroundColor(AppColors.textPrimary)
                .padding(.horizontal, 14)
                .padding(.vertical, 10)
                .background(AppColors.cardBackground)
                .clipShape(WritingRoundedCorner(radius: 18, corners: [.topLeft, .topRight, .bottomRight]))

            Spacer(minLength: 60)
        }
        .padding(.horizontal, 16)
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

private extension View {
    func cornerRadius(_ radius: CGFloat, corners: UIRectCorner) -> some View {
        clipShape(WritingRoundedCorner(radius: radius, corners: corners))
    }
}

private struct WritingRoundedCorner: Shape {
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
