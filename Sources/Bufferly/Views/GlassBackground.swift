import SwiftUI

/// 面板背景使用官方 Liquid Glass；内容卡片仍保持实底，保证剪贴板内容可读。
struct PanelBackground: ViewModifier {
    var cornerRadius: CGFloat

    @Environment(\.accessibilityReduceTransparency) private var reduceTransparency

    func body(content: Content) -> some View {
        let shape = RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)

        content
            .background {
                if reduceTransparency {
                    shape
                        .fill(Color(nsColor: .windowBackgroundColor))
                } else {
                    shape
                        .fill(.regularMaterial)
                        .glassEffect(.regular, in: shape)
                }
            }
            .overlay {
                shape
                    .strokeBorder(Color.primary.opacity(0.08), lineWidth: 1)
            }
            .clipShape(shape)
    }
}

extension View {
    func panelBackground(cornerRadius: CGFloat) -> some View {
        modifier(PanelBackground(cornerRadius: cornerRadius))
    }
}
