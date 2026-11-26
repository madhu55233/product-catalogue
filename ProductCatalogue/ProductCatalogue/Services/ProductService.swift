protocol ProductService: Sendable {
    func fetchProducts() async throws -> [Product]
}