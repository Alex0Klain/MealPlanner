import ComposableArchitecture

extension PackGenerator: DependencyKey {
    public static let liveValue:    PackGenerator = .live
    public static let previewValue: PackGenerator = .live
    /// В тестах используем настоящий генератор, чтобы app-под-test-host
    /// не крашился. Тесты, которым нужен детерминизм, подменяют dependency
    /// на `.seeded(_)` через `withDependencies`.
    public static let testValue:    PackGenerator = .live
}

extension DependencyValues {
    public var packGenerator: PackGenerator {
        get { self[PackGenerator.self] }
        set { self[PackGenerator.self] = newValue }
    }
}
