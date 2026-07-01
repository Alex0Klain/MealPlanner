import SwiftUI

/// Стиль кухни блюда на карточке. См. ARCHITECTURE.md — это НЕ слот в плане.
public enum Cuisine: String, Codable, Sendable, CaseIterable, Identifiable {
    case home
    case asian
    case italian
    case mexican
    case mediterranean
    case french

    public var id: String { rawValue }

    public var displayName: String {
        switch self {
        case .home:          "Домашняя"
        case .asian:         "Азиатская"
        case .italian:       "Итальянская"
        case .mexican:       "Мексиканская"
        case .mediterranean: "Средиземноморская"
        case .french:        "Французская"
        }
    }

    public var accentColor: Color {
        switch self {
        case .home:          .cuisineHome
        case .asian:         .cuisineAsian
        case .italian:       .cuisineItalian
        case .mexican:       .cuisineMexican
        case .mediterranean: .cuisineMediterranean
        case .french:        .cuisineFrench
        }
    }
}
