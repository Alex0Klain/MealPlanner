import SwiftUI

extension Font {
  static let display = Font.system(size: 34, weight: .heavy, design: .rounded)
  static let appTitle = Font.system(size: 28, weight: .bold, design: .default)
  static let screenTitle = Font.system(size: 26, weight: .heavy, design: .rounded)
  static let cardName = Font.system(size: 17, weight: .semibold, design: .rounded)
  static let cardNameRare = Font.system(size: 17, weight: .bold, design: .rounded)
  static let cardNameLegen = Font.system(size: 17, weight: .heavy, design: .rounded)
  static let bodyM = Font.system(size: 15, weight: .regular, design: .default)
  static let captionM = Font.system(size: 12, weight: .medium, design: .default)
  static let numeric = Font.system(size: 22, weight: .bold, design: .monospaced)

  /// JetBrains Mono-подобные капшены дизайна: UPPERCASE + tracking.
  static func mono(_ size: CGFloat, weight: Font.Weight = .bold) -> Font {
    .system(size: size, weight: weight, design: .monospaced)
  }
}

/// Интерфейс приложения — русский; даты не должны зависеть от локали системы.
extension Locale {
  static let appRU = Locale(identifier: "ru_RU")
}

/// Секционный caption из дизайна: MONO · UPPERCASE · РАЗРЯДКА.
struct MonoCaption: View {
  let text: String
  var size: CGFloat = 11
  var color: Color = .inkMuted

  init(_ text: String, size: CGFloat = 11, color: Color = .inkMuted) {
    self.text = text
    self.size = size
    self.color = color
  }

  var body: some View {
    Text(text.uppercased())
      .font(.mono(size))
      .kerning(size * 0.14)
      .foregroundStyle(color)
  }
}
