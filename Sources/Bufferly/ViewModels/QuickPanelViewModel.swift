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

    enum PasteMode {
        case original
        case plainText
    }

    @Published var query = ""
    @Published private(set) var clips: [ClipItem] = []
    @Published var selectedID: ClipItem.ID?
    @Published private(set) var isFocusVisible = false
    /// 仅在键盘 / 程序性选择时设置，驱动卡片墙把目标滚入视野；鼠标点击不设置，避免点一下整排乱跑。
    @Published var scrollTarget: ClipItem.ID?
    @Published var board: Board = .clipboard {
        didSet {
            guard oldValue != board else { return }
            selectedID = filteredClips.first?.id
            isFocusVisible = false
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

        // 各字段模糊打分，加权取最高分；分数越高越相关。
        let scored: [(clip: ClipItem, score: Int)] = boardClips.compactMap { clip in
            let candidates = [
                FuzzySearch.score(query: trimmedQuery, in: clip.title).map { $0 * 3 },
                FuzzySearch.score(query: trimmedQuery, in: clip.kind.rawValue).map { $0 * 2 },
                FuzzySearch.score(query: trimmedQuery, in: clip.source).map { $0 * 2 },
                FuzzySearch.score(query: trimmedQuery, in: clip.preview),
            ].compactMap { $0 }

            var best = candidates.max()

            // 短字段都没命中时，对正文做一次子串兜底（命中深层长文本），给低分。
            if best == nil, clip.content.range(of: trimmedQuery, options: .caseInsensitive) != nil {
                best = 1
            }

            guard let best else { return nil }
            return (clip, best)
        }

        // 分数降序；同分按更新时间降序（更近的靠前）。
        return scored
            .sorted { lhs, rhs in
                lhs.score != rhs.score ? lhs.score > rhs.score : lhs.clip.updatedAt > rhs.clip.updatedAt
            }
            .map(\.clip)
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

    var focusedClipID: ClipItem.ID? {
        isFocusVisible ? selectedID : nil
    }

    func startMonitoring() {
        loadPersistedClips()
        backfillSourceBundleIDs()
        pruneOrphanedBlobs()
        clipboardMonitor.start()
        selectFirstIfNeeded()
    }

    /// 呼出面板时主动补抓一次剪贴板，保证刚复制的内容已在列表里（不必等下一次轮询）。
    func captureLatestNow() {
        clipboardMonitor.checkNow()
    }

    func prepareForPanelShow() {
        selectedID = filteredClips.first?.id
        isFocusVisible = false
        scrollTarget = selectedID
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
            guard ClipBlobStore.write(blob, filename: filename) else {
                return
            }
        }

        clips.insert(newClip, at: 0)

        let locallyPruned = pruneInMemoryIfNeeded()
        if let persistedPruned = persist(newClip) {
            deleteAttachmentBlobs(for: locallyPruned + persistedPruned)
        }

        selectedID = filteredClips.first?.id
        isFocusVisible = false
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
        guard isFocusVisible, let selectedClip else {
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
        guard isFocusVisible, let selectedClip else {
            return
        }

        delete(clipID: selectedClip.id)
    }

    func select(clipID: ClipItem.ID, revealFocus: Bool = true) {
        selectedID = clipID
        isFocusVisible = revealFocus
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
        isFocusVisible = false

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
    func pasteSelected(mode: PasteMode = .original) -> Bool {
        guard let selectedClip, !selectedClip.isSensitive else {
            return false
        }

        if mode == .plainText {
            return pastePlainText(selectedClip)
        }

        switch selectedClip.kind {
        case .image:
            guard
                let filename = selectedClip.attachmentFilename,
                let data = ClipBlobStore.read(filename: filename)
            else {
                return false
            }
            pasteboard.clearContents()
            guard pasteboard.setData(data, forType: .png) else {
                return false
            }

        case .richText:
            var wroteRTF = false
            pasteboard.clearContents()
            if
                let filename = selectedClip.attachmentFilename,
                let rtf = ClipBlobStore.read(filename: filename)
            {
                wroteRTF = pasteboard.setData(rtf, forType: .rtf)
            }
            // 始终附带纯文本，供「纯文本粘贴」与不支持富文本的目标兜底。
            let wroteText = pasteboard.setString(selectedClip.content, forType: .string)
            guard wroteRTF || wroteText else {
                return false
            }

        case .file:
            let urls = selectedClip.content
                .split(separator: "\n")
                .map { URL(fileURLWithPath: String($0)) }
            guard !urls.isEmpty else {
                return false
            }
            pasteboard.clearContents()
            guard pasteboard.writeObjects(urls as [NSURL]) else {
                return false
            }

        default:
            return pastePlainText(selectedClip)
        }

        clipboardMonitor.syncToCurrentChangeCount()
        return true
    }

    func handleQueryChange() {
        selectedID = filteredClips.first?.id
        isFocusVisible = false
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

    private func pruneOrphanedBlobs() {
        guard let clipStore else {
            return
        }

        do {
            let activeFilenames = try clipStore.fetchAttachmentFilenames()
            ClipBlobStore.deleteOrphans(keeping: activeFilenames)
        } catch {
            print("Failed to prune orphaned blobs: \(error)")
        }
    }

    private func pruneInMemoryIfNeeded() -> [ClipItem] {
        let overflow = clips.count - maxHistoryCount

        guard overflow > 0 else {
            return []
        }

        let removable = clips
            .filter { !$0.isPinned }
            .sorted { $0.updatedAt < $1.updatedAt }
            .prefix(overflow)

        guard !removable.isEmpty else {
            return []
        }

        let removableIDs = Set(removable.map(\.id))
        clips.removeAll { removableIDs.contains($0.id) }
        return Array(removable)
    }

    private func pastePlainText(_ clip: ClipItem) -> Bool {
        guard clip.kind != .image else {
            return false
        }

        pasteboard.clearContents()
        guard pasteboard.setString(clip.content, forType: .string) else {
            return false
        }

        clipboardMonitor.syncToCurrentChangeCount()
        return true
    }

    private func deleteAttachmentBlobs(for clips: [ClipItem]) {
        for clip in clips {
            if let filename = clip.attachmentFilename {
                ClipBlobStore.delete(filename: filename)
            }
        }
    }

    @discardableResult
    private func persist(_ clip: ClipItem) -> [ClipItem]? {
        guard let clipStore else {
            return []
        }

        do {
            return try clipStore.upsert(clip)
        } catch {
            print("Failed to persist clip: \(error)")
            return nil
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
            isFocusVisible = false
            return
        }

        guard isFocusVisible else {
            selectedID = visibleClips.first?.id
            isFocusVisible = true
            return
        }

        guard let selectedID, let currentIndex = visibleClips.firstIndex(where: { $0.id == selectedID }) else {
            self.selectedID = visibleClips.first?.id
            isFocusVisible = true
            return
        }

        let nextIndex = min(max(currentIndex + offset, 0), visibleClips.count - 1)
        self.selectedID = visibleClips[nextIndex].id
    }
}
