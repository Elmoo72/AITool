import SwiftUI

extension View {
    func appBackground() -> some View {
        background(AppColors.background)
            .ignoresSafeArea()
    }

    func navigationBarStyle() -> some View {
        modifier(NavigationBarModifier())
    }
}

struct NavigationBarModifier: ViewModifier {
    func body(content: Content) -> some View {
        content
            .toolbarBackground(AppColors.cardBackground, for: .navigationBar)
            .toolbarBackground(.visible, for: .navigationBar)
    }
}
