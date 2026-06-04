import Carbon

/// 全局呼出快捷键预设。用预设而非任意录制，兼顾「可配置」与实现成本。
enum HotKeyPreset: String, CaseIterable, Identifiable {
    case optionSpace
    case controlSpace
    case commandShiftSpace
    case commandShiftV
    case commandOptionV

    var id: String { rawValue }

    /// 键码（Carbon 虚拟键）。
    var keyCode: UInt32 {
        switch self {
        case .optionSpace, .controlSpace, .commandShiftSpace:
            UInt32(kVK_Space)
        case .commandShiftV, .commandOptionV:
            UInt32(kVK_ANSI_V)
        }
    }

    /// Carbon 修饰键掩码。
    var carbonModifiers: UInt32 {
        switch self {
        case .optionSpace:
            UInt32(optionKey)
        case .controlSpace:
            UInt32(controlKey)
        case .commandShiftSpace:
            UInt32(cmdKey | shiftKey)
        case .commandShiftV:
            UInt32(cmdKey | shiftKey)
        case .commandOptionV:
            UInt32(cmdKey | optionKey)
        }
    }

    /// 显示文案，如 `⌥Space`。
    var displayName: String {
        switch self {
        case .optionSpace:
            "⌥Space"
        case .controlSpace:
            "⌃Space"
        case .commandShiftSpace:
            "⌘⇧Space"
        case .commandShiftV:
            "⌘⇧V"
        case .commandOptionV:
            "⌘⌥V"
        }
    }
}
