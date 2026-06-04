import AppKit
import Combine
import Foundation

@MainActor
final class QuickPanelViewModel: ObservableObject {
    @Published var query = ""
    @Published private(set) var clips: [ClipItem] = []
    @Published var selectedID: ClipItem.ID?

    private var maxHistoryCount: Int {
        AppSettings.shared.maxHistoryCount
    }
    private let pasteboard: NSPasteboard
    private let clipStore: ClipStore?
    private lazy var clipboardMonitor = ClipboardMonitor(pasteboard: pasteboard) { [weak self] text in
        self?.addClipboardText(text)
    }

    init(
        pasteboard: NSPasteboard = .general,
        clipStore: ClipStore? = try? ClipStore(maxHistoryCount: AppSettings.shared.maxHistoryCount)
    ) {
        self.pasteboard = pasteboard
        self.clipStore = clipStore
    }

    var filteredClips: [ClipItem] {
        let trimmedQuery = query.trimmingCharacters(in: .whitespacesAndNewlines)

        guard !trimmedQuery.isEmpty else {
            return clips
        }

        return clips.filter { clip in
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

    var selectedClip: ClipItem? {
        guard let selectedID else {
            return filteredClips.first
        }

        return filteredClips.first { $0.id == selectedID }
    }

    func startMonitoring() {
        loadPersistedClips()
        clipboardMonitor.start()
        selectFirstIfNeeded()
    }

    func addClipboardText(_ text: String) {
        guard var newClip = ClipClassifier.makeClip(from: text) else {
            return
        }

        if let existingIndex = clips.firstIndex(where: { $0.content == newClip.content }) {
            var existing = clips.remove(at: existingIndex)
            existing.updatedAt = Date()
            newClip = existing
        }

        clips.insert(newClip, at: 0)

        if clips.count > maxHistoryCount {
            clips.removeLast(clips.count - maxHistoryCount)
        }

        persist(newClip)
        selectedID = filteredClips.first?.id
    }

    func selectNext() {
        moveSelection(offset: 1)
    }

    func selectPrevious() {
        moveSelection(offset: -1)
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

    @discardableResult
    func pasteSelected() -> Bool {
        guard let selectedClip else {
            return false
        }

        pasteboard.clearContents()
        pasteboard.setString(selectedClip.content, forType: .string)
        return true
    }

    func handleQueryChange() {
        selectedID = filteredClips.first?.id
    }

    private func selectFirstIfNeeded() {
        if selectedID == nil || selectedClip == nil {
            selectedID = filteredClips.first?.id
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
