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

## Step 2 — Featured home screen

- Use `@Observable` with `@MainActor` for the catalogue view model. The view owns it through `@State`; the service is injected from the app entry point.
- A single state enum represents idle, loading, loaded products, or failure. Empty featured results are a successful load, not a network failure.
- Keep all fetched products in memory, deriving featured products with `isFeatured`. Do not silently select other products when no featured products exist, or truncate a backend selection to five; the data source owns the curated selection.
- SwiftUI's `.task` manages initial loading and retries. Cancellation returns to idle rather than showing an error. Already loaded data is reused for the lifetime of this view model; refresh and persistent caching are deferred.
- Use an adaptive grid and reusable product tiles, with a single column at accessibility text sizes, semantic system colours, combined accessibility labels, and native USD formatting.
- Show a generic, actionable failure message rather than exposing raw networking errors. More detailed diagnostics can be added with backend integration.
- View-model tests cover filtering, loading, empty data, no featured selections, retry after failure, cancellation, and avoiding repeated fetches after success.

## Step 3 — Category browsing

- Derive unique, sorted category names from loaded products. Match category names exactly as supplied by the data source; do not merge differently named categories or request them separately for this small catalogue.
- The existing catalogue view model filters a selected category into featured and non-featured groups. These groups are disjoint and retain source order. No extra service or category view model is needed.
- Category links appear above the home screen's featured products. Categories remain browsable even if no products are featured. A completely empty catalogue has its own empty state.
- The category page receives product arrays and displays Featured products followed by More products. Hide a section when it has no products; if both groups are empty, show a category empty state.
- Reuse ProductGrid and ProductTile across home and category pages, including accessibility text-size behaviour. NavigationLink uses the existing NavigationStack and native Back navigation.
- Unit tests cover category uniqueness, filtering, disjoint groups, missing categories, featured-only and non-featured-only categories, and reuse without another fetch. A UI test exercises Electronics, Back navigation, and Clothing's absent additional section.
