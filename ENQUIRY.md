# Product enquiry

## Current status

The iOS enquiry flow is implemented, but **real email delivery is not configured**. The repository contains no backend endpoint, email API contract, or sales inbox address. The default `UnavailableEnquiryService` always throws an explicit configuration error; it never reports a successful send.

The email-delivery acceptance criterion cannot be verified until the backend is supplied and a real message is confirmed in the sales inbox. No emails are sent by the automated tests.

## Client behavior

- Enquire on any product-details page opens a product-specific contact form.
- Name and a syntactically valid email address are required. Phone and message are optional.
- Maximum lengths: name 100 characters, email 254, phone 40, message 2,000.
- Submit validates fields, normalizes surrounding whitespace, and includes the selected product ID and title.
- The form shows sending progress and blocks repeated submissions and dismissal while sending.
- Only a successful `EnquiryService.send` result transitions to the “Thank you” screen. Errors retain contact details for retry. Cancellation never reports success.
- Contact data stays in memory only and is cleared on success or when the form is discarded. The client does not log contacts or messages.
- Retries with unchanged details reuse a request UUID. A backend adapter must use that ID and the backend must enforce idempotency; a client UUID alone cannot guarantee exactly-once email delivery.

## Delivery integration required

Provide:

1. The enquiry backend URL and request/response API contract, including any authentication requirements.
2. The destination sales inbox (configured on the backend).
3. How the backend confirms email submission and handles retries or ambiguous failures.

Implement `EnquiryService` using that agreed contract and inject it through the `enquiryService` SwiftUI environment at the app root. Do not put SMTP passwords or email-provider secrets in the iOS application. No endpoint, provider, or API contract has been guessed in this implementation.

The backend should validate input, resolve the product using its ID, use a verified sender and a fixed sales recipient, handle contact email safely as reply-to, and apply appropriate authentication/rate limiting, idempotency, and data-retention rules. Returning a successful HTTP response without sending or accepting the email is not sufficient.

## Verification

Unit tests use controlled test services to cover validation, normalized product/contact payloads, success, failure, cancellation, retries, duplicate-submit protection, and the unconfigured service. UI tests cover opening the form, required-field validation, cancellation at accessibility text sizes, and an honest delivery-unavailable error with retained contacts. Existing product-details tests protect browsing and navigation.

Once delivery is integrated, submit an enquiry with approved test contact details, confirm exactly one email in the configured sales inbox with the correct product and contact information, and verify the customer sees “Thank you”. Test backend failures separately and ensure they never display that confirmation.
