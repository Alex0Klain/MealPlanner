import ComposableArchitecture
import SwiftUI

/// Экран 04 из дизайна: Distribute — «Распредели карточки».
/// Сверху полоса выбранных карт (активная приподнята, распределённые
/// притушены с меткой «→ ЗАВТРАК»), ниже слоты-цели, снизу «⚡ Авто» и
/// «Подтвердить план».
public struct DistributeView: View {
    @Bindable public var store: StoreOf<PackOpeningFeature>

    public init(store: StoreOf<PackOpeningFeature>) {
        self.store = store
    }

    public var body: some View {
        ZStack {
            Color.inkCanvas.ignoresSafeArea()
            VStack(spacing: 0) {
                header
                title
                ScrollView {
                    VStack(alignment: .leading, spacing: Spacing.lg) {
                        selectedStrip
                        slotList
                    }
                    .padding(.horizontal, Spacing.lg)
                    .padding(.bottom, 120)
                }
            }
            bottomBar
        }
    }

    // MARK: header + title

    private var header: some View {
        HStack {
            CircleIconButton(systemName: "chevron.left") {
                store.send(.backToRevealTapped)
            }
            Spacer()
            MonoCaption("Шаг 2 из 2", size: 10)
            Spacer()
            Color.clear.frame(width: 36, height: 36)
        }
        .padding(.horizontal, Spacing.lg)
        .padding(.top, Spacing.xs)
    }

    private var title: some View {
        VStack(alignment: .leading, spacing: 3) {
            Text("Распредели карточки")
                .font(.system(size: 20, weight: .heavy, design: .rounded))
                .foregroundStyle(Color.inkText)
            Text("Тапни слот для каждой карточки или нажми «Авто»")
                .font(.system(size: 12))
                .foregroundStyle(Color.inkMuted)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal, Spacing.lg)
        .padding(.top, Spacing.sm)
        .padding(.bottom, Spacing.md)
    }

    // MARK: selected cards strip

    private var selectedStrip: some View {
        VStack(alignment: .leading, spacing: Spacing.sm) {
            HStack {
                MonoCaption("Выбрано · \(store.selectedIDs.count)", size: 10)
                Spacer()
                if store.unassignedCount > 0 {
                    Text("\(store.unassignedCount) нераспределено")
                        .font(.mono(10))
                        .foregroundStyle(Color.plasma)
                }
            }
            // Фиксированная ширина: с одной выбранной карточкой она не должна
            // растягиваться на весь экран.
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(alignment: .top, spacing: 10) {
                    ForEach(store.selectedCards) { card in
                        stripCard(card)
                            .frame(width: 106)
                    }
                }
            }
        }
    }

    private func stripCard(_ card: PackCard) -> some View {
        let assignedSlot = store.distribution[card.id]
        let isActive = store.activeDistributionID == card.id
        return Button {
            store.send(.distributionCardTapped(card.id))
        } label: {
            VStack(spacing: 6) {
                miniCard(card, isActive: isActive, isAssigned: assignedSlot != nil)
                if let assignedSlot {
                    Text("→ \(assignedSlot.displayName.uppercased())")
                        .font(.mono(8))
                        .kerning(1.1)
                        .foregroundStyle(Color.inkText.opacity(0.85))
                        .padding(.horizontal, 6)
                        .padding(.vertical, 3)
                        .frame(maxWidth: .infinity)
                        .background(
                            RoundedRectangle(cornerRadius: 6)
                                .fill(assignedSlot.accentColor.opacity(0.25))
                        )
                        .overlay(
                            RoundedRectangle(cornerRadius: 6)
                                .stroke(assignedSlot.accentColor.opacity(0.6), lineWidth: 1)
                        )
                        .lineLimit(1)
                        .minimumScaleFactor(0.7)
                } else {
                    Text(card.dish.name)
                        .font(.system(size: 10, weight: .bold, design: .rounded))
                        .foregroundStyle(
                            card.dish.rarity == .legendary ? Color.rarityLegendary : Color.inkText
                        )
                        .lineLimit(1)
                        .minimumScaleFactor(0.7)
                }
            }
        }
        .buttonStyle(.plain)
    }

    private func miniCard(_ card: PackCard, isActive: Bool, isAssigned: Bool) -> some View {
        DishPhoto(dish: card.dish, emojiSize: 34)
            .aspectRatio(7.0 / 10.0, contentMode: .fit)
            .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 10, style: .continuous)
                    .stroke(
                        isActive ? Color.plasma : card.dish.rarity.borderColor,
                        lineWidth: isActive ? 2 : 1.5
                    )
            )
            .opacity(isAssigned && !isActive ? 0.55 : 1)
            .saturation(isAssigned && !isActive ? 0.6 : 1)
            .offset(y: isActive ? -6 : 0)
            .shadow(
                color: isActive ? Color.plasmaDeep.opacity(0.5) : .clear,
                radius: isActive ? 9 : 0, y: isActive ? 8 : 0
            )
            .rarityGlow(isAssigned ? .common : card.dish.rarity)
            .animation(Motion.select, value: isActive)
    }

    // MARK: slot targets

    private var slotList: some View {
        VStack(alignment: .leading, spacing: Spacing.sm) {
            MonoCaption("План на день", size: 11)
            ForEach(MealSlot.displayOrder) { slot in
                slotRow(slot)
            }
        }
    }

    @ViewBuilder
    private func slotRow(_ slot: MealSlot) -> some View {
        let existing = store.existingBySlot[slot] ?? []
        let assignedCards = store.selectedCards.filter { store.distribution[$0.id] == slot }
        let capacity = store.state.remainingCapacity(of: slot)
        let activeCard = store.activeDistributionID.flatMap { store.cards[id: $0] }
        let contents = existing + assignedCards.map(\.dish)

        Button {
            if let activeCard, capacity > 0 {
                Haptics.success()
                store.send(.slotAssigned(activeCard.id, slot))
            }
        } label: {
            if contents.isEmpty {
                if let activeCard {
                    dropTargetRow(slot: slot, cardName: activeCard.dish.name, hint: nil)
                } else {
                    freeSlotRow(slot: slot)
                }
            } else if let activeCard, capacity > 0 {
                dropTargetRow(
                    slot: slot,
                    cardName: activeCard.dish.name,
                    hint: contents.map(\.name).joined(separator: ", ")
                )
            } else {
                occupiedSlotRow(
                    slot: slot,
                    contents: contents,
                    justAdded: !assignedCards.isEmpty,
                    isFull: capacity == 0
                )
            }
        }
        .buttonStyle(.plain)
        .animation(.snappy, value: store.distribution)
    }

    /// Слот с блюдами: уже лежавшие в плане + распределённые на этом шаге.
    private func occupiedSlotRow(
        slot: MealSlot,
        contents: [Dish],
        justAdded: Bool,
        isFull: Bool
    ) -> some View {
        let accent: Color = justAdded ? .cuisineItalian : .inkMuted
        return HStack(spacing: 10) {
            if let first = contents.first {
                DishPhoto(dish: first, emojiSize: 22)
                    .frame(width: 44, height: 60)
                    .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
                    .overlay(
                        RoundedRectangle(cornerRadius: 8, style: .continuous)
                            .stroke(accent.opacity(0.7), lineWidth: 1)
                    )
            }
            VStack(alignment: .leading, spacing: 3) {
                MonoCaption(slot.displayName, size: 9)
                Text(contents.map(\.name).joined(separator: ", "))
                    .font(.system(size: 13, weight: .bold, design: .rounded))
                    .foregroundStyle(Color.inkText)
                    .lineLimit(2)
                    .minimumScaleFactor(0.85)
                if justAdded {
                    Text("✓ только что добавлено")
                        .font(.mono(10, weight: .medium))
                        .foregroundStyle(Color.cuisineItalian)
                } else if isFull {
                    Text("Слот заполнен · \(MealSlot.mealsPerSlot) блюда")
                        .font(.mono(10, weight: .medium))
                        .foregroundStyle(Color.inkMuted)
                } else {
                    Text("В плане · есть место для второго")
                        .font(.mono(10, weight: .medium))
                        .foregroundStyle(Color.inkMuted)
                }
            }
            Spacer(minLength: 0)
        }
        .padding(8)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            LinearGradient(
                colors: [accent.opacity(justAdded ? 0.18 : 0.10), Color.inkSurface],
                startPoint: .leading, endPoint: .trailing
            )
        )
        .overlay(alignment: .leading) {
            Rectangle().fill(accent).frame(width: 3)
        }
        .clipShape(RoundedRectangle(cornerRadius: Radius.slot, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: Radius.slot, style: .continuous)
                .stroke(accent.opacity(0.5), lineWidth: 1.5)
        )
        .opacity(isFull && !justAdded ? 0.65 : 1)
    }

    private func dropTargetRow(slot: MealSlot, cardName: String, hint: String?) -> some View {
        HStack(spacing: 10) {
            Image(systemName: "arrow.down")
                .font(.system(size: 13, weight: .bold))
                .foregroundStyle(Color.plasma)
                .frame(width: 28, height: 28)
                .background(
                    RoundedRectangle(cornerRadius: 8, style: .continuous)
                        .fill(Color.plasma.opacity(0.3))
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 8, style: .continuous)
                        .strokeBorder(style: StrokeStyle(lineWidth: 1.5, dash: [3, 3]))
                        .foregroundStyle(Color.plasma)
                )
            VStack(alignment: .leading, spacing: 2) {
                MonoCaption(slot.displayName, size: 9)
                Text("Опустить «\(cardName)»")
                    .font(.system(size: 13, weight: .bold, design: .rounded))
                    .foregroundStyle(Color.plasma)
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)
                if let hint {
                    Text("Уже в слоте: \(hint)")
                        .font(.mono(9, weight: .medium))
                        .foregroundStyle(Color.inkMuted)
                        .lineLimit(1)
                        .minimumScaleFactor(0.8)
                }
            }
            Spacer(minLength: 0)
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 12)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: Radius.slot, style: .continuous)
                .fill(Color.plasma.opacity(0.12))
        )
        .overlay(
            RoundedRectangle(cornerRadius: Radius.slot, style: .continuous)
                .strokeBorder(style: StrokeStyle(lineWidth: 2, dash: [6, 4]))
                .foregroundStyle(Color.plasma)
        )
        .shadow(color: Color.plasmaDeep.opacity(0.3), radius: 10)
    }

    private func freeSlotRow(slot: MealSlot) -> some View {
        HStack(spacing: 10) {
            Text("+")
                .font(.system(size: 15, weight: .semibold))
                .foregroundStyle(slot.accentColor)
                .frame(width: 28, height: 28)
                .background(
                    RoundedRectangle(cornerRadius: 8, style: .continuous)
                        .fill(slot.accentColor.opacity(0.18))
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 8, style: .continuous)
                        .strokeBorder(style: StrokeStyle(lineWidth: 1, dash: [3, 3]))
                        .foregroundStyle(slot.accentColor.opacity(0.6))
                )
            VStack(alignment: .leading, spacing: 2) {
                MonoCaption(slot.displayName, size: 9)
                Text("Свободен")
                    .font(.system(size: 12, weight: .semibold, design: .rounded))
                    .foregroundStyle(Color.inkText.opacity(0.75))
            }
            Spacer(minLength: 0)
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 12)
        .frame(maxWidth: .infinity, alignment: .leading)
        .overlay(
            RoundedRectangle(cornerRadius: Radius.slot, style: .continuous)
                .strokeBorder(style: StrokeStyle(lineWidth: 1.5, dash: [6, 4]))
                .foregroundStyle(Color.inkRaised)
        )
        .contentShape(RoundedRectangle(cornerRadius: Radius.slot, style: .continuous))
    }

    // MARK: bottom bar

    private var bottomBar: some View {
        VStack {
            Spacer()
            HStack(spacing: 10) {
                Button {
                    store.send(.autoAssignTapped)
                } label: {
                    Text("⚡ Авто")
                        .font(.system(size: 13, weight: .semibold, design: .rounded))
                        .foregroundStyle(Color.inkText)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
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

                Button {
                    Haptics.success()
                    store.send(.confirmDistributionTapped)
                } label: {
                    Text("Подтвердить план")
                        .font(.system(size: 13, weight: .bold, design: .rounded))
                        .foregroundStyle(Color.inkText)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                        .background(
                            RoundedRectangle(cornerRadius: 16, style: .continuous)
                                .fill(
                                    store.canConfirmDistribution
                                    ? AnyShapeStyle(LinearGradient.plasmaCta)
                                    : AnyShapeStyle(Color.inkRaised)
                                )
                        )
                        .shadow(
                            color: store.canConfirmDistribution ? Color.plasmaDeep.opacity(0.5) : .clear,
                            radius: 10, y: 8
                        )
                }
                .pressScale()
                .disabled(!store.canConfirmDistribution)
                .frame(maxWidth: .infinity)
                .layoutPriority(1)
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
}

#Preview {
    DistributeView(
        store: Store(initialState: PackOpeningFeature.State(date: .now)) {
            PackOpeningFeature()
        }
    )
}
