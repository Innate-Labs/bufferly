import SwiftUI

/// 面板背景：macOS 26+ 使用 Apple 官方 Liquid Glass（`.glassEffect`），
/// 旧系统自动回退到 `.ultraThinMaterial` + hairline 描边，保证一致可用。
struct PanelGlassBackground: ViewModifier {
    var cornerRadius: CGFloat

    func body(content: Content) -> some View {
        let shape = RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)

        if #available(macOS 26.0, *) {
            content
                .glassEffect(.regular, in: shape)
        } else {
            content
                .background(.ultraThinMaterial)
                .clipShape(shape)
                .overlay {
                    shape.strokeBorder(Color.primary.opacity(0.08), lineWidth: 1)
                }
        }
    }
}

extension View {
    func panelGlassBackground(cornerRadius: CGFloat) -> some View {
        modifier(PanelGlassBackground(cornerRadius: cornerRadius))
    }
}
