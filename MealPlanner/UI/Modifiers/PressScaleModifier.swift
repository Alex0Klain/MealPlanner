import SwiftUI

/// ButtonStyle: сжимает контент до 0.96 при нажатии, добавляет лёгкое затемнение.
/// ARCHITECTURE.md → Card Visual States → Press.
///
/// Полагаемся на `configuration.isPressed`, а не на `onLongPressGesture` —
/// так UIKit сам корректно отменяет нажатие, если палец ушёл далеко, и
/// не съедает `Button` action.
public struct ScaledPressButtonStyle: ButtonStyle {
    public init() {}

    public func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.96 : 1.0)
            .overlay(
                Color.black.opacity(configuration.isPressed ? 0.22 : 0)
                    .allowsHitTesting(false)
            )
            .animation(Motion.select, value: configuration.isPressed)
    }
}

extension View {
    /// Convenience: применяет ScaledPressButtonStyle к Button.
    /// Внутри `.buttonStyle(.plain)` не нужен — стиль сам красит содержимое.
    public func pressScale() -> some View {
        buttonStyle(ScaledPressButtonStyle())
    }
}
