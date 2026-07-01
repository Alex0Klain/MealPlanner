import ComposableArchitecture

extension MealPlanRepository: DependencyKey {
    /// По умолчанию — in-memory. Боевая реализация с ModelContainer
    /// подключается в `MealPlannerApp` через `.dependency(\.mealPlanRepository, .live(container:))`.
    public static let liveValue:    MealPlanRepository = .preview
    public static let previewValue: MealPlanRepository = .preview
    public static let testValue:    MealPlanRepository = .unimplemented
}

extension DependencyValues {
    public var mealPlanRepository: MealPlanRepository {
        get { self[MealPlanRepository.self] }
        set { self[MealPlanRepository.self] = newValue }
    }
}
