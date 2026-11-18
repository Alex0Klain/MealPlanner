import ComposableArchitecture
import Foundation
import MealPlanner
import Testing

@Suite("RecipeDetailFeature")
@MainActor
struct RecipeDetailFeatureTests {

  private static var dish: Dish {
    Dish(
      id: UUID(uuidString: "33333333-0000-0000-0000-000000000001")!,
      name: "Тестовое блюдо",
      cuisine: .home,
      emoji: "🍽",
      cookTimeMinutes: 10,
      calories: 300,
      proteinGrams: 20,
      rarity: .common,
      difficulty: .one,
      ingredients: [
        Ingredient(emoji: "🥚", name: "Яйцо", amount: "1 шт")
      ],
      steps: [
        RecipeStep(order: 1, title: "Шаг 1", description: "…", durationMinutes: 1),
        RecipeStep(order: 2, title: "Шаг 2", description: "…", durationMinutes: nil),
        RecipeStep(order: 3, title: "Шаг 3", description: "…", durationMinutes: 2),
      ],
    )
  }

  @Test func startCookingActivatesFirstStepAndStartsTimer() async {
    let clock = TestClock()
    let store = TestStore(
      initialState: RecipeDetailFeature.State(dish: Self.dish)
    ) {
      RecipeDetailFeature()
    } withDependencies: {
      $0.continuousClock = clock
    }
    store.exhaustivity = .off

    await store.send(.startCookingTapped) {
      $0.isCooking = true
      $0.mode = .steps
      $0.activeStepIndex = 0
      $0.remainingSeconds = 60
      $0.isTimerRunning = true
    }

    await clock.advance(by: .seconds(2))
    await store.receive(\.timerTicked)
    await store.receive(\.timerTicked)
    #expect(store.state.remainingSeconds == 58)

    await store.send(.closeTapped)
    await store.receive(\.delegate.dismiss)
  }

  @Test func completeStepAdvancesToNextIncomplete() async {
    let clock = TestClock()
    let store = TestStore(
      initialState: RecipeDetailFeature.State(dish: Self.dish)
    ) {
      RecipeDetailFeature()
    } withDependencies: {
      $0.continuousClock = clock
    }
    store.exhaustivity = .off

    await store.send(.startCookingTapped)

    // Шаг 1 → шаг 2 (без таймера: durationMinutes == nil).
    await store.send(.completeStepTapped)
    #expect(store.state.completedSteps == [0])
    #expect(store.state.activeStepIndex == 1)
    #expect(store.state.isTimerRunning == false)

    // Шаг 2 → шаг 3 (таймер 2 минуты автостартует).
    await store.send(.completeStepTapped)
    #expect(store.state.completedSteps == [0, 1])
    #expect(store.state.activeStepIndex == 2)
    #expect(store.state.remainingSeconds == 120)
    #expect(store.state.isTimerRunning == true)

    // Завершаем последний — всё готово, таймер остановлен.
    await store.send(.completeStepTapped)
    #expect(store.state.allStepsCompleted)
    #expect(store.state.isTimerRunning == false)

    await store.send(.closeTapped)
    await store.receive(\.delegate.dismiss)
  }

  @Test func stepTappedJumpsToChosenStep() async {
    let clock = TestClock()
    let store = TestStore(
      initialState: RecipeDetailFeature.State(dish: Self.dish)
    ) {
      RecipeDetailFeature()
    } withDependencies: {
      $0.continuousClock = clock
    }
    store.exhaustivity = .off

    await store.send(.startCookingTapped)
    await store.send(.stepTapped(2))
    #expect(store.state.activeStepIndex == 2)
    #expect(store.state.remainingSeconds == 120)

    // Прыжок в шаг без таймера гасит таймер.
    await store.send(.stepTapped(1))
    #expect(store.state.activeStepIndex == 1)
    #expect(store.state.isTimerRunning == false)

    await store.send(.closeTapped)
    await store.receive(\.delegate.dismiss)
  }

  @Test func timerStopsAtZero() async {
    let clock = TestClock()
    let store = TestStore(
      initialState: RecipeDetailFeature.State(dish: Self.dish)
    ) {
      RecipeDetailFeature()
    } withDependencies: {
      $0.continuousClock = clock
    }
    store.exhaustivity = .off

    await store.send(.startCookingTapped)
    // 60 тиков доводят до нуля, 61-й останавливает таймер.
    // skipReceivedActions прогоняет буфер через reducer — иначе cancel
    // не случится и finish() будет ждать таймер вечно.
    await clock.advance(by: .seconds(61))
    await store.skipReceivedActions()
    #expect(store.state.remainingSeconds == 0)
    #expect(store.state.isTimerRunning == false)
    await store.finish()
  }

  @Test func progressCountsCompletedDurations() async {
    var state = RecipeDetailFeature.State(dish: Self.dish)
    state.completedSteps = [0, 2]
    // Завершены шаги с таймингом 1 и 2 минуты.
    #expect(state.minutesPassed == 3)
    #expect(abs(state.progressFraction - 2.0 / 3.0) < 0.001)
  }
}
