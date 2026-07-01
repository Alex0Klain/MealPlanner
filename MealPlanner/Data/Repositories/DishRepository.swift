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
            ingredients: [
                Ingredient(emoji: "🌾", name: "Овсяные хлопья", amount: "60 г"),
                Ingredient(emoji: "🥛", name: "Молоко",         amount: "200 мл"),
                Ingredient(emoji: "🫐", name: "Ягоды",          amount: "горсть"),
                Ingredient(emoji: "🍯", name: "Мёд",            amount: "по вкусу")
            ],
            steps: [
                RecipeStep(order: 1, title: "Залить молоко",
                           description: "Поставить кастрюлю на средний огонь, влить молоко.",
                           durationMinutes: 2),
                RecipeStep(order: 2, title: "Добавить хлопья",
                           description: "Всыпать овсянку, помешивать.",
                           durationMinutes: 5),
                RecipeStep(order: 3, title: "Подать с ягодами",
                           description: "Выключить огонь, добавить ягоды и мёд.",
                           durationMinutes: 2)
            ]
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
            ingredients: [
                Ingredient(emoji: "🍗", name: "Куриное филе", amount: "200 г"),
                Ingredient(emoji: "🍜", name: "Лапша рамен",  amount: "100 г"),
                Ingredient(emoji: "🥚", name: "Яйцо",         amount: "1 шт")
            ],
            steps: [
                RecipeStep(order: 1, title: "Бульон",
                           description: "Отварить курицу с луком и имбирём.",
                           durationMinutes: 20),
                RecipeStep(order: 2, title: "Собрать миску",
                           description: "Лапша, бульон, курица, половинка яйца.",
                           durationMinutes: 3)
            ]
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
            ingredients: [
                Ingredient(emoji: "🍣", name: "Лосось", amount: "180 г"),
                Ingredient(emoji: "🍚", name: "Рис",    amount: "150 г"),
                Ingredient(emoji: "🥑", name: "Авокадо", amount: "1/2 шт")
            ],
            steps: [
                RecipeStep(order: 1, title: "Рис",
                           description: "Отварить рис, заправить рисовым уксусом.",
                           durationMinutes: 15),
                RecipeStep(order: 2, title: "Подача",
                           description: "Выложить рис в чашу, сверху овощи и лосось.",
                           durationMinutes: 5)
            ]
        )
    ]
}
