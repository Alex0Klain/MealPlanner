import SwiftUI

public enum Rarity: String, Codable, Sendable, CaseIterable {
    case common
    case rare
    case legendary

    /// Веса генерации пака: 60 / 30 / 10
    public var weight: Double {
        switch self {
        case .common:    0.60
        case .rare:      0.30
        case .legendary: 0.10
        }
    }

    public var displayName: String {
        switch self {
        case .common:    "COMMON"
        case .rare:      "RARE"
        case .legendary: "★ LEGENDARY"
        }
    }

    public var borderColor: Color {
        switch self {
        case .common:    .rarityCommon
        case .rare:      .rarityRare
        case .legendary: .rarityLegendary
        }
    }
}
