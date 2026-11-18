import ComposableArchitecture
import SwiftUI

/// Full-screen флоу открытия пака: Closed → Burst → Reveal → Distribute.
public struct PackOpeningView: View {
  @Bindable public var store: StoreOf<PackOpeningFeature>

  public init(store: StoreOf<PackOpeningFeature>) {
    self.store = store
  }

  public var body: some View {
    ZStack {
      Color.inkBase.ignoresSafeArea()
      phaseContent
        .transition(.opacity)
    }
    .animation(.smooth(duration: 0.35), value: store.phase)
    .onAppear { store.send(.onAppear) }
  }

  @ViewBuilder
  private var phaseContent: some View {
    switch store.phase {
    case .closed:
      ZStack(alignment: .top) {
        PackClosedView { store.send(.packTapped) }
        closedHeader
      }
    case .burst:
      ZStack(alignment: .top) {
        PackBurstView()
        burstHeader
      }
    case .reveal:
      PackRevealView(store: store)
    case .distribute:
      DistributeView(store: store)
    }
  }

  private var closedHeader: some View {
    HStack {
      CircleIconButton(systemName: "xmark") {
        store.send(.closeTapped)
      }
      Spacer()
      MonoCaption("Daily Pack · 1 / 1", size: 10)
      Spacer()
      Color.clear.frame(width: 36, height: 36)
    }
    .padding(.horizontal, Spacing.lg)
    .padding(.top, Spacing.xs)
  }

  private var burstHeader: some View {
    HStack {
      Spacer()
      Button {
        store.send(.burstFinished)
      } label: {
        MonoCaption("Пропустить", size: 10, color: .inkText)
          .padding(.horizontal, 12)
          .padding(.vertical, 6)
          .background(Capsule().fill(.ultraThinMaterial))
          .overlay(Capsule().stroke(Color.inkRaised, lineWidth: 1))
      }
      .pressScale()
    }
    .padding(.horizontal, Spacing.lg)
    .padding(.top, Spacing.xs)
  }
}

#Preview {
  PackOpeningView(
    store: Store(initialState: PackOpeningFeature.State(date: .now)) {
      PackOpeningFeature()
    } withDependencies: {
      $0.dishRepository = .preview
      $0.packGenerator = .live
    }
  )
}
