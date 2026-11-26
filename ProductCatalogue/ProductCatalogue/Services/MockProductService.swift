import Foundation

struct MockProductService: ProductService {
    func fetchProducts() async throws -> [Product] {
        Self.products
    }

    private static let products: [Product] = [
        Product(
            id: 1,
            title: "Everyday Backpack",
            description: "A lightweight backpack with a padded laptop pocket.",
            price: Decimal(65),
            category: "Accessories",
            imageURL: nil,
            isFeatured: true
        ),
        Product(
            id: 2,
            title: "Wireless Headphones",
            description: "Over-ear headphones with comfortable ear cushions.",
            price: Decimal(120),
            category: "Electronics",
            imageURL: nil,
            isFeatured: true
        ),
        Product(
            id: 3,
            title: "Cotton T-Shirt",
            description: "A soft cotton T-shirt for everyday wear.",
            price: Decimal(25),
            category: "Clothing",
            imageURL: nil,
            isFeatured: true
        ),
        Product(
            id: 4,
            title: "Desk Lamp",
            description: "An adjustable LED lamp for your workspace.",
            price: Decimal(45),
            category: "Electronics",
            imageURL: nil,
            isFeatured: true
        ),
        Product(
            id: 5,
            title: "Silver Necklace",
            description: "A simple silver necklace with a small pendant.",
            price: Decimal(80),
            category: "Accessories",
            imageURL: nil,
            isFeatured: true
        ),
        Product(
            id: 6,
            title: "Portable Speaker",
            description: "A compact wireless speaker for music on the go.",
            price: Decimal(55),
            category: "Electronics",
            imageURL: nil,
            isFeatured: false
        ),
        Product(
            id: 7,
            title: "Canvas Tote",
            description: "A reusable canvas bag with reinforced handles.",
            price: Decimal(20),
            category: "Accessories",
            imageURL: nil,
            isFeatured: false
        )
    ]
}