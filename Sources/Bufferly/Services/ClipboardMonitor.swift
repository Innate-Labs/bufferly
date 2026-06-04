import AppKit

@MainActor
final class ClipboardMonitor {
    private let pasteboard: NSPasteboard
    private let onTextChange: (String) -> Void
    private var timer: Timer?
    private var lastChangeCount: Int

    init(
        pasteboard: NSPasteboard = .general,
        onTextChange: @escaping (String) -> Void
    ) {
        self.pasteboard = pasteboard
        self.onTextChange = onTextChange
        self.lastChangeCount = pasteboard.changeCount
    }

    func start() {
        guard timer == nil else {
            return
        }

        timer = Timer.scheduledTimer(withTimeInterval: 0.35, repeats: true) { [weak self] _ in
            Task { @MainActor in
                self?.poll()
            }
        }

        if let timer {
            RunLoop.main.add(timer, forMode: .common)
        }
    }

    func stop() {
        timer?.invalidate()
        timer = nil
    }

    private func poll() {
        let changeCount = pasteboard.changeCount

        guard changeCount != lastChangeCount else {
            return
        }

        lastChangeCount = changeCount

        guard let text = pasteboard.string(forType: .string) else {
            return
        }

        onTextChange(text)
    }

    deinit {
        MainActor.assumeIsolated {
            timer?.invalidate()
        }
    }
}
