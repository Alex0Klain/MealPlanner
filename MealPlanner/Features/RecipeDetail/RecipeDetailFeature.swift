import ComposableArchitecture
import Foundation

@Reducer
public struct RecipeDetailFeature {
    @ObservableState
    public struct State: Equatable {
        public var dish: Dish
        public var mode: Mode = .overview
        public var activeStepIndex: Int = 0
        public var remainingSeconds: Int = 0
        public var isTimerRunning: Bool = false

        public init(dish: Dish) {
            self.dish = dish
        }

        public enum Mode: Equatable {
            case overview
            case stepByStep
        }
    }

    public enum Action: Equatable {
        case startCookingTapped
        case backToOverviewTapped
        case nextStepTapped
        case previousStepTapped
        case timerToggled
        case timerTicked
        case closeTapped
        case delegate(Delegate)

        public enum Delegate: Equatable {
            case dismiss
        }
    }

    @Dependency(\.continuousClock) var clock

    private enum CancelID { case timer }

    public init() {}

    public var body: some ReducerOf<Self> {
        Reduce { state, action in
            switch action {
            case .startCookingTapped:
                state.mode = .stepByStep
                state.activeStepIndex = 0
                state.remainingSeconds = (state.dish.steps.first?.durationMinutes ?? 0) * 60
                return .none

            case .backToOverviewTapped:
                state.mode = .overview
                state.isTimerRunning = false
                return .cancel(id: CancelID.timer)

            case .nextStepTapped:
                guard state.activeStepIndex + 1 < state.dish.steps.count else { return .none }
                state.activeStepIndex += 1
                state.remainingSeconds = (state.dish.steps[state.activeStepIndex].durationMinutes ?? 0) * 60
                state.isTimerRunning = false
                return .cancel(id: CancelID.timer)

            case .previousStepTapped:
                guard state.activeStepIndex > 0 else { return .none }
                state.activeStepIndex -= 1
                state.remainingSeconds = (state.dish.steps[state.activeStepIndex].durationMinutes ?? 0) * 60
                state.isTimerRunning = false
                return .cancel(id: CancelID.timer)

            case .timerToggled:
                state.isTimerRunning.toggle()
                if state.isTimerRunning {
                    return .run { [clock] send in
                        for await _ in clock.timer(interval: .seconds(1)) {
                            await send(.timerTicked)
                        }
                    }
                    .cancellable(id: CancelID.timer, cancelInFlight: true)
                } else {
                    return .cancel(id: CancelID.timer)
                }

            case .timerTicked:
                guard state.remainingSeconds > 0 else {
                    state.isTimerRunning = false
                    return .cancel(id: CancelID.timer)
                }
                state.remainingSeconds -= 1
                return .none

            case .closeTapped:
                return .merge(
                    .cancel(id: CancelID.timer),
                    .send(.delegate(.dismiss))
                )

            case .delegate:
                return .none
            }
        }
    }
}
