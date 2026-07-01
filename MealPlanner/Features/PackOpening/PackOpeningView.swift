import ComposableArchitecture
import SwiftUI

public struct PackOpeningView: View {
    @Bindable public var store: StoreOf<PackOpeningFeature>

    public init(store: StoreOf<PackOpeningFeature>) {
        self.store = store
    }

    public var body: some View {
        ZStack {
            Color.inkBase.ignoresSafeArea()
            phaseContent
                .padding(.top, Spacing.xl)
            closeButton
        }
        .onAppear { store.send(.onAppear) }
    }

    @ViewBuilder
    private var phaseContent: some View {
        switch store.phase {
        case .closed:
            PackClosedView { store.send(.packTapped) }
        case .burst:
            PackBurstView()
        case .reveal:
            PackRevealView(store: store)
        case .distribute:
            DistributeView(store: store)
        }
    }

    private var closeButton: some View {
        VStack {
            HStack {
                Spacer()
                Button {
                    store.send(.closeTapped)
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .font(.title)
                        .foregroundStyle(Color.inkMuted)
                }
                .padding(Spacing.lg)
            }
            Spacer()
        }
    }
}

#Preview {
    PackOpeningView(
        store: Store(initialState: PackOpeningFeature.State(date: .now)) {
            PackOpeningFeature()
        } withDependencies: {
            $0.dishRepository = .preview
            $0.packGenerator  = .live
        }
    )
}
