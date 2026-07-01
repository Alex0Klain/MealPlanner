import ComposableArchitecture
import Foundation

@Reducer
public struct AppFeature {
    @ObservableState
    public struct State: Equatable {
        public var selectedTab: Tab = .today
        public var home: HomeFeature.State
        public var week: WeekPlannerFeature.State

        public init() {
            self.home = HomeFeature.State()
            self.week = WeekPlannerFeature.State()
        }
    }

    public enum Tab: String, Equatable, Hashable {
        case today
        case week
    }

    public enum Action: Equatable {
        case tabChanged(Tab)
        case home(HomeFeature.Action)
        case week(WeekPlannerFeature.Action)
    }

    public init() {}

    public var body: some ReducerOf<Self> {
        Scope(state: \.home, action: \.home) { HomeFeature() }
        Scope(state: \.week, action: \.week) { WeekPlannerFeature() }

        Reduce { state, action in
            switch action {
            case let .tabChanged(tab):
                state.selectedTab = tab
                return .none
            case .home, .week:
                return .none
            }
        }
    }
}
