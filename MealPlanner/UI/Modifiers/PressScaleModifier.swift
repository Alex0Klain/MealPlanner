import SwiftUI

/// Сжимает контент до 0.96 при нажатии. ARCHITECTURE.md → Card Visual States → Press.
public struct PressScaleModifier: ViewModifier {
    @State private var isPressed = false

    public func body(content: Content) -> some View {
        content
            .scaleEffect(isPressed ? 0.96 : 1.0)
            .overlay(
                Color.black.opacity(isPressed ? 0.22 : 0)
                    .allowsHitTesting(false)
            )
            .animation(Motion.select, value: isPressed)
            .onLongPressGesture(
                minimumDuration: 0,
                maximumDistance: .infinity,
                perform: {},
                onPressingChanged: { pressing in isPressed = pressing }
            )
    }
}

extension View {
    public func pressScale() -> some View {
        modifier(PressScaleModifier())
    }
}
