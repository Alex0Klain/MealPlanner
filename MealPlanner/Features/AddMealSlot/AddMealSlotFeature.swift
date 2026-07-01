import ComposableArchitecture
import Foundation

@Reducer
public struct AddMealSlotFeature {
    @ObservableState
    public struct State: Equatable {
        public var availableDishes: [Dish] = []
        public var selectedSlot: MealSlot = .breakfast
        public var date: Date

        public init(date: Date, selectedSlot: MealSlot = .breakfast) {
            self.date = date
            self.selectedSlot = selectedSlot
        }
    }

    public enum Action: Equatable {
        case onAppear
        case dishesLoaded([Dish])
        case slotChanged(MealSlot)
        case dishTapped(Dish)
        case cancelTapped
        case delegate(Delegate)

        public enum Delegate: Equatable {
            case picked(Dish, MealSlot)
            case dismiss
        }
    }

    @Dependency(\.dishRepository) var dishRepository

    public init() {}

    public var body: some ReducerOf<Self> {
        Reduce { state, action in
            switch action {
            case .onAppear:
                return .run { [dishRepository] send in
                    if let dishes = try? await dishRepository.all() {
                        await send(.dishesLoaded(dishes))
                    }
                }

            case let .dishesLoaded(dishes):
                state.availableDishes = dishes
                return .none

            case let .slotChanged(slot):
                state.selectedSlot = slot
                return .none

            case let .dishTapped(dish):
                return .send(.delegate(.picked(dish, state.selectedSlot)))

            case .cancelTapped:
                return .send(.delegate(.dismiss))

            case .delegate:
                return .none
            }
        }
    }
}
