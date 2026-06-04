import SwiftUI

/// Paste 式剪贴板卡片：彩色头部（类型 + 时间 + 类型图标）+ 白色正文（富预览 + 来源 + pin）。
/// 选中态：抬起放大 + accentColor 描边 + 更强阴影。
struct ClipCardView: View {
    let clip: ClipItem
    let isSelected: Bool
    let onSelect: () -> Void
    let onActivate: () -> Void
    let onTogglePin: () -> Void

    /// 上次点击时间，用于自己判断双击，避免 SwiftUI 单/双击消歧带来的选中延迟。
    @State private var lastTapTime = Date.distantPast

    static let width: CGFloat = 200
    static let height: CGFloat = 272

    private var isMonospaced: Bool {
        clip.kind == .code || clip.kind == .json || clip.kind == .command
    }

    private var timeText: String {
        clip.relativeTime == "刚刚" ? "刚刚" : clip.relativeTime + "前"
    }

    var body: some View {
        VStack(spacing: 0) {
            header
            content
        }
        .frame(width: Self.width, height: Self.height)
        .background(Color(nsColor: .textBackgroundColor))
        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .strokeBorder(isSelected ? Color.accentColor : Color.primary.opacity(0.08),
                              lineWidth: isSelected ? 3 : 1)
        }
        .shadow(color: .black.opacity(0.10), radius: 7, y: 3)
        .contentShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
        .onTapGesture {
            let now = Date()
            if now.timeIntervalSince(lastTapTime) < 0.3 {
                onActivate()
            } else {
                onSelect()
            }
            lastTapTime = now
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(clip.kind.rawValue)，\(clip.title)，\(timeText)复制自 \(clip.source)")
        .accessibilityAddTraits(isSelected ? .isSelected : [])
    }

    private var header: some View {
        HStack(alignment: .top, spacing: 8) {
            VStack(alignment: .leading, spacing: 2) {
                Text(clip.kind.rawValue)
                    .font(.system(size: 15, weight: .bold))
                    .foregroundStyle(.white)

                Text(timeText)
                    .font(.system(size: 11, weight: .medium))
                    .foregroundStyle(.white.opacity(0.85))
            }

            Spacer(minLength: 0)

            Image(systemName: clip.kind.symbolName)
                .font(.system(size: 15, weight: .semibold))
                .foregroundStyle(.white)
                .frame(width: 30, height: 30)
                .background(.white.opacity(0.22))
                .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
        }
        .padding(.horizontal, 12)
        .frame(height: 62)
        .frame(maxWidth: .infinity)
        .background(
            LinearGradient(
                colors: [clip.kind.accent, clip.kind.accent.opacity(0.82)],
                startPoint: .top,
                endPoint: .bottom
            )
        )
    }

    private var content: some View {
        VStack(alignment: .leading, spacing: 0) {
            if clip.isSensitive {
                sensitiveBody
            } else {
                Text(clip.content)
                    .font(isMonospaced ? .system(size: 12, design: .monospaced) : .system(size: 13))
                    .foregroundStyle(.primary)
                    .lineLimit(8)
                    .truncationMode(.tail)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }

            Spacer(minLength: 8)

            footer
        }
        .padding(12)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
    }

    private var sensitiveBody: some View {
        VStack(alignment: .leading, spacing: 8) {
            Image(systemName: "lock.fill")
                .font(.system(size: 18, weight: .semibold))
                .foregroundStyle(.orange)

            Text("敏感内容已隐藏")
                .font(.system(size: 13, weight: .medium))
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private var footer: some View {
        HStack(spacing: 6) {
            Text(clip.source)
                .font(.system(size: 11))
                .foregroundStyle(.tertiary)
                .lineLimit(1)

            Spacer(minLength: 4)

            Button(action: onTogglePin) {
                let pinIcon = Image(systemName: clip.isPinned ? "pin.fill" : "pin")
                    .font(.system(size: 12, weight: .semibold))

                if clip.isPinned {
                    pinIcon.foregroundStyle(Color.accentColor)
                } else {
                    pinIcon.foregroundStyle(.tertiary)
                }
            }
            .buttonStyle(.plain)
            .accessibilityLabel(clip.isPinned ? "取消固定" : "固定")
        }
    }
}

#Preview {
    HStack(spacing: 14) {
        ClipCardView(clip: MockClips.all[0], isSelected: true, onSelect: {}, onActivate: {}, onTogglePin: {})
        ClipCardView(clip: MockClips.all[3], isSelected: false, onSelect: {}, onActivate: {}, onTogglePin: {})
        ClipCardView(clip: MockClips.all[6], isSelected: false, onSelect: {}, onActivate: {}, onTogglePin: {})
    }
    .padding(40)
    .background(.regularMaterial)
}
