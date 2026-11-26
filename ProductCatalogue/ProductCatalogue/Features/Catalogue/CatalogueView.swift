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
                        VStack(alignment: .leading, spacing: 16) {
                            categoryLinks

                            Text("Featured products")
                                .font(.title2.bold())
                                .accessibilityAddTraits(.isHeader)

                            if viewModel.featuredProducts.isEmpty {
                                Text("No featured products yet. Explore a category above.")
                                    .foregroundStyle(.secondary)
                            } else {
                                Text("Selected highlights from our catalogue.")
                                    .foregroundStyle(.secondary)

                                ProductGrid(products: viewModel.featuredProducts)
                            }
                        }
                        .padding()
                    }
                }
            }
        }
        .navigationTitle("Catalogue")
        .task(id: loadAttempt) {
            await viewModel.load()
        }
    }

    private var categoryColumns: [GridItem] {
        dynamicTypeSize.isAccessibilitySize
            ? [GridItem(.flexible())]
            : [GridItem(.adaptive(minimum: 160), spacing: 12, alignment: .top)]
    }

    private var categoryLinks: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Categories")
                .font(.title2.bold())
                .accessibilityAddTraits(.isHeader)

            LazyVGrid(columns: categoryColumns, spacing: 12) {
                ForEach(viewModel.categories, id: \.self) { category in
                    NavigationLink {
                        let products = viewModel.products(in: category)
                        CategoryView(
                            category: category,
                            featuredProducts: products.featured,
                            additionalProducts: products.additional
                        )
                    } label: {
                        HStack {
                            Text(category)
                                .font(.headline)
                                .fixedSize(horizontal: false, vertical: true)
                            Spacer(minLength: 4)
                            Image(systemName: "chevron.right")
                                .foregroundStyle(.secondary)
                                .accessibilityHidden(true)
                        }
                        .frame(maxWidth: .infinity, minHeight: 64, alignment: .leading)
                        .padding(12)
                        .background(.quaternary, in: RoundedRectangle(cornerRadius: 12))
                    }
                    .buttonStyle(.plain)
                    .accessibilityIdentifier("category-link-\(category)")
                }
            }
        }
        .padding(.bottom, 8)
    }
}

#Preview {
    NavigationStack {
        CatalogueView(service: MockProductService())
    }
}
