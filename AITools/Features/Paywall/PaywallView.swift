import SwiftUI

struct PaywallView: View {
    @StateObject private var viewModel: PaywallViewModel
    @Environment(\.dismiss) var dismiss
    @EnvironmentObject var apphudService: ApphudService

    @State private var showCloseButton = false

    init(apphudService: ApphudService) {
        _viewModel = StateObject(wrappedValue: PaywallViewModel(apphudService: apphudService))
    }

    var body: some View {
        ZStack(alignment: .topLeading) {
            paywallBackground

            // Основной контент — 358 wide, gap 32, top 147
            VStack(spacing: 0) {
                Spacer().frame(height: 147)
                VStack(spacing: 32) {
                    headerSection
                    featuresSection
                    plansSection
                }
                .frame(width: 358)
                Spacer()
            }
            .frame(maxWidth: .infinity)

            // Bottom bar — 390 wide, height 165, прижат к низу
            VStack(spacing: 0) {
                Spacer()
                ctaSection
                    .frame(width: 390, height: 165)
                Spacer().frame(height: 39)
            }
            .frame(maxWidth: .infinity)

            if showCloseButton {
                Button(action: { dismiss() }) {
                    Image(systemName: "xmark")
                        .font(.system(size: 13, weight: .regular))
                        .foregroundColor(.white.opacity(0.3))
                        .frame(width: 28, height: 28)
                }
                .padding(.top, 56)
                .padding(.leading, 20)
                .transition(.opacity)
            }
        }
        .ignoresSafeArea()
        .alert("Error", isPresented: .constant(viewModel.errorMessage != nil), actions: {
            Button("OK") { viewModel.errorMessage = nil }
        }, message: {
            Text(viewModel.errorMessage ?? "")
        })
        .onAppear {
            Task {
                try? await Task.sleep(nanoseconds: 2_000_000_000)
                withAnimation(.easeIn(duration: 0.4)) {
                    showCloseButton = true
                }
            }
        }
        .onChange(of: apphudService.hasActiveSubscription) { isActive in
            if isActive { dismiss() }
        }
    }

    private var paywallBackground: some View {
        GeometryReader { geo in
            ZStack {
                Color(red: 11/255, green: 7/255, blue: 14/255)

                Ellipse()
                    .fill(
                        LinearGradient(
                            colors: [
                                Color(red: 0x98/255, green: 0xC6/255, blue: 0xF7/255),
                                Color(red: 0xEB/255, green: 0x5B/255, blue: 0x92/255)
                            ],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .frame(width: 619.2, height: 246.4)
                    .rotationEffect(.degrees(-18.36))
                    .opacity(0.5)
                    .blur(radius: 100)
                    .position(x: geo.size.width * 0.55, y: geo.size.height * 0.18)

                Ellipse()
                    .fill(Color(red: 11/255, green: 7/255, blue: 14/255))
                    .frame(width: 232.3, height: 380.1)
                    .rotationEffect(.degrees(-89.27))
                    .blur(radius: 108)
                    .position(x: -20, y: geo.size.height * 0.22)

                Ellipse()
                    .fill(Color(red: 11/255, green: 7/255, blue: 14/255))
                    .frame(width: 232.3, height: 312.3)
                    .rotationEffect(.degrees(-89.27))
                    .blur(radius: 108)
                    .position(x: geo.size.width + 20, y: geo.size.height * 0.18)
            }
        }
        .ignoresSafeArea()
    }

    private var headerSection: some View {
        VStack(spacing: 12) {
            Text("Create anything\nyou want")
                .font(.system(size: 34, weight: .bold))
                .foregroundColor(.white)
                .multilineTextAlignment(.center)
                .frame(width: 267)
        }
    }

    private let features: [(icon: String, title: String)] = [
        ("paywall_icon_1", "Get results in seconds"),
        ("paywall_icon_4", "Turn any text into better writing"),
        ("paywall_icon_2", "Simplify complex information"),
        ("paywall_icon_3", "Create content with AI templates")
    ]

    private var featuresSection: some View {
        VStack(spacing: 12) {
            ForEach(features, id: \.title) { feature in
                HStack(spacing: 12) {
                    Image(feature.icon)
                        .resizable()
                        .scaledToFit()
                        .frame(width: 24, height: 24)

                    Text(feature.title)
                        .font(.system(size: 15))
                        .foregroundColor(.white.opacity(0.85))
                }
                .frame(width: 267, alignment: .leading)
            }
        }
    }

    private var plansSection: some View {
        VStack(spacing: 10) {
            let sorted = viewModel.products.sorted { ($0.id == "yearly" ? 0 : 1) < ($1.id == "yearly" ? 0 : 1) }
            ForEach(sorted) { product in
                PaywallPlanCard(
                    product: product,
                    isSelected: viewModel.selectedProduct?.id == product.id,
                    action: { viewModel.selectedProduct = product }
                )
            }
        }
    }

    private func openURL(_ string: String) {
        guard let url = URL(string: string) else { return }
        UIApplication.shared.open(url)
    }

    private let buttonGradient = LinearGradient(
        colors: [
            Color(red: 0x98/255, green: 0xC6/255, blue: 0xF7/255),
            Color(red: 0xEB/255, green: 0x5B/255, blue: 0x92/255)
        ],
        startPoint: .leading,
        endPoint: .trailing
    )

    private var ctaSection: some View {
        VStack(spacing: 0) {
            HStack(spacing: 6) {
                Image(systemName: "clock")
                    .font(.system(size: 13))
                    .foregroundColor(.white.opacity(0.35))
                Text("Cancel Anytime")
                    .font(.system(size: 13))
                    .foregroundColor(.white.opacity(0.35))
            }
            .padding(.bottom, 14)

            Button(action: { viewModel.purchase() }) {
                ZStack {
                    if apphudService.isLoading {
                        ProgressView().tint(.white)
                    } else {
                        Text("Unlock now")
                            .font(.system(size: 17, weight: .semibold))
                            .foregroundColor(.white)
                    }
                }
                .frame(width: 358, height: 50)
                .background(buttonGradient)
                .cornerRadius(24)
            }
            .disabled(apphudService.isLoading)

            HStack(spacing: 0) {
                Button(action: { openURL("https://nebulaapps.site/privacy-policy") }) {
                    Text("Privacy Policy")
                        .font(.system(size: 11, weight: .regular))
                        .kerning(0.06)
                        .foregroundColor(Color(red: 0x60/255, green: 0x60/255, blue: 0x60/255))
                        .frame(width: 123.5, alignment: .leading)
                }
                Button(action: { viewModel.restorePurchases() }) {
                    Text("Restore Purchases")
                        .font(.system(size: 11, weight: .regular))
                        .kerning(0.06)
                        .foregroundColor(Color(red: 0x60/255, green: 0x60/255, blue: 0x60/255))
                        .lineLimit(1)
                        .fixedSize(horizontal: true, vertical: false)
                        .frame(width: 87, alignment: .center)
                }
                Button(action: { openURL("https://nebulaapps.site/terms-of-service") }) {
                    Text("Terms of Use")
                        .font(.system(size: 11, weight: .regular))
                        .kerning(0.06)
                        .foregroundColor(Color(red: 0x60/255, green: 0x60/255, blue: 0x60/255))
                        .frame(width: 123.5, alignment: .trailing)
                }
            }
            .frame(width: 390, height: 37)
            .padding(.top, 16)
        }
        .padding(.top, 16)
    }
}

private struct PaywallPlanCard: View {
    let product: PaywallProduct
    let isSelected: Bool
    let action: () -> Void

    private var accentColor: Color {
        Color(red: 0.6, green: 0.35, blue: 1.0)
    }

    private let cardGradient = LinearGradient(
        colors: [
            Color(red: 0x98/255, green: 0xC6/255, blue: 0xF7/255),
            Color(red: 0xEB/255, green: 0x5B/255, blue: 0x92/255)
        ],
        startPoint: .leading,
        endPoint: .trailing
    )

    var body: some View {
        Button(action: action) {
            HStack(spacing: 8) {
                VStack(alignment: .leading, spacing: 3) {
                    HStack(spacing: 8) {
                        Text(product.title)
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(.white)
                        Text(product.weeklyPrice + " / week")
                            .font(.system(size: 14, weight: .regular))
                            .foregroundColor(.white)
                    }
                    Text(product.originalPrice + " / " + (product.id == "yearly" ? "year" : "month"))
                        .font(.system(size: 13))
                        .foregroundColor(.white.opacity(0.4))
                }

                Spacer()

                if let badge = product.saveBadge {
                    Text(badge)
                        .font(.system(size: 11, weight: .bold))
                        .foregroundColor(.white)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 6)
                        .frame(width: 102, height: 25)
                        .background(cardGradient)
                        .cornerRadius(32)
                }
            }
            .padding(16)
            .frame(width: 358, height: 80)
            .background(Color.white.opacity(0.05))
            .cornerRadius(24)
            .overlay(
                RoundedRectangle(cornerRadius: 24)
                    .stroke(
                        isSelected ? AnyShapeStyle(cardGradient) : AnyShapeStyle(Color.white.opacity(0.12)),
                        lineWidth: 1.5
                    )
            )
        }
    }
}

#Preview {
    PaywallView(apphudService: ApphudService.shared)
        .environmentObject(ApphudService.shared)
}
