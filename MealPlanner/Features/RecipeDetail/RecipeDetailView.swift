import ComposableArchitecture
import SwiftUI

public struct RecipeDetailView: View {
    @Bindable public var store: StoreOf<RecipeDetailFeature>

    public init(store: StoreOf<RecipeDetailFeature>) {
        self.store = store
    }

    public var body: some View {
        NavigationStack {
            ZStack {
                Color.inkCanvas.ignoresSafeArea()
                content
            }
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Закрыть") { store.send(.closeTapped) }
                        .foregroundStyle(Color.plasma)
                }
                if store.mode == .stepByStep {
                    ToolbarItem(placement: .topBarLeading) {
                        Button {
                            store.send(.backToOverviewTapped)
                        } label: {
                            Image(systemName: "chevron.left")
                        }
                        .foregroundStyle(Color.plasma)
                    }
                }
            }
            .navigationTitle(store.dish.name)
            .navigationBarTitleDisplayMode(.inline)
        }
    }

    @ViewBuilder
    private var content: some View {
        switch store.mode {
        case .overview:   overview
        case .stepByStep: stepByStep
        }
    }

    private var overview: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: Spacing.lg) {
                heroBanner
                statsRow
                ingredientsSection
                Button {
                    store.send(.startCookingTapped)
                } label: {
                    Text("Начать готовить")
                        .font(.cardName)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, Spacing.md)
                        .background(LinearGradient.plasmaCta)
                        .foregroundStyle(Color.inkText)
                        .clipShape(RoundedRectangle(cornerRadius: Radius.button))
                }
                .padding(.top, Spacing.md)
            }
            .padding(Spacing.lg)
        }
    }

    private var heroBanner: some View {
        ZStack {
            RoundedRectangle(cornerRadius: Radius.card, style: .continuous)
                .fill(LinearGradient(
                    colors: [store.dish.cuisine.accentColor.opacity(0.4), Color.inkSurface],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                ))
            Text(store.dish.emoji).font(.system(size: 100))
        }
        .frame(height: 220)
    }

    private var statsRow: some View {
        HStack(spacing: Spacing.md) {
            statTile(title: "Время", value: "\(store.dish.cookTimeMinutes) мин")
            statTile(title: "Ккал",  value: "\(store.dish.calories)")
            statTile(title: "Белок", value: "\(store.dish.proteinGrams) г")
            statTile(title: "Сложность", value: store.dish.difficulty.stars)
        }
    }

    private func statTile(title: String, value: String) -> some View {
        VStack(spacing: Spacing.xs) {
            Text(value).font(.cardName).foregroundStyle(Color.inkText)
            Text(title).font(.captionM).foregroundStyle(Color.inkMuted)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, Spacing.sm)
        .background(
            RoundedRectangle(cornerRadius: Radius.slot, style: .continuous)
                .fill(Color.inkSurface)
        )
    }

    private var ingredientsSection: some View {
        VStack(alignment: .leading, spacing: Spacing.sm) {
            Text("Ингредиенты").font(.appTitle).foregroundStyle(Color.inkText)
            ForEach(Array(store.dish.ingredients.enumerated()), id: \.offset) { _, ingredient in
                HStack(spacing: Spacing.sm) {
                    Text(ingredient.emoji).font(.title3)
                    Text(ingredient.name).font(.bodyM).foregroundStyle(Color.inkText)
                    Spacer()
                    Text(ingredient.amount).font(.bodyM).foregroundStyle(Color.inkMuted)
                }
                .padding(.vertical, Spacing.xs)
            }
        }
    }

    private var stepByStep: some View {
        let step = store.dish.steps[safe: store.activeStepIndex]
        return VStack(spacing: Spacing.lg) {
            if let step {
                Text("Шаг \(step.order) из \(store.dish.steps.count)")
                    .font(.captionM)
                    .foregroundStyle(Color.inkMuted)
                Text(step.title)
                    .font(.appTitle)
                    .foregroundStyle(Color.inkText)
                    .multilineTextAlignment(.center)
                Text(step.description)
                    .font(.bodyM)
                    .foregroundStyle(Color.inkText.opacity(0.85))
                    .multilineTextAlignment(.center)
                if let duration = step.durationMinutes, duration > 0 {
                    CircularStepTimer(
                        progress: timerProgress(total: duration * 60),
                        remainingSeconds: store.remainingSeconds
                    )
                    .frame(width: 180, height: 180)
                    Button {
                        store.send(.timerToggled)
                    } label: {
                        Text(store.isTimerRunning ? "Пауза" : "Старт")
                            .font(.cardName)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, Spacing.md)
                            .background(LinearGradient.plasmaCta)
                            .foregroundStyle(Color.inkText)
                            .clipShape(RoundedRectangle(cornerRadius: Radius.button))
                    }
                }
            }
            Spacer()
            HStack(spacing: Spacing.md) {
                Button("Назад") { store.send(.previousStepTapped) }
                    .disabled(store.activeStepIndex == 0)
                Spacer()
                Button("Дальше") { store.send(.nextStepTapped) }
                    .disabled(store.activeStepIndex >= store.dish.steps.count - 1)
            }
            .foregroundStyle(Color.plasma)
        }
        .padding(Spacing.lg)
    }

    private func timerProgress(total: Int) -> Double {
        guard total > 0 else { return 0 }
        return Double(total - store.remainingSeconds) / Double(total)
    }
}

private extension Array {
    subscript(safe index: Int) -> Element? {
        indices.contains(index) ? self[index] : nil
    }
}

#Preview {
    RecipeDetailView(
        store: Store(initialState: RecipeDetailFeature.State(dish: Dish.previewCatalog[0])) {
            RecipeDetailFeature()
        }
    )
}
