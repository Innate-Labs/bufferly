import AppKit

/// 一次剪贴板捕获的载荷。按优先级区分：文件 > 图片 > 富文本 > 纯文本。
enum ClipboardCapture {
    case text(String)
    case richText(rtf: Data, plain: String)
    case image(png: Data, pixelSize: CGSize?)
    case files([URL])
}

@MainActor
final class ClipboardMonitor {
    private let pasteboard: NSPasteboard
    private let onCapture: (ClipboardCapture) -> Void
    private var timer: Timer?
    private var lastChangeCount: Int

    init(
        pasteboard: NSPasteboard = .general,
        onCapture: @escaping (ClipboardCapture) -> Void
    ) {
        self.pasteboard = pasteboard
        self.onCapture = onCapture
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

    func syncToCurrentChangeCount() {
        lastChangeCount = pasteboard.changeCount
    }

    /// 立即检查一次剪贴板（呼出面板时调用），消除轮询间隔导致的「最新一条还没进来」。
    func checkNow() {
        poll()
    }

    private func poll() {
        let changeCount = pasteboard.changeCount

        guard changeCount != lastChangeCount else {
            return
        }

        lastChangeCount = changeCount

        guard let capture = readCapture() else {
            return
        }

        onCapture(capture)
    }

    /// 按优先级读取剪贴板：文件 > 图片 > 富文本 > 纯文本。
    private func readCapture() -> ClipboardCapture? {
        // 1) 文件 URL（Finder 复制文件）。
        if
            let urls = pasteboard.readObjects(
                forClasses: [NSURL.self],
                options: [.urlReadingFileURLsOnly: true]
            ) as? [URL],
            !urls.isEmpty
        {
            return .files(urls)
        }

        // 2) 图片：优先 PNG，否则把 TIFF 转成 PNG 统一存储。
        if let image = readImage() {
            return image
        }

        // 3) 富文本（RTF）：连同纯文本兜底一起带上。
        if
            let rtf = pasteboard.data(forType: .rtf),
            let plain = pasteboard.string(forType: .string),
            !plain.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
        {
            return .richText(rtf: rtf, plain: plain)
        }

        // 4) 纯文本。
        if let text = pasteboard.string(forType: .string) {
            return .text(text)
        }

        return nil
    }

    private func readImage() -> ClipboardCapture? {
        let pngData: Data
        var pixelSize: CGSize?

        if let png = pasteboard.data(forType: .png) {
            pngData = png
            if let rep = NSBitmapImageRep(data: png) {
                pixelSize = CGSize(width: rep.pixelsWide, height: rep.pixelsHigh)
            }
        } else if
            let tiff = pasteboard.data(forType: .tiff),
            let rep = NSBitmapImageRep(data: tiff),
            let png = rep.representation(using: .png, properties: [:])
        {
            pngData = png
            pixelSize = CGSize(width: rep.pixelsWide, height: rep.pixelsHigh)
        } else {
            return nil
        }

        return .image(png: pngData, pixelSize: pixelSize)
    }

    deinit {
        MainActor.assumeIsolated {
            timer?.invalidate()
        }
    }
}
