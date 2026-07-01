import Testing
import MealPlanner

@Suite("MealPlanner — smoke")
struct MealPlannerTests {
    @Test func cuisineAllCasesCovered() {
        #expect(Cuisine.allCases.count == 6)
    }

    @Test func mealSlotDisplayOrderIsCanonical() {
        #expect(MealSlot.displayOrder == [.breakfast, .lunch, .dinner, .snack])
    }
}
