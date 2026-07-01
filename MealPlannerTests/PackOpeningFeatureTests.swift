import Testing
import Foundation
import ComposableArchitecture
import MealPlanner

@Suite("PackOpeningFeature")
@MainActor
struct PackOpeningFeatureTests {

    @Test func tappingCardTogglesSelection() async {
        let dish = Dish.previewCatalog[0]
        let store = TestStore(
            initialState: PackOpeningFeature.State(date: .now)
        ) {
            PackOpeningFeature()
        } withDependencies: {
            $0.dishRepository = .preview
            $0.packGenerator  = PackGenerator { _, _ in [dish] }
        }
        store.exhaustivity = .off

        await store.send(.onAppear)
        await store.receive(\.packLoaded)

        // Симулируем уже открытый pack
        await store.send(.burstFinished) {
            $0.phase = .reveal
            $0.cards[id: dish.id]?.isRevealed = true
        }

        await store.send(.cardTapped(dish.id)) {
            $0.selectedIDs = [dish.id]
            $0.cards[id: dish.id]?.isSelected = true
        }

        await store.send(.cardTapped(dish.id)) {
            $0.selectedIDs = []
            $0.cards[id: dish.id]?.isSelected = false
        }
    }

    @Test func cannotSelectBeyondMaxSelectable() async {
        let dishes = (0..<3).map {
            Dish(
                id: UUID(),
                name: "Dish \($0)",
                cuisine: .home,
                emoji: "🍽",
                cookTimeMinutes: 5,
                calories: 100,
                proteinGrams: 10,
                rarity: .common,
                difficulty: .one,
                ingredients: [],
                steps: []
            )
        }
        let store = TestStore(
            initialState: PackOpeningFeature.State(date: .now, alreadyInPlan: 5)
        ) {
            PackOpeningFeature()
        } withDependencies: {
            $0.dishRepository = .preview
            $0.packGenerator  = PackGenerator { _, _ in dishes }
        }
        store.exhaustivity = .off

        await store.send(.onAppear)
        await store.receive(\.packLoaded)
        await store.send(.burstFinished)

        // maxSelectable = 7 - 5 = 2 → выбираем 2, третий должен игнорироваться
        await store.send(.cardTapped(dishes[0].id))
        await store.send(.cardTapped(dishes[1].id))
        await store.send(.cardTapped(dishes[2].id))

        #expect(store.state.selectedIDs.count == 2)
        #expect(!store.state.selectedIDs.contains(dishes[2].id))
    }
}
