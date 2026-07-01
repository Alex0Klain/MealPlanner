import SwiftUI

public struct CuisineChip: View {
    public let cuisine: Cuisine

    public init(cuisine: Cuisine) {
        self.cuisine = cuisine
    }

    public var body: some View {
        Text(cuisine.displayName)
            .font(.captionM)
            .foregroundStyle(Color.inkText)
            .padding(.horizontal, Spacing.sm)
            .padding(.vertical, Spacing.xs)
            .background(
                Capsule().fill(cuisine.accentColor.opacity(0.22))
            )
            .overlay(
                Capsule().stroke(cuisine.accentColor.opacity(0.55), lineWidth: 1)
            )
    }
}

#Preview {
    VStack(alignment: .leading, spacing: Spacing.sm) {
        ForEach(Cuisine.allCases) { c in
            CuisineChip(cuisine: c)
        }
    }
    .padding()
    .background(Color.inkCanvas)
}
