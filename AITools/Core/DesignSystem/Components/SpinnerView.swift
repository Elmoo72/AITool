import SwiftUI

struct SpinnerView: View {
    var size: CGFloat = 32
    @State private var rotation: Double = 0

    var body: some View {
        Image("ic_spinner")
            .resizable()
            .frame(width: size, height: size)
            .rotationEffect(.degrees(rotation))
            .onAppear {
                withAnimation(.linear(duration: 1.0).repeatForever(autoreverses: false)) {
                    rotation = 360
                }
            }
    }
}
