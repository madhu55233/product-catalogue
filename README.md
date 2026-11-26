# Product Catalogue

A native SwiftUI iPhone and iPad app for product browsing, live name search, product details, and sales enquiry forms.

> **Current status:** The app uses `https://product-catalogue-backend-qzyh.onrender.com`. Catalogue endpoints currently return **502** because Fake Store API blocks Render requests; enquiries return **503** until Resend is configured. Errors offer manual retry, never mock fallback or false success.

## Features

- Up to five backend-ranked featured products and category cards with product counts.
- Category pages separating featured and additional products.
- Live, debounced, case-insensitive backend search of product names, including non-featured items.
- Product details accessible from home, categories, and search, with USD price, description, category, and featured status.
- Enquiry form with required name/email/message, optional phone, validation, retry handling, and a success-only “Thank you” state.
- Adaptive grids, Dynamic Type, light/dark styling, and accessible controls.

## Requirements

- macOS capable of running **Xcode 27.2**, the verified development version, or a newer compatible Xcode.
- An **iOS/iPadOS 27.2 or later** simulator or device. The app and test targets use a 27.2 deployment target.
- Full Xcode, not only standalone Command Line Tools.
- Internet access to the deployed backend is required. No third-party packages, CocoaPods installation, or client API keys are needed.

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

Normal launches use the deployed backend. Until upstream access recovers, expect “Unable to load products” and Retry. For offline previews, add `--use-test-fixtures` to the Debug scheme launch arguments. Remove it to test networking; Release ignores this flag.

### Physical device

1. Connect and trust a device running iOS/iPadOS 27.2 or later; enable Developer Mode if prompted.
2. Under **ProductCatalogue target → Signing & Capabilities**, choose your own development team and enable automatic signing. The checked-in team belongs to the original development environment.
3. Change the bundle identifier if needed for your team. Configure test-target signing too if running tests on the device.
4. Select the connected device and press **⌘R**.

## Try the flows

- Browse a category, then tap a tile to open its details.
- Type a name fragment such as `bag`. Search requests run after a 350 ms debounce; descriptions and categories are excluded. Search dismisses the keyboard, and clearing restores browsing. Terms are limited to 100 characters.
- Open a product and tap **Enquire**. Name, email and message are required. The current backend 503 retains inputs and reports email unavailability.

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

`BackendProductService` and `BackendEnquiryService` are injected at the app root. `BackendClient` owns the HTTPS base URL, JSON decoding, error mapping and 60-second request timeout. Mock/unavailable services are reserved for previews and explicitly enabled Debug tests.

## Backend and email delivery

| Action | Backend endpoint |
| --- | --- |
| Home/counts | `GET /api/products`, `GET /api/categories` |
| Featured ranking | `GET /api/products/featured` |
| Category | `GET /api/products?category=…` |
| Search | `GET /api/products/search?q=…` |
| Details | `GET /api/products/:id` |
| Enquiry | `POST /api/enquiries` |

No direct Fake Store **API** requests are made by the client. Images load from URLs supplied by the backend. `/health` is an operational check, not proof that upstream dependencies work. Home requires all three home requests to succeed. Remote screens show loading, empty/error and manual-retry states; cancelled or superseded searches cannot publish stale results.

Configure Resend, sender and recipient on the backend and resolve its Fake Store access failure. No backend files were changed for this integration. Keep all email credentials on the server.

The strict enquiry payload contains only `name`, `email`, `message` and `productId`; optional phone information is appended to the message. Thank you requires HTTP 202 plus a decoded `status: accepted` and UUID receipt. Acceptance does not guarantee inbox delivery; live delivery remains unverified.

The backend does not implement idempotency. Client UUIDs are not sent as unsupported fields. There are no automatic POST retries; ambiguous failures warn that manual retries may duplicate email.

HTTP unit tests use injected transports; UI tests explicitly enable fixtures. They do not depend on backend availability or send emails.

- [ENQUIRY.md](ENQUIRY.md): delivery status and integration requirements.
- [SEARCH.md](SEARCH.md): current matching rules and examples.
- [DECISIONS.md](DECISIONS.md): incremental architecture notes from earlier development stages.

## Troubleshooting

- **No matching simulator:** install and select an iOS 27.2-or-later runtime. Older simulators cannot run the current deployment target.
- **Project will not open:** use Xcode 27.2 or newer compatible Xcode and open the `.xcodeproj` directory rather than individual source files.
- **Wrong command-line tools:** check `xcodebuild -version`; select the intended Xcode in **Xcode → Settings → Locations → Command Line Tools**.
- **Signing errors:** use the unsigned simulator build command or configure your own team and bundle identifiers for physical devices.
- **No photos:** image-host failures show placeholders; test fixtures intentionally omit photos.
- **Enquiry delivery unavailable (503):** configure Resend on the backend; email has not been sent.
- **502:** backend upstream access failed. A successful health check does not mean products are available.
- **429:** wait before retrying.
- **Timeout:** Render may be starting up; wait and retry.
