import SwiftUI

/// 面板背景用实一点的 material（不是玻璃）：作为「实底」层，
/// 让上面的 Liquid Glass 浮层控件清晰可读，符合 Apple「玻璃用于浮层、背景是实底」的范式。
struct PanelBackground: ViewModifier {
    var cornerRadius: CGFloat

    func body(content: Content) -> some View {
        let shape = RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)

        content
            .background(.regularMaterial)
            .clipShape(shape)
            .overlay {
                shape.strokeBorder(Color.primary.opacity(0.08), lineWidth: 1)
            }
    }
}

extension View {
    func panelBackground(cornerRadius: CGFloat) -> some View {
        modifier(PanelBackground(cornerRadius: cornerRadius))
    }
}

/// 控件背景（搜索框 / 标签 / 按钮）：macOS 26+ 用 Liquid Glass，旧系统回退到淡色填充。
struct ControlGlassBackground<S: Shape>: ViewModifier {
    let shape: S

    func body(content: Content) -> some View {
        if #available(macOS 26.0, *) {
            content.glassEffect(.regular, in: shape)
        } else {
            content.background(Color.primary.opacity(0.06), in: shape)
        }
    }
}

extension View {
    func controlGlassBackground<S: Shape>(in shape: S) -> some View {
        modifier(ControlGlassBackground(shape: shape))
    }
}
