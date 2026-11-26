//
//  ContentView.swift
//  ProductCatalogue
//
//  Created by Madhumitha on 26/11/26.
//

import SwiftUI

struct ContentView: View {
    let productService: any ProductService

    var body: some View {
        NavigationStack {
            CatalogueView(service: productService)
        }
        .tint(CatalogueTheme.accent)
    }
}

#Preview {
    ContentView(productService: MockProductService())
}
