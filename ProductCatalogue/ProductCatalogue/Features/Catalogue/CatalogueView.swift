import SwiftUI

struct CatalogueView: View {
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
                if viewModel.featuredProducts.isEmpty {
                    ContentUnavailableView(
                        "No featured products",
                        systemImage: "shippingbox",
                        description: Text("Featured products will appear here when available.")
                    )
                } else {
                    ScrollView {
                        VStack(alignment: .leading, spacing: 16) {
                            Text("Featured products")
                                .font(.title2.bold())
                                .accessibilityAddTraits(.isHeader)

                            Text("Selected highlights from our catalogue.")
                                .foregroundStyle(.secondary)

                            ProductGrid(products: viewModel.featuredProducts)
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

}

#Preview {
    NavigationStack {
        CatalogueView(service: MockProductService())
    }
}
