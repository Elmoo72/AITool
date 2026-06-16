import SwiftUI

struct OnboardingDemoMessage: Identifiable {
    let id = UUID()
    let text: String
    let isUser: Bool
}

@MainActor
final class OnboardingAIChatViewModel: ObservableObject {
    @Published var messages: [OnboardingDemoMessage] = []
    @Published var isTyping = false
    @Published var showResponseCard = false
    @Published var showTryButton = false

    func start() {
        Task {
            try? await Task.sleep(nanoseconds: 700_000_000)
            withAnimation(.easeInOut(duration: 0.3)) {
                messages.append(OnboardingDemoMessage(text: "Hi! I'd like to chat with AI and ask anything", isUser: true))
            }

            try? await Task.sleep(nanoseconds: 400_000_000)
            withAnimation { isTyping = true }
            try? await Task.sleep(nanoseconds: 1_100_000_000)
            withAnimation(.easeInOut(duration: 0.3)) {
                isTyping = false
                messages.append(OnboardingDemoMessage(text: "Nice! Let me show you how it works", isUser: false))
            }

            try? await Task.sleep(nanoseconds: 600_000_000)
            withAnimation(.easeInOut(duration: 0.3)) {
                messages.append(OnboardingDemoMessage(text: "Give me 5 ideas for a birthday surprise", isUser: true))
            }

            try? await Task.sleep(nanoseconds: 400_000_000)
            withAnimation { isTyping = true }
            try? await Task.sleep(nanoseconds: 1_800_000_000)
            withAnimation(.easeInOut(duration: 0.3)) {
                isTyping = false
                showResponseCard = true
            }

            try? await Task.sleep(nanoseconds: 600_000_000)
            withAnimation(.easeInOut(duration: 0.4)) {
                showTryButton = true
            }
        }
    }
}

struct OnboardingAIChatView: View {
    @StateObject private var viewModel = OnboardingAIChatViewModel()
    @AppStorage("onboarding_completed") private var onboardingCompleted = false
    @State private var showPaywall = false

    private let birthdayIdeas = [
        "Plan a surprise party with close friends",
        "Organize a \"memory lane\" day with meaningful places",
        "Create a personalized video from friends & family",
        "Set up a surprise trip or weekend getaway",
        "Prepare a themed dinner based on their favorite movie or cuisine"
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
                    ForEach(viewModel.messages) { msg in
                        MessageBubble(message: msg.text, isUser: msg.isUser)
                            .id(msg.id)
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
                .animation(.easeInOut(duration: 0.3), value: viewModel.messages.count)
                .animation(.easeInOut(duration: 0.2), value: viewModel.isTyping)
                .animation(.easeInOut(duration: 0.3), value: viewModel.showResponseCard)
            }
            .onChange(of: viewModel.messages.count) { _ in
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

    private var responseCard: some View {
        VStack(alignment: .leading, spacing: 8) {
            VStack(alignment: .leading, spacing: 12) {
                Text("Here are 5 fun birthday surprise ideas")
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundColor(AppColors.textPrimary)

                VStack(alignment: .leading, spacing: 10) {
                    ForEach(Array(birthdayIdeas.enumerated()), id: \.offset) { index, idea in
                        HStack(alignment: .top, spacing: 12) {
                            Text("\(index + 1)")
                                .font(.system(size: 13, weight: .medium))
                                .foregroundColor(AppColors.textSecondary)
                                .frame(width: 16, alignment: .leading)
                            Text(idea)
                                .font(.system(size: 14))
                                .foregroundColor(AppColors.textPrimary)
                                .fixedSize(horizontal: false, vertical: true)
                        }
                    }
                }
            }
            .padding(16)
            .background(AppColors.cardBackground)
            .clipShape(RoundedCornerShape(radius: 18, corners: [.topLeft, .topRight, .bottomRight]))

            Text("See how easy that was?\nNow try it yourself")
                .font(.system(size: 15, weight: .semibold))
                .foregroundColor(AppColors.textPrimary)
                .padding(.horizontal, 14)
                .padding(.vertical, 10)
                .background(AppColors.cardBackground)
                .clipShape(RoundedCornerShape(radius: 18, corners: [.topLeft, .topRight, .bottomRight]))

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

private struct RoundedCornerShape: Shape {
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
