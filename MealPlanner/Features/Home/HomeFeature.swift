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
        // «Заменить»: убираем блюдо и сразу открываем выбор нового
        // для того же слота.
        state.destination = .addMealSlot(
          AddMealSlotFeature.State(date: state.date, selectedSlot: meal.slot)
        )
        let date = state.date
        return .run { [mealPlanRepository] send in
          try? await mealPlanRepository.removeMeal(meal.dishID, date)
          let plan = await mealPlanRepository.planForDate(date) ?? DayPlanSnapshot(date: date)
          await send(.planLoaded(plan))
        }

      // MARK: Destination delegate handling

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
}

extension HomeFeature.Destination.State: Equatable {}
extension HomeFeature.Destination.Action: Equatable {}
