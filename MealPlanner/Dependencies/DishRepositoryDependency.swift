import ComposableArchitecture

extension DishRepository: DependencyKey {
    public static let liveValue:    DishRepository = .live
    public static let previewValue: DishRepository = .preview
    /// Тестовые прогоны используют in-memory каталог, чтобы приложение
    /// как test host могло стартовать без crash в `unimplemented`.
    /// Специфичные тесты подменяют dependency через `withDependencies`.
    public static let testValue:    DishRepository = .preview
}

extension DependencyValues {
    public var dishRepository: DishRepository {
        get { self[DishRepository.self] }
        set { self[DishRepository.self] = newValue }
    }
}
