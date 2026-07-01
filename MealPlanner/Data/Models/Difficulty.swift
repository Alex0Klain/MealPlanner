public enum Difficulty: String, Codable, Sendable, CaseIterable {
    case one
    case two
    case three

    public var stars: String {
        switch self {
        case .one:   "★☆☆"
        case .two:   "★★☆"
        case .three: "★★★"
        }
    }
}
