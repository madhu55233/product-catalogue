# Product search

## Acceptance criterion

Display only products whose names match the current search term, updating results as the customer types.

## Behavior

- The visible Search button and keyboard Search action dismiss the keyboard; results are already updated.
- Results reflect the current text immediately, without a separate submitted query. Keep keyboard focus stable while results change.
- Match literal substrings in product titles only, not descriptions or categories. Matching is locale-aware, case-insensitive, and diacritic-insensitive; surrounding whitespace and newlines are trimmed.
- Search the entire loaded catalogue, including non-featured products. Preserve source order and include each matching product only once. Prices, IDs, and image URLs are not searchable text.
- Replace home categories and featured sections with the matching-product grid. Do not show unrelated featured products when there are no matches; show a dedicated no-results message instead.
- Clear search, delete all text, or enter only whitespace to restore normal category and featured browsing immediately.
- Reuse loaded data without extra service requests. Loading, error/retry, and empty-catalogue states remain separate from search.
- Keep themed search controls above the content, stack them vertically at accessibility text sizes, and reuse the existing accessible product grid.

## Examples using mock data

| Term | Matching products |
| --- | --- |
| `back` | Everyday Backpack |
| `Every` | Everyday Backpack, not Cotton T-Shirt |
| `padded` | No matching products (descriptions are not searched) |
| `wireless` | Wireless Headphones |
| `ELECTRONICS` | No matching products (categories are not searched) |
| `canvas` | Canvas Tote (non-featured) |
| `no-such-product` | No matching products |

## Coverage

`CatalogueViewModelTests` covers live title matching, description/category exclusion, whitespace, accents, punctuation, result ordering, non-featured products, reset behavior, empty results, load-state boundaries, and data reuse. `ProductSearchTests` covers the Every/Backpack regression, continuous typing without refocusing, deletion recovery, button and keyboard actions, clear/no-result recovery, and accessibility text sizes. Existing category-navigation tests remain regression coverage.

Search is implemented locally against the mock catalogue. Backend search, pagination, and product-detail navigation are not part of this feature.
