import Foundation
import SwiftUI
import ApphudSDK

@MainActor
final class ApphudService: ObservableObject {
    static let shared = ApphudService()

    #if DEBUG
    @Published var hasActiveSubscription = true
    #else
    @Published var hasActiveSubscription = false
    #endif
    @Published var isLoading = false
    @Published var products: [PaywallProduct] = []

    private var apphudProducts: [ApphudProduct] = []

    private init() {}

    var userID: String { Apphud.userID() }

    func start() {
        Apphud.start(apiKey: Secrets.apphudAPIKey)
        hasActiveSubscription = Apphud.hasActiveSubscription()
    }

    func fetchPaywallProducts() async -> [PaywallProduct] {
        isLoading = true
        defer { isLoading = false }

        let placement = await Apphud.placement("main")
        let sdkProducts = placement?.paywall?.products ?? []
        apphudProducts = sdkProducts
        let display = sdkProducts.compactMap { makeDisplayProduct($0) }
        products = display
        return display
    }

    func purchase(_ product: PaywallProduct) async throws {
        if apphudProducts.isEmpty {
            _ = await fetchPaywallProducts()
        }

        guard let apphudProduct = apphudProducts.first(where: { $0.productId == product.id }) else {
            if apphudProducts.isEmpty {
                throw PurchaseError.paywallNotLoaded
            } else {
                throw PurchaseError.productNotFound(id: product.id, available: apphudProducts.map(\.productId))
            }
        }

        isLoading = true
        defer { isLoading = false }

        let result = await Apphud.purchase(apphudProduct)
        if let error = result.error {
            throw error
        }
        hasActiveSubscription = Apphud.hasActiveSubscription()
    }

    func restorePurchases() async throws {
        isLoading = true
        defer { isLoading = false }

        try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Void, Error>) in
            Apphud.restorePurchases { _, _, error in
                if let error {
                    continuation.resume(throwing: error)
                } else {
                    continuation.resume()
                }
            }
        }
        hasActiveSubscription = Apphud.hasActiveSubscription()
    }

    func checkSubscription() -> Bool {
        hasActiveSubscription = Apphud.hasActiveSubscription()
        return hasActiveSubscription
    }

    private func makeDisplayProduct(_ product: ApphudProduct) -> PaywallProduct? {
        guard let skProduct = product.skProduct else { return nil }
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.locale = skProduct.priceLocale
        let price = formatter.string(from: skProduct.price) ?? "\(skProduct.price)"
        let isYearly = skProduct.subscriptionPeriod?.unit == .year
        let weeklyDivisor: NSDecimalNumber = isYearly ? 52 : 4
        let weekly = skProduct.price.dividing(by: weeklyDivisor)
        let weeklyStr = formatter.string(from: weekly) ?? ""
        return PaywallProduct(
            id: product.productId,
            title: isYearly ? "Year" : "Month",
            weeklyPrice: weeklyStr,
            originalPrice: price,
            saveBadge: isYearly ? "SAVE 80%" : nil
        )
    }

    enum PurchaseError: LocalizedError {
        case productNotFound(id: String, available: [String])
        case paywallNotLoaded

        var errorDescription: String? {
            switch self {
            case .paywallNotLoaded:
                return "Could not load products. Check Apphud paywall \"main\" is configured."
            case .productNotFound(let id, let available):
                return "Product \"\(id)\" not found. Available: \(available.joined(separator: ", "))"
            }
        }
    }
}

struct PaywallProduct: Identifiable {
    let id: String
    let title: String
    let weeklyPrice: String
    let originalPrice: String
    let saveBadge: String?
}
