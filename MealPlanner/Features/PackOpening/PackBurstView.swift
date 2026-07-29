import SwiftUI

/// Состояние B из дизайна: разрыв пака. Две половинки разлетаются по диагонали
/// с blur и fade, в центре halo-вспышка, три карты «вылетают», частицы,
/// внизу — «Открываем твой пак» с пульсирующими точками.
public struct PackBurstView: View {
    @State private var burst = false
    @State private var dotPhase = false

    public init() {}

    public var body: some View {
        ZStack {
            backdrop
            halo
            topHalf
            bottomHalf
            burstingCards
            particles
            progressCaption
        }
        .onAppear {
            withAnimation(.easeOut(duration: 0.45)) { burst = true }
            withAnimation(.easeInOut(duration: 0.6).repeatForever(autoreverses: true)) {
                dotPhase = true
            }
        }
    }

    // MARK: layers

    private var backdrop: some View {
        RadialGradient(
            colors: [
                Color.plasma.opacity(0.55),
                Color.plasmaDeep.opacity(0.35),
                Color.inkBase
            ],
            center: .center, startRadius: 20, endRadius: 460
        )
        .ignoresSafeArea()
    }

    private var halo: some View {
        ZStack {
            Circle()
                .fill(
                    RadialGradient(
                        colors: [Color.plasma.opacity(0.75), Color.plasmaDeep.opacity(0.4), .clear],
                        center: .center, startRadius: 0, endRadius: 170
                    )
                )
                .frame(width: 340, height: 340)
                .blur(radius: 8)
            Circle()
                .fill(
                    RadialGradient(
                        colors: [.white, Color.plasma.opacity(0.6), .clear],
                        center: .center, startRadius: 0, endRadius: 70
                    )
                )
                .frame(width: 140, height: 140)
                .blur(radius: 4)
        }
        .scaleEffect(burst ? 1 : 0.4)
        .opacity(burst ? 1 : 0)
    }

    private var topHalf: some View {
        PackHalfShape(isTop: true)
            .offset(y: burst ? -230 : -60)
            .rotationEffect(.degrees(burst ? -14 : -4))
            .blur(radius: burst ? 6 : 0)
            .opacity(burst ? 0.25 : 1)
    }

    private var bottomHalf: some View {
        PackHalfShape(isTop: false)
            .offset(y: burst ? 230 : 60)
            .rotationEffect(.degrees(burst ? 11 : 3))
            .blur(radius: burst ? 6 : 0)
            .opacity(burst ? 0.25 : 1)
    }

    private var burstingCards: some View {
        ZStack {
            // Legendary — впереди, по центру
            burstCard(border: Color.rarityLegendary, glow: Color.rarityLegendary, width: 120)
                .rotationEffect(.degrees(-4))
                .offset(y: burst ? -10 : 30)
                .scaleEffect(burst ? 1 : 0.4)
            // Rare — слева сверху
            burstCard(border: Color.rarityRare, glow: Color.rarityRare, width: 90)
                .rotationEffect(.degrees(-22))
                .offset(x: burst ? -120 : -30, y: burst ? -170 : 0)
                .scaleEffect(burst ? 1 : 0.4)
            // Common — справа снизу
            burstCard(border: Color.rarityCommon, glow: .clear, width: 86)
                .rotationEffect(.degrees(20))
                .offset(x: burst ? 120 : 30, y: burst ? 170 : 20)
                .scaleEffect(burst ? 1 : 0.4)
        }
        .opacity(burst ? 1 : 0)
    }

    private func burstCard(border: Color, glow: Color, width: CGFloat) -> some View {
        CardBack()
            .frame(width: width)
            .overlay(
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .stroke(border, lineWidth: 2)
            )
            .shadow(color: .black.opacity(0.7), radius: 16, y: 12)
            .shadow(color: glow.opacity(0.7), radius: 16)
    }

    private var particles: some View {
        ZStack {
            particle(color: .plasma,          size: 7, x: -110, y: -160)
            particle(color: .aqua,            size: 5, x: 110,  y: -120)
            particle(color: .rarityLegendary, size: 6, x: -90,  y: 140)
            particle(color: .plasma,          size: 5, x: 95,   y: 120)
            particle(color: .plasma,          size: 4, x: -10,  y: -240)
            particle(color: .rarityLegendary, size: 4, x: -20,  y: 250)
        }
        .opacity(burst ? 1 : 0)
        .scaleEffect(burst ? 1 : 0.3)
    }

    private func particle(color: Color, size: CGFloat, x: CGFloat, y: CGFloat) -> some View {
        Circle()
            .fill(color)
            .frame(width: size, height: size)
            .shadow(color: color, radius: 6)
            .offset(x: x, y: y)
    }

    private var progressCaption: some View {
        VStack {
            Spacer()
            VStack(spacing: 10) {
                MonoCaption("Открываем твой пак", size: 11, color: Color.inkText.opacity(0.9))
                HStack(spacing: 6) {
                    ForEach(0..<3, id: \.self) { index in
                        Circle()
                            .fill(Color.plasma)
                            .frame(width: 6, height: 6)
                            .opacity(dotPhase ? (index == 1 ? 1 : 0.35) : (index == 1 ? 0.35 : 1))
                    }
                }
            }
            .padding(.bottom, 56)
        }
    }
}

/// Половинка разорванного пака с золотой кромкой по линии разрыва.
private struct PackHalfShape: View {
    let isTop: Bool

    var body: some View {
        UnevenRoundedRectangle(
            topLeadingRadius: isTop ? 18 : 6,
            bottomLeadingRadius: isTop ? 6 : 18,
            bottomTrailingRadius: isTop ? 6 : 18,
            topTrailingRadius: isTop ? 18 : 6,
            style: .continuous
        )
        .fill(
            LinearGradient(
                colors: isTop
                    ? [Color.plasma.opacity(0.85), Color.plasmaDeep]
                    : [Color.plasmaDeep, Color.plasmaDeep.opacity(0.6)],
                startPoint: .top,
                endPoint: .bottom
            )
        )
        .overlay(
            UnevenRoundedRectangle(
                topLeadingRadius: isTop ? 18 : 6,
                bottomLeadingRadius: isTop ? 6 : 18,
                bottomTrailingRadius: isTop ? 6 : 18,
                topTrailingRadius: isTop ? 18 : 6,
                style: .continuous
            )
            .stroke(Color.plasma, lineWidth: 2)
        )
        .overlay(alignment: isTop ? .bottom : .top) {
            LinearGradient(
                colors: [Color.cuisineAsian, Color.rarityLegendary, Color.cuisineAsian],
                startPoint: .leading,
                endPoint: .trailing
            )
            .frame(height: 10)
        }
        .frame(width: 168, height: isTop ? 90 : 76)
        .shadow(color: .black.opacity(0.7), radius: 18, y: isTop ? -8 : 8)
        .shadow(color: Color.plasma.opacity(0.6), radius: 15)
    }
}

#Preview {
    PackBurstView()
        .background(Color.inkBase)
}
