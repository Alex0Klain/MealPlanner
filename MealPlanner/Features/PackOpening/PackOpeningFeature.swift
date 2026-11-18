import ComposableArchitecture
import Foundation

@Reducer
public struct PackOpeningFeature {
    @ObservableState
    public struct State: Equatable {
        public var phase: Phase = .closed
        public var cards: IdentifiedArrayOf<PackCard> = []
        public var selectedIDs: Set<Dish.ID> = []
        public var maxSelectable: Int
        public var date: Date
        /// Блюда, уже лежащие в плане дня, по слотам — для отображения
        /// занятости на шаге Distribute и расчёта ёмкости.
        public var existingBySlot: [MealSlot: [Dish]] = [:]
        public var alreadyInPlanIDs: Set<Dish.ID> = []
        public var distribution: [Dish.ID: MealSlot] = [:]
        /// Карточка, для которой сейчас выбирается слот на шаге Distribute.
        public var activeDistributionID: Dish.ID?

        public init(date: Date, existingBySlot: [MealSlot: [Dish]] = [:]) {
            self.date = date
            self.existingBySlot = existingBySlot
            self.alreadyInPlanIDs = Set(existingBySlot.values.flatMap { $0.map(\.id) })
            let existingCount = existingBySlot.values.reduce(0) { $0 + $1.count }
            self.maxSelectable = max(0, MealSlot.dayCapacity - existingCount)
        }

        public var canConfirmReveal: Bool {
            !selectedIDs.isEmpty
        }

        public var canConfirmDistribution: Bool {
            selectedIDs.allSatisfy { distribution[$0] != nil }
        }

        /// Выбранные карточки в порядке раскладки (revealIndex).
        public var selectedCards: [PackCard] {
            cards.filter { selectedIDs.contains($0.id) }
        }

        public var unassignedCount: Int {
            selectedIDs.count { distribution[$0] == nil }
        }

        var firstUnassignedID: Dish.ID? {
            selectedCards.first { distribution[$0.id] == nil }?.id
        }

        /// Сколько блюд ещё поместится в слот с учётом уже лежащих
        /// и распределённых на этом шаге.
        public func remainingCapacity(of slot: MealSlot) -> Int {
            let existing = existingBySlot[slot]?.count ?? 0
            let assigned = distribution.values.count { $0 == slot }
            return max(0, MealSlot.mealsPerSlot - existing - assigned)
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
        case rerollTapped
        case confirmRevealTapped
        case backToRevealTapped
        case distributionCardTapped(Dish.ID)
        case slotAssigned(Dish.ID, MealSlot)
        case autoAssignTapped
        case confirmDistributionTapped
        case closeTapped
        case delegate(Delegate)

        @CasePathable
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
                    try await clock.sleep(for: .milliseconds(500))
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

            case .rerollTapped:
                // «Ещё пак»: короткий re-burst и новая девятка карточек.
                guard state.phase == .reveal else { return .none }
                state.phase = .burst
                state.selectedIDs = []
                state.distribution = [:]
                state.activeDistributionID = nil
                return .run { [dishRepository, packGenerator, clock] send in
                    let allDishes = (try? await dishRepository.all()) ?? []
                    let pack = packGenerator.generate(9, allDishes)
                    await send(.packLoaded(pack))
                    try await clock.sleep(for: .milliseconds(500))
                    await send(.burstFinished)
                }

            case .confirmRevealTapped:
                guard state.canConfirmReveal else { return .none }
                state.phase = .distribute
                state.activeDistributionID = state.firstUnassignedID
                return .none

            case .backToRevealTapped:
                guard state.phase == .distribute else { return .none }
                state.phase = .reveal
                return .none

            case let .distributionCardTapped(dishID):
                guard state.selectedIDs.contains(dishID) else { return .none }
                state.activeDistributionID = dishID
                return .none

            case let .slotAssigned(dishID, slot):
                // Слот вмещает не больше MealSlot.mealsPerSlot блюд —
                // назначение в полный слот игнорируем.
                guard state.remainingCapacity(of: slot) > 0 else { return .none }
                state.distribution[dishID] = slot
                state.activeDistributionID = state.firstUnassignedID
                return .none

            case .autoAssignTapped:
                // Нераспределённые карточки раскладываем по ёмкости:
                // сначала пустые слоты в каноничном порядке, затем добираем
                // вторыми блюдами. Полные слоты пропускаем.
                for card in state.selectedCards where state.distribution[card.id] == nil {
                    let target = MealSlot.displayOrder
                        .filter { state.remainingCapacity(of: $0) > 0 }
                        .min { lhs, rhs in
                            let l = (state.existingBySlot[lhs]?.count ?? 0)
                                + state.distribution.values.count { $0 == lhs }
                            let r = (state.existingBySlot[rhs]?.count ?? 0)
                                + state.distribution.values.count { $0 == rhs }
                            if l != r { return l < r }
                            let order = MealSlot.displayOrder
                            return (order.firstIndex(of: lhs) ?? 0) < (order.firstIndex(of: rhs) ?? 0)
                        }
                    guard let target else { break }
                    state.distribution[card.id] = target
                }
                state.activeDistributionID = state.firstUnassignedID
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
