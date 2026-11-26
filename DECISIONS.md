# Decisions and assumptions

## Step 1 — Product data foundation

- Client: native iOS using SwiftUI. Plan: lightweight MVVM, without third-party dependencies or extra repository/coordinator layers.
- Backend implementation is outside this iOS workstream. The final app will call the supplied backend, never Fake Store API directly for product metadata.
- Start with local mock products behind `ProductService`. Its asynchronous, throwing interface supports replacing the mock with networking without changing the screens' data dependency.
- “Top rated” means five explicitly selected featured products, based on the acceptance criterion's wording, rather than automatically sorting customer ratings.
- Category screens will separate featured products from remaining products without duplicates. The fixture includes both groups in Accessories and Electronics, and only featured products in Clothing.
- Assume USD for initial price presentation. Use `Decimal` for prices. Currency support can be added when the backend contract is known.
- Keep the UI-facing `Product` independent of JSON decoding until a backend response is available. Add a response DTO and mapping if needed rather than guessing the contract now.
- Mock image URLs are absent intentionally. Screens will show placeholders, keeping initial development offline.

## Featured products versus customer ratings

- A featured product is one the business owner chooses to highlight on the home screen, independently of customer ratings.
- The criterion says “I have chosen 5 products” to be “top rated” and then calls them “featured products.” We interpret this as a curated selection, not an automatic ranking by customer ratings.
- `isFeatured = true` identifies a product for the home screen's featured section. Products marked `false` remain available through category browsing and search.
- Five mock products are manually marked as featured for now. The planned backend integration will supply the selection; Fake Store API customer ratings alone do not identify featured products.

## Current limitations

Only the model, mock service, and fixture tests are implemented in this step. The starter screen is unchanged. Browsing, search, details, enquiry submission, and backend integration remain to be implemented; no email is sent.

## Tracking

This is an incremental decision log, not the completed submission report. Record actual human planning, building, testing, and review time during development; no time estimates here should be presented as actual time spent.