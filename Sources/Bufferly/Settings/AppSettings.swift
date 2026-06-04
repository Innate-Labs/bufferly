import Foundation

@MainActor
final class AppSettings: ObservableObject {
    static let shared = AppSettings()

    @Published var autoPasteAfterSelection: Bool {
        didSet {
            defaults.set(autoPasteAfterSelection, forKey: Keys.autoPasteAfterSelection)
        }
    }

    @Published var hideAfterPaste: Bool {
        didSet {
            defaults.set(hideAfterPaste, forKey: Keys.hideAfterPaste)
        }
    }

    @Published var maxHistoryCount: Int {
        didSet {
            let clampedValue = min(max(maxHistoryCount, 50), 2_000)
            if clampedValue != maxHistoryCount {
                maxHistoryCount = clampedValue
                return
            }

            defaults.set(maxHistoryCount, forKey: Keys.maxHistoryCount)
        }
    }

    private let defaults: UserDefaults

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults

        if defaults.object(forKey: Keys.autoPasteAfterSelection) == nil {
            defaults.set(true, forKey: Keys.autoPasteAfterSelection)
        }

        if defaults.object(forKey: Keys.hideAfterPaste) == nil {
            defaults.set(true, forKey: Keys.hideAfterPaste)
        }

        if defaults.object(forKey: Keys.maxHistoryCount) == nil {
            defaults.set(500, forKey: Keys.maxHistoryCount)
        }

        autoPasteAfterSelection = defaults.bool(forKey: Keys.autoPasteAfterSelection)
        hideAfterPaste = defaults.bool(forKey: Keys.hideAfterPaste)
        maxHistoryCount = defaults.integer(forKey: Keys.maxHistoryCount)
    }

    private enum Keys {
        static let autoPasteAfterSelection = "autoPasteAfterSelection"
        static let hideAfterPaste = "hideAfterPaste"
        static let maxHistoryCount = "maxHistoryCount"
    }
}
