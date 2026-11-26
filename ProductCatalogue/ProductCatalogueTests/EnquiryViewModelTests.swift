import Foundation
import Testing
@testable import ProductCatalogue

@MainActor
struct EnquiryViewModelTests {
    private let product = Product(id: 4, title: "Desk Lamp", description: "An adjustable lamp.", price: 45,
                                  category: "Electronics", imageURL: nil, isFeatured: true)

    @Test func startsWithAnEmptyFormAndNoValidationMessages() {
        let viewModel = EnquiryViewModel(product: product, service: RecordingEnquiryService())
        #expect(viewModel.state == .editing)
        #expect(viewModel.name.isEmpty)
        #expect(viewModel.email.isEmpty)
        #expect(viewModel.validationMessage(for: .name) == nil)
        #expect(viewModel.validationMessage(for: .email) == nil)
    }

    @Test func missingContactDetailsDoNotCallTheService() async {
        let service = RecordingEnquiryService()
        let viewModel = EnquiryViewModel(product: product, service: service)
        viewModel.name = " \n "
        await viewModel.submit()
        #expect(viewModel.validationMessage(for: .name) != nil)
        #expect(viewModel.validationMessage(for: .email) != nil)
        #expect(service.requests.isEmpty)
        #expect(viewModel.state == .editing)
    }

    @Test(arguments: ["", "name", "name@", "@example.com", "name@example", "name @example.com", "a@example.com\r\nBcc:other@example.com"])
    func invalidEmailDoesNotSend(email: String) async {
        let service = RecordingEnquiryService()
        let viewModel = validForm(service: service)
        viewModel.email = email
        await viewModel.submit()
        #expect(viewModel.validationMessage(for: .email) != nil)
        #expect(service.requests.isEmpty)
    }

    @Test func oversizedFieldsDoNotSend() async {
        let service = RecordingEnquiryService()
        let viewModel = validForm(service: service)
        viewModel.name = String(repeating: "a", count: 101)
        viewModel.phone = String(repeating: "1", count: 41)
        viewModel.message = String(repeating: "a", count: 2001)
        await viewModel.submit()
        #expect(viewModel.validationMessage(for: .name) != nil)
        #expect(viewModel.validationMessage(for: .phone) != nil)
        #expect(viewModel.validationMessage(for: .message) != nil)
        #expect(service.requests.isEmpty)
    }

    @Test func successSendsSelectedProductAndNormalizedContactsThenClearsPrivateData() async throws {
        let service = RecordingEnquiryService()
        let viewModel = validForm(service: service)
        viewModel.name = "  Alex Customer \n"
        viewModel.email = " alex@example.com "
        viewModel.phone = " +44 1234 567890 "
        viewModel.message = " Is this available? "
        await viewModel.submit()

        let enquiry = try #require(service.requests.first)
        #expect(enquiry.details.productID == product.id)
        #expect(enquiry.details.productTitle == product.title)
        #expect(enquiry.details.name == "Alex Customer")
        #expect(enquiry.details.email == "alex@example.com")
        #expect(enquiry.details.phone == "+44 1234 567890")
        #expect(enquiry.details.message == "Is this available?")
        #expect(viewModel.state == .sent)
        #expect(viewModel.name.isEmpty && viewModel.email.isEmpty && viewModel.phone.isEmpty && viewModel.message.isEmpty)
    }

    @Test func phoneAndMessageAreOptional() async {
        let service = RecordingEnquiryService()
        let viewModel = validForm(service: service)
        await viewModel.submit()
        #expect(viewModel.state == .sent)
        #expect(service.requests.first?.details.phone == "")
        #expect(service.requests.first?.details.message == "")
    }

    @Test func failurePreservesDetailsAndRetryReusesTheSameRequestID() async {
        let service = RecordingEnquiryService()
        service.result = .failure(TestFailure.offline)
        let viewModel = validForm(service: service)
        await viewModel.submit()
        guard case .failed = viewModel.state else {
            Issue.record("Expected failed submission")
            return
        }
        #expect(viewModel.name == "Alex Customer")
        #expect(viewModel.email == "alex@example.com")
        let firstID = service.requests.first?.id
        service.result = .success(())
        await viewModel.submit()
        #expect(service.requests.count == 2)
        #expect(service.requests.last?.id == firstID)
        #expect(viewModel.state == .sent)
    }

    @Test func changedRetryDetailsGetANewRequestID() async {
        let service = RecordingEnquiryService()
        service.result = .failure(TestFailure.offline)
        let viewModel = validForm(service: service)
        await viewModel.submit()
        let firstID = service.requests.first?.id
        viewModel.email = "another@example.com"
        await viewModel.submit()
        #expect(service.requests.count == 2)
        #expect(service.requests.last?.id != firstID)
        #expect(service.requests.last?.details.email == "another@example.com")
    }

    @Test func duplicateSubmissionsAreBlockedWhileSendingAndAfterSuccess() async {
        let service = RecordingEnquiryService()
        let viewModel = validForm(service: service)
        service.onSend = { [weak viewModel] in
            #expect(viewModel?.state == .submitting)
            await viewModel?.submit()
            #expect(viewModel?.state == .submitting)
        }
        await viewModel.submit()
        await viewModel.submit()
        #expect(service.requests.count == 1)
        #expect(viewModel.state == .sent)
    }

    @Test func cancellationDoesNotShowThankYouAndRetainsContacts() async {
        let service = RecordingEnquiryService()
        service.result = .failure(CancellationError())
        let viewModel = validForm(service: service)
        await viewModel.submit()
        #expect(viewModel.state == .editing)
        #expect(viewModel.name == "Alex Customer")
        #expect(viewModel.email == "alex@example.com")
    }

    @Test func unconfiguredDeliveryNeverReportsSuccess() async {
        let viewModel = validForm(service: UnavailableEnquiryService())
        await viewModel.submit()
        guard case let .failed(message) = viewModel.state else {
            Issue.record("Unconfigured delivery must fail, never display Thank you")
            return
        }
        #expect(message.contains("not been sent"))
        #expect(viewModel.name == "Alex Customer")
    }

    private func validForm(service: any EnquiryService) -> EnquiryViewModel {
        let viewModel = EnquiryViewModel(product: product, service: service)
        viewModel.name = "Alex Customer"
        viewModel.email = "alex@example.com"
        return viewModel
    }
}

private enum TestFailure: Error {
    case offline
}

@MainActor
private final class RecordingEnquiryService: EnquiryService {
    var result: Result<Void, Error> = .success(())
    var onSend: (@MainActor () async -> Void)?
    private(set) var requests: [ProductEnquiry] = []

    func send(_ enquiry: ProductEnquiry) async throws {
        requests.append(enquiry)
        await onSend?()
        try result.get()
    }
}
