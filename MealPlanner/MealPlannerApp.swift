import ComposableArchitecture
import SwiftData
import SwiftUI

@main
struct MealPlannerApp: App {
    let modelContainer: ModelContainer
    let store: StoreOf<AppFeature>

    init() {
        do {
            modelContainer = try ModelContainer(for: DayPlan.self)
        } catch {
            fatalError("Failed to create ModelContainer: \(error)")
        }

        let liveRepository = MealPlanRepository.live(container: modelContainer)
        store = withDependencies {
            $0.mealPlanRepository = liveRepository
        } operation: {
            Store(initialState: AppFeature.State()) {
                AppFeature()
            }
        }
    }

    var body: some Scene {
        WindowGroup {
            AppView(store: store)
        }
        .modelContainer(modelContainer)
    }
}
