import SwiftUI

struct ProductSearchBar: View {
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize
    @FocusState private var isFocused: Bool

    @Binding var text: String
    let onClear: () -> Void

    private var layout: AnyLayout {
        dynamicTypeSize.isAccessibilitySize
            ? AnyLayout(VStackLayout(alignment: .leading, spacing: 12))
            : AnyLayout(HStackLayout(spacing: 12))
    }

    var body: some View {
        layout {
            HStack(spacing: 8) {
                Image(systemName: "magnifyingglass")
                    .foregroundStyle(CatalogueTheme.accent)
                    .accessibilityHidden(true)

                TextField("Search products", text: $text)
                    .textInputAutocapitalization(.never)
                    .autocorrectionDisabled()
                    .submitLabel(.search)
                    .focused($isFocused)
                    .accessibilityLabel("Search products")
                    .accessibilityHint("Results update as you type a product name")
                    .accessibilityIdentifier("product-search-input")

                if !text.isEmpty {
                    Button {
                        onClear()
                        isFocused = false
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundStyle(.secondary)
                            .frame(minWidth: 44, minHeight: 44)
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel("Clear search")
                    .accessibilityIdentifier("product-search-clear")
                }
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 4)
            .frame(minHeight: 52)
            .background(CatalogueTheme.surface, in: RoundedRectangle(cornerRadius: 14))
            .overlay {
                RoundedRectangle(cornerRadius: 14)
                    .strokeBorder(CatalogueTheme.accent.opacity(0.25))
            }

            Button("Search", action: submit)
                .buttonStyle(.borderedProminent)
                .controlSize(.large)
                .accessibilityIdentifier("product-search-button")
        }
        .onSubmit(submit)
        .frame(maxWidth: 960)
        .padding(.horizontal)
        .padding(.vertical, 12)
        .frame(maxWidth: .infinity)
        .background(CatalogueTheme.background)
    }

    private func submit() {
        isFocused = false
    }
}

struct ProductSearchResultsView: View {
    let products: [Product]
    let term: String

    var body: some View {
        if products.isEmpty {
            ContentUnavailableView {
                Label("No matching products", systemImage: "magnifyingglass")
            } description: {
                Text("No products match “\(term)”. Try another term or clear your search.")
            }
            .accessibilityIdentifier("product-search-empty")
        } else {
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    CatalogueSectionHeading(title: "Search results", symbol: "magnifyingglass")
                    Text(products.count == 1
                         ? "1 product matching “\(term)”"
                         : "\(products.count) products matching “\(term)”")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .fixedSize(horizontal: false, vertical: true)
                        .accessibilityIdentifier("product-search-summary")

                    ProductGrid(products: products)
                }
                .frame(maxWidth: 960)
                .padding()
                .frame(maxWidth: .infinity)
            }
            .scrollDismissesKeyboard(.interactively)
        }
    }
}
