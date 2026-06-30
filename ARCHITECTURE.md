# MealPlanner — Architecture

**Stack:** iOS 18+, Swift 6, SwiftUI, TCA, SwiftData, Swift Testing  
**Design System:** v1.0 · Dark Gaming · 30 Jun 2026

---

## Tech Stack

| Layer | Technology |
|---|---|
| UI | SwiftUI |
| State management | TCA (The Composable Architecture) 1.x |
| Persistence | SwiftData |
| Concurrency | Swift 6 (strict) + async/await |
| Testing | Swift Testing + TCA TestStore |
| Monetization (post-MVP) | StoreKit 2 |

---

## Feature Tree (TCA Reducers)

```
AppFeature
└── TabFeature
    ├── HomeFeature                    ← сегодняшний план
    │   ├── PackOpeningFeature         ← 4 фазы: Closed → Burst → Reveal → Distribute
    │   │   └── DistributeFeature      ← шаг 2/2: раскладка карточек по слотам
    │   ├── AddMealSlotFeature         ← bottom-sheet добавления приёма пищи
    │   └── RecipeDetailFeature        ← рецепт с шагами (sheet)
    ├── WeekPlannerFeature             ← план на 7 дней
    │   ├── DayDetailFeature           ← день из недели (push, тот же layout что Home)
    │   └── RecipeDetailFeature        ← тот же reducer, другой контекст
    └── CatalogFeature (post-MVP)      ← все блюда, поиск, фильтрация
```

---

## Data Models

### ⚠️ Ключевое решение дизайна

Дизайн разделяет два понятия, которые часто путают:

- **`MealSlot`** — _время дня_ в плане (Завтрак / Обед / Ужин / Перекус). Принадлежит `DayPlan`.
- **`Cuisine`** — _стиль кухни_ блюда на карточке (Домашняя, Азиатская, ...). Принадлежит `Dish`.

Одна карточка может попасть в любой слот — это расширяет геймплей паков и снимает ограничения ("овсянка — только завтрак").

---

### Dish (статические данные, бандл)

```swift
struct Dish: Identifiable, Codable, Sendable {
    let id: UUID
    let name: String
    let cuisine: Cuisine         // стиль кухни на карточке
    let emoji: String
    let cookTimeMinutes: Int
    let calories: Int            // ккал — на карточке
    let proteinGrams: Int        // г белка — на карточке
    let rarity: Rarity
    let difficulty: Difficulty
    let cardNumber: Int?         // только для Legendary: 003/100
    let ingredients: [Ingredient]
    let steps: [RecipeStep]
}

enum Cuisine: String, Codable, Sendable, CaseIterable {
    case home           // Домашняя · #C9A37D
    case asian          // Азиатская · #E07458
    case italian        // Итальянская · #5CC58A
    case mexican        // Мексиканская · #F0B05A
    case mediterranean  // Средиземноморская · #5BC8E6
    case french         // Французская · #C285DD
}

enum MealSlot: String, Codable, Sendable, CaseIterable {
    case breakfast  // Завтрак
    case lunch      // Обед
    case dinner     // Ужин
    case snack      // Перекус
}

enum Rarity: String, Codable, Sendable {
    case common     // 60% — серый бордер
    case rare       // 30% — синий glow + prismatic film
    case legendary  // 10% — золотой glow + foil-shine
}

enum Difficulty: String, Codable, Sendable {
    case one   // ★☆☆
    case two   // ★★☆
    case three // ★★★
}

struct Ingredient: Codable, Sendable {
    let emoji: String
    let name: String
    let amount: String  // "200 г", "2 шт", "по вкусу"
}

struct RecipeStep: Codable, Sendable {
    let order: Int
    let title: String           // короткое название шага
    let description: String
    let durationMinutes: Int?   // опционально — для таймера
}
```

### SwiftData Models (персистентность)

```swift
@Model
final class DayPlan {
    @Attribute(.unique) var date: Date
    var mealSlots: [PlannedMeal]   // упорядоченный список блюд дня
    var createdAt: Date

    init(date: Date) {
        self.date = Calendar.current.startOfDay(for: date)
        self.mealSlots = []
        self.createdAt = .now
    }
}

// Не @Model — хранится как JSON внутри DayPlan
struct PlannedMeal: Codable {
    let dishID: UUID
    let slot: MealSlot
    let addedAt: Date
}
```

> Каталог блюд — статичный `dishes.json` в бандле. `DayPlan` хранит только ID блюд + слот.

---

## Dependency Layer (TCA DependencyKey)

```swift
struct DishRepository: Sendable {
    var all: @Sendable () async throws -> [Dish]
    var byID: @Sendable (UUID) async -> Dish?
    var byCuisine: @Sendable (Cuisine) async -> [Dish]
}

// Генерация пака с весами редкости: Common 60% / Rare 30% / Legendary 10%
struct PackGenerator: Sendable {
    var generate: @Sendable (_ count: Int, _ from: [Dish]) -> [Dish]
}

struct MealPlanRepository: Sendable {
    var planForDate: @Sendable (Date) async -> DayPlan?
    var save: @Sendable (DayPlan) async throws -> Void
    var weekPlans: @Sendable (Date) async -> [DayPlan]   // 7 дней от даты
    var addMeal: @Sendable (UUID, MealSlot, Date) async throws -> Void
    var removeMeal: @Sendable (UUID, Date) async throws -> Void
}
```

---

## Pack Opening Flow (4 фазы)

```
PackOpeningFeature.Phase:
  .closed     → анимация покачивания, idle glow на кнопке
  .burst      → разрыв пака ~800ms, 9 карт вылетают
  .reveal     → 3×3 сетка, выбор карточек (до N = 7 − уже в плане)
  .distribute → шаг 2/2, раскладка выбранных по MealSlot

PackOpeningFeature.State:
  phase: Phase
  cards: IdentifiedArrayOf<PackCard>
  selectedIDs: Set<Dish.ID>
  maxSelectable: Int               // 7 − count(сегодня в плане)
  
PackCard:
  dish: Dish
  isRevealed: Bool
  isSelected: Bool
  isInPlan: Bool                   // уже в плане → 45% opacity, badge "В ПЛАНЕ"
  revealIndex: Int                 // порядок для stagger-анимации
```

**Размер пака:** 9 карточек  
**Размер карточки в сетке:** 109 × 156pt (соотношение 7:10), gap 12pt, боковые отступы 16pt

---

## Navigation

```
TabView
├── Tab 1 "Сегодня" 🃏:
│   NavigationStack
│   └── HomeView
│       ├── PackOpeningView (fullScreenCover) → 4 фазы внутри одного экрана
│       ├── AddMealSlotView (sheet, .presentationDetents([.medium]))
│       └── RecipeDetailView (sheet)
│
└── Tab 2 "Неделя" 📅:
    NavigationStack
    └── WeekPlannerView
        └── DayDetailView (push, matchedGeometryEffect от мини-карточки дня)
            └── RecipeDetailView (sheet)
```

Навигация управляется исключительно через TCA State — никаких `@State var isPresented` во View.

---

## Animation Specification

Все анимации реализуются нативными SwiftUI API (iOS 17+). Никаких Lottie.

### Pack Reveal (~2.8s total)

| Тайминг | Событие | SwiftUI API |
|---|---|---|
| 0–300ms | Pack shake: scale 1→1.08, jitter ±4° | `withAnimation(.bouncy)` |
| 300–600ms | Pack burst: две половинки + blur(8) + opacity→0 | `withAnimation(.easeOut)` |
| 500–750ms | Grid arrival: 9 рубашек fade-in, scale 0.85→1 | `withAnimation(.snappy)` + stagger |
| 750–2100ms | Flip wave: 9 карт по очереди, Y 180°→0° | `PhaseAnimator` + `.smooth(0.45)` + stagger 150ms |
| на Rare flip | Holo sweep: диагональный блик 400ms | `.linear` + haptic.light |
| на Legendary | Hold + halo: пауза 600ms, scale 1.15, золотой radial burst | `KeyframeAnimator` + haptic.success |
| 2100–2800ms | Idle: counter slide-up 20pt, CTA fade-in | `.smooth` |

```swift
// Card flip — PhaseAnimator
PhaseAnimator([CardPhase.back, .midway, .face], trigger: revealStep) { card, phase in
    card
        .rotation3DEffect(.degrees(phase.angle), axis: (x: 0, y: 1, z: 0))
        .scaleEffect(phase == .midway ? 1.05 : 1.0)
} animation: { phase in
    .smooth(duration: 0.45).delay(Double(card.revealIndex) * 0.15)
}

// Legendary burst — KeyframeAnimator
.keyframeAnimator(initialValue: BurstFrame(), trigger: rarity == .legendary) { content, frame in
    content.scaleEffect(frame.scale).opacity(frame.haloOpacity)
} keyframes: { _ in
    KeyframeTrack(\.scale) {
        CubicKeyframe(1.15, duration: 0.25)
        SpringKeyframe(1.0, duration: 0.35)
    }
    KeyframeTrack(\.haloOpacity) {
        LinearKeyframe(1.0, duration: 0.2)
        LinearKeyframe(0.0, duration: 0.6)
    }
}
```

### Переходы между экранами

| Переход | Механика |
|---|---|
| Home → PackOpening | Zoom cover: кнопка пака → full-screen, `matchedGeometryEffect(id: "pack")`, 350ms `.smooth` |
| Card → RecipeDetail | Hero card: `matchedGeometryEffect(id: dish.id)`, остальные карты fade-out 200ms |
| Reveal → Distribute | Slide-up sheet: выбранные карты "летят" вверх в список |
| WeekDay → DayDetail | Push + `matchedGeometryEffect` от мини-карточки дня к hero-блоку |

### Микроанимации

| Событие | Поведение |
|---|---|
| Тап на карточку (select) | Подъём −6pt Y, фиолетовый stroke, чек-маркер · `.spring(response: 0.3, dampingFraction: 0.6)` + haptic.selection |
| Добавление в план | Карточки "летят" в слот по кривой Безье через `matchedGeometryEffect`, bounce при приёме · haptic.success |
| Pack CTA idle | pulseCta glow 2.4s loop + gift emoji покачивается ±1.2° |
| День заполнен | TimelineView + Canvas конфетти 30 частиц 1.2s, бордер → plasma gradient |
| Таймер шага рецепта | `CircularProgressView` + `.animation(.linear, value:)` |

---

## Design Tokens (Swift)

Копируются в файлы темы напрямую:

```swift
// Color+Theme.swift
extension Color {
    // Surfaces
    static let inkBase    = Color("InkBase")    // #0A0B14
    static let inkCanvas  = Color("InkCanvas")  // #11131F
    static let inkSurface = Color("InkSurface") // #1A1C2A
    static let inkRaised  = Color("InkRaised")  // #262838
    static let inkMuted   = Color("InkMuted")   // #7C7F90
    static let inkText    = Color("InkText")    // #F2F2F5

    // Accent
    static let plasma     = Color("Plasma")     // #A77BFF
    static let plasmaDeep = Color("PlasmaDeep") // #6B3FE0
    static let aqua       = Color("Aqua")       // #5BC8E6

    // Rarity
    static let rarityCommon    = Color("RarityCommon")    // #7B8090
    static let rarityRare      = Color("RarityRare")      // #5DA2FF
    static let rarityLegendary = Color("RarityLegendary") // #F4D27A

    // Cuisine (на карточке)
    static let cuisineHome          = Color("#C9A37D")
    static let cuisineAsian         = Color("#E07458")
    static let cuisineItalian       = Color("#5CC58A")
    static let cuisineMexican       = Color("#F0B05A")
    static let cuisineMediterranean = Color("#5BC8E6")
    static let cuisineFrench        = Color("#C285DD")

    // Meal slots (в плане)
    static let slotBreakfast = Color("#F0B05A")
    static let slotLunch     = Color("#5CC58A")
    static let slotDinner    = Color("#E07458")
    static let slotSnack     = Color("#5BC8E6")
}

extension LinearGradient {
    static let plasmaCta = LinearGradient(
        colors: [.plasma, .plasmaDeep],
        startPoint: .topLeading, endPoint: .bottomTrailing
    )
    static let legendaryFoil = LinearGradient(
        colors: [Color("#F4D27A"), Color("#D49344"), Color("#B26A2E")],
        startPoint: .topLeading, endPoint: .bottomTrailing
    )
}

// Font+Theme.swift
extension Font {
    static let display       = Font.system(size: 34, weight: .heavy,    design: .rounded)
    static let appTitle      = Font.system(size: 28, weight: .bold,     design: .default)
    static let cardName      = Font.system(size: 17, weight: .semibold, design: .rounded)
    static let cardNameRare  = Font.system(size: 17, weight: .bold,     design: .rounded)
    static let cardNameLegen = Font.system(size: 17, weight: .heavy,    design: .rounded)
    static let body          = Font.system(size: 15, weight: .regular,  design: .default)
    static let caption       = Font.system(size: 12, weight: .medium,   design: .default)
    static let numeric       = Font.system(size: 22, weight: .bold,     design: .monospaced)
}

// Spacing.swift
enum Spacing {
    static let xs:  CGFloat = 4
    static let sm:  CGFloat = 8
    static let md:  CGFloat = 12
    static let lg:  CGFloat = 16
    static let xl:  CGFloat = 24
    static let xxl: CGFloat = 32
}

// Radius.swift
enum Radius {
    static let chip:      CGFloat = 999
    static let card:      CGFloat = 22
    static let cardInner: CGFloat = 16
    static let slot:      CGFloat = 14
    static let button:    CGFloat = 14
    static let screen:    CGFloat = 36
}

// Motion.swift
enum Motion {
    static let flip    = Animation.smooth(duration: 0.45)
    static let select  = Animation.spring(response: 0.3, dampingFraction: 0.6)
    static let hero    = Animation.smooth(duration: 0.5, extraBounce: 0.1)
    static let stagger: TimeInterval = 0.15
}
```

> **Доступность:** Plasma #A77BFF на InkCanvas — контраст 7.1:1. Все тексты ≥4.5:1.  
> Dynamic Type до `.accessibility3`. Названия блюд — `.minimumScaleFactor(0.8)`.

---

## Project File Structure

```
MealPlanner/
├── App/
│   ├── MealPlannerApp.swift          ← @main, ModelContainer setup
│   └── AppFeature.swift              ← root reducer + tab state
│
├── Features/
│   ├── Home/
│   │   ├── HomeFeature.swift
│   │   └── HomeView.swift
│   ├── PackOpening/
│   │   ├── PackOpeningFeature.swift  ← 4 фазы: closed/burst/reveal/distribute
│   │   ├── PackOpeningView.swift
│   │   ├── PackClosedView.swift      ← анимация покачивания пака
│   │   ├── PackBurstView.swift       ← разрыв ~800ms
│   │   ├── PackRevealView.swift      ← сетка 3×3, выбор карточек
│   │   ├── DistributeView.swift      ← шаг 2/2: раскладка по слотам
│   │   └── CardView.swift            ← flip + rarity glow + состояния
│   ├── AddMealSlot/
│   │   ├── AddMealSlotFeature.swift
│   │   └── AddMealSlotView.swift     ← bottom-sheet .medium
│   ├── DayDetail/
│   │   ├── DayDetailFeature.swift
│   │   └── DayDetailView.swift       ← тот же layout что Home, для дня из недели
│   ├── WeekPlanner/
│   │   ├── WeekPlannerFeature.swift
│   │   └── WeekPlannerView.swift
│   └── RecipeDetail/
│       ├── RecipeDetailFeature.swift ← ингредиенты + пошаговый режим с таймером
│       └── RecipeDetailView.swift
│
├── Data/
│   ├── Models/
│   │   ├── Dish.swift                ← Dish, Ingredient, RecipeStep
│   │   ├── Cuisine.swift             ← enum + цвет кухни
│   │   ├── MealSlot.swift            ← enum + цвет слота
│   │   ├── Rarity.swift              ← enum + визуальная спецификация
│   │   ├── Difficulty.swift
│   │   ├── DayPlan.swift             ← @Model SwiftData
│   │   └── PlannedMeal.swift
│   ├── Repositories/
│   │   ├── DishRepository.swift
│   │   ├── MealPlanRepository.swift
│   │   └── PackGenerator.swift       ← weighted random, 60/30/10
│   └── Catalog/
│       └── dishes.json
│
├── Dependencies/
│   ├── DishRepositoryDependency.swift
│   ├── MealPlanRepositoryDependency.swift
│   └── PackGeneratorDependency.swift
│
├── UI/
│   ├── Theme/
│   │   ├── Color+Theme.swift         ← все токены из дизайн-системы
│   │   ├── Font+Theme.swift
│   │   ├── Spacing.swift
│   │   ├── Radius.swift
│   │   └── Motion.swift
│   ├── Components/
│   │   ├── DishCard.swift            ← Window-вариант (full-bleed фото)
│   │   ├── CardBack.swift            ← рубашка пака (стопка 3 карт)
│   │   ├── RarityBadge.swift         ← chip COMMON/RARE/★LEGENDARY
│   │   ├── CuisineChip.swift         ← цветной chip кухни
│   │   ├── MealSlotRow.swift         ← строка плана (слот + блюдо)
│   │   ├── EmptySlotView.swift       ← dashed-placeholder слота
│   │   └── CircularStepTimer.swift   ← таймер шага рецепта
│   └── Modifiers/
│       ├── RarityGlowModifier.swift  ← rarePulse / legendaryGlow
│       └── PressScaleModifier.swift  ← scale 0.96 при нажатии
│
├── Assets.xcassets/
│   └── Colors/                       ← InkBase, InkCanvas, ... (Dark/Light)
│
└── Tests/
    ├── HomeFeatureTests.swift
    ├── PackOpeningFeatureTests.swift
    ├── DistributeFeatureTests.swift
    ├── MealPlanRepositoryTests.swift
    └── PackGeneratorTests.swift       ← статистический тест 60/30/10
```

---

## Card Visual States

| Состояние | Визуал |
|---|---|
| Back (рубашка) | Стопка 3 наклонённых карт, plasma-градиент, dashed frame |
| Default | full-bleed фото, glass-chips, бордер по rarity |
| Selected | translateY −6pt, plasma stroke 2pt, ✓ badge, фиолетовый outer glow |
| In Plan | 45% opacity, saturate 0.5, badge "В ПЛАНЕ" |
| Press | scale 0.96, overlay 22% затемнения |

---

## Testing Strategy

```swift
@Test func packGeneratorDistribution() async {
    let generator = PackGenerator.live
    let dishes = Dish.preview(count: 100)
    var counts: [Rarity: Int] = [.common: 0, .rare: 0, .legendary: 0]

    for _ in 0..<1000 {
        let pack = generator.generate(9, dishes)
        pack.forEach { counts[$0.rarity, default: 0] += 1 }
    }
    // Статистический тест: отклонение не более 5%
    #expect(abs(Double(counts[.common]!) / 9000 - 0.60) < 0.05)
    #expect(abs(Double(counts[.rare]!)   / 9000 - 0.30) < 0.05)
    #expect(abs(Double(counts[.legendary]!) / 9000 - 0.10) < 0.05)
}

@Test func selectingCardUpdatesState() async {
    let store = TestStore(initialState: PackOpeningFeature.State()) {
        PackOpeningFeature()
    } withDependencies: {
        $0.packGenerator = .mock(dishes: .preview)
        $0.dishRepository = .mock
    }
    await store.send(.cardTapped(dishID)) {
        $0.cards[id: dishID]?.isSelected = true
    }
}
```

---

## Implementation Order

1. **UI/Theme** — Color+Theme, Font+Theme, Spacing, Radius, Motion (токены готовы к использованию)
2. **Data layer** — модели Dish/Cuisine/MealSlot/Rarity, dishes.json (~70 блюд), DishRepository
3. **SwiftData** — DayPlan + PlannedMeal @Model, MealPlanRepository, ModelContainer
4. **CardView** — все состояния (back, default, selected, in-plan, press) для всех 3 редкостей
5. **PackOpeningFeature** — логика 4 фаз, без финальной анимации
6. **HomeFeature + DayDetailFeature** — планирование на сегодня и из недели
7. **RecipeDetailFeature** — ингредиенты + пошаговый режим с таймером
8. **WeekPlannerFeature** — недельный вид
9. **Pack animations** — PhaseAnimator flip, KeyframeAnimator legendary burst, matchedGeometryEffect переходы
10. **Микроанимации** — select lift, add-to-plan flight, confetti, CTA pulse
11. **Polish** — тёмная тема Asset Catalog, иконка (лого вариант A/B/C), onboarding
