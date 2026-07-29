import Testing
import Foundation
import ComposableArchitecture
import MealPlanner

@Suite("HomeFeature")
@MainActor
struct HomeFeatureTests {

    @Test func packFinishedPersistsMealsAndReloadsPlan() async {
        let repo = MealPlanRepository.inMemory()
        let dish = Dish.previewCatalog[0]
        let store = TestStore(
            initialState: HomeFeature.State()
        ) {
            HomeFeature()
        } withDependencies: {
            $0.dishRepository = .preview
            $0.mealPlanRepository = repo
        }
        store.exhaustivity = .off

        await store.send(.onAppear)
        await store.receive(\.dishesLoaded)

        // Открываем пак и эмулируем завершение distribute.
        await store.send(.packCtaTapped)
        await store.send(
            .destination(.presented(.packOpening(.delegate(.finished([
                PlannedMeal(dishID: dish.id, slot: .breakfast)
            ])))))
        )
        await store.receive(\.planLoaded)

        #expect(store.state.plan.meals.count == 1)
        #expect(store.state.plan.meals.first?.slot == .breakfast)
        #expect(store.state.destination == nil)

        // Данные реально в репозитории, не только в state.
        let persisted = await repo.planForDate(store.state.date)
        #expect(persisted?.meals.count == 1)
    }

    @Test func removeMealDeletesFromRepository() async {
        let repo = MealPlanRepository.inMemory()
        let dish = Dish.previewCatalog[1]
        let date = Calendar.current.startOfDay(for: .now)
        try? await repo.addMeal(dish.id, .lunch, date)

        let store = TestStore(
            initialState: HomeFeature.State()
        ) {
            HomeFeature()
        } withDependencies: {
            $0.dishRepository = .preview
            $0.mealPlanRepository = repo
        }
        store.exhaustivity = .off

        await store.send(.onAppear)
        await store.receive(\.planLoaded)
        #expect(store.state.plan.meals.count == 1)

        let meal = store.state.plan.meals[0]
        await store.send(.removeMealTapped(meal))
        await store.receive(\.planLoaded)

        #expect(store.state.plan.meals.isEmpty)
        let persisted = await repo.planForDate(date)
        #expect(persisted?.meals.isEmpty == true)
    }

    @Test func replaceMealRemovesAndOpensPickerForSameSlot() async {
        let repo = MealPlanRepository.inMemory()
        let dish = Dish.previewCatalog[2]
        let date = Calendar.current.startOfDay(for: .now)
        try? await repo.addMeal(dish.id, .dinner, date)

        let store = TestStore(
            initialState: HomeFeature.State()
        ) {
            HomeFeature()
        } withDependencies: {
            $0.dishRepository = .preview
            $0.mealPlanRepository = repo
        }
        store.exhaustivity = .off

        await store.send(.onAppear)
        await store.receive(\.planLoaded)
        let meal = store.state.plan.meals[0]

        await store.send(.replaceMealTapped(meal))
        await store.receive(\.planLoaded)

        // Блюдо убрано, sheet выбора открыт на том же слоте.
        #expect(store.state.plan.meals.isEmpty)
        guard case let .addMealSlot(sheet) = store.state.destination else {
            Issue.record("Ожидали addMealSlot destination")
            return
        }
        #expect(sheet.selectedSlot == .dinner)
    }

    @Test func packCtaBuildsExistingBySlotFromPlan() async {
        let repo = MealPlanRepository.inMemory()
        let breakfastDish = Dish.previewCatalog[0]
        let lunchDish = Dish.previewCatalog[1]
        let date = Calendar.current.startOfDay(for: .now)
        try? await repo.addMeal(breakfastDish.id, .breakfast, date)
        try? await repo.addMeal(lunchDish.id, .lunch, date)

        let store = TestStore(
            initialState: HomeFeature.State()
        ) {
            HomeFeature()
        } withDependencies: {
            $0.dishRepository = .preview
            $0.mealPlanRepository = repo
        }
        store.exhaustivity = .off

        await store.send(.onAppear)
        await store.receive(\.planLoaded)
        await store.receive(\.dishesLoaded)

        await store.send(.packCtaTapped)
        guard case let .packOpening(pack) = store.state.destination else {
            Issue.record("Ожидали packOpening destination")
            return
        }
        #expect(pack.existingBySlot[.breakfast]?.map(\.id) == [breakfastDish.id])
        #expect(pack.existingBySlot[.lunch]?.map(\.id) == [lunchDish.id])
        // 8 − 2 занятых = 6 доступных к выбору.
        #expect(pack.maxSelectable == 6)
    }
}
