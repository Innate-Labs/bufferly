import AppKit
import SwiftUI

/// Paste 式剪贴板卡片：彩色头部（类型 + 时间 + 类型图标）+ 正文预览 + 来源 + pin。
/// 卡片不绘制选中态；最新信息由卡片顺序表达。
struct ClipCardView: View {
    let clip: ClipItem
    let searchQuery: String
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
    private static let cornerRadius: CGFloat = 14

    init(
        clip: ClipItem,
        searchQuery: String = "",
        onSelect: @escaping () -> Void,
        onActivate: @escaping () -> Void,
        onTogglePin: @escaping () -> Void
    ) {
        self.clip = clip
        self.searchQuery = searchQuery
        self.onSelect = onSelect
        self.onActivate = onActivate
        self.onTogglePin = onTogglePin
    }

    private var isMonospaced: Bool {
        clip.kind == .code || clip.kind == .json || clip.kind == .command
    }

    private var timeText: String {
        clip.relativeTime == "刚刚" ? "刚刚" : clip.relativeTime + "前"
    }

    private var searchMatchLabel: String? {
        let trimmedQuery = searchQuery.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedQuery.isEmpty else {
            return nil
        }

        if containsQuery(clip.title, query: trimmedQuery) {
            return "标题"
        }
        if containsQuery(clip.kind.rawValue, query: trimmedQuery) {
            return "类型"
        }
        if containsQuery(clip.source, query: trimmedQuery) {
            return "来源"
        }
        if containsQuery(clip.preview, query: trimmedQuery) || containsQuery(clip.content, query: trimmedQuery) {
            return "正文"
        }

        return "相关"
    }

    /// 只在按下瞬间缩小作反馈；hover / selected 不再整体放大。
    /// 这张卡用了 compositingGroup 处理圆角抗锯齿，整体放大会把文字当纹理采样，导致发糊。
    private var pressScale: CGFloat {
        if reduceMotion { return 1 }
        return isPressed ? 0.98 : 1
    }

    private var liftOffset: CGFloat {
        if reduceMotion { return 0 }
        if isHovering { return -2 }
        return 0
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
        // 先把彩色头部 + 正文 + 白底压成一层再裁切，避免圆角处层间抗锯齿缝隙漏出白边。
        .compositingGroup()
        .clipShape(RoundedRectangle(cornerRadius: Self.cornerRadius, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: Self.cornerRadius, style: .continuous)
                .strokeBorder(Color.primary.opacity(0.08), lineWidth: 1)
        }
        .scaleEffect(pressScale)
        .offset(y: liftOffset)
        .contentShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
        .onHover { isHovering = $0 }
        .animation(reduceMotion ? nil : .snappy(duration: 0.18), value: isHovering)
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

            TablerIconView(name: clip.kind.tablerIconName, fallbackSystemName: clip.kind.symbolName)
                .foregroundStyle(.white)
                .frame(width: 14, height: 14)
                .frame(width: 24, height: 24)
                .background(.white.opacity(0.16), in: Circle())
        }
        .padding(.horizontal, 14)
        .frame(height: 52)
        .frame(maxWidth: .infinity)
        .background(clip.kind.accent)
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
            case .json:
                jsonBody
            case .command:
                commandBody
            case .code:
                codeBody
            case .email:
                emailBody
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

    private var codeBody: some View {
        HStack(alignment: .top, spacing: 9) {
            RoundedRectangle(cornerRadius: 2, style: .continuous)
                .fill(clip.kind.accent.opacity(0.28))
                .frame(width: 3)

            Text(linePreview(from: clip.content, limit: 8))
                .font(.system(.caption, design: .monospaced))
                .foregroundStyle(.primary)
                .lineSpacing(2)
                .lineLimit(8)
                .truncationMode(.tail)
                .frame(maxWidth: .infinity, alignment: .leading)
        }
    }

    private var commandBody: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 6) {
                Circle()
                    .fill(.green.opacity(0.75))
                    .frame(width: 6, height: 6)
                Circle()
                    .fill(.yellow.opacity(0.75))
                    .frame(width: 6, height: 6)
                Circle()
                    .fill(.red.opacity(0.75))
                    .frame(width: 6, height: 6)

                Spacer(minLength: 0)
            }

            Text(commandPreviewText)
                .font(.system(.caption, design: .monospaced))
                .foregroundStyle(.primary)
                .lineSpacing(2)
                .lineLimit(6)
        }
        .padding(10)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.primary.opacity(0.055), in: RoundedRectangle(cornerRadius: 9, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 9, style: .continuous)
                .strokeBorder(Color.primary.opacity(0.08), lineWidth: 1)
        }
    }

    private var jsonBody: some View {
        VStack(alignment: .leading, spacing: 7) {
            HStack(spacing: 6) {
                Text(jsonMetaText)
                    .font(.caption2.weight(.semibold))
                    .foregroundStyle(clip.kind.accent)
                    .lineLimit(1)

                Spacer(minLength: 0)

                Image(systemName: "curlybraces")
                    .font(.caption2.weight(.semibold))
                    .foregroundStyle(clip.kind.accent.opacity(0.75))
            }

            Text(linePreview(from: jsonPreviewText, limit: 8))
                .font(.system(.caption2, design: .monospaced))
                .foregroundStyle(.primary)
                .lineSpacing(2)
                .lineLimit(8)
                .truncationMode(.tail)
                .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding(10)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(clip.kind.accent.opacity(0.07), in: RoundedRectangle(cornerRadius: 9, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 9, style: .continuous)
                .strokeBorder(clip.kind.accent.opacity(0.14), lineWidth: 1)
        }
    }

    private var emailBody: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(alignment: .top, spacing: 8) {
                Image(systemName: "envelope.circle.fill")
                    .font(.title3)
                    .symbolRenderingMode(.hierarchical)
                    .foregroundStyle(clip.kind.accent)

                Text(clip.title)
                    .font(.callout.weight(.medium))
                    .foregroundStyle(.primary)
                    .lineLimit(2)
            }

            Text(clip.content)
                .font(.caption)
                .foregroundStyle(.secondary)
                .lineSpacing(2)
                .lineLimit(5)
                .truncationMode(.middle)
        }
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
            urlPreviewBody(title: linkTitle ?? urlHostText, icon: linkIcon)
        } else {
            urlPreviewBody(title: urlHostText, icon: nil)
        }
    }

    private func urlPreviewBody(title: String, icon: NSImage?) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(alignment: .top, spacing: 7) {
                if let icon {
                    Image(nsImage: icon)
                        .resizable()
                        .frame(width: 17, height: 17)
                        .clipShape(RoundedRectangle(cornerRadius: 4, style: .continuous))
                } else {
                    Image(systemName: "link.circle.fill")
                        .font(.title3)
                        .symbolRenderingMode(.hierarchical)
                        .foregroundStyle(clip.kind.accent)
                }

                Text(title)
                    .font(.callout.weight(.medium))
                    .foregroundStyle(.primary)
                    .lineLimit(3)
            }

            Text(urlPathText)
                .font(.caption)
                .foregroundStyle(.secondary)
                .lineLimit(3)
                .truncationMode(.middle)

            Text(clip.content)
                .font(.caption2)
                .foregroundStyle(.tertiary)
                .lineLimit(2)
                .truncationMode(.middle)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private var urlHostText: String {
        guard let host = urlDisplayComponents?.host else {
            return clip.title
        }

        return host.hasPrefix("www.") ? String(host.dropFirst(4)) : host
    }

    private var urlPathText: String {
        guard let components = urlDisplayComponents else {
            return clip.content
        }

        let path = components.percentEncodedPath.isEmpty ? "/" : components.percentEncodedPath
        let query = components.percentEncodedQuery.map { "?\($0)" } ?? ""
        let fragment = components.percentEncodedFragment.map { "#\($0)" } ?? ""
        let display = path + query + fragment

        return display == "/" ? "/" : display
    }

    private var urlDisplayComponents: URLComponents? {
        if let components = URLComponents(string: clip.content), components.host != nil {
            return components
        }

        return URLComponents(string: "https://\(clip.content)")
    }

    private var commandPreviewText: String {
        linePreview(from: clip.content, limit: 6, trimsWhitespace: true)
            .components(separatedBy: .newlines)
            .map { "$ \($0)" }
            .joined(separator: "\n")
    }

    private var jsonMetaText: String {
        guard let jsonObject else {
            return "JSON"
        }

        if let dictionary = jsonObject as? [String: Any] {
            return "\(dictionary.count) 个键"
        }

        if let array = jsonObject as? [Any] {
            return "\(array.count) 项"
        }

        return "JSON 值"
    }

    private var jsonPreviewText: String {
        guard let jsonObject else {
            return clip.content
        }

        if
            JSONSerialization.isValidJSONObject(jsonObject),
            let data = try? JSONSerialization.data(withJSONObject: jsonObject, options: [.prettyPrinted, .sortedKeys]),
            let text = String(data: data, encoding: .utf8)
        {
            return text
        }

        return String(describing: jsonObject)
    }

    private var jsonObject: Any? {
        guard let data = clip.content.data(using: .utf8) else {
            return nil
        }

        return try? JSONSerialization.jsonObject(with: data, options: [.fragmentsAllowed])
    }

    private func linePreview(from text: String, limit: Int, trimsWhitespace: Bool = false) -> String {
        let lines = text
            .components(separatedBy: .newlines)
            .map { trimsWhitespace ? $0.trimmingCharacters(in: .whitespaces) : $0 }
            .filter { !$0.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty }

        if lines.isEmpty {
            return text
        }

        return lines.prefix(limit).joined(separator: "\n")
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

            if let searchMatchLabel {
                Text(searchMatchLabel)
                    .font(.caption2.weight(.medium))
                    .foregroundStyle(clip.kind.accent)
                    .padding(.horizontal, 6)
                    .frame(height: 18)
                    .background(clip.kind.accent.opacity(0.1), in: Capsule())
                    .accessibilityLabel("搜索命中\(searchMatchLabel)")
            }

            Button(action: onTogglePin) {
                Image(systemName: clip.isPinned ? "pin.fill" : "pin")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(clip.isPinned ? Color.accentColor : Color.secondary)
                    .symbolEffect(.bounce, value: clip.isPinned)
            }
            .buttonStyle(.plain)
            .opacity(clip.isPinned || isHovering ? 1 : 0)
            .accessibilityLabel(clip.isPinned ? "取消固定" : "固定")
        }
    }

    private func containsQuery(_ value: String, query: String) -> Bool {
        value.range(of: query, options: [.caseInsensitive, .diacriticInsensitive]) != nil
    }
}

#Preview {
    HStack(spacing: 14) {
            ClipCardView(clip: MockClips.all[0], onSelect: {}, onActivate: {}, onTogglePin: {})
            ClipCardView(clip: MockClips.all[3], onSelect: {}, onActivate: {}, onTogglePin: {})
            ClipCardView(clip: MockClips.all[6], onSelect: {}, onActivate: {}, onTogglePin: {})
    }
    .padding(40)
    .background(.regularMaterial)
}
