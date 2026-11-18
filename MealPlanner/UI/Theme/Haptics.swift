import UIKit

/// Haptic-события из дизайн-спеки:
/// tap по паку → medium, reveal Rare → light, reveal Legendary → success,
/// выбор карточки → selection, добавление в план → success.
@MainActor
public enum Haptics {
  public static func light() {
    UIImpactFeedbackGenerator(style: .light).impactOccurred()
  }

  public static func medium() {
    UIImpactFeedbackGenerator(style: .medium).impactOccurred()
  }

  public static func selection() {
    UISelectionFeedbackGenerator().selectionChanged()
  }

  public static func success() {
    UINotificationFeedbackGenerator().notificationOccurred(.success)
  }
}
