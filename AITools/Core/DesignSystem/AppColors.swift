import SwiftUI

struct AppColors {
    static let background = Color(hex: "#0B070E")
    static let cardBackground = Color(hex: "#1F191F")
    static let cardBackgroundLight = Color(hex: "#2A222A")
    static let primaryGradientStart = Color(hex: "#98C6F7")
    static let primaryGradientEnd = Color(hex: "#EB5B92")
    static let textPrimary = Color.white
    static let textSecondary = Color(hex: "#8E8E9A")
    static let inputBackground = Color(hex: "#1F191F")
    static let separatorColor = Color(hex: "#2E262E")

    static let primaryGradient = LinearGradient(
        colors: [primaryGradientStart, primaryGradientEnd],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )
}

extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet(charactersIn: "#"))
        let rgb = Int(hex, radix: 16) ?? 0
        let red = Double((rgb >> 16) & 0xFF) / 255.0
        let green = Double((rgb >> 8) & 0xFF) / 255.0
        let blue = Double(rgb & 0xFF) / 255.0
        self.init(red: red, green: green, blue: blue)
    }
}
