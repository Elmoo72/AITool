import SwiftUI

@MainActor
final class OnboardingUnderstandChatViewModel: ObservableObject {
    @Published var showFirstUserMsg = false
    @Published var showAIReply = false
    @Published var showSummarizePrompt = false
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
            withAnimation(.easeInOut(duration: 0.3)) { showSummarizePrompt = true }

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

struct OnboardingUnderstandChatView: View {
    @StateObject private var viewModel = OnboardingUnderstandChatViewModel()
    @AppStorage("onboarding_completed") private var onboardingCompleted = false
    @State private var showPaywall = false

    private let keyPoints = [
        "Prioritize your tasks",
        "Communicate clearly with the team",
        "Solve issues early to avoid delays"
    ]

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
                        MessageBubble(message: "Hi! I want to understand this text faster", isUser: true)
                            .transition(.opacity.combined(with: .move(edge: .bottom)))
                            .id("msg1")
                    }

                    if viewModel.showAIReply {
                        MessageBubble(message: "Nice! Let me show you how it works", isUser: false)
                            .transition(.opacity.combined(with: .move(edge: .bottom)))
                            .id("msg2")
                    }

                    if viewModel.showSummarizePrompt {
                        summarizePromptBubble
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
                .animation(.easeInOut(duration: 0.3), value: viewModel.showSummarizePrompt)
                .animation(.easeInOut(duration: 0.2), value: viewModel.isTyping)
                .animation(.easeInOut(duration: 0.3), value: viewModel.showResponseCard)
            }
            .onChange(of: viewModel.showFirstUserMsg) { _ in
                withAnimation { proxy.scrollTo("bottom", anchor: .bottom) }
            }
            .onChange(of: viewModel.showAIReply) { _ in
                withAnimation { proxy.scrollTo("bottom", anchor: .bottom) }
            }
            .onChange(of: viewModel.showSummarizePrompt) { _ in
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

    private var summarizePromptBubble: some View {
        HStack(alignment: .bottom, spacing: 8) {
            Spacer(minLength: 60)
            VStack(alignment: .leading, spacing: 6) {
                Text("Summarize this into key points")
                    .font(.system(size: 15, weight: .bold))
                    .foregroundColor(.white)

                Text("In order to improve overall productivity and ensure successful project delivery, it is essential for all team members to prioritize their tasks effectively, maintain clear and consistent communication, and proactively address any emerging issues. Failure to do so may result in delays, misalignment between teams, and reduced efficiency across the workflow.")
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
    }

    private var responseCard: some View {
        VStack(alignment: .leading, spacing: 8) {
            VStack(alignment: .leading, spacing: 12) {
                Text("Here are the key points")
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundColor(AppColors.textPrimary)

                VStack(alignment: .leading, spacing: 10) {
                    ForEach(Array(keyPoints.enumerated()), id: \.offset) { index, point in
                        HStack(alignment: .top, spacing: 12) {
                            Text("\(index + 1)")
                                .font(.system(size: 13, weight: .medium))
                                .foregroundColor(AppColors.textSecondary)
                                .frame(width: 16, alignment: .leading)
                            Text(point)
                                .font(.system(size: 14))
                                .foregroundColor(AppColors.textPrimary)
                        }
                    }
                }
            }
            .padding(16)
            .background(AppColors.cardBackground)
            .clipShape(UnderstandRoundedCorner(radius: 18, corners: [.topLeft, .topRight, .bottomRight]))

            Text("See how easy that was?\nNow try it yourself")
                .font(.system(size: 15, weight: .semibold))
                .foregroundColor(AppColors.textPrimary)
                .padding(.horizontal, 14)
                .padding(.vertical, 10)
                .background(AppColors.cardBackground)
                .clipShape(UnderstandRoundedCorner(radius: 18, corners: [.topLeft, .topRight, .bottomRight]))

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
        clipShape(UnderstandRoundedCorner(radius: radius, corners: corners))
    }
}

private struct UnderstandRoundedCorner: Shape {
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
