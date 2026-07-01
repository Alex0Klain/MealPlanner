import Foundation
import SwiftData

public struct MealPlanRepository: Sendable {
    public var planForDate: @Sendable (Date) async -> DayPlanSnapshot?
    public var save:        @Sendable (DayPlanSnapshot) async throws -> Void
    public var weekPlans:   @Sendable (Date) async -> [DayPlanSnapshot]
    public var addMeal:     @Sendable (UUID, MealSlot, Date) async throws -> Void
    public var removeMeal:  @Sendable (UUID, Date) async throws -> Void

    public init(
        planForDate: @escaping @Sendable (Date) async -> DayPlanSnapshot?,
        save: @escaping @Sendable (DayPlanSnapshot) async throws -> Void,
        weekPlans: @escaping @Sendable (Date) async -> [DayPlanSnapshot],
        addMeal: @escaping @Sendable (UUID, MealSlot, Date) async throws -> Void,
        removeMeal: @escaping @Sendable (UUID, Date) async throws -> Void
    ) {
        self.planForDate = planForDate
        self.save = save
        self.weekPlans = weekPlans
        self.addMeal = addMeal
        self.removeMeal = removeMeal
    }
}

/// Sendable-снимок DayPlan для пересечения границ акторов.
/// SwiftData `@Model` не Sendable, поэтому все методы репозитория обмениваются снимками.
public struct DayPlanSnapshot: Codable, Sendable, Hashable {
    public let date: Date
    public var meals: [PlannedMeal]

    public init(date: Date, meals: [PlannedMeal] = []) {
        self.date = Calendar.current.startOfDay(for: date)
        self.meals = meals
    }
}

extension MealPlanRepository {
    /// Боевая реализация поверх SwiftData. ModelContainer передаётся из App.
    public static func live(container: ModelContainer) -> MealPlanRepository {
        let store = MealPlanStore(modelContainer: container)
        return MealPlanRepository(
            planForDate: { date in await store.plan(for: date) },
            save:        { snapshot in try await store.save(snapshot) },
            weekPlans:   { date in await store.weekPlans(from: date) },
            addMeal:     { dishID, slot, date in
                try await store.addMeal(dishID: dishID, slot: slot, date: date)
            },
            removeMeal:  { dishID, date in
                try await store.removeMeal(dishID: dishID, date: date)
            }
        )
    }

    /// In-memory мок для превью и тестов.
    public static let preview: MealPlanRepository = {
        let storage = InMemoryPlanStorage()
        return MealPlanRepository(
            planForDate: { date in await storage.plan(for: date) },
            save:        { snapshot in await storage.save(snapshot) },
            weekPlans:   { date in await storage.weekPlans(from: date) },
            addMeal:     { dishID, slot, date in
                await storage.addMeal(dishID: dishID, slot: slot, date: date)
            },
            removeMeal:  { dishID, date in
                await storage.removeMeal(dishID: dishID, date: date)
            }
        )
    }()

    public static let unimplemented = MealPlanRepository(
        planForDate: { _ in fatalError("MealPlanRepository.planForDate not implemented") },
        save:        { _ in fatalError("MealPlanRepository.save not implemented") },
        weekPlans:   { _ in fatalError("MealPlanRepository.weekPlans not implemented") },
        addMeal:     { _, _, _ in fatalError("MealPlanRepository.addMeal not implemented") },
        removeMeal:  { _, _ in fatalError("MealPlanRepository.removeMeal not implemented") }
    )
}

// MARK: - SwiftData store actor

@ModelActor
private actor MealPlanStore {
    func plan(for date: Date) -> DayPlanSnapshot? {
        let start = Calendar.current.startOfDay(for: date)
        let predicate = #Predicate<DayPlan> { $0.date == start }
        let descriptor = FetchDescriptor<DayPlan>(predicate: predicate)
        let plans = (try? modelContext.fetch(descriptor)) ?? []
        return plans.first.map { DayPlanSnapshot(date: $0.date, meals: $0.mealSlots) }
    }

    func save(_ snapshot: DayPlanSnapshot) throws {
        let plan = fetchOrCreate(date: snapshot.date)
        plan.mealSlots = snapshot.meals
        try modelContext.save()
    }

    func weekPlans(from date: Date) -> [DayPlanSnapshot] {
        let calendar = Calendar.current
        let start = calendar.startOfDay(for: date)
        return (0..<7).compactMap { offset in
            guard let day = calendar.date(byAdding: .day, value: offset, to: start) else { return nil }
            return plan(for: day) ?? DayPlanSnapshot(date: day)
        }
    }

    func addMeal(dishID: UUID, slot: MealSlot, date: Date) throws {
        let plan = fetchOrCreate(date: date)
        plan.mealSlots.append(PlannedMeal(dishID: dishID, slot: slot))
        try modelContext.save()
    }

    func removeMeal(dishID: UUID, date: Date) throws {
        guard let plan = fetchExisting(date: date) else { return }
        plan.mealSlots.removeAll { $0.dishID == dishID }
        try modelContext.save()
    }

    // MARK: helpers

    private func fetchExisting(date: Date) -> DayPlan? {
        let start = Calendar.current.startOfDay(for: date)
        let predicate = #Predicate<DayPlan> { $0.date == start }
        return try? modelContext.fetch(FetchDescriptor<DayPlan>(predicate: predicate)).first
    }

    private func fetchOrCreate(date: Date) -> DayPlan {
        if let existing = fetchExisting(date: date) { return existing }
        let plan = DayPlan(date: date)
        modelContext.insert(plan)
        return plan
    }
}

// MARK: - In-memory mock

private actor InMemoryPlanStorage {
    private var plans: [Date: DayPlanSnapshot] = [:]

    func plan(for date: Date) -> DayPlanSnapshot? {
        plans[Calendar.current.startOfDay(for: date)]
    }

    func save(_ snapshot: DayPlanSnapshot) {
        plans[snapshot.date] = snapshot
    }

    func weekPlans(from date: Date) -> [DayPlanSnapshot] {
        let calendar = Calendar.current
        let start = calendar.startOfDay(for: date)
        return (0..<7).compactMap { offset in
            guard let day = calendar.date(byAdding: .day, value: offset, to: start) else { return nil }
            return plans[day] ?? DayPlanSnapshot(date: day)
        }
    }

    func addMeal(dishID: UUID, slot: MealSlot, date: Date) {
        let day = Calendar.current.startOfDay(for: date)
        var snapshot = plans[day] ?? DayPlanSnapshot(date: day)
        snapshot.meals.append(PlannedMeal(dishID: dishID, slot: slot))
        plans[day] = snapshot
    }

    func removeMeal(dishID: UUID, date: Date) {
        let day = Calendar.current.startOfDay(for: date)
        guard var snapshot = plans[day] else { return }
        snapshot.meals.removeAll { $0.dishID == dishID }
        plans[day] = snapshot
    }
}
