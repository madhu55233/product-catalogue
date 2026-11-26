import SwiftUI

extension EnvironmentValues {
    @Entry var productService: (any ProductService)? = nil
    @Entry var featuredProductIDs: Set<Int> = []
}

@MainActor
@Observable
final class ResourceModel<Value> {
    enum State {
        case loading
        case loaded(Value)
        case failed(String)
    }
    private(set) var state: State = .loading
    private var requestID = UUID()

    func load(_ operation: () async throws -> Value) async {
        let id = UUID()
        requestID = id
        state = .loading
        do {
            let value = try await operation()
            try Task.checkCancellation()
            guard id == requestID else { return }
            state = .loaded(value)
        } catch {
            guard id == requestID, !Task.isCancelled, !(error is CancellationError) else { return }
            state = .failed(BackendError.message(for: error))
        }
    }
}

struct ResourceView<Value, Content: View>: View {
    let title: String
    let operation: () async throws -> Value
    @ViewBuilder let content: (Value) -> Content
    @State private var model = ResourceModel<Value>()
    @State private var attempt = 0

    var body: some View {
        Group {
            switch model.state {
            case .loading:
                ProgressView("Loading…")
            case .failed(let message):
                ContentUnavailableView {
                    Label(title, systemImage: "exclamationmark.triangle")
                } description: {
                    Text(message)
                } actions: {
                    Button("Retry") { attempt += 1 }
                        .buttonStyle(.borderedProminent)
                }
            case .loaded(let value):
                content(value)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(CatalogueTheme.background)
        .task(id: attempt) {
            if case .loaded = model.state { return }
            await model.load(operation)
        }
    }
}

struct RemoteSearchView: View {
    let service: any ProductService
    let term: String
    @Environment(\.featuredProductIDs) private var featuredIDs

    var body: some View {
        if term.count > 100 {
            ContentUnavailableView("Search is too long", systemImage: "magnifyingglass",
                                   description: Text("Use no more than 100 characters."))
        } else {
            ResourceView(title: "Unable to search", operation: {
                try await Task.sleep(for: .milliseconds(350))
                return try await service.searchProducts(term)
            }) { products in
                ProductSearchResultsView(products: products.map { $0.withFeatured(featuredIDs.contains($0.id)) }, term: term)
            }
            .id(term)
        }
    }
}

struct RemoteCategoryView: View {
    let service: any ProductService
    let category: String
    let featuredIDs: Set<Int>

    var body: some View {
        ResourceView(title: "Unable to load category", operation: {
            try await service.fetchProducts(in: category)
        }) { products in
            if products.isEmpty {
                ContentUnavailableView("No products", systemImage: "shippingbox")
            } else {
                CategoryView(category: category,
                             featuredProducts: products.filter { featuredIDs.contains($0.id) }.map { $0.withFeatured(true) },
                             additionalProducts: products.filter { !featuredIDs.contains($0.id) })
            }
        }
        .navigationTitle(category)
        .navigationBarTitleDisplayMode(.inline)
    }
}

struct RemoteProductDetailsView: View {
    let product: Product
    let service: (any ProductService)?

    var body: some View {
        Group {
            if let service {
                ResourceView(title: "Unable to load product", operation: {
                    try await service.fetchProduct(id: product.id)
                }) { detail in
                    ProductDetailsView(product: detail.withFeatured(product.isFeatured))
                }
            } else {
                ProductDetailsView(product: product)
            }
        }
        .navigationTitle("Product details")
        .navigationBarTitleDisplayMode(.inline)
    }
}
