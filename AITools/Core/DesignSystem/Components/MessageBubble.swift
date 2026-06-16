import SwiftUI

struct MessageBubble: View {
    let message: String
    let isUser: Bool
    var onCopy: (() -> Void)? = nil
    var onRegenerate: (() -> Void)? = nil

    var body: some View {
        HStack(alignment: .bottom, spacing: 8) {
            if isUser {
                Spacer(minLength: 60)
                Text(message)
                    .font(AppFonts.body)
                    .foregroundColor(.white)
                    .padding(.horizontal, 14)
                    .padding(.vertical, 10)
                    .background(AppColors.primaryGradient)
                    .cornerRadius(18)
                    .cornerRadius(4, corners: .bottomRight)
            } else {
                Text(message)
                    .font(AppFonts.body)
                    .foregroundColor(AppColors.textPrimary)
                    .padding(.horizontal, 14)
                    .padding(.vertical, 10)
                    .background(AppColors.cardBackground)
                    .cornerRadius(18)
                    .cornerRadius(4, corners: .bottomLeft)
                    .contextMenu {
                        Button {
                            UIPasteboard.general.string = message
                            onCopy?()
                        } label: {
                            Label("Copy", systemImage: "doc.on.doc")
                        }
                        Button {
                            onRegenerate?()
                        } label: {
                            Label("Regenerate", systemImage: "arrow.clockwise")
                        }
                    }
                Spacer(minLength: 60)
            }
        }
        .padding(.horizontal, 16)
        .transition(.opacity.combined(with: .move(edge: .bottom)))
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

struct TypingIndicator: View {
    @State private var animate = false

    var body: some View {
        HStack(alignment: .bottom, spacing: 8) {
            HStack(alignment: .center, spacing: 6) {
                Circle()
                    .fill(LinearGradient(
                        colors: [AppColors.primaryGradientStart, AppColors.primaryGradientEnd],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ))
                    .frame(width: 19, height: 19)
                    .offset(y: animate ? -3 : 0)
                    .animation(.easeInOut(duration: 0.5).repeatForever(autoreverses: true).delay(0), value: animate)

                Circle()
                    .fill(Color.white.opacity(0.5))
                    .frame(width: 13, height: 13)
                    .offset(y: animate ? -3 : 0)
                    .animation(.easeInOut(duration: 0.5).repeatForever(autoreverses: true).delay(0.15), value: animate)

                Circle()
                    .fill(Color.white.opacity(0.3))
                    .frame(width: 9, height: 9)
                    .offset(y: animate ? -3 : 0)
                    .animation(.easeInOut(duration: 0.5).repeatForever(autoreverses: true).delay(0.3), value: animate)
            }
            .frame(width: 52, height: 19)
            .padding(.horizontal, 14)
            .padding(.vertical, 14)
            .background(AppColors.cardBackground)
            .cornerRadius(18)
            .cornerRadius(4, corners: .bottomLeft)

            Spacer(minLength: 60)
        }
        .padding(.horizontal, 16)
        .onAppear { animate = true }
    }
}

#Preview {
    VStack(spacing: 16) {
        MessageBubble(message: "Hello! How can I help you?", isUser: false)
        MessageBubble(message: "Tell me about SwiftUI", isUser: true)
        TypingIndicator()
    }
    .padding()
    .background(AppColors.background)
}
