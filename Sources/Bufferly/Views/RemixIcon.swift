import SwiftUI

/// 加载 Resources 里的 Remix Icon 模板图（Apache-2.0）。作为 template image，
/// 可被 foregroundStyle 着色，行为接近 SF Symbol。
struct RemixIcon: View {
    let name: String
    var size: CGFloat = 16

    var body: some View {
        Image(nsImage: Self.image(name))
            .resizable()
            .renderingMode(.template)
            .interpolation(.high)
            .frame(width: size, height: size)
    }

    private static var cache: [String: NSImage] = [:]

    static func image(_ name: String) -> NSImage {
        if let cached = cache[name] {
            return cached
        }

        let image: NSImage
        if
            let url = Bundle.module.url(forResource: name, withExtension: "png"),
            let loaded = NSImage(contentsOf: url)
        {
            loaded.isTemplate = true
            image = loaded
        } else {
            image = NSImage()
        }

        cache[name] = image
        return image
    }
}
