import ComposableArchitecture
import Foundation

@Reducer
public struct RecipeDetailFeature {
    @ObservableState
    public struct State: Equatable {
        public var dish: Dish
        /// Активная вкладка сегмент-контрола: Ингредиенты / Шаги.
        public var mode: Mode = .ingredients
        /// true после «Начать готовить» — компактный hero, прогресс, таймер.
        public var isCooking: Bool = false
        public var activeStepIndex: Int = 0
        public var completedSteps: Set<Int> = []
        public var remainingSeconds: Int = 0
        public var isTimerRunning: Bool = false

        public init(dish: Dish) {
            self.dish = dish
        }

        public enum Mode: Equatable {
            case ingredients
            case steps
        }

        public var allStepsCompleted: Bool {
            !dish.steps.isEmpty && completedSteps.count == dish.steps.count
        }

        public var activeStep: RecipeStep? {
            dish.steps.indices.contains(activeStepIndex) ? dish.steps[activeStepIndex] : nil
        }

        /// Прошедшее время по завершённым шагам, минуты.
        public var minutesPassed: Int {
            dish.steps
                .enumerated()
                .filter { completedSteps.contains($0.offset) }
                .compactMap(\.element.durationMinutes)
                .reduce(0, +)
        }

        public var progressFraction: Double {
            guard !dish.steps.isEmpty else { return 0 }
            return Double(completedSteps.count) / Double(dish.steps.count)
        }
    }

    public enum Action: Equatable {
        case modeChanged(State.Mode)
        case startCookingTapped
        case stepTapped(Int)
        case completeStepTapped
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
            case let .modeChanged(mode):
                state.mode = mode
                return .none

            case .startCookingTapped:
                state.isCooking = true
                state.mode = .steps
                state.completedSteps = []
                return activate(step: firstIncompleteIndex(state), state: &state)

            case let .stepTapped(index):
                guard state.isCooking, state.dish.steps.indices.contains(index) else { return .none }
                return activate(step: index, state: &state)

            case .completeStepTapped:
                guard state.isCooking else { return .none }
                state.completedSteps.insert(state.activeStepIndex)
                if let next = firstIncompleteIndex(state) {
                    return activate(step: next, state: &state)
                }
                state.isTimerRunning = false
                return .cancel(id: CancelID.timer)

            case .timerToggled:
                state.isTimerRunning.toggle()
                if state.isTimerRunning {
                    return startTimer()
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

    // MARK: - Helpers

    private func firstIncompleteIndex(_ state: State) -> Int? {
        state.dish.steps.indices.first { !state.completedSteps.contains($0) }
    }

    /// Делает шаг активным; если у шага есть таймер — сразу запускает его.
    private func activate(step index: Int?, state: inout State) -> Effect<Action> {
        guard let index else {
            state.isTimerRunning = false
            return .cancel(id: CancelID.timer)
        }
        state.activeStepIndex = index
        let duration = state.dish.steps[index].durationMinutes ?? 0
        state.remainingSeconds = duration * 60
        state.isTimerRunning = duration > 0
        return duration > 0 ? startTimer() : .cancel(id: CancelID.timer)
    }

    private func startTimer() -> Effect<Action> {
        .run { [clock] send in
            for await _ in clock.timer(interval: .seconds(1)) {
                await send(.timerTicked)
            }
        }
        .cancellable(id: CancelID.timer, cancelInFlight: true)
    }
}
