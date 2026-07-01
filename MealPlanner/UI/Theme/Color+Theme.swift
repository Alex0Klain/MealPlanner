import SwiftUI

/// Цвета поверхностей, акцентов и редкости автоматически генерируются Xcode'ом
/// из Asset Catalog (`Color.inkBase`, `Color.plasma`, `Color.rarityRare`, …) —
/// см. `ASSETCATALOG_COMPILER_GENERATE_SWIFT_ASSET_SYMBOL_EXTENSIONS`.
///
/// Здесь живут только цвета, которых нет в каталоге: кухни и слоты приёма пищи.
extension Color {
    init(hex: UInt32, opacity: Double = 1.0) {
        let r = Double((hex >> 16) & 0xFF) / 255.0
        let g = Double((hex >> 8) & 0xFF) / 255.0
        let b = Double(hex & 0xFF) / 255.0
        self.init(.sRGB, red: r, green: g, blue: b, opacity: opacity)
    }

    // MARK: Cuisine
    static let cuisineHome          = Color(hex: 0xC9A37D)
    static let cuisineAsian         = Color(hex: 0xE07458)
    static let cuisineItalian       = Color(hex: 0x5CC58A)
    static let cuisineMexican       = Color(hex: 0xF0B05A)
    static let cuisineMediterranean = Color(hex: 0x5BC8E6)
    static let cuisineFrench        = Color(hex: 0xC285DD)

    // MARK: Meal slots
    static let slotBreakfast = Color(hex: 0xF0B05A)
    static let slotLunch     = Color(hex: 0x5CC58A)
    static let slotDinner    = Color(hex: 0xE07458)
    static let slotSnack     = Color(hex: 0x5BC8E6)
}

extension LinearGradient {
    @MainActor
    static let plasmaCta = LinearGradient(
        colors: [.plasma, .plasmaDeep],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )

    @MainActor
    static let legendaryFoil = LinearGradient(
        colors: [
            Color(hex: 0xF4D27A),
            Color(hex: 0xD49344),
            Color(hex: 0xB26A2E)
        ],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )
}
