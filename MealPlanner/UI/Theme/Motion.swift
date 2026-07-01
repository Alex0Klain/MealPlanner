import SwiftUI

public enum Motion {
    public static let flip   = Animation.smooth(duration: 0.45)
    public static let select = Animation.spring(response: 0.3, dampingFraction: 0.6)
    public static let hero   = Animation.smooth(duration: 0.5, extraBounce: 0.1)
    public static let stagger: TimeInterval = 0.15

    /// Pack reveal таймлайн (ARCHITECTURE.md → Pack Reveal ~2.8s).
    public enum Pack {
        public static let shake: ClosedRange<Double>  = 0.0...0.3
        public static let burst: ClosedRange<Double>  = 0.3...0.6
        public static let grid:  ClosedRange<Double>  = 0.5...0.75
        public static let flip:  ClosedRange<Double>  = 0.75...2.1
        public static let idle:  ClosedRange<Double>  = 2.1...2.8
    }
}
