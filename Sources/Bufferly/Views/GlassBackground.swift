import SwiftUI

/// 面板背景用实一点的 material（不是玻璃）：作为「实底」层，
/// 让上面的 Liquid Glass 浮层控件清晰可读，符合 Apple「玻璃用于浮层、背景是实底」的范式。
struct PanelBackground: ViewModifier {
    var cornerRadius: CGFloat

    func body(content: Content) -> some View {
        let shape = RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)

        content
            .background(.thinMaterial)
            .clipShape(shape)
    }
}

extension View {
    func panelBackground(cornerRadius: CGFloat) -> some View {
        modifier(PanelBackground(cornerRadius: cornerRadius))
    }
}
