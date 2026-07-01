import SwiftUI

/// Время дня в плане. Принадлежит DayPlan.
public enum MealSlot: String, Codable, Sendable, CaseIterable, Identifiable {
    case breakfast
    case lunch
    case dinner
    case snack

    public var id: String { rawValue }

    public var displayName: String {
        switch self {
        case .breakfast: "Завтрак"
        case .lunch:     "Обед"
        case .dinner:    "Ужин"
        case .snack:     "Перекус"
        }
    }

    public var emoji: String {
        switch self {
        case .breakfast: "🌅"
        case .lunch:     "☀️"
        case .dinner:    "🌙"
        case .snack:     "🍎"
        }
    }

    public var accentColor: Color {
        switch self {
        case .breakfast: .slotBreakfast
        case .lunch:     .slotLunch
        case .dinner:    .slotDinner
        case .snack:     .slotSnack
        }
    }

    /// Каноничный порядок отображения слотов в плане дня.
    public static let displayOrder: [MealSlot] = [.breakfast, .lunch, .dinner, .snack]
}
