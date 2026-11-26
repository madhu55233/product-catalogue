import Foundation

struct Product: Identifiable, Equatable, Sendable {
    let id: Int
    let title: String
    let description: String
    let price: Decimal
    let category: String
    let imageURL: URL?
    let isFeatured: Bool
}