import AppKit
import SwiftUI

/// Paste 式剪贴板卡片：彩色头部（类型 + 时间 + 类型图标）+ 白色正文（文本/图片/文件/富文本预览 + 来源 + pin）。
/// 选中态：抬起放大 + accentColor 描边 + 更强阴影。
struct ClipCardView: View {
    let clip: ClipItem
    let isSelected: Bool
    let onSelect: () -> Void
    let onActivate: () -> Void
    let onTogglePin: () -> Void

    /// 上次点击时间，用于自己判断双击，避免 SwiftUI 单/双击消歧带来的选中延迟。
    @State private var lastTapTime = Date.distantPast
    @State private var isHovering = false
    /// 附件型懒加载：图片缩略图 / 富文本富排版，从 blob 读出后缓存。
    @State private var loadedImage: NSImage?
    @State private var loadedRichText: AttributedString?

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
                              lineWidth: isSelected ? 2 : 1)
        }
        .shadow(color: .black.opacity(0.05), radius: 1, y: 1)
        .shadow(color: .black.opacity(0.07), radius: 6, y: 3)
        .contentShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
        .onHover { isHovering = $0 }
        .animation(.easeOut(duration: 0.12), value: isHovering)
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
                    .font(.headline)
                    .foregroundStyle(.white)

                Text(timeText)
                    .font(.caption)
                    .foregroundStyle(.white.opacity(0.85))
                    .monospacedDigit()
            }

            Spacer(minLength: 0)

            Image(systemName: clip.kind.symbolName)
                .font(.system(size: 14, weight: .semibold))
                .foregroundStyle(.white)
                .frame(width: 26, height: 26)
                .background(.white.opacity(0.16), in: Circle())
        }
        .padding(.horizontal, 12)
        .frame(height: 62)
        .frame(maxWidth: .infinity)
        .background {
            LinearGradient(
                colors: [clip.kind.accent, clip.kind.accent.opacity(0.82)],
                startPoint: .top,
                endPoint: .bottom
            )
            .overlay(alignment: .top) {
                LinearGradient(
                    colors: [.white.opacity(0.22), .clear],
                    startPoint: .top,
                    endPoint: .bottom
                )
                .frame(height: 26)
            }
        }
    }

    private var content: some View {
        VStack(alignment: .leading, spacing: 0) {
            bodyContent

            Spacer(minLength: 8)

            footer
        }
        .padding(12)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .onAppear(perform: loadAttachmentIfNeeded)
    }

    @ViewBuilder
    private var bodyContent: some View {
        if clip.isSensitive {
            sensitiveBody
        } else {
            switch clip.kind {
            case .image:
                imageBody
            case .file:
                fileBody
            case .richText:
                richTextBody
            default:
                textBody
            }
        }
    }

    private var textBody: some View {
        Text(clip.content)
            .font(isMonospaced ? .system(.body, design: .monospaced) : .body)
            .foregroundStyle(.primary)
            .lineSpacing(2)
            .lineLimit(8)
            .truncationMode(.tail)
            .frame(maxWidth: .infinity, alignment: .leading)
    }

    @ViewBuilder
    private var imageBody: some View {
        if let loadedImage {
            Image(nsImage: loadedImage)
                .resizable()
                .aspectRatio(contentMode: .fill)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
        } else {
            Image(systemName: "photo")
                .font(.largeTitle)
                .symbolRenderingMode(.hierarchical)
                .foregroundStyle(.tertiary)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
    }

    private var fileBody: some View {
        let firstPath = clip.content.split(whereSeparator: \.isNewline).first.map(String.init) ?? ""
        return HStack(alignment: .top, spacing: 10) {
            Image(nsImage: NSWorkspace.shared.icon(forFile: firstPath))
                .resizable()
                .frame(width: 40, height: 40)

            VStack(alignment: .leading, spacing: 2) {
                Text(clip.title)
                    .font(.callout)
                    .foregroundStyle(.primary)
                    .lineLimit(2)

                Text(firstPath)
                    .font(.caption2)
                    .foregroundStyle(.secondary)
                    .lineLimit(2)
                    .truncationMode(.middle)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    @ViewBuilder
    private var richTextBody: some View {
        if let loadedRichText {
            Text(loadedRichText)
                .lineSpacing(2)
                .lineLimit(8)
                .truncationMode(.tail)
                .frame(maxWidth: .infinity, alignment: .leading)
        } else {
            textBody
        }
    }

    /// 从 blob 懒加载图片缩略图 / 富文本富排版（仅附件型，小附件主线程读取即可）。
    private func loadAttachmentIfNeeded() {
        guard let filename = clip.attachmentFilename else {
            return
        }

        switch clip.kind {
        case .image where loadedImage == nil:
            loadedImage = ClipBlobStore.read(filename: filename).flatMap { NSImage(data: $0) }
        case .richText where loadedRichText == nil:
            if
                let data = ClipBlobStore.read(filename: filename),
                let ns = try? NSAttributedString(
                    data: data,
                    options: [.documentType: NSAttributedString.DocumentType.rtf],
                    documentAttributes: nil
                )
            {
                loadedRichText = AttributedString(ns)
            }
        default:
            break
        }
    }

    private var sensitiveBody: some View {
        VStack(alignment: .leading, spacing: 8) {
            Image(systemName: "lock.fill")
                .font(.system(size: 18, weight: .semibold))
                .foregroundStyle(.orange)

            Text("敏感内容已隐藏")
                .font(.callout)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private var footer: some View {
        HStack(spacing: 6) {
            Text(clip.source)
                .font(.caption2)
                .foregroundStyle(.tertiary)
                .lineLimit(1)

            Spacer(minLength: 4)

            Button(action: onTogglePin) {
                Image(systemName: clip.isPinned ? "pin.fill" : "pin")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(clip.isPinned ? Color.accentColor : Color.secondary)
                    .symbolEffect(.bounce, value: clip.isPinned)
            }
            .buttonStyle(.plain)
            .opacity(clip.isPinned || isHovering || isSelected ? 1 : 0)
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
