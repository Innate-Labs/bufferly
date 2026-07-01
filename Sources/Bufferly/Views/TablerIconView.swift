import AppKit
import SwiftUI

struct TablerIconView: View {
    let name: String
    let fallbackSystemName: String

    var body: some View {
        if let image = TablerIconCache.image(named: name) {
            Image(nsImage: image)
                .resizable()
                .renderingMode(.template)
                .aspectRatio(contentMode: .fit)
        } else {
            Image(systemName: fallbackSystemName)
                .resizable()
                .aspectRatio(contentMode: .fit)
        }
    }
}

@MainActor
private enum TablerIconCache {
    private static var images: [String: NSImage] = [:]

    static func image(named name: String) -> NSImage? {
        if let image = images[name] {
            return image
        }

        guard
            let url = AppResources.url(
                forResource: name,
                withExtension: "svg",
                subdirectory: "TablerIcons"
            ),
            let image = NSImage(contentsOf: url)
        else {
            return nil
        }

        image.isTemplate = true
        images[name] = image
        return image
    }
}
