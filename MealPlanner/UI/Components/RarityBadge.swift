import SwiftUI

public struct RarityBadge: View {
    public let rarity: Rarity

    public init(rarity: Rarity) {
        self.rarity = rarity
    }

    public var body: some View {
        Text(rarity.displayName)
            .font(.captionM)
            .foregroundStyle(rarity.borderColor)
            .padding(.horizontal, Spacing.sm)
            .padding(.vertical, Spacing.xs)
            .background(
                Capsule().fill(.ultraThinMaterial)
            )
            .overlay(
                Capsule().stroke(rarity.borderColor.opacity(0.6), lineWidth: 1)
            )
    }
}

#Preview {
    HStack {
        RarityBadge(rarity: .common)
        RarityBadge(rarity: .rare)
        RarityBadge(rarity: .legendary)
    }
    .padding()
    .background(Color.inkCanvas)
}
