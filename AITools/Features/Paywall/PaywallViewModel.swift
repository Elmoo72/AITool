import Foundation
import SwiftUI

@MainActor
final class PaywallViewModel: ObservableObject {
    @Published var products: [PaywallProduct] = []
    @Published var selectedProduct: PaywallProduct?
    @Published var isLoading = false
    @Published var errorMessage: String?

    private let apphudService: ApphudService

    init(apphudService: ApphudService) {
        self.apphudService = apphudService
        loadProducts()
    }

    func loadProducts() {
        Task { @MainActor in
            isLoading = true
            defer { isLoading = false }

            products = await apphudService.fetchPaywallProducts()
            if products.isEmpty {
                products = Self.mockProducts
            }
            selectedProduct = products.first(where: { $0.saveBadge != nil }) ?? products.first
        }
    }

    private static let mockProducts: [PaywallProduct] = [
        PaywallProduct(id: "monthly", title: "Month", weeklyPrice: "$3.75", originalPrice: "$14.99", saveBadge: nil),
        PaywallProduct(id: "yearly",  title: "Year",  weeklyPrice: "$1.15", originalPrice: "$59.99", saveBadge: "SAVE 80%")
    ]

    func purchase() {
        guard let product = selectedProduct else { return }

        Task { @MainActor in
            do {
                try await apphudService.purchase(product)
            } catch {
                errorMessage = error.localizedDescription
            }
        }
    }

    func restorePurchases() {
        Task { @MainActor in
            do {
                try await apphudService.restorePurchases()
            } catch {
                errorMessage = error.localizedDescription
            }
        }
    }
}
