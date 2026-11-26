import Foundation
import Observation

@MainActor
@Observable
final class CatalogueViewModel {
    enum State: Equatable {
        case idle
        case loading
        case loaded([Product])
        case failed
    }

    private(set) var state: State = .idle
    var searchText = ""
    let service: any ProductService
    private var snapshot: CatalogueSnapshot?
    private(set) var errorMessage = ""

    var searchTerm: String {
        guard case .loaded = state else { return "" }
        return searchText.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    var isSearching: Bool {
        !searchTerm.isEmpty
    }

    var searchResults: [Product] {
        guard isSearching, case let .loaded(products) = state else { return [] }
        return products.filter { product in
            product.title.localizedStandardContains(searchTerm)
        }
    }

    func clearSearch() {
        searchText = ""
    }

    var featuredProducts: [Product] {
        guard case let .loaded(products) = state else { return [] }
        return snapshot?.featured ?? products.filter(\.isFeatured)
    }

    var categories: [String] {
        guard case let .loaded(products) = state else { return [] }
        return snapshot?.categories ?? Array(Set(products.map(\.category))).sorted()
    }

    func products(in category: String) -> (featured: [Product], additional: [Product]) {
        guard case let .loaded(products) = state else { return ([], []) }
        let categoryProducts = products.filter { $0.category == category }
        return (
            featured: categoryProducts.filter(\.isFeatured),
            additional: categoryProducts.filter { !$0.isFeatured }
        )
    }

    init(service: any ProductService) {
        self.service = service
    }

    func load() async {
        // Do not start overlapping requests or reload an already loaded catalogue.
        switch state {
        case .loading, .loaded:
            return
        case .idle, .failed:
            break
        }

        state = .loading

        do {
            let result = try await service.fetchCatalogue()
            try Task.checkCancellation()
            snapshot = result
            state = .loaded(result.products)
        } catch {
            // Leaving a screen is not a user-facing network failure.
            if Task.isCancelled || error is CancellationError {
                state = .idle
            } else {
                errorMessage = BackendError.message(for: error)
                state = .failed
            }
        }
    }
}
