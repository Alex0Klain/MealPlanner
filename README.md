<div align="center">

# 🃏 MealPlanner

**Планировщик меню, в котором блюда выпадают из паков карточек**

Открываешь пак, получаешь карточки с блюдами разной редкости и раскладываешь их по приёмам пищи на день или неделю.

<p>
  <a href="https://github.com/Alex0Klain/MealPlanner/actions/workflows/ios.yml"><img src="https://github.com/Alex0Klain/MealPlanner/actions/workflows/ios.yml/badge.svg" alt="iOS CI" /></a>
  <img src="https://img.shields.io/badge/iOS-18%2B-000000?style=flat-square&logo=apple&logoColor=white" />
  <img src="https://img.shields.io/badge/Swift-6-F05138?style=flat-square&logo=swift&logoColor=white" />
  <img src="https://img.shields.io/badge/SwiftUI-0D96F6?style=flat-square&logo=swift&logoColor=white" />
  <img src="https://img.shields.io/badge/TCA-1.x-6E40C9?style=flat-square" />
  <img src="https://img.shields.io/badge/SwiftData-1C1C1E?style=flat-square&logo=apple&logoColor=white" />
  <a href="LICENSE"><img src="https://img.shields.io/badge/License-CC_BY--NC--ND_4.0-lightgrey?style=flat-square" /></a>
</p>

<!-- Добавь скриншоты в docs/screenshots/ и раскомментируй:
<p>
  <img src="docs/screenshots/home.png" width="230" />
  <img src="docs/screenshots/pack.png" width="230" />
  <img src="docs/screenshots/week.png" width="230" />
</p>
-->

</div>

---

## ✨ Возможности

- 🎴 **Открытие паков.** Анимация в четыре фазы: Closed → Burst → Reveal → Distribute
- 💎 **Три редкости карточек**

  | Редкость | Шанс | Оформление |
  |---|---|---|
  | Common | 60% | серая рамка |
  | Rare | 30% | синее свечение и призматическая плёнка |
  | Legendary | 10% | золотое свечение, фольга и номер карточки `003/100` |

- 🍽 **Слоты дня:** завтрак, обед, ужин, перекус. Любую карточку можно положить в любой слот
- 🌍 **Шесть кухонь** со своим цветом: домашняя, азиатская, итальянская, мексиканская, средиземноморская, французская
- 📅 **План на неделю** с переходом в каждый день
- 👨‍🍳 **Рецепты по шагам** с ингредиентами, КБЖУ и таймером для шагов
- 🌑 **Тёмный «игровой» дизайн**, макеты лежат в [`MealPlanner Design.html`](MealPlanner%20Design.html)

## 🧱 Стек

| Слой | Технология |
|---|---|
| UI | SwiftUI |
| Состояние | [The Composable Architecture](https://github.com/pointfreeco/swift-composable-architecture) 1.x |
| Хранение | SwiftData |
| Конкурентность | Swift 6 (strict concurrency), async/await |
| Тесты | Swift Testing, TCA `TestStore` |
| CI | GitHub Actions |

## 🗺 Архитектура

```
AppFeature
└── TabFeature
    ├── HomeFeature              ← план на сегодня
    │   ├── PackOpeningFeature   ← открытие пака
    │   │   └── DistributeFeature
    │   ├── AddMealSlotFeature
    │   └── RecipeDetailFeature
    └── WeekPlannerFeature       ← план на 7 дней
        ├── DayDetailFeature
        └── RecipeDetailFeature
```

Каталог блюд лежит статичным `dishes.json` в бандле. `DayPlan` (SwiftData) хранит только ID блюд и слоты. Репозитории и генератор паков подключаются через `DependencyKey`, поэтому в тестах их легко подменить.

Подробнее: [ARCHITECTURE.md](ARCHITECTURE.md).

<details>
<summary>📁 Структура проекта</summary>

```
MealPlanner/
├── App/              # AppFeature, корневая View
├── Data/
│   ├── Catalog/      # dishes.json
│   ├── Models/       # Dish, DayPlan, Cuisine, Rarity, ...
│   └── Repositories/ # DishRepository, MealPlanRepository, PackGenerator
├── Dependencies/     # TCA DependencyKey
├── Features/         # Home, PackOpening, WeekPlanner, DayDetail, RecipeDetail, AddMealSlot
└── UI/
    ├── Components/   # DishCard, RarityBadge, CuisineChip, CircularStepTimer, ...
    └── Modifiers/
```

</details>

## 🚀 Запуск

**Нужно:** Xcode 26+, iOS 18+ (симулятор или устройство).

```bash
git clone https://github.com/Alex0Klain/MealPlanner.git
cd MealPlanner
open MealPlanner.xcodeproj
```

Зависимости подтянутся через Swift Package Manager. Выбери схему **MealPlanner** и нажми `⌘R`.

Тесты запускаются по `⌘U`.

## 🛣 Roadmap

- [x] Открытие паков и раскладка карточек
- [x] План на день и неделю
- [x] Рецепты с пошаговым таймером
- [ ] Каталог блюд с поиском и фильтрами
- [ ] Расширение каталога
- [ ] StoreKit 2

## 📄 Лицензия

[CC BY-NC-ND 4.0](LICENSE) © 2026 Aleksei Guz
