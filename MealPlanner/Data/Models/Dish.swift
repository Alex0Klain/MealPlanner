import Foundation

public struct Dish: Identifiable, Codable, Sendable, Hashable {
    public let id: UUID
    public let name: String
    public let cuisine: Cuisine
    public let emoji: String
    public let cookTimeMinutes: Int
    public let calories: Int
    public let proteinGrams: Int
    public let rarity: Rarity
    public let difficulty: Difficulty
    public let cardNumber: Int?
    public let ingredients: [Ingredient]
    public let steps: [RecipeStep]

    public init(
        id: UUID = UUID(),
        name: String,
        cuisine: Cuisine,
        emoji: String,
        cookTimeMinutes: Int,
        calories: Int,
        proteinGrams: Int,
        rarity: Rarity,
        difficulty: Difficulty,
        cardNumber: Int? = nil,
        ingredients: [Ingredient],
        steps: [RecipeStep]
    ) {
        self.id = id
        self.name = name
        self.cuisine = cuisine
        self.emoji = emoji
        self.cookTimeMinutes = cookTimeMinutes
        self.calories = calories
        self.proteinGrams = proteinGrams
        self.rarity = rarity
        self.difficulty = difficulty
        self.cardNumber = cardNumber
        self.ingredients = ingredients
        self.steps = steps
    }
}

public struct Ingredient: Codable, Sendable, Hashable {
    public let emoji: String
    public let name: String
    public let amount: String

    public init(emoji: String, name: String, amount: String) {
        self.emoji = emoji
        self.name = name
        self.amount = amount
    }
}

public struct RecipeStep: Codable, Sendable, Hashable, Identifiable {
    public let order: Int
    public let title: String
    public let description: String
    public let durationMinutes: Int?

    public var id: Int { order }

    public init(order: Int, title: String, description: String, durationMinutes: Int? = nil) {
        self.order = order
        self.title = title
        self.description = description
        self.durationMinutes = durationMinutes
    }
}
