import ComposableArchitecture

extension MealPlanRepository: DependencyKey {
    /// По умолчанию — in-memory. Боевая реализация с ModelContainer
    /// подключается в `MealPlannerApp` через `.dependency(\.mealPlanRepository, .live(container:))`.
    public static let liveValue:    MealPlanRepository = .preview
    public static let previewValue: MealPlanRepository = .preview
    /// In-memory для тестов — избегаем краша app-под-test-host на unimplemented.
    /// Специфичные тесты переопределяют через `withDependencies`.
    public static let testValue:    MealPlanRepository = .preview
}

extension DependencyValues {
    public var mealPlanRepository: MealPlanRepository {
        get { self[MealPlanRepository.self] }
        set { self[MealPlanRepository.self] = newValue }
    }
}
