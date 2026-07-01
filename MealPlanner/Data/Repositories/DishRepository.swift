import Foundation

public struct DishRepository: Sendable {
    public var all:        @Sendable () async throws -> [Dish]
    public var byID:       @Sendable (UUID) async -> Dish?
    public var byCuisine:  @Sendable (Cuisine) async -> [Dish]

    public init(
        all: @escaping @Sendable () async throws -> [Dish],
        byID: @escaping @Sendable (UUID) async -> Dish?,
        byCuisine: @escaping @Sendable (Cuisine) async -> [Dish]
    ) {
        self.all = all
        self.byID = byID
        self.byCuisine = byCuisine
    }
}

extension DishRepository {
    /// Загружает каталог из `dishes.json` в бандле один раз и кэширует.
    public static let live: DishRepository = {
        let cache = DishCache()
        return DishRepository(
            all: { try await cache.load() },
            byID: { id in try? await cache.load().first { $0.id == id } },
            byCuisine: { cuisine in
                (try? await cache.load().filter { $0.cuisine == cuisine }) ?? []
            }
        )
    }()

    public static let preview = DishRepository(
        all:       { Dish.previewCatalog },
        byID:      { id in Dish.previewCatalog.first { $0.id == id } },
        byCuisine: { cuisine in Dish.previewCatalog.filter { $0.cuisine == cuisine } }
    )

    public static let unimplemented = DishRepository(
        all:       { fatalError("DishRepository.all not implemented") },
        byID:      { _ in fatalError("DishRepository.byID not implemented") },
        byCuisine: { _ in fatalError("DishRepository.byCuisine not implemented") }
    )
}

// MARK: - Bundle loader

private actor DishCache {
    private var loaded: [Dish]?

    func load() async throws -> [Dish] {
        if let loaded { return loaded }
        guard let url = Bundle.main.url(forResource: "dishes", withExtension: "json") else {
            throw DishRepositoryError.catalogMissing
        }
        let data = try Data(contentsOf: url)
        let dishes = try JSONDecoder().decode([Dish].self, from: data)
        loaded = dishes
        return dishes
    }
}

public enum DishRepositoryError: Error, Sendable {
    case catalogMissing
}

// MARK: - Preview data

extension Dish {
    /// Минимальный набор для SwiftUI Preview / TestStore. Реальный каталог идёт из `dishes.json`.
    public static let previewCatalog: [Dish] = [
        Dish(
            id: UUID(uuidString: "11111111-0000-0000-0000-000000000001")!,
            name: "Овсянка с ягодами",
            cuisine: .home,
            emoji: "🥣",
            cookTimeMinutes: 10,
            calories: 320,
            proteinGrams: 12,
            rarity: .common,
            difficulty: .one,
            ingredients: [],
            steps: []
        ),
        Dish(
            id: UUID(uuidString: "11111111-0000-0000-0000-000000000003")!,
            name: "Рамен с курицей",
            cuisine: .asian,
            emoji: "🍜",
            cookTimeMinutes: 35,
            calories: 540,
            proteinGrams: 32,
            rarity: .rare,
            difficulty: .two,
            ingredients: [],
            steps: []
        ),
        Dish(
            id: UUID(uuidString: "11111111-0000-0000-0000-000000000008")!,
            name: "Боул с лососем",
            cuisine: .asian,
            emoji: "🍣",
            cookTimeMinutes: 25,
            calories: 560,
            proteinGrams: 36,
            rarity: .legendary,
            difficulty: .three,
            cardNumber: 3,
            ingredients: [],
            steps: []
        )
    ]
}
