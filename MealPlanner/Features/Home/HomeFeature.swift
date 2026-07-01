import ComposableArchitecture
import Foundation

@Reducer
public struct HomeFeature {
    @ObservableState
    public struct State: Equatable {
        public var date: Date = Calendar.current.startOfDay(for: .now)
        public var plan: DayPlanSnapshot
        public var dishesByID: [Dish.ID: Dish] = [:]
        @Presents public var destination: Destination.State?

        public init(date: Date = .now, plan: DayPlanSnapshot? = nil) {
            let day = Calendar.current.startOfDay(for: date)
            self.date = day
            self.plan = plan ?? DayPlanSnapshot(date: day)
        }
    }

    public enum Action: Equatable {
        case onAppear
        case planLoaded(DayPlanSnapshot)
        case dishesLoaded([Dish])
        case packCtaTapped
        case slotTapped(MealSlot)
        case mealTapped(PlannedMeal)
        case removeMealTapped(PlannedMeal)
        case mealRemoved(UUID)
        case destination(PresentationAction<Destination.Action>)
    }

    @Reducer(state: .equatable, action: .equatable)
    public enum Destination {
        case packOpening(PackOpeningFeature)
        case addMealSlot(AddMealSlotFeature)
        case recipeDetail(RecipeDetailFeature)
    }

    @Dependency(\.dishRepository)     var dishRepository
    @Dependency(\.mealPlanRepository) var mealPlanRepository

    public init() {}

    public var body: some ReducerOf<Self> {
        Reduce { state, action in
            switch action {
            case .onAppear:
                let date = state.date
                return .run { [mealPlanRepository, dishRepository] send in
                    let plan = await mealPlanRepository.planForDate(date) ?? DayPlanSnapshot(date: date)
                    let dishes = (try? await dishRepository.all()) ?? []
                    await send(.planLoaded(plan))
                    await send(.dishesLoaded(dishes))
                }

            case let .planLoaded(plan):
                state.plan = plan
                return .none

            case let .dishesLoaded(dishes):
                state.dishesByID = Dictionary(uniqueKeysWithValues: dishes.map { ($0.id, $0) })
                return .none

            case .packCtaTapped:
                state.destination = .packOpening(
                    PackOpeningFeature.State(
                        date: state.date,
                        alreadyInPlan: state.plan.meals.count
                    )
                )
                return .none

            case let .slotTapped(slot):
                state.destination = .addMealSlot(
                    AddMealSlotFeature.State(date: state.date, selectedSlot: slot)
                )
                return .none

            case let .mealTapped(meal):
                guard let dish = state.dishesByID[meal.dishID] else { return .none }
                state.destination = .recipeDetail(RecipeDetailFeature.State(dish: dish))
                return .none

            case let .removeMealTapped(meal):
                let date = state.date
                return .run { [mealPlanRepository] send in
                    try? await mealPlanRepository.removeMeal(meal.dishID, date)
                    await send(.mealRemoved(meal.dishID))
                }

            case let .mealRemoved(dishID):
                state.plan.meals.removeAll { $0.dishID == dishID }
                return .none

            // MARK: Destination delegate handling

            case let .destination(.presented(.packOpening(.delegate(.finished(meals))))):
                state.plan.meals.append(contentsOf: meals)
                state.destination = nil
                let snapshot = state.plan
                return .run { [mealPlanRepository] _ in
                    try? await mealPlanRepository.save(snapshot)
                }

            case .destination(.presented(.packOpening(.delegate(.dismiss)))):
                state.destination = nil
                return .none

            case let .destination(.presented(.addMealSlot(.delegate(.picked(dish, slot))))):
                state.plan.meals.append(PlannedMeal(dishID: dish.id, slot: slot))
                state.destination = nil
                let snapshot = state.plan
                let date = state.date
                return .run { [mealPlanRepository] _ in
                    try? await mealPlanRepository.addMeal(dish.id, slot, date)
                    try? await mealPlanRepository.save(snapshot)
                }

            case .destination(.presented(.addMealSlot(.delegate(.dismiss)))):
                state.destination = nil
                return .none

            case .destination(.presented(.recipeDetail(.delegate(.dismiss)))):
                state.destination = nil
                return .none

            case .destination:
                return .none
            }
        }
        .ifLet(\.$destination, action: \.destination)
    }
}
