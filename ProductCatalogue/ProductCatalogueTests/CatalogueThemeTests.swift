import SwiftUI
import Testing
import UIKit
@testable import ProductCatalogue

@MainActor
struct CatalogueThemeTests {
    @Test(arguments: ["Accessories", "Clothing", "Electronics", "Other"])
    func categorySymbolsAreAvailable(category: String) {
        let style = CatalogueCategoryStyle(category: category)
        #expect(UIImage(systemName: style.symbol) != nil)
    }

    @Test func unknownCategoriesHaveANeutralFallback() {
        let style = CatalogueCategoryStyle(category: "New category")
        #expect(style.symbol == "square.grid.2x2.fill")
    }

    @Test func paletteHasReadableContrastInBothAppearances() throws {
        let tints = [CatalogueTheme.accent, CatalogueTheme.ochre, CatalogueTheme.indigo]
        for appearance in [UIUserInterfaceStyle.light, .dark] {
            let traits = UITraitCollection(userInterfaceStyle: appearance)
            let surface = UIColor(CatalogueTheme.surface).resolvedColor(with: traits)
            for tint in tints {
                let foreground = UIColor(tint).resolvedColor(with: traits)
                // The strongest tint behind text is the featured badge's 10% fill.
                let background = try blended(foreground, over: surface, opacity: 0.1)
                let first = try luminance(foreground)
                let second = try luminance(background)
                let contrast = (max(first, second) + 0.05) / (min(first, second) + 0.05)
                #expect(contrast >= 4.5)
            }
        }
    }

    private func components(_ color: UIColor) throws -> (CGFloat, CGFloat, CGFloat) {
        var red: CGFloat = 0
        var green: CGFloat = 0
        var blue: CGFloat = 0
        var alpha: CGFloat = 0
        try #require(color.getRed(&red, green: &green, blue: &blue, alpha: &alpha))
        return (red, green, blue)
    }

    private func blended(_ foreground: UIColor, over background: UIColor, opacity: CGFloat) throws -> UIColor {
        let (red, green, blue) = try components(foreground)
        let (baseRed, baseGreen, baseBlue) = try components(background)
        return UIColor(
            red: red * opacity + baseRed * (1 - opacity),
            green: green * opacity + baseGreen * (1 - opacity),
            blue: blue * opacity + baseBlue * (1 - opacity),
            alpha: 1
        )
    }

    private func luminance(_ color: UIColor) throws -> Double {
        let (red, green, blue) = try components(color)
        func linear(_ value: CGFloat) -> Double {
            let channel = Double(value)
            return channel <= 0.04045 ? channel / 12.92 : pow((channel + 0.055) / 1.055, 2.4)
        }
        return 0.2126 * linear(red) + 0.7152 * linear(green) + 0.0722 * linear(blue)
    }
}
