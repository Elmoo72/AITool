import SwiftUI

struct HomeView: View {
    @StateObject private var viewModel = HomeViewModel()
    @EnvironmentObject var apphudService: ApphudService
    @State private var navigateToChat = false

    var body: some View {
        NavigationStack {
            ZStack {
                AppColors.background
                    .ignoresSafeArea()

                ScrollView(showsIndicators: false) {
                    VStack(spacing: 24) {
                        HStack {
                            Spacer()
                            NavigationLink(destination: SettingsView().environmentObject(apphudService)) {
                                Image("ic_settings")
                                    .renderingMode(.template)
                                    .resizable()
                                    .frame(width: 22, height: 22)
                                    .foregroundColor(AppColors.textSecondary)
                            }
                        }
                        .padding(.horizontal, 20)
                        .padding(.top, 8)

                        VStack(spacing: 16) {
                            Image("ic_sparkles")
                                .resizable()
                                .frame(width: 52, height: 52)

                            Text("Your AI tools,\nready to go")
                                .font(AppFonts.title1)
                                .foregroundColor(AppColors.textPrimary)
                                .multilineTextAlignment(.center)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.horizontal, 16)

                        Button(action: { navigateToChat = true }) {
                            HStack(spacing: 10) {
                                Image("ic_sparkles")
                                    .resizable()
                                    .frame(width: 18, height: 18)

                                Text("Ask anything...")
                                    .foregroundColor(.white.opacity(0.6))
                                    .font(.system(size: 17))

                                Spacer()
                            }
                            .padding(.horizontal, 14)
                            .padding(.vertical, 14)
                            .background(AppColors.inputBackground)
                            .cornerRadius(14)
                            .overlay(
                                RoundedRectangle(cornerRadius: 14)
                                    .stroke(AppColors.primaryGradient, lineWidth: 1.5)
                            )
                        }
                        .buttonStyle(.plain)
                        .padding(.horizontal, 16)

                        VStack(spacing: 12) {
                            HStack(alignment: .top, spacing: 12) {
                                NavigationLink(destination: VideoGeneratorView().environmentObject(apphudService)) {
                                    AIToolCard(title: "Turn Photo\ninto Video", subtitle: "Animate • Templates", actionLabel: "Ready in seconds", isLarge: true) {
                                        Image("ic_generate")
                                            .renderingMode(.template)
                                            .resizable()
                                            .frame(width: 18, height: 18)
                                    }
                                }
                                .buttonStyle(.plain)

                                VStack(spacing: 12) {
                                    NavigationLink(destination: AIWritingView().environmentObject(apphudService)) {
                                        AIToolCard(title: "Fix & Improve Writing", subtitle: "Rewrite • Fix grammar", actionLabel: nil) {
                                            Image("ic_writing")
                                                .renderingMode(.template)
                                                .resizable()
                                                .frame(width: 16, height: 16)
                                        }
                                    }
                                    .buttonStyle(.plain)

                                    NavigationLink(destination: AIChatView().environmentObject(apphudService)) {
                                        AIToolCard(title: "Understand Faster", subtitle: "Summarize • Key points", actionLabel: nil) {
                                            Image("ic_chat")
                                                .renderingMode(.template)
                                                .resizable()
                                                .frame(width: 16, height: 16)
                                        }
                                    }
                                    .buttonStyle(.plain)
                                }
                            }
                        }
                        .padding(.horizontal, 16)

                        Spacer().frame(height: 81)
                    }
                }
            }
            .navigationBarHidden(true)
            .navigationDestination(isPresented: $navigateToChat) {
                AIChatView().environmentObject(apphudService)
            }
        }
    }
}

#Preview {
    HomeView()
        .environmentObject(ApphudService.shared)
}
