import ComposableArchitecture

extension PackGenerator: DependencyKey {
    public static let liveValue:    PackGenerator = .live
    public static let previewValue: PackGenerator = .live
    public static let testValue:    PackGenerator = .unimplemented
}

extension DependencyValues {
    public var packGenerator: PackGenerator {
        get { self[PackGenerator.self] }
        set { self[PackGenerator.self] = newValue }
    }
}
