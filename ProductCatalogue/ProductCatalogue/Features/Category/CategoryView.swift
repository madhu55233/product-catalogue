import SwiftUI

struct CategoryView: View {
    let category: String
    let featuredProducts: [Product]
    let additionalProducts: [Product]

    var body: some View {
        Group {
            if featuredProducts.isEmpty && additionalProducts.isEmpty {
                ContentUnavailableView(
                    "No products in this category",
                    systemImage: "shippingbox",
                    description: Text("Please explore another category.")
                )
            } else {
                ScrollView {
                    VStack(alignment: .leading, spacing: 24) {
                        if !featuredProducts.isEmpty {
                            productSection("Featured products", products: featuredProducts)
                        }

                        if !additionalProducts.isEmpty {
                            productSection("More products", products: additionalProducts)
                        }
                    }
                    .padding()
                }
            }
        }
        .navigationTitle(category)
        .navigationBarTitleDisplayMode(.inline)
    }

    private func productSection(_ title: String, products: [Product]) -> some View {
        VStack(alignment: .leading, spacing: 16) {
            Text(title)
                .font(.title2.bold())
                .accessibilityAddTraits(.isHeader)

            ProductGrid(products: products)
        }
    }
}