import Foundation

struct ProductEnquiry: Equatable, Sendable {
    struct Details: Equatable, Sendable {
        let productID: Int
        let productTitle: String
        let name: String
        let email: String
        let phone: String
        let message: String
    }

    /// A delivery adapter should use this as an idempotency key for retries.
    let id: UUID
    let details: Details
}
