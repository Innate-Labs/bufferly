import AppKit
import LinkPresentation

/// 链接预览抓取。仅在用户开启「链接预览」时调用——会**联网**请求目标 URL。
///
/// 并发安全：抓取在 nonisolated 上下文跑，只把可 Sendable 的结果（标题 String + 图标 PNG Data）
/// 跨回主线程，避免把非 Sendable 的 LPLinkMetadata / NSImage 带过 actor 边界。
enum LinkPreview {
    struct Result: Sendable {
        let title: String?
        let iconPNG: Data?
    }

    /// 进程内缓存，避免同一 URL 反复联网。
    @MainActor private static var cache: [String: Result] = [:]

    @MainActor
    static func cached(for key: String) -> Result? {
        cache[key]
    }

    @MainActor
    static func store(_ result: Result, for key: String) {
        cache[key] = result
    }

    nonisolated static func fetch(_ url: URL) async -> Result? {
        let provider = LPMetadataProvider()
        provider.shouldFetchSubresources = true
        provider.timeout = 8

        guard let metadata = try? await provider.startFetchingMetadata(for: url) else {
            return nil
        }

        let title = metadata.title
        var iconPNG: Data?
        if let iconProvider = metadata.iconProvider {
            iconPNG = await loadIconPNG(from: iconProvider)
        }

        return Result(title: title, iconPNG: iconPNG)
    }

    /// 把 item provider 里的图标读成 PNG Data（Sendable），在闭包内完成 NSImage→Data 转换。
    nonisolated private static func loadIconPNG(from provider: NSItemProvider) async -> Data? {
        guard provider.canLoadObject(ofClass: NSImage.self) else {
            return nil
        }

        return await withCheckedContinuation { (continuation: CheckedContinuation<Data?, Never>) in
            _ = provider.loadObject(ofClass: NSImage.self) { object, _ in
                guard
                    let image = object as? NSImage,
                    let tiff = image.tiffRepresentation,
                    let rep = NSBitmapImageRep(data: tiff),
                    let png = rep.representation(using: .png, properties: [:])
                else {
                    continuation.resume(returning: nil)
                    return
                }
                continuation.resume(returning: png)
            }
        }
    }
}
