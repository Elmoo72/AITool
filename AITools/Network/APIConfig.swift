import Foundation

// MARK: - Secrets
// ⚠️ SECURITY: Before committing to git, move values below to a .xcconfig
// that is listed in .gitignore. The backendToken is an ADMIN-level JWT —
// rotate it and replace with a dynamic auth endpoint before App Store release.
enum Secrets {
    /// Apphud publishable key — safe to ship, but prefer xcconfig for consistency.
    static let apphudAPIKey = "app_FmCjFTwjWpcLSafxT8vCDeVffJyfFS"
    /// Backend admin JWT. ⚠️ Rotate before release and switch to a proper auth flow.
    static let backendToken = "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJzdWIiOiIxIiwiZW1haWwiOiJzaGFyb3ZfMTk5OUBsaXN0LnJ1Iiwicm9sZSI6IkFETUlOIiwiZXhwIjo0OTM1MjA4NjcxLCJpYXQiOjE3ODE2MDg2NzEsInR5cGUiOiJhY2Nlc3MifQ.0GRnZq1LZA__0G0tYEsPER8lQiCiX_myE6_T_nMwUmc"
}

// MARK: - API Config
enum APIConfig {
    static let baseURL = "https://nebulaapps.site"
    static let appID = "com.labs.fviu"
    static var bearerToken: String { Secrets.backendToken }
}
