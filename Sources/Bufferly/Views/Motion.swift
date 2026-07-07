import SwiftUI

/// Quick Panel 动效统一参数（DESIGN §8）：短、轻、ease-out，不用强弹簧。
/// Reduce Motion 由调用方以 `reduceMotion ? nil : Motion.xxx` 关闭。
enum Motion {
    /// 卡片按下 / 松开的缩放反馈。
    static let press = Animation.easeOut(duration: 0.13)
    /// 卡片 hover 上移与键盘脉冲上移。
    static let hover = Animation.easeOut(duration: 0.12)
    /// 键盘定位卡片滚入视野。
    static let scroll = Animation.easeOut(duration: 0.16)
    /// 覆盖层（Quick Look 预览 / 首次引导）出入场。
    static let overlay = Animation.easeOut(duration: 0.12)
    /// 状态 toast 出入场。
    static let toast = Animation.easeOut(duration: 0.16)
    /// 卡片墙增删 / 重排。
    static let listChange = Animation.easeOut(duration: 0.18)
    /// 分段控件选中 pill 滑动（cubic-bezier(0.22, 1, 0.36, 1)）。
    static let tabSlide = Animation.timingCurve(0.22, 1, 0.36, 1, duration: 0.2)
    /// 键盘落到目标卡时的瞬时上移脉冲时长（秒），动完无痕。
    static let keyboardPulseDuration: TimeInterval = 0.15
}
