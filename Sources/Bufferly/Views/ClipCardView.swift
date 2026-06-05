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
    @State private var isPressed = false
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    /// 附件型懒加载：图片缩略图 / 富文本富排版，从 blob 读出后缓存。
    @State private var loadedImage: NSImage?
    @State private var loadedRichText: AttributedString?
    /// 来源 App 图标，从 bundle id 解析后缓存。
    @State private var sourceIcon: NSImage?
    /// 链接预览（仅 URL 且用户开启时联网抓取）。
    @State private var linkTitle: String?
    @State private var linkIcon: NSImage?

    static let width: CGFloat = 208
    static let height: CGFloat = 272

    private var isMonospaced: Bool {
        clip.kind == .code || clip.kind == .json || clip.kind == .command
    }

    private var timeText: String {
        clip.relativeTime == "刚刚" ? "刚刚" : clip.relativeTime + "前"
    }

    /// 缩放：按下轻微下压、选中浮起、悬停微抬；Reduce Motion 下一律不缩放。
    private var cardScale: CGFloat {
        if reduceMotion { return 1 }
        if isPressed { return 0.97 }
        if isSelected { return 1.03 }
        if isHovering { return 1.02 }
        return 1
    }

    private var shadowRadius: CGFloat {
        if isSelected { return 12 }
        if isHovering { return 9 }
        return 6
    }

    private var shadowOpacity: Double {
        if isSelected { return 0.16 }
        if isHovering { return 0.12 }
        return 0.07
    }

    /// 点击时的按下脉冲：快速下压再弹回，给"点了有反应"的反馈（不新增手势，避免与横向滚动冲突）。
    private func triggerPressPulse() {
        guard !reduceMotion else { return }
        isPressed = true
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.09) {
            isPressed = false
        }
    }

    var body: some View {
        VStack(spacing: 0) {
            header
            content
        }
        .frame(width: Self.width, height: Self.height)
        .background(Color(nsColor: .textBackgroundColor))
        // 先把彩色头部 + 白色正文 + 白底压成一层再裁切，避免圆角处层间抗锯齿缝隙漏出白边。
        .compositingGroup()
        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .strokeBorder(isSelected ? Color.accentColor : Color.primary.opacity(0.08),
                              lineWidth: isSelected ? 2 : 1)
        }
        .scaleEffect(cardScale)
        .shadow(color: .black.opacity(0.05), radius: 1, y: 1)
        .shadow(color: .black.opacity(shadowOpacity), radius: shadowRadius, y: isSelected ? 6 : 3)
        .contentShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
        .onHover { isHovering = $0 }
        .animation(reduceMotion ? nil : .snappy(duration: 0.22), value: isHovering)
        .animation(reduceMotion ? nil : .snappy(duration: 0.22), value: isSelected)
        .animation(reduceMotion ? nil : .snappy(duration: 0.13), value: isPressed)
        .onTapGesture {
            triggerPressPulse()
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
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundStyle(.white)

                Text(timeText)
                    .font(.caption2)
                    .foregroundStyle(.white.opacity(0.8))
                    .monospacedDigit()
            }

            Spacer(minLength: 0)

            Image(systemName: clip.kind.symbolName)
                .font(.system(size: 13, weight: .semibold))
                .foregroundStyle(.white)
                .frame(width: 24, height: 24)
                .background(.white.opacity(0.16), in: Circle())
        }
        .padding(.horizontal, 14)
        .frame(height: 52)
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
                .frame(height: 22)
            }
        }
    }

    private var content: some View {
        VStack(alignment: .leading, spacing: 0) {
            bodyContent

            Spacer(minLength: 8)

            footer
        }
        .padding(14)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .onAppear {
            loadAttachmentIfNeeded()
            loadSourceIcon()
            loadLinkPreviewIfNeeded()
        }
    }

    /// 抓取链接预览：仅当是 URL、用户开启了链接预览、且尚未加载时。命中缓存直接用，否则联网。
    private func loadLinkPreviewIfNeeded() {
        guard
            clip.kind == .url,
            AppSettings.shared.linkPreviewsEnabled,
            linkTitle == nil, linkIcon == nil,
            let url = URL(string: clip.content)
        else {
            return
        }

        if let cached = LinkPreview.cached(for: clip.content) {
            applyLinkResult(cached)
            return
        }

        Task {
            guard let result = await LinkPreview.fetch(url) else { return }
            LinkPreview.store(result, for: clip.content)
            applyLinkResult(result)
        }
    }

    private func applyLinkResult(_ result: LinkPreview.Result) {
        if let title = result.title, !title.isEmpty {
            linkTitle = title
        }
        if let data = result.iconPNG {
            linkIcon = NSImage(data: data)
        }
    }

    /// 从 bundle id 解析来源 App 图标。
    private func loadSourceIcon() {
        guard
            sourceIcon == nil,
            let bundleID = clip.sourceBundleID,
            let url = NSWorkspace.shared.urlForApplication(withBundleIdentifier: bundleID)
        else {
            return
        }
        sourceIcon = NSWorkspace.shared.icon(forFile: url.path)
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
            case .url:
                urlBody
            default:
                textBody
            }
        }
    }

    private var textBody: some View {
        Text(clip.content)
            .font(isMonospaced ? .system(.body, design: .monospaced) : .body)
            .foregroundStyle(.primary)
            .lineSpacing(3)
            .lineLimit(9)
            .truncationMode(.tail)
            .frame(maxWidth: .infinity, alignment: .leading)
    }

    @ViewBuilder
    private var imageBody: some View {
        if let loadedImage {
            // 用 .fit 完整显示整图（不裁切），letterbox 区域给一层极淡底衬托。
            Image(nsImage: loadedImage)
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .background(Color.primary.opacity(0.04))
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
                .lineSpacing(3)
                .lineLimit(9)
                .truncationMode(.tail)
                .frame(maxWidth: .infinity, alignment: .leading)
        } else {
            textBody
        }
    }

    /// URL：抓到链接预览（开启时）就显示 favicon + 标题 + 链接，否则退回纯文本。
    @ViewBuilder
    private var urlBody: some View {
        if linkTitle != nil || linkIcon != nil {
            VStack(alignment: .leading, spacing: 8) {
                HStack(alignment: .top, spacing: 6) {
                    if let linkIcon {
                        Image(nsImage: linkIcon)
                            .resizable()
                            .frame(width: 16, height: 16)
                            .clipShape(RoundedRectangle(cornerRadius: 3, style: .continuous))
                    }

                    Text(linkTitle ?? clip.content)
                        .font(.callout.weight(.medium))
                        .foregroundStyle(.primary)
                        .lineLimit(3)
                }

                Text(clip.content)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .lineLimit(2)
                    .truncationMode(.middle)
            }
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
        HStack(spacing: 5) {
            if let sourceIcon {
                Image(nsImage: sourceIcon)
                    .resizable()
                    .frame(width: 14, height: 14)
            }

            Text(clip.source)
                .font(.caption2)
                .foregroundStyle(.secondary)
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
