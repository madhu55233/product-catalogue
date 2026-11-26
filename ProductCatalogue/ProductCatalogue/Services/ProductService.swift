import Foundation

protocol ProductService: Sendable {
    func fetchProducts() async throws -> [Product]
    func fetchCatalogue() async throws -> CatalogueSnapshot
    func fetchProducts(in category: String) async throws -> [Product]
    func searchProducts(_ term: String) async throws -> [Product]
    func fetchProduct(id: Int) async throws -> Product
}

struct CatalogueSnapshot: Sendable {
    let products: [Product]
    let categories: [String]
    let featured: [Product]
}

// Defaults keep previews and test doubles independent of the network.
extension ProductService {
    func fetchCatalogue() async throws -> CatalogueSnapshot {
        let products = try await fetchProducts()
        return CatalogueSnapshot(products: products,
                                 categories: Array(Set(products.map(\.category))).sorted(),
                                 featured: products.filter(\.isFeatured))
    }

    func fetchProducts(in category: String) async throws -> [Product] {
        try await fetchProducts().filter { $0.category == category }
    }

    func searchProducts(_ term: String) async throws -> [Product] {
        try await fetchProducts().filter { $0.title.localizedStandardContains(term) }
    }

    func fetchProduct(id: Int) async throws -> Product {
        guard let product = try await fetchProducts().first(where: { $0.id == id }) else {
            throw BackendError.http(404)
        }
        return product
    }
}
