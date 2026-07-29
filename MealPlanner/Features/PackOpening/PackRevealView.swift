import ComposableArchitecture
import SwiftUI

/// Экран 03 из дизайна: Reveal — сетка 3×3, выбор до N карточек.
/// Снизу: счётчик «Выбрано N / M», progress dots, «↻ Ещё пак» и
/// «Добавить в план →».
public struct PackRevealView: View {
    @Bindable public var store: StoreOf<PackOpeningFeature>

    public init(store: StoreOf<PackOpeningFeature>) {
        self.store = store
    }

    private let columns: [GridItem] = Array(
        repeating: GridItem(.flexible(), spacing: Spacing.md),
        count: 3
    )

    public var body: some View {
        ZStack {
            backdrop
            VStack(spacing: 0) {
                header
                ScrollView {
                    LazyVGrid(columns: columns, spacing: Spacing.md) {
                        ForEach(store.cards) { card in
                            CardView(card: card) {
                                Haptics.selection()
                                store.send(.cardTapped(card.id))
                            }
                        }
                    }
                    .padding(.horizontal, Spacing.lg)
                    .padding(.top, Spacing.md)

                    MonoCaption("Не нравится — открой ещё один пак", size: 9, color: .inkMuted)
                        .padding(.top, Spacing.sm)
                        .padding(.bottom, 150)
                }
            }
            bottomBar
        }
    }

    // MARK: pieces

    private var backdrop: some View {
        ZStack {
            Color.inkCanvas
            RadialGradient(
                colors: [Color.plasmaDeep.opacity(0.5), .clear],
                center: .init(x: 0.5, y: 0.1), startRadius: 0, endRadius: 300
            )
            RadialGradient(
                colors: [Color.aqua.opacity(0.25), .clear],
                center: .init(x: 0.5, y: 0.95), startRadius: 0, endRadius: 300
            )
        }
        .ignoresSafeArea()
    }

    private var header: some View {
        HStack {
            CircleIconButton(systemName: "xmark") {
                store.send(.closeTapped)
            }
            Spacer()
            VStack(spacing: 2) {
                MonoCaption("Daily Pack", size: 10)
                Text("Выбери до \(store.maxSelectable)")
                    .font(.system(size: 16, weight: .heavy, design: .rounded))
                    .foregroundStyle(Color.inkText)
            }
            Spacer()
            // симметричный спейсер под кнопку слева
            Color.clear.frame(width: 36, height: 36)
        }
        .padding(.horizontal, Spacing.lg)
        .padding(.top, Spacing.xs)
    }

    private var bottomBar: some View {
        VStack {
            Spacer()
            VStack(spacing: 12) {
                HStack(alignment: .center) {
                    VStack(alignment: .leading, spacing: 2) {
                        MonoCaption("Выбрано", size: 10)
                        HStack(alignment: .firstTextBaseline, spacing: 4) {
                            Text("\(store.selectedIDs.count)")
                                .font(.mono(24))
                                .foregroundStyle(Color.plasma)
                                .contentTransition(.numericText())
                                .animation(.snappy, value: store.selectedIDs.count)
                            Text("/ \(store.maxSelectable)")
                                .font(.mono(14, weight: .medium))
                                .foregroundStyle(Color.inkMuted)
                        }
                    }
                    Spacer()
                    progressDots
                }
                HStack(spacing: 10) {
                    Button {
                        store.send(.rerollTapped)
                    } label: {
                        Text("↻ Ещё пак")
                            .font(.system(size: 13, weight: .semibold, design: .rounded))
                            .foregroundStyle(Color.inkText)
                            .padding(.horizontal, 16)
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
                        store.send(.confirmRevealTapped)
                    } label: {
                        Text("Добавить в план →")
                            .font(.system(size: 13, weight: .bold, design: .rounded))
                            .foregroundStyle(Color.inkText)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 14)
                            .background(
                                RoundedRectangle(cornerRadius: 16, style: .continuous)
                                    .fill(
                                        store.canConfirmReveal
                                        ? AnyShapeStyle(LinearGradient.plasmaCta)
                                        : AnyShapeStyle(Color.inkRaised)
                                    )
                            )
                            .shadow(
                                color: store.canConfirmReveal ? Color.plasmaDeep.opacity(0.5) : .clear,
                                radius: 10, y: 8
                            )
                    }
                    .pressScale()
                    .disabled(!store.canConfirmReveal)
                }
            }
            .padding(.horizontal, Spacing.lg)
            .padding(.top, Spacing.lg)
            .padding(.bottom, Spacing.md)
            .background(
                LinearGradient(
                    stops: [
                        .init(color: .clear, location: 0),
                        .init(color: Color.inkCanvas.opacity(0.9), location: 0.3),
                        .init(color: Color.inkCanvas, location: 0.6)
                    ],
                    startPoint: .top,
                    endPoint: .bottom
                )
                .ignoresSafeArea(edges: .bottom)
            )
        }
    }

    private var progressDots: some View {
        HStack(spacing: 6) {
            ForEach(0..<max(store.maxSelectable, 1), id: \.self) { index in
                Circle()
                    .fill(index < store.selectedIDs.count ? Color.plasma : Color.inkRaised)
                    .frame(width: 10, height: 10)
            }
        }
        .animation(.snappy, value: store.selectedIDs.count)
    }
}

/// Круглая кнопка-иконка 36×36 из шапок дизайна.
struct CircleIconButton: View {
    let systemName: String
    var action: () -> Void

    var body: some View {
        Button(action: action) {
            Image(systemName: systemName)
                .font(.system(size: 14, weight: .semibold))
                .foregroundStyle(Color.inkText)
                .frame(width: 36, height: 36)
                .background(Circle().fill(Color.inkSurface))
                .overlay(Circle().stroke(Color.inkRaised, lineWidth: 1))
        }
        .pressScale()
    }
}

#Preview {
    PackRevealView(
        store: Store(initialState: PackOpeningFeature.State(date: .now)) {
            PackOpeningFeature()
        } withDependencies: {
            $0.dishRepository = .preview
            $0.packGenerator  = .live
        }
    )
}
