import ComposableArchitecture
import Foundation

@Reducer
public struct WeekPlannerFeature {
    @ObservableState
    public struct State: Equatable {
        public var weekStart: Date
        public var days: [DayPlanSnapshot] = []
        public var dishesByID: [Dish.ID: Dish] = [:]
        public var path = StackState<Path.State>()

        public init(weekStart: Date = .now) {
            let calendar = Calendar.current
            let start = calendar.dateInterval(of: .weekOfYear, for: weekStart)?.start
                ?? calendar.startOfDay(for: weekStart)
            self.weekStart = start
        }
    }

    public enum Action: Equatable {
        case onAppear
        case daysLoaded([DayPlanSnapshot])
        case dishesLoaded([Dish])
        case previousWeekTapped
        case nextWeekTapped
        case dayTapped(Date)
        case path(StackAction<Path.State, Path.Action>)
    }

    @Reducer
    public enum Path {
        case dayDetail(DayDetailFeature)
    }

    @Dependency(\.dishRepository)     var dishRepository
    @Dependency(\.mealPlanRepository) var mealPlanRepository

    public init() {}

    public var body: some ReducerOf<Self> {
        Reduce { state, action in
            switch action {
            case .onAppear:
                let weekStart = state.weekStart
                return .run { [mealPlanRepository, dishRepository] send in
                    let days = await mealPlanRepository.weekPlans(weekStart)
                    let dishes = (try? await dishRepository.all()) ?? []
                    await send(.daysLoaded(days))
                    await send(.dishesLoaded(dishes))
                }

            case let .daysLoaded(days):
                state.days = days
                return .none

            case let .dishesLoaded(dishes):
                state.dishesByID = Dictionary(
                    dishes.map { ($0.id, $0) },
                    uniquingKeysWith: { first, _ in first }
                )
                return .none

            case .previousWeekTapped:
                return shiftWeek(by: -1, state: &state)

            case .nextWeekTapped:
                return shiftWeek(by: 1, state: &state)

            case let .dayTapped(date):
                state.path.append(.dayDetail(DayDetailFeature.State(date: date)))
                return .none

            case .path(.popFrom):
                // Возврат с DayDetail — план мог измениться, перечитываем неделю
                let weekStart = state.weekStart
                return .run { [mealPlanRepository] send in
                    let days = await mealPlanRepository.weekPlans(weekStart)
                    await send(.daysLoaded(days))
                }

            case .path:
                return .none
            }
        }
        .forEach(\.path, action: \.path)
    }

    private func shiftWeek(by offset: Int, state: inout State) -> Effect<Action> {
        guard let newStart = Calendar.current.date(byAdding: .day, value: offset * 7, to: state.weekStart) else {
            return .none
        }
        state.weekStart = newStart
        let weekStart = newStart
        return .run { [mealPlanRepository] send in
            let days = await mealPlanRepository.weekPlans(weekStart)
            await send(.daysLoaded(days))
        }
    }
}

extension WeekPlannerFeature.Path.State: Equatable {}
extension WeekPlannerFeature.Path.Action: Equatable {}
