import Foundation

public struct PackGenerator: Sendable {
    public var generate: @Sendable (_ count: Int, _ from: [Dish]) -> [Dish]

    public init(generate: @escaping @Sendable (Int, [Dish]) -> [Dish]) {
        self.generate = generate
    }
}

extension PackGenerator {
    /// Веса редкости: Common 60% / Rare 30% / Legendary 10%.
    /// Если в каталоге нет блюд нужной редкости — слот пропускается без падения.
    public static let live = PackGenerator { count, dishes in
        guard !dishes.isEmpty, count > 0 else { return [] }
        var generator = SystemRandomNumberGenerator()
        return Self.makePack(count: count, from: dishes, using: &generator)
    }

    /// Детерминированный генератор для тестов: одинаковый seed → одинаковый pack.
    public static func seeded(_ seed: UInt64) -> PackGenerator {
        PackGenerator { count, dishes in
            guard !dishes.isEmpty, count > 0 else { return [] }
            var generator = SplitMix64(seed: seed)
            return Self.makePack(count: count, from: dishes, using: &generator)
        }
    }

    public static let unimplemented = PackGenerator { _, _ in
        fatalError("PackGenerator.generate not implemented")
    }

    // MARK: - Core

    /// Возвращает `min(count, dishes.count)` уникальных блюд.
    /// Сначала пробуем pool нужной редкости; если исчерпан — берём любое
    /// ещё не выбранное блюдо. Так распределение 60/30/10 сохраняется, пока
    /// в каталоге хватает разнообразия, но пак никогда не содержит дубликатов.
    private static func makePack<G: RandomNumberGenerator>(
        count: Int,
        from dishes: [Dish],
        using generator: inout G
    ) -> [Dish] {
        let limit = min(count, dishes.count)
        var pack: [Dish] = []
        var used: Set<Dish.ID> = []
        pack.reserveCapacity(limit)

        for _ in 0..<limit {
            let rarity = rollRarity(using: &generator)
            let pool = dishes.filter { $0.rarity == rarity && !used.contains($0.id) }
            let chosen = pool.randomElement(using: &generator)
                ?? dishes.filter { !used.contains($0.id) }.randomElement(using: &generator)
            if let chosen {
                pack.append(chosen)
                used.insert(chosen.id)
            }
        }
        return pack
    }

    private static func rollRarity<G: RandomNumberGenerator>(using generator: inout G) -> Rarity {
        let r = Double.random(in: 0..<1, using: &generator)
        var cumulative = 0.0
        for rarity in [Rarity.common, .rare, .legendary] {
            cumulative += rarity.weight
            if r < cumulative { return rarity }
        }
        return .common
    }
}

// MARK: - Deterministic RNG

private struct SplitMix64: RandomNumberGenerator {
    var state: UInt64
    init(seed: UInt64) { self.state = seed }

    mutating func next() -> UInt64 {
        state &+= 0x9E37_79B9_7F4A_7C15
        var z = state
        z = (z ^ (z >> 30)) &* 0xBF58_476D_1CE4_E5B9
        z = (z ^ (z >> 27)) &* 0x94D0_49BB_1331_11EB
        return z ^ (z >> 31)
    }
}
