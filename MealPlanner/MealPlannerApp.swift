import ComposableArchitecture
import SwiftData
import SwiftUI

@main
struct MealPlannerApp: App {
    let modelContainer: ModelContainer
    let store: StoreOf<AppFeature>

    init() {
        modelContainer = Self.makeModelContainer()

        let liveRepository = MealPlanRepository.live(container: modelContainer)
        store = withDependencies {
            $0.mealPlanRepository = liveRepository
        } operation: {
            Store(initialState: AppFeature.State()) {
                AppFeature()
            }
        }
    }

    /// Пытаемся поднять постоянный store; если sandbox запрещает файловый доступ
    /// (например, unit-тесты в CI поднимают приложение как test host), падаем
    /// в in-memory режим, чтобы `@main`-инициализация не крашила процесс.
    private static func makeModelContainer() -> ModelContainer {
        if let container = try? ModelContainer(for: DayPlan.self) {
            return container
        }
        do {
            let configuration = ModelConfiguration(isStoredInMemoryOnly: true)
            return try ModelContainer(for: DayPlan.self, configurations: configuration)
        } catch {
            // Даже in-memory контейнер не поднялся — это невосстановимо:
            // SwiftData не работоспособна. Явный фатал с описанием лучше,
            // чем неопределённый крэш где-то дальше.
            preconditionFailure(
                "Unable to create even an in-memory ModelContainer: \(error). " +
                "SwiftData is broken; the app cannot proceed."
            )
        }
    }

    var body: some Scene {
        WindowGroup {
            AppView(store: store)
        }
        .modelContainer(modelContainer)
    }
}
