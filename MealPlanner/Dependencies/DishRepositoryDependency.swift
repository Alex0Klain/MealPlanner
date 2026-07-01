import ComposableArchitecture

extension DishRepository: DependencyKey {
    public static let liveValue:    DishRepository = .live
    public static let previewValue: DishRepository = .preview
    public static let testValue:    DishRepository = .unimplemented
}

extension DependencyValues {
    public var dishRepository: DishRepository {
        get { self[DishRepository.self] }
        set { self[DishRepository.self] = newValue }
    }
}
