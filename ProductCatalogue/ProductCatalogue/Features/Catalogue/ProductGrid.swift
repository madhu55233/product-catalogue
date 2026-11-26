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
                ProductTile(product: product)
            }
        }
    }
}