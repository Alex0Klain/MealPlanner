# MealPlanner — правила проекта

iOS 18+ · Swift 6 (strict concurrency) · SwiftUI · TCA 1.26 · SwiftData · Swift Testing.

- Архитектура, модели, анимации, токены → [`ARCHITECTURE.md`](ARCHITECTURE.md). Он местами устарел:
  при расхождении приоритет у этого файла (CLAUDE.md), затем у кода.
- Дизайн экранов → `MealPlanner Design.html`
- Отвечать и писать комментарии/доки на русском; идентификаторы и термины — в оригинале.
  Коммиты, названия веток и PR — на английском.

## Сборка и тесты

`xcode-select` на машине смотрит в CommandLineTools, поэтому перед любым `xcodebuild`/`simctl`:

```sh
export DEVELOPER_DIR=/Applications/Xcode.app/Contents/Developer

xcodebuild build -scheme MealPlanner -destination 'platform=iOS Simulator,name=iPhone 17 Pro'
xcodebuild test  -scheme MealPlanner -destination 'platform=iOS Simulator,name=iPhone 17 Pro' \
  -skip-testing MealPlannerUITests
```

- Не смешивать артефакты `build-for-testing` и `test` в одном `-derivedDataPath` — линкер ломается; брать чистую папку.
- CI: `.github/workflows/ios.yml` — `build-for-testing` → `test-without-building`.
  Unit-тесты — на PR и на push в `main`; UI-тесты — только на push в `main`.
  Симулятор в CI — последний доступный iPhone (не обязательно iPhone 17 Pro).

## Архитектура

- Фича = `Features/<Name>/<Name>Feature.swift` + `<Name>View.swift`. Reducer — `@Reducer`, state — `@ObservableState`, `Action: Equatable`.
  Дополнительные View фичи (как `PackClosedView`, `PackRevealView` в `PackOpening`) — в той же папке.
- Навигация только через TCA state: `@Presents var destination` + `@Reducer enum Destination`, push — `StackState`. Никаких `@State var isPresented` во View.
- Child → parent общается через `case delegate(Delegate)`; родитель не лезет во внутренние экшены ребёнка.
- Сайд-эффекты только в `.run`. Зависимости — через `@Dependency`, объявляются в `Dependencies/` (`liveValue` / `previewValue` / `testValue`).
- UI — только токены `UI/Theme` (`Color+Theme`, `Font+Theme`, `Spacing`, `Radius`, `Motion`, `Haptics`) и компоненты `UI/Components` / `UI/Modifiers`.
  В новом коде хардкод цветов, шрифтов, отступов, анимаций запрещён; нет нужного токена — добавить его в `UI/Theme`, а не писать литерал.
  Существующий хардкод не трогать без отдельной задачи и не копировать.
- Анимации — нативный SwiftUI (`PhaseAnimator`, `KeyframeAnimator`, `matchedGeometryEffect`), без Lottie.
- Каталог блюд — статичный `Data/Catalog/dishes.json`; SwiftData хранит только ID блюда + слот.

## Тесты

- Swift Testing: `@Suite`, `@Test`, `#expect` / `#require`. XCTest — только для UI-тестов.
- Reducer’ы тестируются через `TestStore` с подменой зависимостей в `withDependencies`.
- Репозиторий в тестах — всегда свежий `MealPlanRepository.inMemory()` на каждый тест.
  `MealPlanRepository.preview` — общий `static let` с состоянием между обращениями, только для SwiftUI Previews.
- Новая логика в reducer’е или репозитории → тест в `MealPlannerTests/`.

## Git — GitHub Flow

- `main` всегда рабочий. Любая работа — в короткой ветке от `main` → PR в `main` → merge после зелёного CI.
- Ветки: `feature/…`, `fix/…`, `chore/…` (kebab-case, на английском).
- Коммиты — строго по **[gitmoji](https://gitmoji.dev)**: `<emoji> <description>` на английском, юникод-эмодзи (не `:code:`), эмодзи по таблице gitmoji. Частые:
  ✨ фича · 🐛 фикс · 🩹 мелкий фикс · 💄 UI/стили · 🎨 структура/формат кода · ♻️ рефакторинг ·
  ✅ тесты · ⬆️ апгрейд зависимостей · ➕/➖ добавить/удалить зависимость · 📝 документация ·
  🔧 конфиг · 👷 CI · 💚 починить CI · 🔥 удаление кода. 🧪 — только для намеренно падающего теста.
- Массовое переформатирование — отдельным коммитом/PR, не смешивать с логикой.

## Swift Style — [Google Swift Style Guide](https://google.github.io/swift/)

Гайд — источник истины. Отдельно (отличается от дефолтов Xcode):

- Отступ **2 пробела**, перенос строки-продолжения — +2. Лимит строки — **100 символов**.
- Без горизонтального выравнивания (между `@Dependency(\.x)` и `var`, перед `=` и комментариями).
- Запрещены `!`, `try!`, `as!` в коде app-таргета (в тестах допустимы, лучше `#require`).
- В `switch` по собственным enum — без `default`, перечислять все case’ы.
- `for … where` вместо `if` первой строкой в теле цикла.
- Trailing closure — только для последнего параметра-замыкания; при нескольких — все с метками.
- Импорты по алфавиту, по одному на строку.

Форматирование проверяется `swift-format` (конфиг `.swift-format` в корне). Перед коммитом:

```sh
xcrun swift-format format -i -r --parallel MealPlanner MealPlannerTests MealPlannerUITests
xcrun swift-format lint -r MealPlanner MealPlannerTests MealPlannerUITests
```
