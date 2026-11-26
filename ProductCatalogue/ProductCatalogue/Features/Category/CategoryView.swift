import SwiftUI

struct CategoryView: View {
    let category: String
    let featuredProducts: [Product]
    let additionalProducts: [Product]

    private var style: CatalogueCategoryStyle {
        CatalogueCategoryStyle(category: category)
    }

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
                    VStack(alignment: .leading, spacing: 28) {
                        categorySummary

                        if !featuredProducts.isEmpty {
                            productSection("Featured products", symbol: "star.fill", tint: CatalogueTheme.ochre, products: featuredProducts)
                        }

                        if !additionalProducts.isEmpty {
                            productSection("More products", symbol: "square.grid.2x2.fill", tint: style.tint, products: additionalProducts)
                        }
                    }
                    .frame(maxWidth: 960)
                    .padding()
                    .frame(maxWidth: .infinity)
                }
            }
        }
        .background(CatalogueTheme.background)
        .navigationTitle(category)
        .navigationBarTitleDisplayMode(.inline)
    }

    private var categorySummary: some View {
        let count = featuredProducts.count + additionalProducts.count
        return HStack(alignment: .top, spacing: 16) {
            Image(systemName: style.symbol)
                .font(.title2)
                .symbolRenderingMode(.hierarchical)
                .foregroundStyle(style.tint)
                .frame(width: 48, height: 48)
                .background(style.tint.opacity(0.12), in: RoundedRectangle(cornerRadius: 14))
                .accessibilityHidden(true)

            VStack(alignment: .leading, spacing: 4) {
                Text(category)
                    .font(.title2.weight(.semibold))
                    .accessibilityAddTraits(.isHeader)
                Text(count == 1 ? "1 product to explore" : "\(count) products to explore")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
            .fixedSize(horizontal: false, vertical: true)
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding(20)
        .background(style.tint.opacity(0.07), in: RoundedRectangle(cornerRadius: 20))
        .overlay {
            RoundedRectangle(cornerRadius: 20)
                .strokeBorder(style.tint.opacity(0.16))
        }
    }

    private func productSection(_ title: String, symbol: String, tint: Color, products: [Product]) -> some View {
        VStack(alignment: .leading, spacing: 16) {
            CatalogueSectionHeading(title: title, symbol: symbol, tint: tint)

            ProductGrid(products: products)
        }
    }
}
