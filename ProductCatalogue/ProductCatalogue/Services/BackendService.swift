import Foundation

enum BackendError: Error, Equatable, LocalizedError {
    case http(Int)
    case invalidResponse
    case offline
    case timedOut
    case connection

    var errorDescription: String? {
        switch self {
        case .http(400), .http(415): return "Some details were not accepted. Please check your input."
        case .http(404): return "This product is no longer available."
        case .http(429): return "Too many requests. Please wait a minute before trying again."
        case .http(502): return "The server cannot reach its product or email provider. Please try again later."
        case .http(503): return "This service is temporarily unavailable. Please try again later."
        case .http(504), .timedOut: return "The server took too long to respond. It may be starting up; please try again."
        case .http: return "The server could not complete the request. Please try again later."
        case .invalidResponse: return "The server returned an unexpected response. Please try again later."
        case .offline: return "You appear to be offline. Check your internet connection and try again."
        case .connection: return "Unable to connect to the server. Check your connection and try again."
        }
    }

    static func message(for error: Error) -> String {
        (error as? BackendError)?.errorDescription ?? "Something went wrong. Please try again."
    }

    var enquiryMessage: String {
        if self == .http(503) {
            return "Enquiry email is currently unavailable. Your enquiry has not been sent. Your details are still here."
        }
        return "\(errorDescription ?? "Request failed.") We couldn’t confirm delivery. Your details are still here. Retrying may send a duplicate email."
    }
}

struct BackendClient: Sendable {
    static var baseURL: URL {
        #if DEBUG
        if ProcessInfo.processInfo.arguments.contains("--use-local-backend") {
            return URL(string: "http://localhost:3000")!
        }
        #endif
        return URL(string: "https://product-catalogue-backend-qzyh.onrender.com")!
    }
    typealias Transport = @Sendable (URLRequest) async throws -> (Data, URLResponse)
    private let transport: Transport

    init(transport: @escaping Transport = { try await URLSession.shared.data(for: $0) }) {
        self.transport = transport
    }

    func request<T: Decodable>(
        _ path: String, query: [URLQueryItem] = [], body: Data? = nil,
        expectedStatus: Int = 200
    ) async throws -> T {
        var components = URLComponents(url: Self.baseURL.appendingPathComponent(path), resolvingAgainstBaseURL: false)!
        components.queryItems = query.isEmpty ? nil : query
        // Express decodes a raw '+' as a space in query strings.
        components.percentEncodedQuery = components.percentEncodedQuery?.replacingOccurrences(of: "+", with: "%2B")
        var request = URLRequest(url: components.url!)
        request.timeoutInterval = 60
        request.cachePolicy = .reloadIgnoringLocalCacheData
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        if let body {
            request.httpMethod = "POST"
            request.httpBody = body
            request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        }
        do {
            let (data, response) = try await transport(request)
            try Task.checkCancellation()
            guard let http = response as? HTTPURLResponse else { throw BackendError.invalidResponse }
            guard (200..<300).contains(http.statusCode) else { throw BackendError.http(http.statusCode) }
            guard http.statusCode == expectedStatus else { throw BackendError.invalidResponse }
            do { return try JSONDecoder().decode(T.self, from: data) }
            catch { throw BackendError.invalidResponse }
        } catch let error as URLError {
            switch error.code {
            case .cancelled: throw CancellationError()
            case .notConnectedToInternet: throw BackendError.offline
            case .timedOut: throw BackendError.timedOut
            default: throw BackendError.connection
            }
        }
    }
}

struct BackendProductService: ProductService {
    let client: BackendClient

    init(client: BackendClient = BackendClient()) { self.client = client }

    func fetchProducts() async throws -> [Product] {
        let items: [BackendProduct] = try await client.request("api/products")
        return items.map { $0.product() }
    }

    func fetchCatalogue() async throws -> CatalogueSnapshot {
        async let products = fetchProducts()
        async let categories: [String] = client.request("api/categories")
        async let featuredItems: [BackendProduct] = client.request("api/products/featured")
        let (all, names, highlights) = try await (products, categories, featuredItems)
        let featuredIDs = Set(highlights.map(\.id))
        return CatalogueSnapshot(
            products: all.map { $0.withFeatured(featuredIDs.contains($0.id)) },
            categories: Array(Set(names)).sorted(),
            featured: highlights.map { $0.product(featured: true) }
        )
    }

    func fetchProducts(in category: String) async throws -> [Product] {
        let items: [BackendProduct] = try await client.request("api/products", query: [URLQueryItem(name: "category", value: category)])
        return items.map { $0.product() }
    }

    func searchProducts(_ term: String) async throws -> [Product] {
        let items: [BackendProduct] = try await client.request("api/products/search", query: [URLQueryItem(name: "q", value: term)])
        return items.map { $0.product() }
    }

    func fetchProduct(id: Int) async throws -> Product {
        let item: BackendProduct = try await client.request("api/products/\(id)")
        guard item.id == id else { throw BackendError.invalidResponse }
        return item.product()
    }
}

private struct BackendProduct: Decodable {
    let id: Int
    let title: String
    let description: String
    let price: Decimal
    let category: String
    let image: URL

    func product(featured: Bool = false) -> Product {
        Product(id: id, title: title, description: description, price: price,
                category: category, imageURL: image, isFeatured: featured)
    }
}

extension Product {
    func withFeatured(_ featured: Bool) -> Product {
        Product(id: id, title: title, description: description, price: price,
                category: category, imageURL: imageURL, isFeatured: featured)
    }
}

struct BackendEnquiryService: EnquiryService {
    let client: BackendClient
    init(client: BackendClient = BackendClient()) { self.client = client }

    func send(_ enquiry: ProductEnquiry) async throws {
        let details = enquiry.details
        // The strict backend schema has no phone field; preserve it in the message.
        let message = details.phone.isEmpty ? details.message : "\(details.message)\n\nPhone: \(details.phone)"
        let body = EnquiryBody(name: details.name, email: details.email, message: message, productId: details.productID)
        let receipt: Receipt = try await client.request("api/enquiries", body: JSONEncoder().encode(body), expectedStatus: 202)
        guard receipt.status == "accepted", UUID(uuidString: receipt.id) != nil else {
            throw BackendError.invalidResponse
        }
    }

    private struct EnquiryBody: Encodable {
        let name: String
        let email: String
        let message: String
        let productId: Int
    }
    private struct Receipt: Decodable {
        let status: String
        let id: String
    }
}
