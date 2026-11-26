import SwiftUI

struct ProductDetailsView: View {
    @Environment(\.enquiryService) private var enquiryService
    @State private var isEnquiryPresented = false

    let product: Product

    private var style: CatalogueCategoryStyle {
        CatalogueCategoryStyle(category: product.category)
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                productImage

                VStack(alignment: .leading, spacing: 12) {
                    Label(product.category, systemImage: style.symbol)
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(style.tint)
                        .accessibilityIdentifier("product-details-category")

                    Text(product.title)
                        .font(.largeTitle.weight(.bold))
                        .fixedSize(horizontal: false, vertical: true)
                        .accessibilityAddTraits(.isHeader)
                        .accessibilityIdentifier("product-details-title")

                    Text(product.price, format: .currency(code: "USD"))
                        .font(.title2.weight(.semibold))
                        .foregroundStyle(CatalogueTheme.accent)
                        .fixedSize(horizontal: false, vertical: true)
                        .accessibilityIdentifier("product-details-price")

                    if product.isFeatured {
                        Label("Featured product", systemImage: "star.fill")
                            .font(.subheadline.weight(.semibold))
                            .foregroundStyle(CatalogueTheme.ochre)
                            .fixedSize(horizontal: false, vertical: true)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 8)
                            .background(CatalogueTheme.ochre.opacity(0.1), in: RoundedRectangle(cornerRadius: 10))
                            .accessibilityIdentifier("product-details-featured")
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)

                VStack(alignment: .leading, spacing: 12) {
                    CatalogueSectionHeading(title: "About this product", symbol: "text.alignleft", tint: style.tint)
                    Text(product.description.isEmpty ? "No description available." : product.description)
                        .font(.body)
                        .fixedSize(horizontal: false, vertical: true)
                        .accessibilityIdentifier("product-details-description")
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(20)
                .background(CatalogueTheme.surface, in: RoundedRectangle(cornerRadius: 20))
            }
            .frame(maxWidth: 720)
            .padding()
            .frame(maxWidth: .infinity)
        }
        .accessibilityIdentifier("product-details")
        .safeAreaInset(edge: .bottom) {
            Button {
                isEnquiryPresented = true
            } label: {
                Label("Enquire", systemImage: "envelope.fill")
                    .font(.headline)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 4)
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.large)
            .accessibilityIdentifier("product-enquire-button")
            .padding()
            .background(CatalogueTheme.surface)
        }
        .sheet(isPresented: $isEnquiryPresented) {
            NavigationStack {
                EnquiryView(product: product, service: enquiryService)
            }
        }
        .background(CatalogueTheme.background)
        .tint(CatalogueTheme.accent)
        .navigationTitle("Product details")
        .navigationBarTitleDisplayMode(.inline)
    }

    private var productImage: some View {
        Group {
            if let imageURL = product.imageURL {
                AsyncImage(url: imageURL) { phase in
                    switch phase {
                    case .empty:
                        ProgressView("Loading image…")
                    case .success(let image):
                        image
                            .resizable()
                            .scaledToFit()
                            .accessibilityLabel("Image of \(product.title)")
                    case .failure:
                        imagePlaceholder
                    @unknown default:
                        imagePlaceholder
                    }
                }
            } else {
                imagePlaceholder
            }
        }
        .padding(24)
        .frame(maxWidth: .infinity)
        .frame(height: 260)
        .background {
            LinearGradient(
                colors: [style.tint.opacity(0.14), style.tint.opacity(0.04)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        }
        .clipShape(RoundedRectangle(cornerRadius: 24))
        .overlay {
            RoundedRectangle(cornerRadius: 24)
                .strokeBorder(style.tint.opacity(0.16))
        }
    }

    private var imagePlaceholder: some View {
        VStack(spacing: 16) {
            Image(systemName: style.symbol)
                .font(.system(size: 64, weight: .light))
                .symbolRenderingMode(.hierarchical)
                .foregroundStyle(style.tint)
                .accessibilityHidden(true)
            Text("No image available")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
    }
}

#Preview {
    NavigationStack {
        ProductDetailsView(product: Product(
            id: 1,
            title: "Everyday Backpack",
            description: "A lightweight backpack with a padded laptop pocket.",
            price: 65,
            category: "Accessories",
            imageURL: nil,
            isFeatured: true
        ))
    }
}
