import Foundation
import Testing
@testable import ProductCatalogue

private let itemJSON = #"{"id":1,"title":"Travel Bag","description":"Useful storage","price":109.95,"category":"men's clothing","image":"https://example.org/bag.png","rating":{"rate":4.5,"count":120}}"#

private func response(_ request: URLRequest, status: Int = 200, json: String) -> (Data, URLResponse) {
    (Data(json.utf8), HTTPURLResponse(url: request.url!, statusCode: status,
                                    httpVersion: nil, headerFields: ["Content-Type": "application/json"])!)
}

@MainActor
struct BackendServiceTests {
    @Test func catalogueUsesBackendCategoriesAndFeaturedEndpoint() async throws {
        let client = BackendClient { request in
            #expect(request.url?.host == "product-catalogue-backend-qzyh.onrender.com")
            #expect(request.httpMethod == "GET")
            switch request.url?.path {
            case "/api/categories": return response(request, json: #"["men's clothing","electronics"]"#)
            case "/api/products", "/api/products/featured": return response(request, json: "[\(itemJSON)]")
            default: Issue.record("Unexpected endpoint"); return response(request, status: 404, json: "{}")
            }
        }
        let result = try await BackendProductService(client: client).fetchCatalogue()
        #expect(result.categories == ["electronics", "men's clothing"])
        #expect(result.featured.map(\.id) == [1])
        let product = try #require(result.products.first)
        #expect(product.title == "Travel Bag")
        #expect(product.description == "Useful storage")
        #expect(product.price == Decimal(string: "109.95"))
        #expect(product.imageURL?.absoluteString == "https://example.org/bag.png")
        #expect(product.isFeatured)
    }

    @Test func categoryAndSearchQueriesAreEncodedWithoutInjectingParameters() async throws {
        let term = "bag & coat + café"
        let client = BackendClient { request in
            let components = URLComponents(url: request.url!, resolvingAgainstBaseURL: false)!
            #expect(components.queryItems?.count == 1)
            #expect(components.queryItems?.first?.value == term)
            #expect(components.percentEncodedQuery?.contains("%2B") == true)
            #expect(components.percentEncodedQuery?.contains("+") == false)
            if components.path == "/api/products/search" {
                #expect(components.queryItems?.first?.name == "q")
            } else {
                #expect(components.path == "/api/products")
                #expect(components.queryItems?.first?.name == "category")
            }
            return response(request, json: "[]")
        }
        let service = BackendProductService(client: client)
        #expect(try await service.searchProducts(term).isEmpty)
        #expect(try await service.fetchProducts(in: term).isEmpty)
    }

    @Test func detailsUseIDEndpointAndRejectWrongProduct() async throws {
        let service = BackendProductService(client: BackendClient { request in
            #expect(["/api/products/1", "/api/products/2"].contains(request.url!.path))
            return response(request, json: itemJSON)
        })
        #expect(try await service.fetchProduct(id: 1).id == 1)
        await #expect(throws: BackendError.invalidResponse) { try await service.fetchProduct(id: 2) }
    }

    @Test(arguments: [400, 404, 429, 500, 502, 503, 504])
    func httpFailuresArePreserved(status: Int) async {
        let service = BackendProductService(client: BackendClient { request in
            response(request, status: status, json: #"{"error":"Provider unavailable"}"#)
        })
        await #expect(throws: BackendError.http(status)) { try await service.fetchProducts() }
        #expect(!(BackendError.http(status).errorDescription ?? "").isEmpty)
    }

    @Test(arguments: ["not json", "{}", "null", "[{\"id\":1}]"])
    func malformedProductsFailSafely(json: String) async {
        let service = BackendProductService(client: BackendClient { response($0, json: json) })
        await #expect(throws: BackendError.invalidResponse) { try await service.fetchProducts() }
    }

    @Test func offlineTimeoutAndCancellationHaveDistinctOutcomes() async {
        for (code, expected) in [(URLError.notConnectedToInternet, BackendError.offline), (.timedOut, .timedOut), (.cannotConnectToHost, .connection)] {
            let service = BackendProductService(client: BackendClient { _ in throw URLError(code) })
            await #expect(throws: expected) { try await service.fetchProducts() }
        }
        let cancelled = BackendProductService(client: BackendClient { _ in throw URLError(.cancelled) })
        await #expect(throws: CancellationError.self) { try await cancelled.fetchProducts() }
    }

    @Test func enquirySendsStrictBodyAndRequiresAcceptedReceipt() async throws {
        let client = BackendClient { request in
            #expect(request.url?.path == "/api/enquiries")
            #expect(request.httpMethod == "POST")
            #expect(request.value(forHTTPHeaderField: "Content-Type") == "application/json")
            let body = try #require(JSONSerialization.jsonObject(with: request.httpBody!) as? [String: Any])
            #expect(Set(body.keys) == ["name", "email", "message", "productId"])
            #expect(body["productId"] as? Int == 1)
            #expect(body["name"] as? String == "Buyer")
            #expect(body["email"] as? String == "buyer@example.org")
            #expect(body["message"] as? String == "Available?\n\nPhone: 123")
            return response(request, status: 202, json: #"{"status":"accepted","id":"550e8400-e29b-41d4-a716-446655440000"}"#)
        }
        try await BackendEnquiryService(client: client).send(enquiry)
    }

    @Test(arguments: ["{}", #"{"status":"failed","id":"550e8400-e29b-41d4-a716-446655440000"}"#, #"{"status":"accepted","id":""}"#])
    func unconfirmedReceiptNeverShowsThankYou(json: String) async {
        let service = BackendEnquiryService(client: BackendClient { response($0, status: 202, json: json) })
        await #expect(throws: BackendError.invalidResponse) { try await service.send(enquiry) }
    }

    @Test func enquiryRejectsWrongSuccessStatus() async {
        let service = BackendEnquiryService(client: BackendClient {
            response($0, status: 200, json: #"{"status":"accepted","id":"550e8400-e29b-41d4-a716-446655440000"}"#)
        })
        await #expect(throws: BackendError.invalidResponse) { try await service.send(enquiry) }
    }

    @Test func unavailableEmailPreservesFormAndNeverShowsThankYou() async {
        let service = BackendEnquiryService(client: BackendClient { response($0, status: 503, json: #"{"error":"Enquiry email is not configured."}"#) })
        let model = EnquiryViewModel(product: product, service: service)
        model.name = "Buyer"
        model.email = "buyer@example.org"
        model.message = "Available?"
        await model.submit()
        guard case .failed(let message) = model.state else {
            Issue.record("Must fail, not show Thank you")
            return
        }
        #expect(message.contains("not been sent"))
        #expect(model.name == "Buyer")
        #expect(model.message == "Available?")
    }

    @Test func catalogue502OffersAnErrorNotMockProducts() async {
        let service = BackendProductService(client: BackendClient { response($0, status: 502, json: "{}") })
        let model = CatalogueViewModel(service: service)
        await model.load()
        #expect(model.state == .failed)
        #expect(model.errorMessage.contains("server"))
        #expect(model.featuredProducts.isEmpty)
        #expect(model.categories.isEmpty)
    }

    @Test func resourceCanRetryAfterFailureAndLoadEmptyResults() async {
        let model = ResourceModel<[Product]>()
        await model.load { throw BackendError.http(502) }
        guard case .failed = model.state else { Issue.record("Expected failure"); return }
        await model.load { [] }
        guard case .loaded(let products) = model.state else { Issue.record("Expected recovery"); return }
        #expect(products.isEmpty)
    }

    @Test func lateResponseCannotOverwriteNewerResults() async {
        let model = ResourceModel<String>()
        var continuation: CheckedContinuation<String, Never>?
        let old = Task { await model.load { await withCheckedContinuation { continuation = $0 } } }
        while continuation == nil { await Task.yield() }
        await model.load { "new" }
        continuation?.resume(returning: "old")
        await old.value
        guard case .loaded(let value) = model.state else { Issue.record("Expected results"); return }
        #expect(value == "new")
    }

    @Test func cancelledResourceDoesNotPublishResults() async {
        let model = ResourceModel<String>()
        let task = Task {
            await model.load {
                try await Task.sleep(for: .seconds(10))
                return "stale"
            }
        }
        task.cancel()
        await task.value
        guard case .loading = model.state else { Issue.record("Cancelled result was published"); return }
    }

    private var product: Product {
        Product(id: 1, title: "Bag", description: "", price: 10, category: "electronics", imageURL: nil, isFeatured: false)
    }
    private var enquiry: ProductEnquiry {
        ProductEnquiry(id: UUID(), details: .init(productID: 1, productTitle: "Bag", name: "Buyer",
                                                email: "buyer@example.org", phone: "123", message: "Available?"))
    }
}
