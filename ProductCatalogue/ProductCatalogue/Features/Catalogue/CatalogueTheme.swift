import SwiftUI
import UIKit

/// Restrained, appearance-aware colours shared by catalogue surfaces and symbols.
enum CatalogueTheme {
    static let accent = adaptive(light: 0x176B62, dark: 0x80CEC0)
    static let ochre = adaptive(light: 0x865A20, dark: 0xE5BF82)
    static let indigo = adaptive(light: 0x565A91, dark: 0xB7B9ED)
    static let background = adaptive(light: 0xF5F5F1, dark: 0x141A1A)
    static let surface = adaptive(light: 0xFFFFFF, dark: 0x202828)

    private static func adaptive(light: UInt32, dark: UInt32) -> Color {
        Color(uiColor: UIColor { traits in
            let hex = traits.userInterfaceStyle == .dark ? dark : light
            return UIColor(
                red: CGFloat((hex >> 16) & 0xFF) / 255,
                green: CGFloat((hex >> 8) & 0xFF) / 255,
                blue: CGFloat(hex & 0xFF) / 255,
                alpha: 1
            )
        })
    }
}

struct CatalogueCategoryStyle {
    let symbol: String
    let tint: Color

    init(category: String) {
        switch category.lowercased() {
        case "accessories", "jewelery", "jewelry":
            symbol = "bag.fill"
            tint = CatalogueTheme.ochre
        case "clothing", "men's clothing", "women's clothing":
            symbol = "tshirt.fill"
            tint = CatalogueTheme.indigo
        case "electronics":
            symbol = "hifispeaker.fill"
            tint = CatalogueTheme.accent
        default:
            symbol = "square.grid.2x2.fill"
            tint = CatalogueTheme.accent
        }
    }
}

struct CatalogueSectionHeading: View {
    let title: String
    let symbol: String
    var tint: Color = CatalogueTheme.accent

    var body: some View {
        HStack(alignment: .firstTextBaseline, spacing: 10) {
            Image(systemName: symbol)
                .font(.headline)
                .foregroundStyle(tint)
                .accessibilityHidden(true)
            Text(title)
                .font(.title2.weight(.semibold))
                .fixedSize(horizontal: false, vertical: true)
                .accessibilityAddTraits(.isHeader)
        }
    }
}
