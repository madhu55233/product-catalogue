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
    private let service: any ProductService

    var featuredProducts: [Product] {
        guard case let .loaded(products) = state else { return [] }
        return products.filter(\.isFeatured)
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
            let products = try await service.fetchProducts()
            try Task.checkCancellation()
            state = .loaded(products)
        } catch {
            // Leaving a screen is not a user-facing network failure.
            if Task.isCancelled || error is CancellationError {
                state = .idle
            } else {
                state = .failed
            }
        }
    }
}
