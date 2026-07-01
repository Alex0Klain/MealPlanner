import ComposableArchitecture
import SwiftUI

public struct AppView: View {
    @Bindable public var store: StoreOf<AppFeature>

    public init(store: StoreOf<AppFeature>) {
        self.store = store
    }

    public var body: some View {
        TabView(selection: $store.selectedTab.sending(\.tabChanged)) {
            HomeView(store: store.scope(state: \.home, action: \.home))
                .tabItem {
                    Label("Сегодня", systemImage: "sparkles")
                }
                .tag(AppFeature.Tab.today)

            WeekPlannerView(store: store.scope(state: \.week, action: \.week))
                .tabItem {
                    Label("Неделя", systemImage: "calendar")
                }
                .tag(AppFeature.Tab.week)
        }
        .tint(Color.plasma)
        .preferredColorScheme(.dark)
    }
}
