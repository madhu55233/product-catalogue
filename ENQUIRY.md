# Product enquiry

## Integration status

The app submits to `https://product-catalogue-backend-qzyh.onrender.com/api/enquiries` through `BackendEnquiryService`. The backend currently returns 503 until Resend is configured. Live inbox receipt has not been verified. Automated tests never send real emails.

## Request and acceptance

- POST JSON with exactly `name`, `email`, `message`, and the selected `productId`.
- Name, valid email and a nonblank message are required. Phone is optional and appended to the message because the backend rejects unknown fields.
- Client limits: name 100, email 254, phone 40, message 2,000 characters. The combined message remains below the backend's 3,000-character limit.
- Only HTTP 202 with `status: accepted` and a valid UUID receipt transitions to Thank you. This confirms provider acceptance, not guaranteed delivery.
- No product title, request UUID, or separate phone field is sent to the strict endpoint.

## Errors and retries

The form retains inputs on validation, network, HTTP, or receipt-decoding failure. It distinguishes unavailable email (503), rate limits (429), invalid input (400), timeout, offline and provider/server failures. Input is kept in memory, never logged, and cleared after acceptance or dismissal.

Repeated submissions and dismissal are blocked while sending. Cancellation never reports success. POST requests are not automatically retried. Ambiguous failures warn that retrying may duplicate email.

The existing form model retains a local request UUID for unchanged retries, but the supplied backend does not support idempotency and does not accept that UUID. This is not exactly-once delivery protection. Server-side idempotency is required before safe automatic retries can be added.

## Deployment and verification

Configure Resend credentials, a verified sender and destination inbox on the backend, never in the app. Resolve the catalogue upstream 502 so customers can reach product details. With approved test contacts, verify provider acceptance and receipt in the sales inbox. A healthy `/health` endpoint alone is insufficient.

Unit tests cover the strict request body, 202 receipt validation, 503 retention, malformed responses, validation, duplicate-submit prevention, cancellation and retry state. UI tests use explicit offline fixtures to test the form without live email.
