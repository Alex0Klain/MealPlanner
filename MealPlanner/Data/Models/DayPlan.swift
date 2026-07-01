import Foundation
import SwiftData

@Model
public final class DayPlan {
    @Attribute(.unique) public var date: Date
    public var mealSlots: [PlannedMeal]
    public var createdAt: Date

    public init(date: Date, mealSlots: [PlannedMeal] = [], createdAt: Date = .now) {
        self.date = Calendar.current.startOfDay(for: date)
        self.mealSlots = mealSlots
        self.createdAt = createdAt
    }
}
