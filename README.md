# Product Catalogue

A native SwiftUI iPhone and iPad app for product browsing, live name search, product details, and sales enquiry forms.

> **Current status:** Products use local mock data. The enquiry form is implemented, but real email delivery is **not configured**. Valid submissions currently show a delivery-unavailable error, not a false success message.

## Features

- Five curated featured products and category cards with product counts.
- Category pages separating featured and additional products.
- Live, case- and diacritic-insensitive search of product names, including non-featured items.
- Product details accessible from home, categories, and search, with USD price, description, category, and featured status.
- Enquiry form with required name/email, optional phone/message, validation, retry handling, and a success-only “Thank you” state.
- Adaptive grids, Dynamic Type, light/dark styling, and accessible controls.

## Requirements

- macOS capable of running **Xcode 27.2**, the verified development version, or a newer compatible Xcode.
- An **iOS/iPadOS 27.2 or later** simulator or device. The app and test targets use a 27.2 deployment target.
- Full Xcode, not only standalone Command Line Tools.
- No third-party packages, CocoaPods installation, API keys, or backend are needed for the mock catalogue.

The project uses Swift 5 language mode with Xcode's compiler; this does not mean an older Xcode can open or build the project.

## Run the app

### iOS Simulator

1. Clone the repository, or use an existing checkout:

   ```bash
   git clone https://github.com/madhu55233/product-catalogue.git
   cd product-catalogue
   ```

2. Open **`ProductCatalogue/ProductCatalogue.xcodeproj`** with Xcode's **File → Open**, or run:

   ```bash
   open ProductCatalogue/ProductCatalogue.xcodeproj
   ```

   Open the enclosing `.xcodeproj` project; its configuration is named `project.xcproj`. Do not rename it or generate a `.pbxproj` file.

3. Select the **ProductCatalogue** scheme.
4. Select an iPhone or iPad simulator running **iOS 27.2 or later**. Install a compatible runtime in Xcode Settings if needed, then create a simulator under **Window → Devices and Simulators**.
5. Press **⌘R** (**Product → Run**).

The app loads seven mock products across Accessories, Clothing, and Electronics; five are featured. Image URLs are intentionally absent, so placeholders are expected.

### Physical device

1. Connect and trust a device running iOS/iPadOS 27.2 or later; enable Developer Mode if prompted.
2. Under **ProductCatalogue target → Signing & Capabilities**, choose your own development team and enable automatic signing. The checked-in team belongs to the original development environment.
3. Change the bundle identifier if needed for your team. Configure test-target signing too if running tests on the device.
4. Select the connected device and press **⌘R**.

## Try the flows

- Browse a category, then tap a tile to open its details.
- Type `Every` in search: only **Everyday Backpack** matches. Descriptions and categories are not searched. Results update while typing; Search dismisses the keyboard, and clearing the field restores browsing.
- Open a product and tap **Enquire**. Invalid required fields show validation messages. A valid form currently shows a delivery-unavailable error and retains contacts because no email backend is configured.

## Build and test

Run terminal commands from the **repository root**.

### Build for Simulator

```bash
xcodebuild build \
  -project ProductCatalogue/ProductCatalogue.xcodeproj \
  -scheme ProductCatalogue \
  -configuration Debug \
  -destination 'generic/platform=iOS Simulator' \
  CODE_SIGNING_ALLOWED=NO
```

This builds without a development team; use Xcode's Run action to install and launch the app.

### Run tests

In Xcode, select a compatible simulator and press **⌘U** (**Product → Test**).

For terminal tests, list compatible destinations:

```bash
xcodebuild -showdestinations \
  -project ProductCatalogue/ProductCatalogue.xcodeproj \
  -scheme ProductCatalogue
```

Replace the placeholder with the `id` of an available **iOS Simulator** destination:

```bash
SIMULATOR_ID="YOUR_SIMULATOR_UDID"

xcodebuild test \
  -project ProductCatalogue/ProductCatalogue.xcodeproj \
  -scheme ProductCatalogue \
  -destination "platform=iOS Simulator,id=$SIMULATOR_ID" \
  -parallel-testing-enabled NO \
  CODE_SIGNING_ALLOWED=NO
```

Add `-only-testing:ProductCatalogueTests` for unit tests or `-only-testing:ProductCatalogueUITests` for UI tests. Let UI tests finish before manually interacting with their simulator.

Tests cover catalogue loading/filtering, live search, palette contrast, details navigation, enquiry validation/submission states, and accessibility text sizes. Success-path enquiry tests use controlled test doubles; **automated tests do not send real emails**.

## Architecture

Lightweight MVVM using SwiftUI, `@Observable` view models, and asynchronous service protocols:

- `ProductCatalogue/ProductCatalogue/Features/`: Catalogue, Category, ProductDetails, and Enquiry screens.
- `ProductCatalogue/ProductCatalogue/Models/`: product and enquiry data.
- `ProductCatalogue/ProductCatalogue/Services/`: product and enquiry service interfaces.
- `ProductCatalogue/ProductCatalogueTests/`: unit tests.
- `ProductCatalogue/ProductCatalogueUITests/`: UI tests.

`MockProductService` is injected from the app entry point. `EnquiryService` uses the SwiftUI environment and defaults to `UnavailableEnquiryService`.

## Backend and email delivery

To complete email delivery, supply the **backend endpoint/API contract**, authentication requirements, and **sales inbox address**. Implement `EnquiryService` against that contract and inject it at the app root.

Email credentials, recipient configuration, input validation, rate limiting, and idempotent retries belong on the backend. **Never embed SMTP passwords or email-provider secrets in the iOS app.** Client request IDs prevent duplicate emails only when the server enforces idempotency.

“Thank you” is shown only after a successful service response. The default service deliberately reports unavailability. Real receipt in the sales inbox has not been implemented or verified. Product networking is also pending; browsing and search use the loaded mock catalogue.

- [ENQUIRY.md](ENQUIRY.md): delivery status and integration requirements.
- [SEARCH.md](SEARCH.md): current matching rules and examples.
- [DECISIONS.md](DECISIONS.md): incremental architecture notes from earlier development stages.

## Troubleshooting

- **No matching simulator:** install and select an iOS 27.2-or-later runtime. Older simulators cannot run the current deployment target.
- **Project will not open:** use Xcode 27.2 or newer compatible Xcode and open the `.xcodeproj` directory rather than individual source files.
- **Wrong command-line tools:** check `xcodebuild -version`; select the intended Xcode in **Xcode → Settings → Locations → Command Line Tools**.
- **Signing errors:** use the unsigned simulator build command or configure your own team and bundle identifiers for physical devices.
- **No photos:** expected while mock image URLs are absent.
- **Enquiry delivery unavailable:** expected until the backend is configured; no email is sent in this state.
