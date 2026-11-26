//
//  ProductCatalogueApp.swift
//  ProductCatalogue
//
//  Created by Madhumitha on 26/11/26.
//

import SwiftUI

@main
struct ProductCatalogueApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView(productService: MockProductService())
        }
    }
}
