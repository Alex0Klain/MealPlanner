import SwiftUI

/// Фото блюда: AsyncImage с фолбэком на emoji поверх градиента кухни.
/// Заполняет контейнер (scaledToFill) — обрезайте снаружи clipShape'ом.
public struct DishPhoto: View {
    public let dish: Dish
    /// Размер emoji в фолбэке/плейсхолдере.
    public var emojiSize: CGFloat = 34

    public init(dish: Dish, emojiSize: CGFloat = 34) {
        self.dish = dish
        self.emojiSize = emojiSize
    }

    public var body: some View {
        Color.clear
            .overlay {
                if let url = dish.imageURL {
                    AsyncImage(url: url) { phase in
                        switch phase {
                        case let .success(image):
                            image
                                .resizable()
                                .scaledToFill()
                        default:
                            fallback
                        }
                    }
                } else {
                    fallback
                }
            }
            .clipped()
    }

    private var fallback: some View {
        ZStack {
            LinearGradient(
                colors: [dish.cuisine.accentColor.opacity(0.5), Color.inkBase],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            Text(dish.emoji).font(.system(size: emojiSize))
        }
    }
}

#Preview {
    HStack {
        DishPhoto(dish: Dish.previewCatalog[0])
            .frame(width: 109, height: 156)
            .clipShape(RoundedRectangle(cornerRadius: 12))
        DishPhoto(dish: Dish.previewCatalog[2], emojiSize: 24)
            .frame(width: 44, height: 60)
            .clipShape(RoundedRectangle(cornerRadius: 8))
    }
    .padding()
    .background(Color.inkCanvas)
}
