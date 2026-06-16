import SwiftUI
import StoreKit

struct SettingsView: View {
    @Environment(\.dismiss) var dismiss
    @EnvironmentObject var apphudService: ApphudService
    @State private var showPaywall = false

    var body: some View {
        ZStack {
            AppColors.background
                .ignoresSafeArea()

            VStack(spacing: 0) {
                // Navigation Bar
                HStack {
                    Button(action: { dismiss() }) {
                        Image("ic_back")
                            .renderingMode(.template)
                            .resizable()
                            .frame(width: 20, height: 20)
                            .foregroundColor(.white)
                    }

                    Text("Settings")
                        .font(AppFonts.headline)
                        .foregroundColor(AppColors.textPrimary)

                    Spacer()
                }
                .padding(16)
                .background(AppColors.cardBackground)

                Divider()
                    .background(AppColors.separatorColor)

                ScrollView(showsIndicators: false) {
                    VStack(spacing: 0) {
                        // Account Section
                        VStack(spacing: 0) {
                            Text("Account")
                                .font(AppFonts.caption)
                                .foregroundColor(AppColors.textSecondary)
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .padding(.horizontal, 16)
                                .padding(.vertical, 12)

                            SettingRow(
                                title: "Subscription",
                                subtitle: apphudService.hasActiveSubscription ? "Premium" : "Free",
                                action: { showPaywall = true }
                            )

                            Divider()
                                .background(AppColors.separatorColor)
                                .padding(.horizontal, 16)

                            SettingRow(
                                title: "Manage Plan",
                                subtitle: "View and modify",
                                action: { showPaywall = true }
                            )
                        }
                        .background(AppColors.cardBackground)
                        .cornerRadius(12)
                        .padding(16)

                        // Legal Section
                        VStack(spacing: 0) {
                            Text("Legal")
                                .font(AppFonts.caption)
                                .foregroundColor(AppColors.textSecondary)
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .padding(.horizontal, 16)
                                .padding(.vertical, 12)

                            SettingRow(
                                title: "Privacy Policy",
                                subtitle: "Learn about your data",
                                action: { openURL("https://nebulaapps.site/privacy-policy") }
                            )

                            Divider()
                                .background(AppColors.separatorColor)
                                .padding(.horizontal, 16)

                            SettingRow(
                                title: "Terms of Service",
                                subtitle: "Read our terms",
                                action: { openURL("https://nebulaapps.site/terms-of-service") }
                            )
                        }
                        .background(AppColors.cardBackground)
                        .cornerRadius(12)
                        .padding(16)

                        // Other Section
                        VStack(spacing: 0) {
                            Text("More")
                                .font(AppFonts.caption)
                                .foregroundColor(AppColors.textSecondary)
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .padding(.horizontal, 16)
                                .padding(.vertical, 12)

                            SettingRow(
                                title: "Rate App",
                                subtitle: "Share your feedback",
                                action: { rateApp() }
                            )

                            Divider()
                                .background(AppColors.separatorColor)
                                .padding(.horizontal, 16)

                            SettingRow(
                                title: "Share with Friends",
                                subtitle: "Tell others about us",
                                action: { shareApp() }
                            )
                        }
                        .background(AppColors.cardBackground)
                        .cornerRadius(12)
                        .padding(16)

                        // Version
                        VStack(spacing: 8) {
                            Text("AI Tools")
                                .font(AppFonts.caption)
                                .foregroundColor(AppColors.textSecondary)

                            Text("v1.0.0")
                                .font(AppFonts.captionSmall)
                                .foregroundColor(AppColors.textSecondary.opacity(0.6))
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 20)

                        Spacer()
                    }
                }
            }
        }
        .navigationBarHidden(true)
        .fullScreenCover(isPresented: $showPaywall) {
            PaywallView(apphudService: apphudService)
                .environmentObject(apphudService)
        }
    }

    private func openURL(_ string: String) {
        guard let url = URL(string: string) else { return }
        UIApplication.shared.open(url)
    }

    private func rateApp() {
        guard let scene = UIApplication.shared.connectedScenes.first as? UIWindowScene else { return }
        SKStoreReviewController.requestReview(in: scene)
    }

    private func shareApp() {
        let items: [Any] = ["Check out AI Tools — your personal AI assistant!"]
        let activityVC = UIActivityViewController(activityItems: items, applicationActivities: nil)
        guard let scene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
              let root = scene.windows.first?.rootViewController else { return }
        var top = root
        while let presented = top.presentedViewController { top = presented }
        top.present(activityVC, animated: true)
    }
}

struct SettingRow: View {
    let title: String
    let subtitle: String
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 12) {
                VStack(alignment: .leading, spacing: 4) {
                    Text(title)
                        .font(AppFonts.body)
                        .foregroundColor(AppColors.textPrimary)

                    Text(subtitle)
                        .font(AppFonts.caption)
                        .foregroundColor(AppColors.textSecondary)
                }

                Spacer()

                Image(systemName: "chevron.right")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(AppColors.textSecondary)
            }
            .padding(16)
        }
    }
}

#Preview {
    SettingsView()
        .environmentObject(ApphudService.shared)
}
