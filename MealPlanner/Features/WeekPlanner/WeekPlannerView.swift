import ComposableArchitecture
import SwiftUI

/// Экран 06 из дизайна: планировщик недели.
/// Header «НЕДЕЛЯ N» + диапазон дат + ‹ ›, прогресс-карточка с баром и
/// счётчиком Legendary, плитки дней с мини-миниатюрами блюд.
public struct WeekPlannerView: View {
  @Bindable public var store: StoreOf<WeekPlannerFeature>

  @Namespace private var dayNamespace

  public init(store: StoreOf<WeekPlannerFeature>) {
    self.store = store
  }

  public var body: some View {
    NavigationStack(
      path: $store.scope(state: \.path, action: \.path)
    ) {
      VStack(spacing: 0) {
        header
          .padding(.horizontal, Spacing.lg)
          .padding(.top, Spacing.sm)
          .padding(.bottom, Spacing.md)
          .background(Color.inkBase)
        ScrollView {
          VStack(alignment: .leading, spacing: Spacing.md) {
            progressCard
            daysList
          }
          .padding(.horizontal, Spacing.lg)
          .padding(.bottom, Spacing.xl)
        }
      }
      .background(Color.inkBase.ignoresSafeArea())
      .toolbar(.hidden, for: .navigationBar)
      .onAppear { store.send(.onAppear) }
    } destination: { pathStore in
      switch pathStore.case {
      case .dayDetail(let dayStore):
        DayDetailView(store: dayStore)
          .navigationTransition(.zoom(sourceID: dayStore.date, in: dayNamespace))
      }
    }
  }

  // MARK: header

  private var header: some View {
    HStack(alignment: .top) {
      VStack(alignment: .leading, spacing: 4) {
        MonoCaption("Неделя \(weekNumber)", size: 11)
        Text(weekRangeTitle)
          .font(.system(size: 24, weight: .heavy, design: .rounded))
          .foregroundStyle(Color.inkText)
      }
      Spacer()
      HStack(spacing: 4) {
        CircleIconButton(systemName: "chevron.left") {
          store.send(.previousWeekTapped, animation: .snappy)
        }
        CircleIconButton(systemName: "chevron.right") {
          store.send(.nextWeekTapped, animation: .snappy)
        }
      }
    }
  }

  private var weekNumber: Int {
    Calendar.current.component(.weekOfYear, from: store.weekStart)
  }

  private var weekRangeTitle: String {
    let end =
      Calendar.current.date(byAdding: .day, value: 6, to: store.weekStart) ?? store.weekStart
    let startText = store.weekStart.formatted(.dateTime.day().month(.abbreviated).locale(.appRU))
    let endText = end.formatted(.dateTime.day().month(.abbreviated).locale(.appRU))
    return "\(startText) — \(endText)"
  }

  // MARK: progress card

  private var progressCard: some View {
    VStack(spacing: 8) {
      HStack(alignment: .firstTextBaseline) {
        HStack(alignment: .firstTextBaseline, spacing: 4) {
          Text("\(filledSlotsTotal)")
            .font(.mono(22))
            .foregroundStyle(Color.inkText)
            .contentTransition(.numericText())
          Text("/ \(weekTarget) приёмов")
            .font(.mono(13, weight: .medium))
            .foregroundStyle(Color.inkMuted)
        }
        Spacer()
        if legendaryCount > 0 {
          HStack(spacing: 4) {
            Text("★ \(legendaryCount) Legendary")
              .font(.mono(10))
              .kerning(0.8)
          }
          .foregroundStyle(Color.rarityLegendary)
          .padding(.horizontal, 8)
          .padding(.vertical, 3)
          .background(Capsule().fill(Color.rarityLegendary.opacity(0.12)))
          .overlay(Capsule().stroke(Color.rarityLegendary.opacity(0.4), lineWidth: 1))
        }
      }
      GeometryReader { proxy in
        ZStack(alignment: .leading) {
          Capsule().fill(Color.inkRaised)
          Capsule()
            .fill(
              LinearGradient(
                colors: [.plasma, .aqua],
                startPoint: .leading,
                endPoint: .trailing,
              )
            )
            .frame(width: max(8, proxy.size.width * progressFraction))
            .animation(.smooth, value: progressFraction)
        }
      }
      .frame(height: 8)
    }
    .padding(12)
    .background(
      RoundedRectangle(cornerRadius: Radius.slot, style: .continuous)
        .fill(Color.inkSurface)
    )
    .overlay(
      RoundedRectangle(cornerRadius: Radius.slot, style: .continuous)
        .stroke(Color.inkRaised, lineWidth: 1)
    )
  }

  private var weekTarget: Int { MealSlot.displayOrder.count * 7 }

  /// Заполненные слоты (приёмы), а не блюда: слот вмещает до 2 блюд.
  private var filledSlotsTotal: Int {
    store.days.reduce(0) { $0 + Set($1.meals.map(\.slot)).count }
  }

  private var progressFraction: Double {
    weekTarget > 0 ? min(1, Double(filledSlotsTotal) / Double(weekTarget)) : 0
  }

  private var legendaryCount: Int {
    store.days
      .flatMap(\.meals)
      .compactMap { store.dishesByID[$0.dishID] }
      .count { $0.rarity == .legendary }
  }

  // MARK: day list

  private var daysList: some View {
    VStack(spacing: 7) {
      ForEach(store.days, id: \.date) { snapshot in
        dayTile(snapshot)
          .matchedTransitionSource(id: snapshot.date, in: dayNamespace)
      }
    }
  }

  private func dayTile(_ snapshot: DayPlanSnapshot) -> some View {
    let isToday = Calendar.current.isDateInToday(snapshot.date)
    let isEmpty = snapshot.meals.isEmpty
    return Button {
      store.send(.dayTapped(snapshot.date))
    } label: {
      VStack(spacing: 6) {
        HStack(alignment: .center) {
          HStack(alignment: .firstTextBaseline, spacing: 6) {
            MonoCaption(
              dayCaption(snapshot.date, isToday: isToday),
              size: 9,
              color: isToday ? .plasma : .inkMuted,
            )
            Text(snapshot.date.formatted(.dateTime.day()))
              .font(.system(size: 15, weight: .heavy, design: .rounded))
              .foregroundStyle(isEmpty && !isToday ? Color.inkMuted : Color.inkText)
          }
          Spacer()
          if isEmpty {
            openPackChip
          } else {
            Text(
              "\(filledSlots(of: snapshot))/\(MealSlot.displayOrder.count) · \(calories(of: snapshot)) ккал"
            )
            .font(.mono(10, weight: isToday ? .bold : .medium))
            .foregroundStyle(isToday ? Color.plasma : Color.inkMuted)
          }
        }
        thumbnailsRow(snapshot)
      }
      .padding(.horizontal, 12)
      .padding(.vertical, 8)
      .background(
        RoundedRectangle(cornerRadius: 16, style: .continuous)
          .fill(tileBackground(isToday: isToday, isEmpty: isEmpty))
      )
      .overlay {
        if isEmpty && !isToday {
          RoundedRectangle(cornerRadius: 16, style: .continuous)
            .strokeBorder(style: StrokeStyle(lineWidth: 1, dash: [6, 4]))
            .foregroundStyle(Color.inkRaised)
        } else {
          RoundedRectangle(cornerRadius: 16, style: .continuous)
            .stroke(
              isToday ? Color.plasma : Color.inkRaised,
              lineWidth: isToday ? 1.5 : 1,
            )
        }
      }
      .shadow(color: isToday ? Color.plasmaDeep.opacity(0.35) : .clear, radius: 10)
    }
    .pressScale()
  }

  private func dayCaption(_ date: Date, isToday: Bool) -> String {
    let weekday = date.formatted(.dateTime.weekday(.abbreviated).locale(.appRU))
    return isToday ? "Сегодня · \(weekday)" : weekday
  }

  private func tileBackground(isToday: Bool, isEmpty: Bool) -> Color {
    if isToday { return Color.plasmaDeep.opacity(0.25) }
    if isEmpty { return Color.inkCanvas }
    return Color.inkSurface
  }

  private func calories(of snapshot: DayPlanSnapshot) -> Int {
    snapshot.meals
      .compactMap { store.dishesByID[$0.dishID]?.calories }
      .reduce(0, +)
  }

  private func filledSlots(of snapshot: DayPlanSnapshot) -> Int {
    Set(snapshot.meals.map(\.slot)).count
  }

  private func thumbnailsRow(_ snapshot: DayPlanSnapshot) -> some View {
    let dishes = snapshot.meals.compactMap { store.dishesByID[$0.dishID] }
    let target = MealSlot.displayOrder.count
    return HStack(spacing: 4) {
      ForEach(Array(dishes.prefix(target).enumerated()), id: \.offset) { _, dish in
        dishThumb(dish)
      }
      ForEach(0..<max(0, target - dishes.count), id: \.self) { _ in
        emptyThumb
      }
    }
  }

  private func dishThumb(_ dish: Dish) -> some View {
    DishPhoto(dish: dish, emojiSize: 22)
      .aspectRatio(1, contentMode: .fit)
      .frame(maxWidth: .infinity)
      .clipShape(RoundedRectangle(cornerRadius: 7, style: .continuous))
      .overlay(
        RoundedRectangle(cornerRadius: 7, style: .continuous)
          .stroke(
            dish.rarity == .common ? Color.inkRaised : dish.rarity.borderColor,
            lineWidth: dish.rarity == .common ? 1 : 1.5,
          )
      )
      .shadow(
        color: dish.rarity == .common ? .clear : dish.rarity.borderColor.opacity(0.55),
        radius: dish.rarity == .common ? 0 : 5,
      )
  }

  private var emptyThumb: some View {
    RoundedRectangle(cornerRadius: 7, style: .continuous)
      .fill(Color.inkBase)
      .aspectRatio(1, contentMode: .fit)
      .frame(maxWidth: .infinity)
      .overlay(
        RoundedRectangle(cornerRadius: 7, style: .continuous)
          .strokeBorder(style: StrokeStyle(lineWidth: 1.5, dash: [4, 3]))
          .foregroundStyle(Color.inkRaised)
      )
  }

  private var openPackChip: some View {
    Text("+ ОТКРЫТЬ ПАК")
      .font(.mono(10))
      .kerning(0.6)
      .foregroundStyle(Color.plasma)
      .padding(.horizontal, 8)
      .padding(.vertical, 3)
      .background(Capsule().fill(Color.plasmaDeep.opacity(0.25)))
      .overlay(Capsule().stroke(Color.plasma.opacity(0.5), lineWidth: 1))
  }
}

#Preview {
  WeekPlannerView(
    store: Store(initialState: WeekPlannerFeature.State()) {
      WeekPlannerFeature()
    } withDependencies: {
      $0.dishRepository = .preview
      $0.mealPlanRepository = .preview
    }
  )
}
