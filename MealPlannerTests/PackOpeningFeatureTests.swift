import Testing
import Foundation
import Synchronization
import ComposableArchitecture
import MealPlanner

@Suite("PackOpeningFeature")
@MainActor
struct PackOpeningFeatureTests {

    // MARK: - Helpers

    private static func makeDish(_ name: String, rarity: Rarity = .common) -> Dish {
        Dish(
            id: UUID(),
            name: name,
            cuisine: .home,
            emoji: "🍽",
            cookTimeMinutes: 5,
            calories: 100,
            proteinGrams: 10,
            rarity: rarity,
            difficulty: .one,
            ingredients: [],
            steps: []
        )
    }

    private static func makeDishes(_ count: Int) -> [Dish] {
        (0..<count).map { makeDish("Dish \($0)") }
    }

    // MARK: - Reveal

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

    @Test func maxSelectableReflectsRemainingDayCapacity() async {
        // 3 слота по 2 блюда заняты → свободно 8 − 6 = 2.
        let existing: [MealSlot: [Dish]] = [
            .breakfast: [Self.makeDish("A"), Self.makeDish("B")],
            .lunch:     [Self.makeDish("C"), Self.makeDish("D")],
            .dinner:    [Self.makeDish("E"), Self.makeDish("F")]
        ]
        let state = PackOpeningFeature.State(date: .now, existingBySlot: existing)
        #expect(state.maxSelectable == 2)
    }

    @Test func cannotSelectBeyondMaxSelectable() async {
        let dishes = Self.makeDishes(3)
        // Занято 6 из 8 → выбрать можно только 2.
        let existing: [MealSlot: [Dish]] = [
            .breakfast: [Self.makeDish("A"), Self.makeDish("B")],
            .lunch:     [Self.makeDish("C"), Self.makeDish("D")],
            .dinner:    [Self.makeDish("E"), Self.makeDish("F")]
        ]
        let store = TestStore(
            initialState: PackOpeningFeature.State(date: .now, existingBySlot: existing)
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

        await store.send(.cardTapped(dishes[0].id))
        await store.send(.cardTapped(dishes[1].id))
        await store.send(.cardTapped(dishes[2].id))

        #expect(store.state.selectedIDs.count == 2)
        #expect(!store.state.selectedIDs.contains(dishes[2].id))
    }

    @Test func packCardMarksAlreadyInPlanDishes() async {
        let dishes = Self.makeDishes(3)
        // Первое блюдо пака уже лежит в завтраке.
        let store = TestStore(
            initialState: PackOpeningFeature.State(
                date: .now,
                existingBySlot: [.breakfast: [dishes[0]]]
            )
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

        // Тап по уже-в-плане карточке не выбирает её.
        await store.send(.burstFinished)
        await store.send(.cardTapped(dishes[0].id))
        #expect(store.state.selectedIDs.isEmpty)
    }

    @Test func rerollResetsSelectionAndDealsNewPack() async {
        let firstPack = Self.makeDishes(2)
        let secondPack = Self.makeDishes(2)
        let packs = Mutex([firstPack, secondPack])
        let clock = TestClock()

        let store = TestStore(
            initialState: PackOpeningFeature.State(date: .now)
        ) {
            PackOpeningFeature()
        } withDependencies: {
            $0.dishRepository = .preview
            $0.packGenerator = PackGenerator { _, _ in
                packs.withLock { $0.removeFirst() }
            }
            $0.continuousClock = clock
        }
        store.exhaustivity = .off

        await store.send(.onAppear)
        await store.receive(\.packLoaded)
        await store.send(.burstFinished)
        await store.send(.cardTapped(firstPack[0].id))
        #expect(store.state.selectedIDs.count == 1)

        await store.send(.rerollTapped) {
            $0.phase = .burst
        }
        await store.receive(\.packLoaded)
        await clock.advance(by: .milliseconds(500))
        await store.receive(\.burstFinished)

        #expect(store.state.selectedIDs.isEmpty)
        #expect(store.state.distribution.isEmpty)
        #expect(store.state.phase == .reveal)
        #expect(store.state.cards[id: secondPack[0].id] != nil)
        #expect(store.state.cards[id: firstPack[0].id] == nil)
    }

    // MARK: - Distribute

    @Test func slotAssignmentRespectsSlotCapacity() async {
        let dishes = Self.makeDishes(3)
        // Завтрак уже полон (2 блюда).
        let store = TestStore(
            initialState: PackOpeningFeature.State(
                date: .now,
                existingBySlot: [.breakfast: [Self.makeDish("A"), Self.makeDish("B")]]
            )
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
        await store.send(.cardTapped(dishes[0].id))
        await store.send(.confirmRevealTapped)

        // Полный слот игнорирует назначение.
        await store.send(.slotAssigned(dishes[0].id, .breakfast))
        #expect(store.state.distribution[dishes[0].id] == nil)

        // Свободный слот принимает.
        await store.send(.slotAssigned(dishes[0].id, .lunch))
        #expect(store.state.distribution[dishes[0].id] == .lunch)
    }

    @Test func secondDishAllowedInPartiallyFilledSlot() async {
        let dishes = Self.makeDishes(1)
        // В завтраке одно блюдо — второе должно поместиться.
        let store = TestStore(
            initialState: PackOpeningFeature.State(
                date: .now,
                existingBySlot: [.breakfast: [Self.makeDish("A")]]
            )
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
        await store.send(.cardTapped(dishes[0].id))
        await store.send(.confirmRevealTapped)

        await store.send(.slotAssigned(dishes[0].id, .breakfast))
        #expect(store.state.distribution[dishes[0].id] == .breakfast)
        #expect(store.state.remainingCapacity(of: .breakfast) == 0)
    }

    @Test func autoAssignFillsAllRespectingCapacity() async {
        let dishes = Self.makeDishes(5)
        // Завтрак полон, в обеде одно блюдо → свободно: lunch 1, dinner 2, snack 2.
        let store = TestStore(
            initialState: PackOpeningFeature.State(
                date: .now,
                existingBySlot: [
                    .breakfast: [Self.makeDish("A"), Self.makeDish("B")],
                    .lunch:     [Self.makeDish("C")]
                ]
            )
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
        for dish in dishes {
            await store.send(.cardTapped(dish.id))
        }
        #expect(store.state.selectedIDs.count == 5)

        await store.send(.confirmRevealTapped)
        await store.send(.autoAssignTapped)

        #expect(store.state.unassignedCount == 0)
        #expect(store.state.canConfirmDistribution)
        // Ни один слот не переполнен.
        for slot in MealSlot.displayOrder {
            #expect(store.state.remainingCapacity(of: slot) >= 0)
        }
        // Завтрак был полон — auto не должен был докладывать в него.
        let breakfastAssigned = store.state.distribution.values.count { $0 == .breakfast }
        #expect(breakfastAssigned == 0)
    }

    @Test func confirmDistributionEmitsAllSelectedMeals() async {
        let dishes = Self.makeDishes(2)
        let store = TestStore(
            initialState: PackOpeningFeature.State(date: .now)
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
        await store.send(.cardTapped(dishes[0].id))
        await store.send(.cardTapped(dishes[1].id))
        await store.send(.confirmRevealTapped)
        await store.send(.autoAssignTapped)
        await store.send(.confirmDistributionTapped)

        await store.receive(\.delegate.finished) { _ in }
        let delivered = store.state.distribution
        #expect(Set(delivered.keys) == Set(dishes.map(\.id)))
    }

    @Test func activeCardAdvancesAfterAssignment() async {
        let dishes = Self.makeDishes(2)
        let store = TestStore(
            initialState: PackOpeningFeature.State(date: .now)
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
        await store.send(.cardTapped(dishes[0].id))
        await store.send(.cardTapped(dishes[1].id))
        await store.send(.confirmRevealTapped)

        #expect(store.state.activeDistributionID == dishes[0].id)
        await store.send(.slotAssigned(dishes[0].id, .breakfast))
        #expect(store.state.activeDistributionID == dishes[1].id)
        await store.send(.slotAssigned(dishes[1].id, .lunch))
        #expect(store.state.activeDistributionID == nil)
    }
}
