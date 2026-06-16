import SwiftUI

@MainActor
final class OnboardingChatViewModel: ObservableObject {
    @Published var messages: [String] = []
    @Published var showTyping = false
    @Published var showOptions = false

    func start() {
        Task {
            await showTypingThen(delay: 0.9, message: "Hey! I'm your AI assistant")
            await showTypingThen(delay: 1.3, message: "I can help you create almost anything in seconds")
            await showTypingThen(delay: 1.1, message: "Let's try something simple!")
            try? await Task.sleep(nanoseconds: 400_000_000)
            withAnimation(.easeInOut(duration: 0.3)) { showOptions = true }
        }
    }

    private func showTypingThen(delay: Double, message: String) async {
        withAnimation { showTyping = true }
        try? await Task.sleep(nanoseconds: UInt64(delay * 1_000_000_000))
        withAnimation {
            showTyping = false
            messages.append(message)
        }
        try? await Task.sleep(nanoseconds: 350_000_000)
    }
}

struct OnboardingChatView: View {
    @StateObject private var viewModel = OnboardingChatViewModel()
    @AppStorage("onboarding_completed") var onboardingCompleted = false
    @State private var showAIDemo = false
    @State private var showWritingDemo = false
    @State private var showUnderstandDemo = false
    @State private var showVideoDemo = false

    private let bubbleGradient = LinearGradient(
        colors: [
            Color(red: 0x98/255, green: 0xC6/255, blue: 0xF7/255),
            Color(red: 0xEB/255, green: 0x5B/255, blue: 0x92/255)
        ],
        startPoint: .leading,
        endPoint: .trailing
    )

    var body: some View {
        ZStack {
            AppColors.background.ignoresSafeArea()

            VStack(spacing: 0) {
                navBar
                Divider().background(AppColors.separatorColor)
                messagesList
                Spacer()
            }
        }
        .navigationBarHidden(true)
        .onAppear { viewModel.start() }
        .fullScreenCover(isPresented: $showAIDemo) {
            OnboardingAIChatView()
        }
        .fullScreenCover(isPresented: $showWritingDemo) {
            OnboardingWritingChatView()
        }
        .fullScreenCover(isPresented: $showUnderstandDemo) {
            OnboardingUnderstandChatView()
        }
        .fullScreenCover(isPresented: $showVideoDemo) {
            OnboardingVideoChatView()
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

            VStack(alignment: .leading, spacing: 1) {
                Text("AI Chat")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(AppColors.textPrimary)
                Text("Your AI assistant")
                    .font(.system(size: 12))
                    .foregroundColor(AppColors.textSecondary)
            }

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

                    // Первые два сообщения — один пузырь, появляется когда оба готовы
                    if viewModel.messages.count >= 2 {
                        combinedFirstBubble
                            .transition(.opacity.combined(with: .move(edge: .bottom)))
                            .id("msg_combined")
                    }

                    // Третье сообщение
                    if viewModel.messages.count >= 3 {
                        thirdMessageBubble
                            .transition(.opacity.combined(with: .move(edge: .bottom)))
                            .id("msg_3")
                    }

                    if viewModel.showTyping {
                        TypingIndicator()
                            .id("typing")
                    }

                    if viewModel.showOptions {
                        optionsSection
                            .transition(.opacity.combined(with: .move(edge: .bottom)))
                            .id("options")
                    }

                    Color.clear.frame(height: 1).id("bottom")
                }
                .padding(.vertical, 16)
                .padding(.horizontal, 16)
                .animation(.easeInOut(duration: 0.3), value: viewModel.messages.count)
                .animation(.easeInOut(duration: 0.2), value: viewModel.showTyping)
                .animation(.easeInOut(duration: 0.3), value: viewModel.showOptions)
            }
            .onChange(of: viewModel.messages.count) { _ in
                withAnimation { proxy.scrollTo("bottom", anchor: .bottom) }
            }
            .onChange(of: viewModel.showTyping) { _ in
                withAnimation { proxy.scrollTo("bottom", anchor: .bottom) }
            }
            .onChange(of: viewModel.showOptions) { _ in
                withAnimation { proxy.scrollTo("bottom", anchor: .bottom) }
            }
        }
    }

    private let msgBg = Color(hex: "#1F191F").opacity(0.5)

    // MARK: - Первый пузырь (сообщения 1 + 2)

    private var combinedFirstBubble: some View {
        VStack(alignment: .leading, spacing: 16) {
            // "Hey! I'm your AI assistant" — вся строка градиент
            Text("Hey! I'm your AI assistant")
                .font(.system(size: 15, weight: .semibold))
                .foregroundColor(.clear)
                .overlay {
                    bubbleGradient.mask(
                        Text("Hey! I'm your AI assistant")
                            .font(.system(size: 15, weight: .semibold))
                    )
                }

            Text("I can help you create almost anything in seconds")
                .font(.system(size: 15))
                .foregroundColor(AppColors.textPrimary)
        }
        .padding(16)
        .frame(width: 334, height: 108, alignment: .topLeading)
        .background(msgBg)
        .clipShape(RoundedCorner(radius: 24, corners: [.topLeft, .topRight, .bottomRight]))
    }

    // MARK: - Второй пузырь ("Let's try something simple!")

    private var thirdMessageBubble: some View {
        Text("Let's try something simple!")
            .font(.system(size: 15))
            .foregroundColor(AppColors.textPrimary)
            .frame(width: 334, alignment: .leading)
            .padding(16)
            .background(msgBg)
            .clipShape(RoundedCorner(radius: 24, corners: [.topLeft, .topRight, .bottomRight]))
    }

    // MARK: - Опции (третий блок)

    private var optionsSection: some View {
        VStack(alignment: .leading, spacing: 24) {
            Text("What do you want to create?")
                .font(.system(size: 16, weight: .semibold))
                .foregroundColor(AppColors.textPrimary)

            VStack(spacing: 12) {
                OptionCard(
                    icon: "ic_sparkles",
                    title: "Talk to AI",
                    subtitle: "Ask anything. Get answers fast"
                ) { showAIDemo = true }

                OptionCard(
                    icon: "ic_generate",
                    title: "Create videos",
                    subtitle: "Pick a template. Done in seconds"
                ) { showVideoDemo = true }

                OptionCard(
                    icon: "ic_magic_pencil",
                    title: "Write like a pro",
                    subtitle: "Rewrite and improve your text"
                ) { showWritingDemo = true }

                OptionCard(
                    icon: "ic_mic",
                    title: "Understand faster",
                    subtitle: "Simplify complex info instantly"
                ) { showUnderstandDemo = true }
            }
        }
        .frame(width: 334, alignment: .leading)
        .padding(.top, 24)
        .padding(.leading, 16)
        .padding(.trailing, 16)
        .padding(.bottom, 16)
        .background(msgBg)
        .clipShape(RoundedCorner(radius: 24, corners: [.topLeft, .topRight, .bottomRight]))
    }
}

struct OptionCard: View {
    let icon: String
    let title: String
    let subtitle: String
    let action: () -> Void

    private let iconGradient = LinearGradient(
        colors: [
            Color(red: 0x98/255, green: 0xC6/255, blue: 0xF7/255),
            Color(red: 0xEB/255, green: 0x5B/255, blue: 0x92/255)
        ],
        startPoint: .leading,
        endPoint: .trailing
    )

    var body: some View {
        Button(action: action) {
            HStack(spacing: 12) {
                ZStack {
                    RoundedRectangle(cornerRadius: 8)
                        .fill(AppColors.cardBackgroundLight)
                        .frame(width: 44, height: 44)
                    Image(icon)
                        .resizable()
                        .renderingMode(.template)
                        .foregroundStyle(iconGradient)
                        .frame(width: 22, height: 22)
                }

                VStack(alignment: .leading, spacing: 2) {
                    Text(title)
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(AppColors.textPrimary)
                    Text(subtitle)
                        .font(.system(size: 13, weight: .regular))
                        .foregroundColor(AppColors.textSecondary)
                }

                Spacer()

                Image(systemName: "chevron.right")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(AppColors.textSecondary)
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 12)
            .background(AppColors.cardBackground)
            .cornerRadius(14)
        }
    }
}

private extension View {
    func cornerRadius(_ radius: CGFloat, corners: UIRectCorner) -> some View {
        clipShape(RoundedCorner(radius: radius, corners: corners))
    }
}

private struct RoundedCorner: Shape {
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

#Preview {
    OnboardingChatView()
}
