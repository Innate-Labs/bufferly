import AppKit
import Combine
import Foundation
import SwiftUI

@MainActor
final class QuickPanelViewModel: ObservableObject {
    /// Pinboard 分段：剪贴板（全部历史）/ 已固定。
    enum Board: String, CaseIterable, Identifiable {
        case clipboard = "剪贴板"
        case pinned = "已固定"

        var id: String { rawValue }

        var dotColor: Color {
            switch self {
            case .clipboard:
                .secondary
            case .pinned:
                .orange
            }
        }
    }

    @Published var query = ""
    @Published private(set) var clips: [ClipItem] = []
    @Published var selectedID: ClipItem.ID?
    /// 仅在键盘 / 程序性选择时设置，驱动卡片墙把目标滚入视野；鼠标点击不设置，避免点一下整排乱跑。
    @Published var scrollTarget: ClipItem.ID?
    @Published var board: Board = .clipboard {
        didSet {
            guard oldValue != board else { return }
            selectedID = filteredClips.first?.id
            scrollTarget = selectedID
        }
    }

    private var maxHistoryCount: Int {
        AppSettings.shared.maxHistoryCount
    }
    private let pasteboard: NSPasteboard
    private let clipStore: ClipStore?
    private lazy var clipboardMonitor = ClipboardMonitor(pasteboard: pasteboard) { [weak self] capture in
        self?.addCapture(capture)
    }

    init(
        pasteboard: NSPasteboard = .general,
        clipStore: ClipStore? = try? ClipStore(maxHistoryCount: AppSettings.shared.maxHistoryCount)
    ) {
        self.pasteboard = pasteboard
        self.clipStore = clipStore

        NotificationCenter.default.addObserver(
            forName: .clearHistoryRequested,
            object: nil,
            queue: .main
        ) { [weak self] notification in
            let keepPinned = (notification.userInfo?["keepPinned"] as? Bool) ?? true
            Task { @MainActor in
                self?.clearHistory(keepPinned: keepPinned)
            }
        }
    }

    var filteredClips: [ClipItem] {
        let boardClips = board == .pinned ? clips.filter(\.isPinned) : clips
        let trimmedQuery = query.trimmingCharacters(in: .whitespacesAndNewlines)

        guard !trimmedQuery.isEmpty else {
            return boardClips
        }

        return boardClips.filter { clip in
            clip.title.localizedCaseInsensitiveContains(trimmedQuery)
                || clip.preview.localizedCaseInsensitiveContains(trimmedQuery)
                || clip.content.localizedCaseInsensitiveContains(trimmedQuery)
                || clip.kind.rawValue.localizedCaseInsensitiveContains(trimmedQuery)
        }
    }

    var pinnedClips: [ClipItem] {
        filteredClips.filter(\.isPinned)
    }

    var recentClips: [ClipItem] {
        filteredClips.filter { !$0.isPinned }
    }

    var sensitiveFilteringEnabled: Bool {
        AppSettings.shared.sensitiveFiltering
    }

    var selectedClip: ClipItem? {
        guard let selectedID else {
            return filteredClips.first
        }

        return filteredClips.first { $0.id == selectedID }
    }

    func startMonitoring() {
        loadPersistedClips()
        backfillSourceBundleIDs()
        clipboardMonitor.start()
        selectFirstIfNeeded()
    }

    /// 一次性回填旧条目的来源 bundle id（功能上线前的历史没有它，导致无来源图标）。
    /// 来源 → bundle id 映射来自：已带 bundle id 的同源条目 + 当前运行的 App 名。
    private func backfillSourceBundleIDs() {
        var map: [String: String] = [:]

        for clip in clips where clip.sourceBundleID != nil {
            if map[clip.source] == nil {
                map[clip.source] = clip.sourceBundleID
            }
        }

        for app in NSWorkspace.shared.runningApplications {
            guard let name = app.localizedName, let bundleID = app.bundleIdentifier else {
                continue
            }
            if map[name] == nil {
                map[name] = bundleID
            }
        }

        var updates: [(ClipItem.ID, String)] = []
        for index in clips.indices where clips[index].sourceBundleID == nil {
            if let bundleID = map[clips[index].source] {
                clips[index].sourceBundleID = bundleID
                updates.append((clips[index].id, bundleID))
            }
        }

        guard !updates.isEmpty, let clipStore else {
            return
        }

        for (clipID, bundleID) in updates {
            do {
                try clipStore.updateSourceBundleID(clipID: clipID, bundleID: bundleID)
            } catch {
                print("Failed to backfill sourceBundleID: \(error)")
            }
        }
    }

    func addCapture(_ capture: ClipboardCapture) {
        let frontmost = NSWorkspace.shared.frontmostApplication

        // 排除特定 App：来源在排除列表内则不采集。
        if
            let bundleID = frontmost?.bundleIdentifier,
            AppSettings.shared.excludedBundleIDs.contains(bundleID)
        {
            return
        }

        let source = frontmost?.localizedName ?? "剪贴板"
        let bundleID = frontmost?.bundleIdentifier

        switch capture {
        case .text(let text):
            addText(text, source: source, bundleID: bundleID)
        case .richText(let rtf, let plain):
            addRichText(rtf: rtf, plain: plain, source: source, bundleID: bundleID)
        case .image(let png, let pixelSize):
            register(
                ClipClassifier.makeImageClip(png: png, pixelSize: pixelSize, source: source, sourceBundleID: bundleID),
                blob: png
            )
        case .files(let urls):
            guard let clip = ClipClassifier.makeFileClip(urls: urls, source: source, sourceBundleID: bundleID) else {
                return
            }
            register(clip)
        }
    }

    private func addText(_ text: String, source: String, bundleID: String?) {
        var newClip: ClipItem
        if AppSettings.shared.sensitiveFiltering, SensitiveContentFilter.isSensitive(text) {
            // 命中敏感内容：要么丢弃，要么留一个不含明文的脱敏占位。
            guard AppSettings.shared.storeSensitivePlaceholder else {
                return
            }
            newClip = ClipClassifier.makeMaskedSecret(source: source, sourceBundleID: bundleID)
        } else {
            guard let clip = ClipClassifier.makeClip(from: text, source: source, sourceBundleID: bundleID) else {
                return
            }
            newClip = clip
        }

        register(newClip)
    }

    private func addRichText(rtf: Data, plain: String, source: String, bundleID: String?) {
        // 敏感判定按纯文本走；命中则按脱敏占位处理，丢弃 RTF。
        if AppSettings.shared.sensitiveFiltering, SensitiveContentFilter.isSensitive(plain) {
            guard AppSettings.shared.storeSensitivePlaceholder else {
                return
            }
            register(ClipClassifier.makeMaskedSecret(source: source, sourceBundleID: bundleID))
            return
        }

        guard let clip = ClipClassifier.makeRichTextClip(rtf: rtf, plain: plain, source: source, sourceBundleID: bundleID) else {
            return
        }
        register(clip, blob: rtf)
    }

    /// 对选中条目套用一个转换（JSON 格式化/压缩、URL 清理），结果写回剪贴板并作为新条目。
    /// 返回是否成功（内容不适用该转换时返回 false）。
    @discardableResult
    func applyTransform(_ transform: (String) -> String?, to clipID: ClipItem.ID) -> Bool {
        guard
            let clip = clips.first(where: { $0.id == clipID }),
            !clip.isSensitive,
            !clip.kind.isAttachment,
            let result = transform(clip.content),
            let transformed = ClipClassifier.makeClip(from: result, source: clip.source)
        else {
            return false
        }

        pasteboard.clearContents()
        pasteboard.setString(result, forType: .string)
        clipboardMonitor.syncToCurrentChangeCount()
        register(transformed)
        return true
    }

    /// 去重后插入到列表头并持久化，同时把选中移到它。`blob` 为附件型的二进制数据，
    /// 仅在确为新条目时写盘（命中去重则复用已有附件，避免写孤儿文件）。
    private func register(_ clip: ClipItem, blob: Data? = nil) {
        var newClip = clip
        var isDuplicate = false

        if let existingIndex = clips.firstIndex(where: {
            $0.content == newClip.content && $0.isSensitive == newClip.isSensitive
        }) {
            var existing = clips.remove(at: existingIndex)
            existing.updatedAt = Date()
            newClip = existing
            isDuplicate = true
        }

        if !isDuplicate, let blob, let filename = newClip.attachmentFilename {
            ClipBlobStore.write(blob, filename: filename)
        }

        clips.insert(newClip, at: 0)

        if clips.count > maxHistoryCount {
            // 被裁掉的旧条目若带附件，一并清理 blob，避免磁盘泄漏。
            clips.suffix(clips.count - maxHistoryCount).forEach { pruned in
                if let filename = pruned.attachmentFilename {
                    ClipBlobStore.delete(filename: filename)
                }
            }
            clips.removeLast(clips.count - maxHistoryCount)
        }

        persist(newClip)
        selectedID = filteredClips.first?.id
        scrollTarget = selectedID
    }

    func selectNext() {
        moveSelection(offset: 1)
        scrollTarget = selectedID
    }

    func selectPrevious() {
        moveSelection(offset: -1)
        scrollTarget = selectedID
    }

    func togglePinSelected() {
        guard let selectedClip else {
            return
        }

        togglePin(clipID: selectedClip.id)
    }

    func togglePin(clipID: ClipItem.ID) {
        guard let index = clips.firstIndex(where: { $0.id == clipID }) else {
            return
        }

        selectedID = clipID
        clips[index].isPinned.toggle()
        persistPinState(for: clips[index])
    }

    func deleteSelected() {
        guard let selectedClip else {
            return
        }

        delete(clipID: selectedClip.id)
    }

    func delete(clipID: ClipItem.ID) {
        guard let index = clips.firstIndex(where: { $0.id == clipID }) else {
            return
        }

        // 删除后把选中移到相邻项，保持键盘流不中断。
        let visibleBefore = filteredClips
        let removedVisibleIndex = visibleBefore.firstIndex(where: { $0.id == clipID })

        if let filename = clips[index].attachmentFilename {
            ClipBlobStore.delete(filename: filename)
        }
        clips.remove(at: index)
        persistDelete(clipID: clipID)

        let visibleAfter = filteredClips
        if let removedVisibleIndex {
            let nextIndex = min(removedVisibleIndex, visibleAfter.count - 1)
            selectedID = nextIndex >= 0 ? visibleAfter[nextIndex].id : nil
        } else {
            selectedID = visibleAfter.first?.id
        }
    }

    func clearHistory(keepPinned: Bool) {
        // 被清掉的条目若带附件，先删 blob。
        let removed = keepPinned ? clips.filter { !$0.isPinned } : clips
        removed.forEach { clip in
            if let filename = clip.attachmentFilename {
                ClipBlobStore.delete(filename: filename)
            }
        }

        clips = keepPinned ? clips.filter(\.isPinned) : []
        selectedID = filteredClips.first?.id

        guard let clipStore else {
            return
        }

        do {
            try clipStore.clear(keepPinned: keepPinned)
        } catch {
            print("Failed to clear history: \(error)")
        }
    }

    @discardableResult
    func pasteSelected() -> Bool {
        guard let selectedClip, !selectedClip.isSensitive else {
            return false
        }

        pasteboard.clearContents()

        switch selectedClip.kind {
        case .image:
            guard
                let filename = selectedClip.attachmentFilename,
                let data = ClipBlobStore.read(filename: filename)
            else {
                return false
            }
            pasteboard.setData(data, forType: .png)

        case .richText:
            if
                let filename = selectedClip.attachmentFilename,
                let rtf = ClipBlobStore.read(filename: filename)
            {
                pasteboard.setData(rtf, forType: .rtf)
            }
            // 始终附带纯文本，供「纯文本粘贴」与不支持富文本的目标兜底。
            pasteboard.setString(selectedClip.content, forType: .string)

        case .file:
            let urls = selectedClip.content
                .split(separator: "\n")
                .map { URL(fileURLWithPath: String($0)) }
            guard !urls.isEmpty else {
                return false
            }
            pasteboard.writeObjects(urls as [NSURL])

        default:
            pasteboard.setString(selectedClip.content, forType: .string)
        }

        clipboardMonitor.syncToCurrentChangeCount()
        return true
    }

    func handleQueryChange() {
        selectedID = filteredClips.first?.id
        scrollTarget = selectedID
    }

    private func selectFirstIfNeeded() {
        if selectedID == nil || selectedClip == nil {
            selectedID = filteredClips.first?.id
            scrollTarget = selectedID
        }
    }

    private func loadPersistedClips() {
        guard let clipStore else {
            return
        }

        do {
            clips = try clipStore.fetchClips()
        } catch {
            print("Failed to load clips: \(error)")
        }
    }

    private func persist(_ clip: ClipItem) {
        guard let clipStore else {
            return
        }

        do {
            try clipStore.upsert(clip)
        } catch {
            print("Failed to persist clip: \(error)")
        }
    }

    private func persistPinState(for clip: ClipItem) {
        guard let clipStore else {
            return
        }

        do {
            try clipStore.updatePin(clipID: clip.id, isPinned: clip.isPinned)
        } catch {
            print("Failed to persist pin state: \(error)")
        }
    }

    private func persistDelete(clipID: ClipItem.ID) {
        guard let clipStore else {
            return
        }

        do {
            try clipStore.delete(clipID: clipID)
        } catch {
            print("Failed to delete clip: \(error)")
        }
    }

    private func moveSelection(offset: Int) {
        let visibleClips = filteredClips

        guard !visibleClips.isEmpty else {
            selectedID = nil
            return
        }

        guard let selectedID, let currentIndex = visibleClips.firstIndex(where: { $0.id == selectedID }) else {
            self.selectedID = visibleClips.first?.id
            return
        }

        let nextIndex = min(max(currentIndex + offset, 0), visibleClips.count - 1)
        self.selectedID = visibleClips[nextIndex].id
    }
}
