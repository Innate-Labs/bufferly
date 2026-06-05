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

    /// 敏感内容过滤总开关（默认开，隐私优先）。
    @Published var sensitiveFiltering: Bool {
        didSet {
            defaults.set(sensitiveFiltering, forKey: Keys.sensitiveFiltering)
        }
    }

    /// 命中敏感内容时是否保留一个脱敏占位卡（关则直接丢弃，不入库）。
    @Published var storeSensitivePlaceholder: Bool {
        didSet {
            defaults.set(storeSensitivePlaceholder, forKey: Keys.storeSensitivePlaceholder)
        }
    }

    /// 链接预览：开启后会**联网**获取 URL 的标题与图标。默认关，守住本地优先 / 隐私优先。
    @Published var linkPreviewsEnabled: Bool {
        didSet {
            defaults.set(linkPreviewsEnabled, forKey: Keys.linkPreviewsEnabled)
        }
    }

    /// 是否已看过首次使用引导。
    @Published var hasCompletedOnboarding: Bool {
        didSet {
            defaults.set(hasCompletedOnboarding, forKey: Keys.hasCompletedOnboarding)
        }
    }

    /// 开机自启（依赖 .app 包，由 LoginItem 实际登记）。
    @Published var launchAtLogin: Bool {
        didSet {
            defaults.set(launchAtLogin, forKey: Keys.launchAtLogin)
            LoginItem.setEnabled(launchAtLogin)
        }
    }

    /// 全局呼出快捷键预设。变更后发通知让 AppDelegate 重注册。
    @Published var hotKeyPreset: HotKeyPreset {
        didSet {
            guard oldValue != hotKeyPreset else { return }
            defaults.set(hotKeyPreset.rawValue, forKey: Keys.hotKeyPreset)
            NotificationCenter.default.post(name: .hotKeyPresetDidChange, object: nil)
        }
    }

    /// 排除采集的 App bundle identifier 列表。
    @Published var excludedBundleIDs: [String] {
        didSet {
            defaults.set(excludedBundleIDs, forKey: Keys.excludedBundleIDs)
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

        if defaults.object(forKey: Keys.sensitiveFiltering) == nil {
            defaults.set(true, forKey: Keys.sensitiveFiltering)
        }

        if defaults.object(forKey: Keys.storeSensitivePlaceholder) == nil {
            defaults.set(true, forKey: Keys.storeSensitivePlaceholder)
        }

        autoPasteAfterSelection = defaults.bool(forKey: Keys.autoPasteAfterSelection)
        hideAfterPaste = defaults.bool(forKey: Keys.hideAfterPaste)
        maxHistoryCount = defaults.integer(forKey: Keys.maxHistoryCount)
        sensitiveFiltering = defaults.bool(forKey: Keys.sensitiveFiltering)
        storeSensitivePlaceholder = defaults.bool(forKey: Keys.storeSensitivePlaceholder)
        // 默认 false（缺省即关）：联网获取链接预览是 opt-in。
        linkPreviewsEnabled = defaults.bool(forKey: Keys.linkPreviewsEnabled)
        hasCompletedOnboarding = defaults.bool(forKey: Keys.hasCompletedOnboarding)
        // 以系统实际登记状态为准，避免偏好与系统不同步。
        launchAtLogin = LoginItem.isEnabled
        hotKeyPreset = HotKeyPreset(rawValue: defaults.string(forKey: Keys.hotKeyPreset) ?? "")
            ?? .optionSpace
        excludedBundleIDs = defaults.stringArray(forKey: Keys.excludedBundleIDs) ?? []
    }

    private enum Keys {
        static let autoPasteAfterSelection = "autoPasteAfterSelection"
        static let hideAfterPaste = "hideAfterPaste"
        static let maxHistoryCount = "maxHistoryCount"
        static let sensitiveFiltering = "sensitiveFiltering"
        static let storeSensitivePlaceholder = "storeSensitivePlaceholder"
        static let linkPreviewsEnabled = "linkPreviewsEnabled"
        static let hasCompletedOnboarding = "hasCompletedOnboarding"
        static let launchAtLogin = "launchAtLogin"
        static let hotKeyPreset = "hotKeyPreset"
        static let excludedBundleIDs = "excludedBundleIDs"
    }
}
