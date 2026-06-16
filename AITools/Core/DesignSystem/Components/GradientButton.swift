import SwiftUI

struct GradientButton: View {
    let title: String
    let action: () -> Void
    var isLoading: Bool = false

    var body: some View {
        Button(action: action) {
            if isLoading {
                SpinnerView(size: 24)
            } else {
                Text(title)
                    .font(AppFonts.headline)
                    .foregroundColor(.white)
            }
        }
        .frame(maxWidth: .infinity)
        .frame(height: 52)
        .background(AppColors.primaryGradient)
        .cornerRadius(12)
        .disabled(isLoading)
    }
}

#Preview {
    VStack(spacing: 16) {
        GradientButton(title: "Generate", action: {})
        GradientButton(title: "Loading...", action: {}, isLoading: true)
    }
    .padding()
    .background(AppColors.background)
}
