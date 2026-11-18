import ComposableArchitecture
import SwiftUI

/// Экраны 05a/05b из дизайна: карточка рецепта.
/// Обзор: hero 16:10 с glass-chips → stats-плитки → сегменты → ингредиенты →
/// «Начать готовить». Готовка: компактный hero, progress bar, список шагов
/// (done / active с таймером / upcoming), «⏸ / Завершить шаг ›».
public struct RecipeDetailView: View {
    @Bindable public var store: StoreOf<RecipeDetailFeature>

    public init(store: StoreOf<RecipeDetailFeature>) {
        self.store = store
    }

    public var body: some View {
        ZStack {
            Color.inkCanvas.ignoresSafeArea()
            VStack(spacing: 0) {
                navBar
                ScrollView {
                    VStack(spacing: Spacing.md) {
                        if store.isCooking {
                            compactHero
                            progressBar
                        } else {
                            hero
                        }
                        statsRow
                        segmented
                        switch store.mode {
                        case .ingredients: ingredientsList
                        case .steps:       stepsList
                        }
                    }
                    .padding(.horizontal, Spacing.lg)
                    .padding(.bottom, 130)
                }
            }
            bottomBar
        }
    }

    // MARK: nav

    private var navBar: some View {
        HStack {
            CircleIconButton(systemName: store.isCooking ? "chevron.left" : "xmark") {
                store.send(.closeTapped)
            }
            Spacer()
            VStack(spacing: 1) {
                if store.isCooking {
                    MonoCaption(store.dish.name, size: 10)
                    Text("Шаг \(min(store.activeStepIndex + 1, store.dish.steps.count)) из \(store.dish.steps.count)")
                        .font(.system(size: 14, weight: .bold, design: .rounded))
                        .foregroundStyle(Color.inkText)
                } else {
                    MonoCaption(recipeCode, size: 11)
                }
            }
            Spacer()
            Color.clear.frame(width: 36, height: 36)
        }
        .padding(.horizontal, Spacing.lg)
        .padding(.top, Spacing.lg)
        .padding(.bottom, Spacing.xs)
    }

    private var recipeCode: String {
        if let number = store.dish.cardNumber {
            "Recipe · \(String(format: "%03d", number))"
        } else {
            "Recipe"
        }
    }

    // MARK: hero

    private var hero: some View {
        ZStack {
            DishPhoto(dish: store.dish, emojiSize: 96)
            LinearGradient(
                stops: [
                    .init(color: .black.opacity(0.25), location: 0),
                    .init(color: .clear, location: 0.3),
                    .init(color: .clear, location: 0.5),
                    .init(color: .black.opacity(0.85), location: 1)
                ],
                startPoint: .top, endPoint: .bottom
            )
            heroChips
        }
        .aspectRatio(16.0 / 10.0, contentMode: .fit)
        .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .stroke(store.dish.rarity.borderColor, lineWidth: 1.5)
        )
        .rarityGlow(store.dish.rarity)
    }

    private var heroChips: some View {
        VStack(alignment: .leading) {
            HStack(alignment: .top) {
                rarityBadge
                Spacer()
                Text(store.dish.difficulty.stars)
                    .font(.mono(10, weight: .medium))
                    .foregroundStyle(Color.rarityLegendary)
                    .padding(.horizontal, 7)
                    .padding(.vertical, 4)
                    .background(RoundedRectangle(cornerRadius: 6).fill(.ultraThinMaterial))
            }
            Spacer()
            CuisineChip(cuisine: store.dish.cuisine)
            Text(store.dish.name)
                .font(.system(size: 22, weight: .heavy, design: .rounded))
                .foregroundStyle(
                    store.dish.rarity == .legendary ? Color.rarityLegendary : Color.inkText
                )
                .lineLimit(2)
                .minimumScaleFactor(0.8)
                .padding(.top, 2)
        }
        .padding(10)
    }

    private var rarityBadge: some View {
        Text(rarityBadgeText)
            .font(.mono(10))
            .kerning(1.4)
            .foregroundStyle(
                store.dish.rarity == .common ? Color.inkText : store.dish.rarity.borderColor
            )
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(RoundedRectangle(cornerRadius: 6).fill(.ultraThinMaterial))
            .overlay(
                RoundedRectangle(cornerRadius: 6)
                    .stroke(store.dish.rarity.borderColor.opacity(0.8), lineWidth: 1)
            )
    }

    private var rarityBadgeText: String {
        let letter = switch store.dish.rarity {
        case .common:    "C"
        case .rare:      "R"
        case .legendary: "★ L"
        }
        if let number = store.dish.cardNumber {
            return "\(letter) · \(String(format: "%03d", number)) / 100"
        }
        return letter
    }

    private var compactHero: some View {
        ZStack(alignment: .leading) {
            DishPhoto(dish: store.dish, emojiSize: 44)
            LinearGradient(
                colors: [Color.inkBase.opacity(0.9), Color.inkBase.opacity(0.35), .clear],
                startPoint: .leading,
                endPoint: .trailing
            )
            VStack(alignment: .leading, spacing: 4) {
                Text(store.dish.name)
                    .font(.system(size: 18, weight: .heavy, design: .rounded))
                    .foregroundStyle(
                        store.dish.rarity == .legendary ? Color.rarityLegendary : Color.inkText
                    )
                    .lineLimit(2)
                    .minimumScaleFactor(0.8)
                Text("⏱ \(store.dish.cookTimeMinutes)м  🔥 \(store.dish.calories)  \(store.dish.difficulty.stars)")
                    .font(.mono(10, weight: .medium))
                    .foregroundStyle(Color.inkText.opacity(0.85))
            }
            .padding(.leading, 14)
        }
        .frame(height: 100)
        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .stroke(store.dish.rarity.borderColor, lineWidth: 1.5)
        )
    }

    private var progressBar: some View {
        VStack(spacing: 6) {
            GeometryReader { proxy in
                ZStack(alignment: .leading) {
                    Capsule().fill(Color.inkRaised)
                    Capsule()
                        .fill(
                            LinearGradient(
                                colors: [.plasma, .aqua],
                                startPoint: .leading, endPoint: .trailing
                            )
                        )
                        .frame(width: max(6, proxy.size.width * store.progressFraction))
                        .animation(.smooth, value: store.progressFraction)
                }
            }
            .frame(height: 6)
            HStack {
                Text("\(Int(store.progressFraction * 100))% · \(store.minutesPassed)м прошло")
                Spacer()
                Text("\(max(0, store.dish.cookTimeMinutes - store.minutesPassed))м осталось")
            }
            .font(.mono(10, weight: .medium))
            .foregroundStyle(Color.inkMuted)
        }
    }

    // MARK: stats

    private var statsRow: some View {
        HStack(spacing: Spacing.sm) {
            statTile(value: "\(store.dish.cookTimeMinutes)", unit: "мин", title: "Время")
            statTile(value: "\(store.dish.calories)", title: "Ккал")
            statTile(value: "\(store.dish.ingredients.count)", title: "Ингр.")
            statTile(value: store.dish.difficulty.stars, title: "Слож.", tint: .rarityLegendary)
        }
    }

    private func statTile(value: String, unit: String? = nil, title: String, tint: Color = .inkText) -> some View {
        VStack(spacing: 2) {
            HStack(alignment: .firstTextBaseline, spacing: 2) {
                Text(value)
                    .font(.mono(16))
                    .foregroundStyle(tint)
                if let unit {
                    Text(unit)
                        .font(.mono(9, weight: .medium))
                        .foregroundStyle(Color.inkMuted)
                }
            }
            MonoCaption(title, size: 9)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 8)
        .background(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .fill(Color.inkSurface)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .stroke(Color.inkRaised, lineWidth: 1)
        )
    }

    // MARK: segmented

    private var segmented: some View {
        HStack(spacing: 2) {
            segment("Ингредиенты · \(store.dish.ingredients.count)", mode: .ingredients)
            segment("Шаги · \(store.dish.steps.count)", mode: .steps)
        }
        .padding(3)
        .background(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .fill(Color.inkCanvas)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .stroke(Color.inkRaised, lineWidth: 1)
        )
    }

    private func segment(_ label: String, mode: RecipeDetailFeature.State.Mode) -> some View {
        let isActive = store.mode == mode
        return Button {
            store.send(.modeChanged(mode), animation: .snappy)
        } label: {
            Text(label)
                .font(.system(size: 12, weight: isActive ? .bold : .regular))
                .foregroundStyle(isActive ? Color.inkText : Color.inkMuted)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 8)
                .background(
                    RoundedRectangle(cornerRadius: 9, style: .continuous)
                        .fill(isActive ? Color.inkRaised : .clear)
                )
                // Без contentShape тап ловится только по тексту:
                // прозрачный фон неактивного сегмента не участвует в hit-testing.
                .contentShape(RoundedRectangle(cornerRadius: 9, style: .continuous))
        }
        .buttonStyle(.plain)
    }

    // MARK: ingredients

    private var ingredientsList: some View {
        VStack(spacing: 0) {
            ForEach(store.dish.ingredients) { ingredient in
                HStack(spacing: 10) {
                    Text(ingredient.emoji)
                        .font(.system(size: 13))
                        .frame(width: 26, height: 26)
                        .background(
                            RoundedRectangle(cornerRadius: 7, style: .continuous)
                                .fill(Color.inkSurface)
                        )
                        .overlay(
                            RoundedRectangle(cornerRadius: 7, style: .continuous)
                                .stroke(Color.inkRaised, lineWidth: 1)
                        )
                    Text(ingredient.name)
                        .font(.system(size: 13))
                        .foregroundStyle(Color.inkText)
                    Spacer()
                    Text(ingredient.amount)
                        .font(.mono(12, weight: .medium))
                        .foregroundStyle(Color.inkMuted)
                }
                .padding(.vertical, 6)
                if ingredient.id != store.dish.ingredients.last?.id {
                    Divider().overlay(Color.inkRaised.opacity(0.6))
                }
            }
        }
    }

    // MARK: steps

    private var stepsList: some View {
        VStack(spacing: Spacing.sm) {
            ForEach(Array(store.dish.steps.enumerated()), id: \.element.id) { index, step in
                stepRow(index: index, step: step)
            }
        }
        .animation(.snappy, value: store.activeStepIndex)
        .animation(.snappy, value: store.completedSteps)
    }

    @ViewBuilder
    private func stepRow(index: Int, step: RecipeStep) -> some View {
        let isDone = store.completedSteps.contains(index)
        let isActive = store.isCooking && store.activeStepIndex == index && !isDone
        Button {
            store.send(.stepTapped(index))
        } label: {
            HStack(alignment: .top, spacing: 12) {
                stepBadge(index: index, isDone: isDone, isActive: isActive)
                VStack(alignment: .leading, spacing: 4) {
                    HStack {
                        MonoCaption(
                            isActive ? "Шаг \(step.order) · Сейчас" : "Шаг \(step.order)",
                            size: 10,
                            color: isDone ? .cuisineItalian : (isActive ? .plasma : .inkMuted)
                        )
                        if let minutes = step.durationMinutes, !isActive {
                            Text("· \(minutes) мин")
                                .font(.mono(10, weight: .medium))
                                .foregroundStyle(Color.inkMuted)
                        }
                        Spacer()
                        if isActive, (step.durationMinutes ?? 0) > 0 {
                            timerPill
                        }
                    }
                    Text(step.title)
                        .font(.system(size: isActive ? 16 : 14, weight: isActive ? .bold : .semibold, design: .rounded))
                        .foregroundStyle(isDone ? Color.inkMuted : Color.inkText)
                        .strikethrough(isDone, color: .inkMuted)
                    if isActive {
                        Text(step.description)
                            .font(.system(size: 12))
                            .foregroundStyle(Color.inkText.opacity(0.85))
                            .lineSpacing(3)
                    }
                }
            }
            .padding(isActive ? 14 : 12)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(stepBackground(isDone: isDone, isActive: isActive))
            .overlay(
                RoundedRectangle(cornerRadius: isActive ? 16 : 14, style: .continuous)
                    .stroke(
                        isActive ? Color.plasma : Color.inkRaised,
                        lineWidth: isActive ? 1.5 : 1
                    )
            )
            .opacity(isDone ? 0.6 : 1)
            .shadow(color: isActive ? Color.plasmaDeep.opacity(0.4) : .clear, radius: 12, y: 8)
        }
        .buttonStyle(.plain)
        .disabled(!store.isCooking)
    }

    @ViewBuilder
    private func stepBackground(isDone: Bool, isActive: Bool) -> some View {
        if isActive {
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(
                    LinearGradient(
                        colors: [Color.plasmaDeep.opacity(0.55), Color.inkSurface],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
        } else {
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .fill(Color.inkSurface.opacity(isDone ? 0.7 : 1))
        }
    }

    private func stepBadge(index: Int, isDone: Bool, isActive: Bool) -> some View {
        ZStack {
            if isDone {
                Circle().fill(Color.cuisineItalian)
                Image(systemName: "checkmark")
                    .font(.system(size: 14, weight: .heavy))
                    .foregroundStyle(.white)
            } else if isActive {
                Circle().fill(Color.plasma)
                Text("\(index + 1)")
                    .font(.system(size: 18, weight: .heavy, design: .rounded))
                    .foregroundStyle(.white)
            } else {
                Circle().fill(Color.inkRaised)
                Circle().stroke(Color.inkMuted.opacity(0.4), lineWidth: 1.5)
                Text("\(index + 1)")
                    .font(.system(size: 14, weight: .bold, design: .rounded))
                    .foregroundStyle(Color.inkText.opacity(0.85))
            }
        }
        .frame(width: isActive ? 44 : 36, height: isActive ? 44 : 36)
        .shadow(color: isActive ? Color.plasmaDeep.opacity(0.6) : .clear, radius: 6, y: 4)
    }

    private var timerPill: some View {
        Button {
            store.send(.timerToggled)
        } label: {
            HStack(spacing: 4) {
                Circle()
                    .fill(store.isTimerRunning ? Color.cuisineItalian : Color.inkMuted)
                    .frame(width: 6, height: 6)
                    .shadow(
                        color: store.isTimerRunning ? Color.cuisineItalian : .clear,
                        radius: 3
                    )
                Text(timeString(store.remainingSeconds))
                    .font(.mono(11))
                    .foregroundStyle(Color.inkText)
                    .contentTransition(.numericText())
                    .animation(.linear(duration: 0.2), value: store.remainingSeconds)
            }
            .padding(.horizontal, 8)
            .padding(.vertical, 3)
            .background(Capsule().fill(Color.inkBase.opacity(0.5)))
            .overlay(Capsule().stroke(Color.plasma.opacity(0.5), lineWidth: 1))
        }
        .buttonStyle(.plain)
    }

    private func timeString(_ seconds: Int) -> String {
        String(format: "%d:%02d", seconds / 60, seconds % 60)
    }

    // MARK: bottom bar

    private var bottomBar: some View {
        VStack {
            Spacer()
            Group {
                if store.isCooking && !store.allStepsCompleted {
                    cookingControls
                } else if store.allStepsCompleted {
                    primaryButton("Готово ✓") {
                        Haptics.success()
                        store.send(.closeTapped)
                    }
                } else {
                    primaryButton("Начать готовить") {
                        store.send(.startCookingTapped, animation: .snappy)
                    }
                }
            }
            .padding(.horizontal, Spacing.lg)
            .padding(.top, Spacing.lg)
            .padding(.bottom, Spacing.md)
            .background(
                LinearGradient(
                    stops: [
                        .init(color: .clear, location: 0),
                        .init(color: Color.inkCanvas.opacity(0.95), location: 0.3),
                        .init(color: Color.inkCanvas, location: 0.6)
                    ],
                    startPoint: .top,
                    endPoint: .bottom
                )
                .ignoresSafeArea(edges: .bottom)
            )
        }
    }

    private var cookingControls: some View {
        HStack(spacing: 10) {
            Button {
                store.send(.timerToggled)
            } label: {
                Image(systemName: store.isTimerRunning ? "pause.fill" : "play.fill")
                    .font(.system(size: 16, weight: .bold))
                    .foregroundStyle(Color.inkText)
                    .frame(width: 52, height: 52)
                    .background(
                        RoundedRectangle(cornerRadius: 16, style: .continuous)
                            .fill(Color.inkSurface)
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 16, style: .continuous)
                            .stroke(Color.inkRaised, lineWidth: 1)
                    )
            }
            .pressScale()
            .disabled((store.activeStep?.durationMinutes ?? 0) == 0)

            Button {
                Haptics.light()
                store.send(.completeStepTapped, animation: .snappy)
            } label: {
                HStack(spacing: 8) {
                    Text("Завершить шаг")
                    Image(systemName: "chevron.right")
                        .font(.system(size: 13, weight: .bold))
                }
                .font(.system(size: 15, weight: .bold, design: .rounded))
                .foregroundStyle(Color.inkText)
                .frame(maxWidth: .infinity)
                .frame(height: 52)
                .background(
                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                        .fill(LinearGradient.plasmaCta)
                )
                .shadow(color: Color.plasmaDeep.opacity(0.5), radius: 12, y: 8)
            }
            .pressScale()
        }
    }

    private func primaryButton(_ title: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Text(title)
                .font(.system(size: 15, weight: .bold, design: .rounded))
                .foregroundStyle(Color.inkText)
                .frame(maxWidth: .infinity)
                .frame(height: 52)
                .background(
                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                        .fill(LinearGradient.plasmaCta)
                )
                .shadow(color: Color.plasmaDeep.opacity(0.5), radius: 12, y: 8)
        }
        .pressScale()
    }
}

#Preview {
    RecipeDetailView(
        store: Store(initialState: RecipeDetailFeature.State(dish: Dish.previewCatalog[2])) {
            RecipeDetailFeature()
        }
    )
}
