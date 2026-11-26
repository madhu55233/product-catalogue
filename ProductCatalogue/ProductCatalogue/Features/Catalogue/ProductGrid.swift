import SwiftUI

struct ProductGrid: View {
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize

    let products: [Product]

    private var columns: [GridItem] {
        dynamicTypeSize.isAccessibilitySize
            ? [GridItem(.flexible())]
            : [GridItem(.adaptive(minimum: 160), spacing: 16, alignment: .top)]
    }

    var body: some View {
        LazyVGrid(columns: columns, alignment: .leading, spacing: 16) {
            ForEach(products) { product in
                NavigationLink {
                    ProductDetailsView(product: product)
                } label: {
                    ProductTile(product: product)
                        .contentShape(RoundedRectangle(cornerRadius: 16))
                }
                .buttonStyle(.plain)
                .accessibilityElement(children: .combine)
                .accessibilityHint("View product details")
                .accessibilityIdentifier("product-tile-\(product.id)")
            }
        }
    }
}
