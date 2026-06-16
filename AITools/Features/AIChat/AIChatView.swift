import SwiftUI

struct AIChatView: View {
    @StateObject private var viewModel = AIChatViewModel()
    @Environment(\.dismiss) var dismiss
    @EnvironmentObject var apphudService: ApphudService
    @State private var showHistory = false
    @State private var showCopiedToast = false
    @State private var showPaywall = false

    var body: some View {
        ZStack {
            AppColors.background.ignoresSafeArea()

            VStack(spacing: 0) {
                navBar
                Divider().background(AppColors.separatorColor)
                messagesList
                inputBar
            }

            if showCopiedToast {
                VStack {
                    Spacer()
                    Text("Copied to clipboard")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(.white)
                        .padding(.horizontal, 20)
                        .padding(.vertical, 10)
                        .background(Color.black.opacity(0.75))
                        .cornerRadius(20)
                        .padding(.bottom, 100)
                        .transition(.opacity.combined(with: .move(edge: .bottom)))
                }
            }
        }
        .navigationBarHidden(true)
        .onAppear {
            viewModel.onAppear()
            if !apphudService.hasActiveSubscription {
                showPaywall = true
            }
        }
        .fullScreenCover(isPresented: $showPaywall) {
            PaywallView(apphudService: apphudService)
                .environmentObject(apphudService)
        }
    }

    private func showToast() {
        withAnimation(.easeInOut(duration: 0.2)) { showCopiedToast = true }
        Task { @MainActor in
            try? await Task.sleep(nanoseconds: 1_500_000_000)
            withAnimation(.easeInOut(duration: 0.2)) { showCopiedToast = false }
        }
    }

    private var navBar: some View {
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
                    .fill(LinearGradient(
                        colors: [AppColors.primaryGradientStart, AppColors.primaryGradientEnd],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ))
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

            NavigationLink(destination: AIChatHistoryView(viewModel: viewModel)) {
                Image("ic_history")
                    .renderingMode(.template)
                    .resizable()
                    .frame(width: 22, height: 22)
                    .foregroundColor(AppColors.textSecondary)
                    .frame(width: 36, height: 36)
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(AppColors.cardBackground)
    }

    private var messagesList: some View {
        ScrollViewReader { proxy in
            ScrollView(showsIndicators: false) {
                LazyVStack(spacing: 12) {
                    if viewModel.messages.isEmpty {
                        emptyState
                    } else {
                        dateSeparator
                        ForEach(viewModel.messages) { message in
                            MessageBubble(
                                message: message.text,
                                isUser: message.isUser,
                                onCopy: message.isUser ? nil : {
                                    UIPasteboard.general.string = message.text
                                    showToast()
                                },
                                onRegenerate: message.isUser ? nil : {
                                    viewModel.regenerateLastResponse()
                                }
                            )
                                .id(message.id)
                        }
                    }
                    Color.clear.frame(height: 1).id("bottom")
                }
                .padding(.vertical, 16)
                .animation(.easeInOut(duration: 0.3), value: viewModel.messages.count)
            }
            .onChange(of: viewModel.messages.count) { _ in
                withAnimation { proxy.scrollTo("bottom", anchor: .bottom) }
            }
            .onChange(of: viewModel.isLoading) { _ in
                withAnimation { proxy.scrollTo("bottom", anchor: .bottom) }
            }
        }
    }

    private var dateSeparator: some View {
        Text(Date().formatted(.dateTime.day().month(.twoDigits).year()))
            .font(.system(size: 12))
            .foregroundColor(AppColors.textSecondary)
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
            .background(AppColors.cardBackground)
            .cornerRadius(12)
    }

    private var emptyState: some View {
        VStack(spacing: 12) {
            HStack(spacing: 0) {
                Text("Your ")
                    .foregroundColor(AppColors.textPrimary)
                Text("AI assistant")
                    .foregroundColor(.clear)
                    .overlay(
                        LinearGradient(
                            colors: [AppColors.primaryGradientStart, AppColors.primaryGradientEnd],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                        .mask(Text("AI assistant").font(.system(size: 20, weight: .semibold)))
                    )
                Text(" for anything")
                    .foregroundColor(AppColors.textPrimary)
            }
            .font(.system(size: 20, weight: .semibold))

            Text("Ask questions, get answers, and explore ideas\nin seconds")
                .font(.system(size: 14, weight: .regular))
                .foregroundColor(AppColors.textSecondary)
                .multilineTextAlignment(.center)
                .lineSpacing(4)
        }
        .frame(maxWidth: .infinity)
        .padding(.horizontal, 23)
        .padding(.top, 135)
    }

    private var inputBar: some View {
        VStack(spacing: 0) {
            Divider().background(AppColors.separatorColor)

            HStack(spacing: 12) {
                HStack {
                    TextField("", text: $viewModel.inputText,
                              prompt: Text("Ask anything...")
                                .foregroundColor(AppColors.textSecondary))
                        .textFieldStyle(.plain)
                        .foregroundColor(AppColors.textPrimary)
                        .font(.system(size: 16, weight: .regular))
                        .onSubmit { viewModel.sendMessage() }
                }
                .padding(.horizontal, 14)
                .padding(.vertical, 12)
                .background(AppColors.inputBackground)
                .cornerRadius(22)

                Button(action: { viewModel.sendMessage() }) {
                    if viewModel.inputText.isEmpty {
                        Image("ic_photo")
                            .renderingMode(.template)
                            .resizable()
                            .frame(width: 40, height: 40)
                            .foregroundColor(.white)
                    } else {
                        Image("ic_send")
                            .renderingMode(.template)
                            .resizable()
                            .frame(width: 18, height: 18)
                            .foregroundColor(.white)
                            .frame(width: 44, height: 44)
                            .background(AppColors.primaryGradient)
                            .clipShape(Circle())
                    }
                }
                .frame(width: 44, height: 44)
                .disabled(viewModel.isLoading)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 10)
        }
        .background(AppColors.cardBackground)
    }
}

#Preview {
    NavigationStack {
        AIChatView()
            .environmentObject(ApphudService.shared)
    }
}
