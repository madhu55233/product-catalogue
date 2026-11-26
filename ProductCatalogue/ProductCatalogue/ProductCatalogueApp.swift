//
//  ProductCatalogueApp.swift
//  ProductCatalogue
//
//  Created by Madhumitha on 26/11/26.
//

import SwiftUI

@main
struct ProductCatalogueApp: App {
    private var usesFixtures: Bool {
        #if DEBUG
        ProcessInfo.processInfo.arguments.contains("--use-test-fixtures")
        #else
        false
        #endif
    }

    private var enquiryService: any EnquiryService {
        if usesFixtures { return UnavailableEnquiryService() }
        return BackendEnquiryService()
    }

    var body: some Scene {
        WindowGroup {
            ContentView(productService: usesFixtures ? MockProductService() : BackendProductService())
                .environment(\.enquiryService, enquiryService)
        }
    }
}
