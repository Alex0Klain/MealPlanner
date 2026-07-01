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
        let existing: Set<UUID> = [
            UUID(uuidString: "22222222-0000-0000-0000-000000000001")!,
            UUID(uuidString: "22222222-0000-0000-0000-000000000002")!,
            UUID(uuidString: "22222222-0000-0000-0000-000000000003")!,
            UUID(uuidString: "22222222-0000-0000-0000-000000000004")!,
            UUID(uuidString: "22222222-0000-0000-0000-000000000005")!
        ]
        let store = TestStore(
            initialState: PackOpeningFeature.State(date: .now, alreadyInPlanIDs: existing)
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

    @Test func packCardMarksAlreadyInPlanDishes() async {
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
        // Первое блюдо в паке уже в плане — карточка должна быть isInPlan = true
        let alreadyInPlan: Set<UUID> = [dishes[0].id]
        let store = TestStore(
            initialState: PackOpeningFeature.State(date: .now, alreadyInPlanIDs: alreadyInPlan)
        ) {
            PackOpeningFeature()
        } withDependencies: {
            $0.dishRepository = .preview
            $0.packGenerator  = PackGenerator { _, _ in dishes }
        }
        store.exhaustivity = .off

        await store.send(.onAppear)
        await store.receive(\.packLoaded)

        #expect(store.state.cards[id: dishes[0].id]?.isInPlan == true)
        #expect(store.state.cards[id: dishes[1].id]?.isInPlan == false)
        #expect(store.state.cards[id: dishes[2].id]?.isInPlan == false)

        // Тап по уже-в-плане карточке не должен её выбирать
        await store.send(.burstFinished)
        await store.send(.cardTapped(dishes[0].id))
        #expect(store.state.selectedIDs.isEmpty)
    }
}
