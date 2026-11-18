import ComposableArchitecture
import Foundation

@Reducer
public struct DayDetailFeature {
  @ObservableState
  public struct State: Equatable {
    public var date: Date
    public var plan: DayPlanSnapshot
    public var dishesByID: [Dish.ID: Dish] = [:]
    @Presents public var destination: Destination.State?

    public init(date: Date) {
      self.date = Calendar.current.startOfDay(for: date)
      self.plan = DayPlanSnapshot(date: date)
    }
  }

  public enum Action: Equatable {
    case onAppear
    case planLoaded(DayPlanSnapshot)
    case dishesLoaded([Dish])
    case previousDayTapped
    case nextDayTapped
    case packCtaTapped
    case slotTapped(MealSlot)
    case mealTapped(PlannedMeal)
    case removeMealTapped(PlannedMeal)
    case replaceMealTapped(PlannedMeal)
    case destination(PresentationAction<Destination.Action>)
  }

  @Reducer
  public enum Destination {
    case packOpening(PackOpeningFeature)
    case addMealSlot(AddMealSlotFeature)
    case recipeDetail(RecipeDetailFeature)
  }

  @Dependency(\.dishRepository) var dishRepository
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

      case .planLoaded(let plan):
        state.plan = plan
        return .none

      case .dishesLoaded(let dishes):
        state.dishesByID = Dictionary(
          dishes.map { ($0.id, $0) },
          uniquingKeysWith: { first, _ in first },
        )
        return .none

      case .previousDayTapped:
        return shiftDay(by: -1, state: &state)

      case .nextDayTapped:
        return shiftDay(by: 1, state: &state)

      case .packCtaTapped:
        state.destination = .packOpening(
          PackOpeningFeature.State(
            date: state.date,
            existingBySlot: Dictionary(grouping: state.plan.meals, by: \.slot)
              .mapValues { $0.compactMap { state.dishesByID[$0.dishID] } },
          )
        )
        return .none

      case .slotTapped(let slot):
        state.destination = .addMealSlot(
          AddMealSlotFeature.State(date: state.date, selectedSlot: slot)
        )
        return .none

      case .mealTapped(let meal):
        guard let dish = state.dishesByID[meal.dishID] else { return .none }
        state.destination = .recipeDetail(RecipeDetailFeature.State(dish: dish))
        return .none

      case .removeMealTapped(let meal):
        let date = state.date
        return .run { [mealPlanRepository] send in
          try? await mealPlanRepository.removeMeal(meal.dishID, date)
          let plan = await mealPlanRepository.planForDate(date) ?? DayPlanSnapshot(date: date)
          await send(.planLoaded(plan))
        }

      case .replaceMealTapped(let meal):
        state.destination = .addMealSlot(
          AddMealSlotFeature.State(date: state.date, selectedSlot: meal.slot)
        )
        let date = state.date
        return .run { [mealPlanRepository] send in
          try? await mealPlanRepository.removeMeal(meal.dishID, date)
          let plan = await mealPlanRepository.planForDate(date) ?? DayPlanSnapshot(date: date)
          await send(.planLoaded(plan))
        }

      case .destination(.presented(.packOpening(.delegate(.finished(let meals))))):
        state.destination = nil
        let date = state.date
        return .run { [mealPlanRepository] send in
          for meal in meals {
            try? await mealPlanRepository.addMeal(meal.dishID, meal.slot, date)
          }
          let plan = await mealPlanRepository.planForDate(date) ?? DayPlanSnapshot(date: date)
          await send(.planLoaded(plan))
        }

      case .destination(.presented(.packOpening(.delegate(.dismiss)))):
        state.destination = nil
        return .none

      case .destination(.presented(.addMealSlot(.delegate(.picked(let dish, let slot))))):
        state.destination = nil
        let date = state.date
        return .run { [mealPlanRepository] send in
          try? await mealPlanRepository.addMeal(dish.id, slot, date)
          let plan = await mealPlanRepository.planForDate(date) ?? DayPlanSnapshot(date: date)
          await send(.planLoaded(plan))
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

  /// Свайп/стрелки по дням: меняем дату и перечитываем план.
  private func shiftDay(by offset: Int, state: inout State) -> Effect<Action> {
    guard let newDate = Calendar.current.date(byAdding: .day, value: offset, to: state.date) else {
      return .none
    }
    state.date = Calendar.current.startOfDay(for: newDate)
    state.plan = DayPlanSnapshot(date: newDate)
    let date = state.date
    return .run { [mealPlanRepository] send in
      let plan = await mealPlanRepository.planForDate(date) ?? DayPlanSnapshot(date: date)
      await send(.planLoaded(plan))
    }
  }
}

extension DayDetailFeature.Destination.State: Equatable {}
extension DayDetailFeature.Destination.Action: Equatable {}
