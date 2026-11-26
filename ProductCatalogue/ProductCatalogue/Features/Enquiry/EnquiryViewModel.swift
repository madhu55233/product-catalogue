import Foundation
import Observation

@MainActor
@Observable
final class EnquiryViewModel {
    enum State: Equatable {
        case editing
        case submitting
        case sent
        case failed(String)
    }

    enum Field {
        case name, email, phone, message
    }

    var name = ""
    var email = ""
    var phone = ""
    var message = ""
    private(set) var state: State = .editing
    private(set) var hasAttemptedSubmission = false
    let product: Product
    private let service: any EnquiryService
    private var pendingEnquiry: ProductEnquiry?

    init(product: Product, service: any EnquiryService) {
        self.product = product
        self.service = service
    }

    var isSubmitting: Bool { state == .submitting }

    func validationMessage(for field: Field) -> String? {
        guard hasAttemptedSubmission else { return nil }
        return validationIssue(for: field)
    }

    private func validationIssue(for field: Field) -> String? {
        switch field {
        case .name:
            let value = name.trimmingCharacters(in: .whitespacesAndNewlines)
            if value.isEmpty { return "Enter your name." }
            return value.count > 100 ? "Use no more than 100 characters for your name." : nil
        case .email:
            let value = email.trimmingCharacters(in: .whitespacesAndNewlines)
            let valid = value.count <= 254 && value.range(
                of: #"^[^\s@]+@[^\s@]+\.[^\s@]+$"#, options: .regularExpression
            ) != nil
            return valid ? nil : "Enter a valid email address, such as name@example.com."
        case .phone:
            return phone.count > 40 ? "Use no more than 40 characters for your phone number." : nil
        case .message:
            if message.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty { return "Enter a message." }
            return message.count > 2000 ? "Use no more than 2,000 characters for your message." : nil
        }
    }

    func submit() async {
        guard !isSubmitting, state != .sent else { return }
        hasAttemptedSubmission = true
        state = .editing
        guard [Field.name, .email, .phone, .message].allSatisfy({ validationIssue(for: $0) == nil }) else { return }

        let details = ProductEnquiry.Details(
            productID: product.id,
            productTitle: product.title,
            name: name.trimmingCharacters(in: .whitespacesAndNewlines),
            email: email.trimmingCharacters(in: .whitespacesAndNewlines),
            phone: phone.trimmingCharacters(in: .whitespacesAndNewlines),
            message: message.trimmingCharacters(in: .whitespacesAndNewlines)
        )
        let enquiry: ProductEnquiry
        if let pendingEnquiry, pendingEnquiry.details == details {
            enquiry = pendingEnquiry
        } else {
            enquiry = ProductEnquiry(id: UUID(), details: details)
        }
        pendingEnquiry = enquiry
        state = .submitting

        do {
            try await service.send(enquiry)
            try Task.checkCancellation()
            state = .sent
            // Contact details are kept in memory only and cleared after success.
            name = ""
            email = ""
            phone = ""
            message = ""
            pendingEnquiry = nil
        } catch {
            if Task.isCancelled || error is CancellationError {
                state = .editing
            } else if error as? EnquiryServiceError == .notConfigured {
                state = .failed("Enquiries are currently unavailable because email delivery has not been configured. Your enquiry has not been sent.")
            } else if let error = error as? BackendError {
                state = .failed(error.enquiryMessage)
            } else {
                state = .failed("We couldn’t confirm your enquiry was sent. Your details are still here; please try again.")
            }
        }
    }
}
