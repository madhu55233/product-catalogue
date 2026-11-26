import SwiftUI

struct ProductTile: View {
    let product: Product

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            AsyncImage(url: product.imageURL) { phase in
                switch phase {
                case .success(let image):
                    image
                        .resizable()
                        .scaledToFit()
                case .empty, .failure:
                    Image(systemName: "shippingbox")
                        .font(.largeTitle)
                        .foregroundStyle(.secondary)
                @unknown default:
                    Image(systemName: "shippingbox")
                        .font(.largeTitle)
                        .foregroundStyle(.secondary)
                }
            }
            .frame(maxWidth: .infinity)
            .frame(height: 120)
            .accessibilityHidden(true)

            Text(product.category)
                .font(.caption)
                .foregroundStyle(.secondary)

            Text(product.title)
                .font(.headline)
                .fixedSize(horizontal: false, vertical: true)

            Text(product.price, format: .currency(code: "USD"))
                .font(.subheadline.weight(.semibold))
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(.background, in: RoundedRectangle(cornerRadius: 16))
        .overlay {
            RoundedRectangle(cornerRadius: 16)
                .strokeBorder(.quaternary)
        }
        .accessibilityElement(children: .combine)
        .accessibilityIdentifier("product-tile-\(product.id)")
    }
}