//
//  ProductCatalogueTests.swift
//  ProductCatalogueTests
//
//  Created by Madhumitha on 26/11/26.
//

import Testing
@testable import ProductCatalogue

@MainActor
struct ProductCatalogueTests {
    @Test func mockCatalogueHasFiveFeaturedProducts() async throws {
        let service: any ProductService = MockProductService()

        let products = try await service.fetchProducts()

        #expect(products.filter(\.isFeatured).count == 5)
    }

    @Test func mockProductIDsAreUnique() async throws {
        let products = try await MockProductService().fetchProducts()

        #expect(Set(products.map(\.id)).count == products.count)
    }

    @Test func mockCategoryContainsFeaturedAndAdditionalProducts() async throws {
        let products = try await MockProductService().fetchProducts()
        let electronics = products.filter { $0.category == "Electronics" }

        #expect(electronics.contains { $0.isFeatured })
        #expect(electronics.contains { !$0.isFeatured })
    }
}
