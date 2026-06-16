import SwiftUI

@main
struct AIToolsApp: App {
    @StateObject private var apphudService = ApphudService.shared
    @AppStorage("onboarding_completed") private var onboardingCompleted = false

    var body: some Scene {
        WindowGroup {
            HomeView()
                .environmentObject(apphudService)
                .onAppear {
                    apphudService.start()
                }
                .fullScreenCover(isPresented: .constant(!onboardingCompleted)) {
                    OnboardingChatView()
                        .environmentObject(apphudService)
                }
        }
    }
}
