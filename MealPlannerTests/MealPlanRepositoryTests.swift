import Testing
import Foundation
import MealPlanner

@Suite("MealPlanRepository (in-memory)")
struct MealPlanRepositoryTests {

    @Test func savingPlanIsRetrievable() async throws {
        let repo = MealPlanRepository.preview
        let date = Calendar.current.startOfDay(for: .now)
        let dish = Dish.previewCatalog[0]

        try await repo.addMeal(dish.id, .breakfast, date)
        let plan = await repo.planForDate(date)

        #expect(plan?.meals.count == 1)
        #expect(plan?.meals.first?.dishID == dish.id)
        #expect(plan?.meals.first?.slot == .breakfast)
    }

    @Test func removeMealClearsEntry() async throws {
        let repo = MealPlanRepository.preview
        let date = Calendar.current.startOfDay(for: .now)
        let dish = Dish.previewCatalog[1]

        try await repo.addMeal(dish.id, .dinner, date)
        try await repo.removeMeal(dish.id, date)
        let plan = await repo.planForDate(date)

        #expect(plan?.meals.isEmpty == true)
    }

    @Test func weekPlansReturnsSevenDays() async {
        let repo = MealPlanRepository.preview
        let plans = await repo.weekPlans(.now)
        #expect(plans.count == 7)
    }
}
