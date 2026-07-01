import ComposableArchitecture
import Foundation

@Reducer
public struct PackOpeningFeature {
    @ObservableState
    public struct State: Equatable {
        public var phase: Phase = .closed
        public var cards: IdentifiedArrayOf<PackCard> = []
        public var selectedIDs: Set<Dish.ID> = []
        public var maxSelectable: Int = 7
        public var date: Date
        public var alreadyInPlanIDs: Set<Dish.ID> = []
        public var distribution: [Dish.ID: MealSlot] = [:]

        public init(date: Date, alreadyInPlanIDs: Set<Dish.ID> = []) {
            self.date = date
            self.alreadyInPlanIDs = alreadyInPlanIDs
            self.maxSelectable = max(0, 7 - alreadyInPlanIDs.count)
        }

        public var canConfirmReveal: Bool {
            !selectedIDs.isEmpty
        }

        public var canConfirmDistribution: Bool {
            selectedIDs.allSatisfy { distribution[$0] != nil }
        }

        public var selectedCards: [PackCard] {
            cards.filter { selectedIDs.contains($0.id) }
        }
    }

    public enum Phase: Equatable {
        case closed
        case burst
        case reveal
        case distribute
    }

    public enum Action: Equatable {
        case onAppear
        case packLoaded([Dish])
        case packTapped
        case burstFinished
        case cardTapped(Dish.ID)
        case confirmRevealTapped
        case slotAssigned(Dish.ID, MealSlot)
        case confirmDistributionTapped
        case closeTapped
        case delegate(Delegate)

        public enum Delegate: Equatable {
            case finished([PlannedMeal])
            case dismiss
        }
    }

    @Dependency(\.dishRepository) var dishRepository
    @Dependency(\.packGenerator)  var packGenerator
    @Dependency(\.continuousClock) var clock

    public init() {}

    public var body: some ReducerOf<Self> {
        Reduce { state, action in
            switch action {
            case .onAppear:
                return .run { [dishRepository, packGenerator] send in
                    let allDishes = (try? await dishRepository.all()) ?? []
                    let pack = packGenerator.generate(9, allDishes)
                    await send(.packLoaded(pack))
                }

            case let .packLoaded(dishes):
                // Защита от возможных дубликатов: IdentifiedArray(uniqueElements:)
                // падает fatalError, если в списке два элемента с одинаковым id.
                var cards = IdentifiedArrayOf<PackCard>()
                for (index, dish) in dishes.enumerated() {
                    let inPlan = state.alreadyInPlanIDs.contains(dish.id)
                    cards.updateOrAppend(
                        PackCard(dish: dish, isInPlan: inPlan, revealIndex: index)
                    )
                }
                state.cards = cards
                return .none

            case .packTapped:
                guard state.phase == .closed else { return .none }
                state.phase = .burst
                return .run { [clock] send in
                    try await clock.sleep(for: .milliseconds(800))
                    await send(.burstFinished)
                }

            case .burstFinished:
                state.phase = .reveal
                for id in state.cards.ids {
                    state.cards[id: id]?.isRevealed = true
                }
                return .none

            case let .cardTapped(dishID):
                guard state.phase == .reveal else { return .none }
                guard let card = state.cards[id: dishID], !card.isInPlan else { return .none }
                if state.selectedIDs.contains(dishID) {
                    state.selectedIDs.remove(dishID)
                    state.cards[id: dishID]?.isSelected = false
                } else if state.selectedIDs.count < state.maxSelectable {
                    state.selectedIDs.insert(dishID)
                    state.cards[id: dishID]?.isSelected = true
                }
                return .none

            case .confirmRevealTapped:
                guard state.canConfirmReveal else { return .none }
                state.phase = .distribute
                return .none

            case let .slotAssigned(dishID, slot):
                state.distribution[dishID] = slot
                return .none

            case .confirmDistributionTapped:
                guard state.canConfirmDistribution else { return .none }
                let meals = state.distribution.map { dishID, slot in
                    PlannedMeal(dishID: dishID, slot: slot)
                }
                return .send(.delegate(.finished(meals)))

            case .closeTapped:
                return .send(.delegate(.dismiss))

            case .delegate:
                return .none
            }
        }
    }
}

public struct PackCard: Identifiable, Equatable {
    public var dish: Dish
    public var isRevealed: Bool = false
    public var isSelected: Bool = false
    public var isInPlan: Bool   = false
    public var revealIndex: Int

    public var id: Dish.ID { dish.id }

    public init(dish: Dish, isRevealed: Bool = false, isSelected: Bool = false, isInPlan: Bool = false, revealIndex: Int) {
        self.dish = dish
        self.isRevealed = isRevealed
        self.isSelected = isSelected
        self.isInPlan = isInPlan
        self.revealIndex = revealIndex
    }
}
