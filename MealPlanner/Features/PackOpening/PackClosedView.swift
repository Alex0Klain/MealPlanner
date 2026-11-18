import SwiftUI

/// Состояние A из дизайна: закрытый фольгированный пак.
/// floatY 3s, пульсирующее halo позади, tear strip, подсказка «Тапни, чтобы открыть».
/// По тапу: haptic.medium → shake 300ms (scale 1.08, jitter) → onOpen().
public struct PackClosedView: View {
  public var onOpen: () -> Void

  @State private var floating = false
  @State private var pulsing = false
  @State private var isShaking = false

  public init(onOpen: @escaping () -> Void) {
    self.onOpen = onOpen
  }

  public var body: some View {
    VStack(spacing: 0) {
      Spacer()
      ZStack {
        halo
        sealedPack
          .offset(y: floating ? -6 : 6)
          .scaleEffect(isShaking ? 1.08 : 1.0)
          .rotationEffect(.degrees(isShaking ? 3 : 0))
          .onTapGesture(perform: openPack)
      }
      tapHint
        .padding(.top, 36)
      Spacer()
    }
    .frame(maxWidth: .infinity)
    .background(backdrop)
    .onAppear {
      withAnimation(Motion.float) { floating = true }
      withAnimation(Motion.pulse) { pulsing = true }
    }
  }

  private func openPack() {
    guard !isShaking else { return }
    Haptics.medium()
    withAnimation(.bouncy(duration: 0.3)) { isShaking = true }
    Task {
      try? await Task.sleep(for: .milliseconds(300))
      onOpen()
    }
  }

  // MARK: layers

  private var backdrop: some View {
    RadialGradient(
      colors: [Color.plasmaDeep.opacity(0.45), Color.inkBase],
      center: .center,
      startRadius: 40,
      endRadius: 420,
    )
    .ignoresSafeArea()
  }

  private var halo: some View {
    Circle()
      .fill(
        RadialGradient(
          colors: [Color.plasma.opacity(pulsing ? 0.45 : 0.25), .clear],
          center: .center,
          startRadius: 0,
          endRadius: 160,
        )
      )
      .frame(width: 320, height: 320)
      .blur(radius: 8)
  }

  private var sealedPack: some View {
    ZStack {
      // Тело пака
      RoundedRectangle(cornerRadius: 20, style: .continuous)
        .fill(
          LinearGradient(
            colors: [Color.plasma.opacity(0.8), Color.plasmaDeep, Color.inkBase],
            startPoint: .topLeading,
            endPoint: .bottomTrailing,
          )
        )
        .overlay(foilStripes.clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous)))
        .overlay(
          RoundedRectangle(cornerRadius: 20, style: .continuous)
            .stroke(Color.plasma, lineWidth: 2)
        )
        .shadow(color: .black.opacity(0.7), radius: 30, y: 22)
        .shadow(color: Color.plasma.opacity(0.45), radius: 26)

      VStack(spacing: 0) {
        tearStrip
          .padding(.top, 38)
        Spacer()
        logoStack
        Spacer()
        bottomPlate
          .padding(.bottom, 20)
      }
    }
    .frame(width: 210, height: 280)
  }

  private var foilStripes: some View {
    LinearGradient(
      stops: [
        .init(color: .white.opacity(0.10), location: 0.0),
        .init(color: .clear, location: 0.25),
        .init(color: Color.aqua.opacity(0.10), location: 0.5),
        .init(color: .clear, location: 0.75),
        .init(color: .white.opacity(0.08), location: 1.0),
      ],
      startPoint: .topLeading,
      endPoint: .bottomTrailing,
    )
  }

  private var tearStrip: some View {
    ZStack {
      LinearGradient(
        colors: [Color.cuisineAsian, Color.rarityLegendary, Color.cuisineAsian],
        startPoint: .leading,
        endPoint: .trailing,
      )
      Text("TEAR HERE ▸")
        .font(.mono(8, weight: .heavy))
        .kerning(2.4)
        .foregroundStyle(Color.inkBase)
    }
    .frame(height: 16)
    .overlay(alignment: .top) {
      DashedLine().frame(height: 1)
    }
    .overlay(alignment: .bottom) {
      DashedLine().frame(height: 1)
    }
  }

  private var logoStack: some View {
    ZStack {
      RoundedRectangle(cornerRadius: 11, style: .continuous)
        .fill(Color.inkRaised)
        .rotationEffect(.degrees(-10))
        .offset(x: -16, y: 8)
      RoundedRectangle(cornerRadius: 11, style: .continuous)
        .fill(LinearGradient.plasmaCta)
        .overlay(
          RoundedRectangle(cornerRadius: 11, style: .continuous)
            .stroke(Color.plasma, lineWidth: 1)
        )
        .rotationEffect(.degrees(-4))
        .offset(x: -5, y: 3)
        .shadow(color: .black.opacity(0.4), radius: 7, y: 4)
      RoundedRectangle(cornerRadius: 11, style: .continuous)
        .fill(LinearGradient.legendaryFoil)
        .overlay(
          RoundedRectangle(cornerRadius: 11, style: .continuous)
            .stroke(Color.rarityLegendary, lineWidth: 1.5)
        )
        .shadow(color: Color.rarityLegendary.opacity(0.6), radius: 11)
    }
    .frame(width: 80, height: 105)
  }

  private var bottomPlate: some View {
    VStack(spacing: 4) {
      (Text("MealPlanner").foregroundStyle(Color.inkText)
        + Text(".").foregroundStyle(Color.rarityLegendary))
        .font(.system(size: 20, weight: .heavy, design: .rounded))
        .shadow(color: Color.plasma.opacity(0.7), radius: 7)
      MonoCaption("Daily Pack · 9 Cards", size: 8, color: Color.inkText.opacity(0.75))
    }
  }

  private var tapHint: some View {
    VStack(spacing: 6) {
      Text("Тапни, чтобы открыть")
        .font(.system(size: 16, weight: .bold, design: .rounded))
        .foregroundStyle(Color.inkText)
        .shadow(color: Color.plasma.opacity(0.5), radius: 6)
      MonoCaption("9 карточек ждут", size: 10, color: .inkMuted)
    }
  }
}

private struct DashedLine: View {
  var body: some View {
    Line()
      .stroke(style: StrokeStyle(lineWidth: 1, dash: [3, 3]))
      .foregroundStyle(Color.rarityLegendary.opacity(0.6))
  }

  private struct Line: Shape {
    func path(in rect: CGRect) -> Path {
      var path = Path()
      path.move(to: CGPoint(x: 0, y: rect.midY))
      path.addLine(to: CGPoint(x: rect.width, y: rect.midY))
      return path
    }
  }
}

#Preview {
  PackClosedView(onOpen: {})
    .background(Color.inkBase)
}
