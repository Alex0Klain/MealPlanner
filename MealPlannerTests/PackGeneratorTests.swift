import Testing
import Foundation
import MealPlanner

@Suite("PackGenerator")
struct PackGeneratorTests {

    /// Каталог из 60/30/10 блюд → веса должны воспроизводиться в пакете 9×1000.
    @Test func distributionMatches60_30_10() {
        let dishes = Self.makeCatalog(common: 60, rare: 30, legendary: 10)
        let generator = PackGenerator.live

        var counts: [Rarity: Int] = [.common: 0, .rare: 0, .legendary: 0]
        let totalPacks = 1000
        for _ in 0..<totalPacks {
            let pack = generator.generate(9, dishes)
            for dish in pack { counts[dish.rarity, default: 0] += 1 }
        }

        let total = Double(totalPacks * 9)
        #expect(abs(Double(counts[.common]!)    / total - 0.60) < 0.05)
        #expect(abs(Double(counts[.rare]!)      / total - 0.30) < 0.05)
        #expect(abs(Double(counts[.legendary]!) / total - 0.10) < 0.05)
    }

    @Test func generatesExactCountWhenCatalogIsBigEnough() {
        let generator = PackGenerator.live
        let pack = generator.generate(9, Self.makeCatalog(common: 10, rare: 10, legendary: 10))
        #expect(pack.count == 9)
    }

    @Test func emptyCatalogReturnsEmptyPack() {
        let generator = PackGenerator.live
        #expect(generator.generate(9, []).isEmpty)
    }

    @Test func seededGeneratorIsDeterministic() {
        let dishes = Self.makeCatalog(common: 12, rare: 6, legendary: 3)
        let a = PackGenerator.seeded(42).generate(9, dishes).map(\.id)
        let b = PackGenerator.seeded(42).generate(9, dishes).map(\.id)
        #expect(a == b)
    }

    // MARK: - Helpers

    private static func makeCatalog(common: Int, rare: Int, legendary: Int) -> [Dish] {
        let commons   = (0..<common).map    { makeDish(index: $0, rarity: .common) }
        let rares     = (0..<rare).map      { makeDish(index: $0, rarity: .rare) }
        let legendaries = (0..<legendary).map { makeDish(index: $0, rarity: .legendary) }
        return commons + rares + legendaries
    }

    private static func makeDish(index: Int, rarity: Rarity) -> Dish {
        Dish(
            id: UUID(),
            name: "\(rarity.rawValue)-\(index)",
            cuisine: .home,
            emoji: "🍽",
            cookTimeMinutes: 10,
            calories: 100,
            proteinGrams: 10,
            rarity: rarity,
            difficulty: .one,
            ingredients: [],
            steps: []
        )
    }
}
