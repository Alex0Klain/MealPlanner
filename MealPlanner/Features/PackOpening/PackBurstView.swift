import SwiftUI

public struct PackBurstView: View {
    @State private var halfOffset: CGFloat = 0
    @State private var opacity: Double = 1

    public init() {}

    public var body: some View {
        ZStack {
            CardBack(size: .init(width: 200, height: 140))
                .offset(y: -halfOffset)
            CardBack(size: .init(width: 200, height: 140))
                .offset(y: halfOffset)
                .rotationEffect(.degrees(180))
        }
        .opacity(opacity)
        .blur(radius: opacity < 1 ? 8 : 0)
        .onAppear {
            withAnimation(.easeOut(duration: 0.3)) {
                halfOffset = 140
                opacity = 0
            }
        }
    }
}

#Preview {
    PackBurstView()
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.inkCanvas)
}
