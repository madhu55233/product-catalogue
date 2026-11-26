import SwiftUI

struct ProductTile: View {
    let product: Product

    private var style: CatalogueCategoryStyle {
        CatalogueCategoryStyle(category: product.category)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            AsyncImage(url: product.imageURL) { phase in
                switch phase {
                case .success(let image):
                    image
                        .resizable()
                        .scaledToFit()
                case .empty, .failure:
                    placeholder
                @unknown default:
                    placeholder
                }
            }
            .padding(16)
            .frame(maxWidth: .infinity)
            .frame(height: 140)
            .background {
                LinearGradient(
                    colors: [style.tint.opacity(0.14), style.tint.opacity(0.04)],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            }
            .clipped()
            .accessibilityHidden(true)

            VStack(alignment: .leading, spacing: 8) {
                Text(product.category)
                    .font(.caption.weight(.medium))
                    .foregroundStyle(style.tint)

                Text(product.title)
                    .font(.headline)
                    .fixedSize(horizontal: false, vertical: true)

                Text(product.price, format: .currency(code: "USD"))
                    .font(.headline)
                    .foregroundStyle(CatalogueTheme.accent)
                    .fixedSize(horizontal: false, vertical: true)
                    .padding(.top, 4)

                if product.isFeatured {
                    Label("Featured", systemImage: "star.fill")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(CatalogueTheme.ochre)
                        .fixedSize(horizontal: false, vertical: true)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 5)
                        .background(CatalogueTheme.ochre.opacity(0.1), in: RoundedRectangle(cornerRadius: 8))
                }
            }
            .padding(16)
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(CatalogueTheme.surface)
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .overlay {
            RoundedRectangle(cornerRadius: 16)
                .strokeBorder(style.tint.opacity(0.16))
        }
    }

    private var placeholder: some View {
        Image(systemName: style.symbol)
            .font(.system(size: 38, weight: .light))
            .symbolRenderingMode(.hierarchical)
            .foregroundStyle(style.tint)
            .frame(width: 84, height: 84)
            .background(style.tint.opacity(0.08), in: Circle())
    }
}
