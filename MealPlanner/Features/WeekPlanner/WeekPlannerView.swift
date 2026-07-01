import ComposableArchitecture
import SwiftUI

public struct WeekPlannerView: View {
    @Bindable public var store: StoreOf<WeekPlannerFeature>

    public init(store: StoreOf<WeekPlannerFeature>) {
        self.store = store
    }

    public var body: some View {
        NavigationStack(
            path: $store.scope(state: \.path, action: \.path)
        ) {
            ZStack {
                Color.inkBase.ignoresSafeArea()
                ScrollView {
                    VStack(spacing: Spacing.md) {
                        ForEach(store.days, id: \.date) { snapshot in
                            dayTile(snapshot: snapshot)
                        }
                    }
                    .padding(Spacing.lg)
                }
            }
            .navigationTitle("Неделя")
            .navigationBarTitleDisplayMode(.large)
            .onAppear { store.send(.onAppear) }
        } destination: { pathStore in
            switch pathStore.case {
            case let .dayDetail(dayStore):
                DayDetailView(store: dayStore)
            }
        }
    }

    private func dayTile(snapshot: DayPlanSnapshot) -> some View {
        Button {
            store.send(.dayTapped(snapshot.date))
        } label: {
            HStack(spacing: Spacing.md) {
                VStack(alignment: .leading, spacing: Spacing.xs) {
                    Text(snapshot.date, format: .dateTime.weekday(.wide))
                        .font(.cardName)
                        .foregroundStyle(Color.inkText)
                    Text(snapshot.date, format: .dateTime.day().month())
                        .font(.captionM)
                        .foregroundStyle(Color.inkMuted)
                }
                Spacer()
                Text("\(snapshot.meals.count) блюд")
                    .font(.captionM)
                    .foregroundStyle(Color.inkText.opacity(0.7))
                Image(systemName: "chevron.right")
                    .foregroundStyle(Color.inkMuted)
            }
            .padding(Spacing.md)
            .background(
                RoundedRectangle(cornerRadius: Radius.slot)
                    .fill(Color.inkSurface)
            )
        }
        .buttonStyle(.plain)
        .pressScale()
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
