# Product search

## Behavior

- The app calls its backend at `GET /api/products/search?q=…`, never Fake Store API directly.
- Search begins after 350 ms without typing. There is no separate submit step; the visible Search button and keyboard action dismiss the keyboard.
- The backend matches case-insensitive substrings in product names only. Descriptions and categories are excluded. Unlike the former local implementation, diacritic folding is not guaranteed.
- Surrounding whitespace is trimmed. Empty/whitespace-only input immediately restores home browsing and cancels pending search work.
- Queries longer than 100 characters show validation guidance without an HTTP call.
- Superseded requests are cancelled; generation checks prevent stale results from replacing newer data even if an operation ignores cancellation.
- Loading, failure with Retry, empty results, and matching products are distinct. Failed searches never display unrelated featured products or mock fallback.
- Product selection fetches fresh details by ID. Back navigation preserves the query. Search controls remain outside changing content to retain keyboard focus.

## Tests and previews

Existing mock fixtures remain available only for previews and explicitly enabled Debug UI tests. Their local service defaults preserve locale/diacritic-aware matching for the historic fixture tests; this is not a guarantee of backend behavior.

`BackendServiceTests` covers query encoding, empty responses, request failures, malformed JSON, and stale/cancelled resources. `ProductSearchTests` covers live typing, clear/delete recovery, description exclusion, keyboard submission and accessibility sizes with fixtures. No tests depend on the deployed upstream provider.
