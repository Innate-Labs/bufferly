import Foundation

enum AppResources {
    static func url(forResource name: String, withExtension extensionName: String) -> URL? {
        if let url = Bundle.main.url(forResource: name, withExtension: extensionName) {
            return url
        }

        if
            let resourceBundle = Bundle(
                url: Bundle.main.bundleURL.appendingPathComponent("Bufferly_Bufferly.bundle", isDirectory: true)
            ),
            let url = resourceBundle.url(forResource: name, withExtension: extensionName)
        {
            return url
        }

        return Bundle.module.url(forResource: name, withExtension: extensionName)
    }
}
