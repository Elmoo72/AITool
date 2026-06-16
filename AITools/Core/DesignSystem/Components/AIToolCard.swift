import SwiftUI

struct AIToolCard<Icon: View>: View {
    let title: String
    let subtitle: String
    let actionLabel: String?
    var isLarge: Bool = false
    @ViewBuilder let icon: () -> Icon

    var body: some View {
        if isLarge {
            largeCard
        } else {
            smallCard
        }
    }

    private var largeCard: some View {
        ZStack(alignment: .bottomLeading) {
            RoundedRectangle(cornerRadius: 20)
                .fill(
                    LinearGradient(
                        colors: [Color(hex: "#98C6F7"), Color(hex: "#C47FD8"), Color(hex: "#EB5B92")],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )

            GeometryReader { geo in
                Path { path in
                    let w = geo.size.width
                    let h = geo.size.height
                    path.move(to: CGPoint(x: 0, y: h * 0.55))
                    path.addCurve(
                        to: CGPoint(x: w, y: h * 0.45),
                        control1: CGPoint(x: w * 0.3, y: h * 0.35),
                        control2: CGPoint(x: w * 0.7, y: h * 0.65)
                    )
                    path.addLine(to: CGPoint(x: w, y: h))
                    path.addLine(to: CGPoint(x: 0, y: h))
                    path.closeSubpath()
                }
                .fill(Color.white.opacity(0.08))
            }
            .clipShape(RoundedRectangle(cornerRadius: 20))

            VStack(alignment: .leading, spacing: 0) {
                // Icon in semi-transparent circle
                ZStack {
                    Circle()
                        .fill(Color.white.opacity(0.18))
                        .frame(width: 36, height: 36)
                    icon()
                        .foregroundColor(.white)
                }
                .padding(.bottom, 10)

                Text(title)
                    .font(.system(size: 17, weight: .bold))
                    .foregroundColor(.white)
                    .fixedSize(horizontal: false, vertical: true)

                Text(subtitle)
                    .font(.system(size: 12, weight: .regular))
                    .foregroundColor(.white.opacity(0.75))
                    .padding(.top, 2)

                Spacer()

                if let label = actionLabel {
                    HStack(spacing: 6) {
                        Text(label)
                            .font(.system(size: 12, weight: .medium))
                            .foregroundColor(.white)
                        Image("ic_polygon")
                            .renderingMode(.template)
                            .resizable()
                            .frame(width: 9, height: 9)
                            .foregroundColor(.white)
                    }
                    .padding(.horizontal, 10)
                    .padding(.vertical, 6)
                    .background(Color.white.opacity(0.2))
                    .cornerRadius(20)
                }
            }
            .padding(16)
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .frame(height: 313)
    }

    private var smallCard: some View {
        ZStack(alignment: .topLeading) {
            RoundedRectangle(cornerRadius: 20)
                .fill(AppColors.cardBackground)

            VStack(alignment: .leading, spacing: 8) {
                // Gradient icon on semi-transparent circle
                ZStack {
                    Circle()
                        .fill(Color.white.opacity(0.12))
                        .frame(width: 40, height: 40)
                    icon()
                        .foregroundStyle(AppColors.primaryGradient)
                }

                Spacer()

                Text(title)
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundColor(AppColors.textPrimary)
                    .fixedSize(horizontal: false, vertical: true)
                    .lineLimit(2)

                Text(subtitle)
                    .font(.system(size: 11, weight: .regular))
                    .foregroundColor(AppColors.textSecondary)
                    .fixedSize(horizontal: false, vertical: true)
                    .lineLimit(2)
            }
            .padding(14)
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        }
        .frame(height: 152)
    }
}

#Preview {
    VStack(spacing: 16) {
        AIToolCard(title: "Turn Photo\ninto Video", subtitle: "Animate • Templates", actionLabel: "Ready in seconds", isLarge: true) {
            Image("ic_generate")
                .renderingMode(.template)
                .resizable()
                .frame(width: 18, height: 18)
        }
        HStack(spacing: 12) {
            AIToolCard(title: "Fix & Improve Writing", subtitle: "Rewrite • Fix grammar", actionLabel: nil) {
                Image("ic_writing")
                    .renderingMode(.template)
                    .resizable()
                    .frame(width: 16, height: 16)
            }
            AIToolCard(title: "Understand Faster", subtitle: "Summarize • Key points", actionLabel: nil) {
                Image("ic_chat")
                    .renderingMode(.template)
                    .resizable()
                    .frame(width: 16, height: 16)
            }
        }
    }
    .padding()
    .background(AppColors.background)
}
