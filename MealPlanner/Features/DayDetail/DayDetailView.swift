import ComposableArchitecture
import SwiftUI

/// Side flow B из дизайна: Day Detail — тот же шаблон, что Home,
/// с закреплённой навигацией «‹ дата ›» и swipe-действиями на строках плана.
public struct DayDetailView: View {
    @Bindable public var store: StoreOf<DayDetailFeature>

    @Namespace private var heroNamespace

    public init(store: StoreOf<DayDetailFeature>) {
        self.store = store
    }

    public var body: some View {
        VStack(spacing: 0) {
            dayNav
                .padding(.horizontal, Spacing.lg)
                .padding(.top, Spacing.sm)
                .padding(.bottom, Spacing.md)
                .background(Color.inkBase)
            List {
                Group {
                    PackCTAButton {
                        store.send(.packCtaTapped)
                    }
                    .matchedTransitionSource(id: "day-pack", in: heroNamespace)

                    MonoCaption("План на день", size: 11)
                        .padding(.top, Spacing.sm)

                    planRows
                }
                .listRowInsets(EdgeInsets(top: 5, leading: Spacing.lg, bottom: 5, trailing: Spacing.lg))
                .listRowSeparator(.hidden)
                .listRowBackground(Color.clear)
            }
            .listStyle(.plain)
            .scrollContentBackground(.hidden)
        }
        .background(Color.inkBase.ignoresSafeArea())
        .navigationBarTitleDisplayMode(.inline)
        .onAppear { store.send(.onAppear) }
        .fullScreenCover(
            item: $store.scope(state: \.destination?.packOpening, action: \.destination.packOpening)
        ) { packStore in
            PackOpeningView(store: packStore)
                .navigationTransition(.zoom(sourceID: "day-pack", in: heroNamespace))
        }
        .sheet(
            item: $store.scope(state: \.destination?.addMealSlot, action: \.destination.addMealSlot)
        ) { addStore in
            AddMealSlotView(store: addStore)
                .presentationDetents([.medium])
        }
        .sheet(
            item: $store.scope(state: \.destination?.recipeDetail, action: \.destination.recipeDetail)
        ) { recipeStore in
            RecipeDetailView(store: recipeStore)
                .navigationTransition(.zoom(sourceID: recipeStore.dish.id, in: heroNamespace))
        }
    }

    // MARK: day navigation (pinned)

    private var dayNav: some View {
        HStack {
            CircleIconButton(systemName: "chevron.left") {
                store.send(.previousDayTapped, animation: .snappy)
            }
            Spacer()
            VStack(spacing: 2) {
                Text(store.date.formatted(.dateTime.day().month(.wide).weekday(.abbreviated).locale(.appRU)))
                    .font(.system(size: 16, weight: .bold, design: .rounded))
                    .foregroundStyle(Color.inkText)
                    .contentTransition(.numericText())
                Text("\(filledSlots) из \(MealSlot.displayOrder.count) приёмов")
                    .font(.system(size: 11))
                    .foregroundStyle(Color.inkMuted)
            }
            Spacer()
            CircleIconButton(systemName: "chevron.right") {
                store.send(.nextDayTapped, animation: .snappy)
            }
        }
    }

    private var filledSlots: Int {
        Set(store.plan.meals.map(\.slot)).count
    }

    // MARK: plan rows

    @ViewBuilder
    private var planRows: some View {
        ForEach(MealSlot.displayOrder) { slot in
            let mealsInSlot = store.plan.meals.filter { $0.slot == slot }
            if mealsInSlot.isEmpty {
                EmptySlotView(slot: slot) { store.send(.slotTapped(slot)) }
            } else {
                ForEach(mealsInSlot) { meal in
                    if let dish = store.dishesByID[meal.dishID] {
                        MealSlotRow(
                            slot: slot,
                            dish: dish,
                            onTap: { store.send(.mealTapped(meal)) },
                            onRemove: { store.send(.removeMealTapped(meal)) }
                        )
                        .matchedTransitionSource(id: dish.id, in: heroNamespace)
                        .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                            Button(role: .destructive) {
                                store.send(.removeMealTapped(meal))
                            } label: {
                                Label("Убрать", systemImage: "trash")
                            }
                            Button {
                                store.send(.replaceMealTapped(meal))
                            } label: {
                                Label("Заменить", systemImage: "arrow.triangle.2.circlepath")
                            }
                            .tint(Color.plasmaDeep)
                        }
                    }
                }
            }
        }
    }
}

#Preview {
    NavigationStack {
        DayDetailView(
            store: Store(initialState: DayDetailFeature.State(date: .now)) {
                DayDetailFeature()
            } withDependencies: {
                $0.dishRepository = .preview
                $0.mealPlanRepository = .preview
            }
        )
    }
}
