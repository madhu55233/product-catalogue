import SwiftUI

struct CatalogueView: View {
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize
    @State private var viewModel: CatalogueViewModel
    @State private var loadAttempt = 0

    init(service: any ProductService) {
        _viewModel = State(initialValue: CatalogueViewModel(service: service))
    }

    var body: some View {
        Group {
            switch viewModel.state {
            case .idle, .loading:
                ProgressView("Loading products…")
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            case .failed:
                ContentUnavailableView {
                    Label("Unable to load products", systemImage: "wifi.exclamationmark")
                } description: {
                    Text("Please try again. If the problem continues, check your connection.")
                } actions: {
                    Button("Retry") {
                        loadAttempt += 1
                    }
                    .buttonStyle(.borderedProminent)
                }
            case .loaded:
                if viewModel.categories.isEmpty {
                    ContentUnavailableView(
                        "No products",
                        systemImage: "shippingbox",
                        description: Text("Products will appear here when available.")
                    )
                } else {
                    ScrollView {
                        VStack(alignment: .leading, spacing: 28) {
                            categoryLinks

                            Divider()

                            featuredSection
                        }
                        .frame(maxWidth: 960)
                        .padding()
                        .frame(maxWidth: .infinity)
                    }
                }
            }
        }
        .background(CatalogueTheme.background)
        .tint(CatalogueTheme.accent)
        .navigationTitle("Catalogue")
        .task(id: loadAttempt) {
            await viewModel.load()
        }
    }

    private var categoryColumns: [GridItem] {
        dynamicTypeSize.isAccessibilitySize
            ? [GridItem(.flexible())]
            : [GridItem(.adaptive(minimum: dynamicTypeSize >= .xxxLarge ? 160 : 104), spacing: 12, alignment: .top)]
    }

    private var categoryLinks: some View {
        VStack(alignment: .leading, spacing: 16) {
            sectionHeading("Categories", subtitle: "Browse by what you need.", symbol: "square.grid.2x2.fill")

            LazyVGrid(columns: categoryColumns, spacing: 12) {
                ForEach(viewModel.categories, id: \.self) { category in
                    let products = viewModel.products(in: category)
                    let count = products.featured.count + products.additional.count
                    let style = CatalogueCategoryStyle(category: category)
                    NavigationLink {
                        CategoryView(
                            category: category,
                            featuredProducts: products.featured,
                            additionalProducts: products.additional
                        )
                    } label: {
                        VStack(alignment: .leading, spacing: 12) {
                            HStack {
                                Image(systemName: style.symbol)
                                    .font(.title3.weight(.medium))
                                    .symbolRenderingMode(.hierarchical)
                                    .foregroundStyle(style.tint)
                                    .frame(width: 40, height: 40)
                                    .background(style.tint.opacity(0.12), in: RoundedRectangle(cornerRadius: 12))
                                Spacer(minLength: 0)
                                Image(systemName: "chevron.right")
                                    .font(.caption.weight(.semibold))
                                    .foregroundStyle(style.tint)
                            }
                            .accessibilityHidden(true)

                            VStack(alignment: .leading, spacing: 4) {
                                Text(category)
                                    .font(.subheadline.weight(.semibold))
                                    .foregroundStyle(.primary)
                                Text(count == 1 ? "1 product" : "\(count) products")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                            .fixedSize(horizontal: false, vertical: true)
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(12)
                        .background {
                            RoundedRectangle(cornerRadius: 16)
                                .fill(CatalogueTheme.surface)
                                .overlay {
                                    RoundedRectangle(cornerRadius: 16)
                                        .fill(style.tint.opacity(0.06))
                                }
                        }
                        .overlay {
                            RoundedRectangle(cornerRadius: 16)
                                .strokeBorder(style.tint.opacity(0.2))
                        }
                        .contentShape(RoundedRectangle(cornerRadius: 16))
                    }
                    .buttonStyle(.plain)
                    .accessibilityElement(children: .combine)
                    .accessibilityLabel("\(category), \(count == 1 ? "1 product" : "\(count) products")")
                    .accessibilityHint("Browse products in this category")
                    .accessibilityIdentifier("category-link-\(category)")
                }
            }
        }
    }

    private var featuredSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            sectionHeading("Featured products", subtitle: "Handpicked highlights from our catalogue.", symbol: "star.fill", tint: CatalogueTheme.ochre)

            if viewModel.featuredProducts.isEmpty {
                Text("No featured products yet. Explore a category above.")
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding()
                    .background(CatalogueTheme.surface, in: RoundedRectangle(cornerRadius: 16))
            } else {
                ProductGrid(products: viewModel.featuredProducts)
            }
        }
    }

    private func sectionHeading(_ title: String, subtitle: String, symbol: String, tint: Color = CatalogueTheme.accent) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            CatalogueSectionHeading(title: title, symbol: symbol, tint: tint)
            Text(subtitle)
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
    }
}

#Preview {
    NavigationStack {
        CatalogueView(service: MockProductService())
    }
}

#Preview("Large text · Dark") {
    NavigationStack {
        CatalogueView(service: MockProductService())
    }
    .environment(\.dynamicTypeSize, .accessibility3)
    .preferredColorScheme(.dark)
}
