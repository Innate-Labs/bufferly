import SwiftUI

/// 「剪贴板 / 已固定」分段切换：药丸在选中项后面平滑滑动。
///
/// 参考 Transitions.dev「Tabs sliding」：药丸用 matchedGeometryEffect 在选中 tab 后面
/// 滑动（位置 + 宽度一起补间），缓动 = cubic-bezier(0.22, 1, 0.36, 1) / 200ms，
/// 文字仅做颜色过渡（muted ↔ active，不变字重，避免宽度跳动）。尊重 Reduce Motion。
struct PinboardTabs: View {
    @Binding var selection: QuickPanelViewModel.Board

    @Namespace private var pillNamespace
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    private static let slide = Animation.timingCurve(0.22, 1, 0.36, 1, duration: 0.2)

    var body: some View {
        HStack(spacing: 3) {
            ForEach(QuickPanelViewModel.Board.allCases) { board in
                tab(board)
            }
        }
        .padding(3)
        .background(
            Capsule(style: .continuous)
                .fill(Color.primary.opacity(0.06))
        )
    }

    private func tab(_ board: QuickPanelViewModel.Board) -> some View {
        let isSelected = selection == board

        return Text(board.rawValue)
            .font(.callout)
            .foregroundStyle(isSelected ? Color.primary : Color.secondary)
            .animation(reduceMotion ? nil : .easeOut(duration: 0.2), value: isSelected)
            .padding(.horizontal, 12)
            .frame(height: 28)
            .background {
                if isSelected {
                    Capsule(style: .continuous)
                        .fill(.regularMaterial)
                        .overlay(
                            Capsule(style: .continuous)
                                .strokeBorder(.white.opacity(0.12))
                        )
                        .shadow(color: .black.opacity(0.10), radius: 1.5, y: 1)
                        .matchedGeometryEffect(id: "pinboardPill", in: pillNamespace)
                }
            }
            .contentShape(Capsule(style: .continuous))
            .onTapGesture {
                guard selection != board else { return }
                if reduceMotion {
                    selection = board
                } else {
                    withAnimation(Self.slide) {
                        selection = board
                    }
                }
            }
            .accessibilityAddTraits(isSelected ? [.isSelected, .isButton] : .isButton)
    }
}
