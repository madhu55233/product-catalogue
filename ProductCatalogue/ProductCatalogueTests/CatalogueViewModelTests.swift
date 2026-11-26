import Foundation
import Testing
@testable import ProductCatalogue

@MainActor
struct CatalogueViewModelTests {
    @Test func startsIdle() {
        let viewModel = CatalogueViewModel(service: MockProductService())

        #expect(viewModel.state == .idle)
        #expect(viewModel.featuredProducts.isEmpty)
    }

    @Test func loadsOnlySelectedFeaturedProductsForHome() async throws {
        let products = try await MockProductService().fetchProducts()
        let viewModel = CatalogueViewModel(service: StubProductService(response: .success(products)))

        await viewModel.load()

        #expect(viewModel.state == .loaded(products))
        #expect(viewModel.featuredProducts == products.filter(\.isFeatured))
        #expect(viewModel.featuredProducts.count == 5)
    }

    @Test func exposesLoadingStateWhileFetching() async {
        let service = StubProductService(response: .success([]))
        let viewModel = CatalogueViewModel(service: service)
        service.onFetch = { [weak viewModel] in
            #expect(viewModel?.state == .loading)
        }

        await viewModel.load()

        #expect(service.requestCount == 1)
        #expect(viewModel.state == .loaded([]))
    }

    @Test func emptyResponseIsSuccessfulNotAnError() async {
        let viewModel = CatalogueViewModel(service: StubProductService(response: .success([])))

        await viewModel.load()

        #expect(viewModel.state == .loaded([]))
        #expect(viewModel.featuredProducts.isEmpty)
    }

    @Test func catalogueWithoutFeaturedProductsDoesNotPromoteOtherProducts() async throws {
        let products = try await MockProductService().fetchProducts().filter { !$0.isFeatured }
        let viewModel = CatalogueViewModel(service: StubProductService(response: .success(products)))

        await viewModel.load()

        #expect(!products.isEmpty)
        #expect(viewModel.state == .loaded(products))
        #expect(viewModel.featuredProducts.isEmpty)
    }

    @Test func failureCanBeRetriedSuccessfully() async throws {
        let service = StubProductService(response: .failure(TestError.offline))
        let viewModel = CatalogueViewModel(service: service)

        await viewModel.load()
        #expect(viewModel.state == .failed)

        let products = try await MockProductService().fetchProducts()
        service.response = .success(products)
        await viewModel.load()

        #expect(service.requestCount == 2)
        #expect(viewModel.state == .loaded(products))
    }

    @Test func cancellationReturnsToIdleAndAllowsAnotherLoad() async {
        let service = StubProductService(response: .failure(CancellationError()))
        let viewModel = CatalogueViewModel(service: service)

        await viewModel.load()
        #expect(viewModel.state == .idle)

        service.response = .success([])
        await viewModel.load()
        #expect(viewModel.state == .loaded([]))
    }

    @Test func loadedCatalogueIsNotFetchedAgain() async {
        let service = StubProductService(response: .success([]))
        let viewModel = CatalogueViewModel(service: service)

        await viewModel.load()
        await viewModel.load()

        #expect(service.requestCount == 1)
    }

}

private enum TestError: Error {
    case offline
}

@MainActor
private final class StubProductService: ProductService {
    var response: Result<[Product], Error>
    var onFetch: (@MainActor () -> Void)?
    private(set) var requestCount = 0

    init(response: Result<[Product], Error>) {
        self.response = response
    }

    func fetchProducts() async throws -> [Product] {
        requestCount += 1
        onFetch?()
        return try response.get()
    }
}
