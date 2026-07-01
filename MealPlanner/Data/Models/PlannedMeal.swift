import Foundation

/// Запись о блюде в плане дня. Хранится как JSON внутри DayPlan, не @Model.
public struct PlannedMeal: Codable, Sendable, Hashable, Identifiable {
    public let dishID: UUID
    public let slot: MealSlot
    public let addedAt: Date

    public var id: UUID { dishID }

    public init(dishID: UUID, slot: MealSlot, addedAt: Date = .now) {
        self.dishID = dishID
        self.slot = slot
        self.addedAt = addedAt
    }
}
