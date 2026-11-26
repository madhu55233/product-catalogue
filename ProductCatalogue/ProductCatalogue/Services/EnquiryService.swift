import Foundation

protocol EnquiryService {
    /// Return only after the backend confirms successful email submission.
    /// Throw on failure or an ambiguous response; never simulate success in production.
    func send(_ enquiry: ProductEnquiry) async throws
}

enum EnquiryServiceError: Error {
    case notConfigured
}

/// Safe default until the sales inbox and backend contract are supplied.
/// Email-provider credentials must remain on the backend, never in the iOS app.
struct UnavailableEnquiryService: EnquiryService {
    func send(_ enquiry: ProductEnquiry) async throws {
        throw EnquiryServiceError.notConfigured
    }
}
