import AppKit
import SwiftUI

struct SettingsView: View {
    @ObservedObject var settings: AppSettings
    @ObservedObject var eventPostingPermission: EventPostingPermission

    init(
        settings: AppSettings,
        eventPostingPermission: EventPostingPermission = .shared
    ) {
        self.settings = settings
        self.eventPostingPermission = eventPostingPermission
    }

    var body: some View {
        Form {
            generalSection
            shortcutsSection
            privacySection
            permissionsSection
            dataSection
        }
        .formStyle(.grouped)
        .padding(20)
        .frame(width: 580, height: 560)
        .onAppear {
            eventPostingPermission.refresh()
        }
    }

    // MARK: - 通用

    private var generalSection: some View {
        Section("通用") {
            settingRow("登录 macOS 后自动启动 Bufferly 并常驻后台。") {
                Toggle("开机自动启动", isOn: $settings.launchAtLogin)
            }

            settingRow("选中条目后自动收起面板，回到你刚才的窗口。") {
                Toggle("粘贴后隐藏面板", isOn: $settings.hideAfterPaste)
            }

            settingRow("选中后自动替你按 ⌘V 贴回前台 App（需在「权限」里授权）。关闭则只写回剪贴板，由你自己按 ⌘V。") {
                Toggle("选择后粘贴到上一应用", isOn: $settings.autoPasteAfterSelection)
            }

            settingRow("历史超过这个数量时，自动删除最旧的未固定条目。") {
                Stepper(value: $settings.maxHistoryCount, in: 50...2_000, step: 50) {
                    HStack {
                        Text("最大历史数量")
                        Spacer()
                        Text("\(settings.maxHistoryCount)")
                            .foregroundStyle(.secondary)
                    }
                }
            }
        }
    }

    /// 设置项 + 下方一行说明的统一排版。
    @ViewBuilder
    private func settingRow<Control: View>(_ caption: String, @ViewBuilder control: () -> Control) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            control()
            Text(caption)
                .font(.caption)
                .foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)
        }
    }

    // MARK: - 快捷键

    private var shortcutsSection: some View {
        Section("快捷键") {
            settingRow("在任意 App 里按这个组合，呼出或收起 Bufferly 面板。") {
                Picker("呼出 / 隐藏 Bufferly", selection: $settings.hotKeyPreset) {
                    ForEach(HotKeyPreset.allCases) { preset in
                        Text(preset.displayName).tag(preset)
                    }
                }
            }

            if settings.hotKeyPreset.requiresInputMonitoring {
                Label(
                    "双击修饰键需在「系统设置 → 隐私与安全性 → 辅助功能」中允许 Bufferly，否则不会触发。",
                    systemImage: "exclamationmark.triangle.fill"
                )
                .font(.caption)
                .foregroundStyle(.orange)
            }

            LabeledContent("面板内") {
                Text("←→ 选择 · Return 粘贴 · ⌥Return 仅复制 · ⌘Return 纯文本 · ⌘P 固定 · ⌘⌫ 删除 · ⌘K 动作")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.trailing)
            }
        }
    }

    // MARK: - 隐私

    private var privacySection: some View {
        Section("隐私") {
            settingRow("自动识别 token、密码、API key、.env 值等敏感内容，避免明文存进历史。") {
                Toggle("敏感内容过滤", isOn: $settings.sensitiveFiltering)
            }

            settingRow("命中敏感内容时存一张打码占位卡（不含明文）；关闭则直接丢弃、不入库。") {
                Toggle("保留脱敏占位（关则直接丢弃）", isOn: $settings.storeSensitivePlaceholder)
                    .disabled(!settings.sensitiveFiltering)
            }

            settingRow("开启后会联网获取 URL 的标题与图标。默认关闭以保护隐私。") {
                Toggle("链接预览", isOn: $settings.linkPreviewsEnabled)
            }

            excludedAppsRow

            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text("清空历史")
                    Spacer()
                    Button("保留固定", role: .destructive) {
                        requestClearHistory(keepPinned: true)
                    }
                    Button("全部清空", role: .destructive) {
                        requestClearHistory(keepPinned: false)
                    }
                }
                Text("「保留固定」只清未固定的条目；「全部清空」连固定的一起删。删除不可恢复。")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
    }

    private var excludedAppsRow: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text("排除的 App")
                Spacer()
                Menu("添加…") {
                    if addableApps.isEmpty {
                        Text("没有可添加的 App")
                    } else {
                        ForEach(addableApps, id: \.bundleID) { app in
                            Button(app.name) {
                                addExcluded(app.bundleID)
                            }
                        }
                    }
                }
                .fixedSize()
            }

            Text("从这些 App 里复制的内容不会被 Bufferly 记录（比如密码管理器、银行 App）。")
                .font(.caption)
                .foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)

            if settings.excludedBundleIDs.isEmpty {
                Text("当前没有排除任何 App。")
                    .font(.caption)
                    .foregroundStyle(.tertiary)
            } else {
                ForEach(settings.excludedBundleIDs, id: \.self) { bundleID in
                    HStack {
                        Text(appName(for: bundleID))
                            .font(.callout)
                        Spacer()
                        Button {
                            removeExcluded(bundleID)
                        } label: {
                            Image(systemName: "minus.circle.fill")
                                .foregroundStyle(.secondary)
                        }
                        .buttonStyle(.plain)
                        .accessibilityLabel("移除 \(appName(for: bundleID))")
                    }
                }
            }
        }
    }

    // MARK: - 权限

    private var permissionsSection: some View {
        Section("权限") {
            settingRow("允许 Bufferly 模拟 ⌘V，把内容自动粘回前台 App（即上面的「选择后粘贴到上一应用」）。未授权也能正常用——只是要你自己按 ⌘V。此权限仅用于粘贴，不做别的。") {
                LabeledContent("自动粘贴") {
                    Label(
                        eventPostingPermission.isGranted ? "已允许" : "需要授权",
                        systemImage: eventPostingPermission.isGranted ? "checkmark.circle.fill" : "exclamationmark.triangle.fill"
                    )
                    .foregroundStyle(eventPostingPermission.isGranted ? .green : .orange)
                }
            }

            HStack {
                Button {
                    eventPostingPermission.requestAccess()
                } label: {
                    Label("请求授权", systemImage: "hand.raised")
                }
                .disabled(eventPostingPermission.isGranted)

                Button {
                    eventPostingPermission.refresh()
                } label: {
                    Label("刷新", systemImage: "arrow.clockwise")
                }

                Spacer()

                Button {
                    eventPostingPermission.openPrivacySettings()
                } label: {
                    Label("打开系统设置", systemImage: "gear")
                }
                .disabled(eventPostingPermission.isGranted)
            }
        }
    }

    // MARK: - 数据

    private var dataSection: some View {
        Section("数据") {
            settingRow("你的剪贴板历史只保存在这个本地数据库文件里，不上传云端、不联网同步。") {
                LabeledContent("存储位置") {
                    Text(ClipStore.databasePath)
                        .foregroundStyle(.secondary)
                        .lineLimit(2)
                        .multilineTextAlignment(.trailing)
                }
            }
        }
    }

    // MARK: - 排除 App 辅助

    private struct RunningApp {
        let name: String
        let bundleID: String
    }

    private var addableApps: [RunningApp] {
        let selfBundleID = Bundle.main.bundleIdentifier
        var seen = Set(settings.excludedBundleIDs)

        return NSWorkspace.shared.runningApplications
            .compactMap { app -> RunningApp? in
                guard
                    app.activationPolicy == .regular,
                    let bundleID = app.bundleIdentifier,
                    bundleID != selfBundleID,
                    let name = app.localizedName
                else {
                    return nil
                }

                guard seen.insert(bundleID).inserted else {
                    return nil
                }

                return RunningApp(name: name, bundleID: bundleID)
            }
            .sorted { $0.name.localizedCaseInsensitiveCompare($1.name) == .orderedAscending }
    }

    private func appName(for bundleID: String) -> String {
        if
            let url = NSWorkspace.shared.urlForApplication(withBundleIdentifier: bundleID),
            let bundle = Bundle(url: url),
            let name = bundle.localizedInfoDictionary?["CFBundleName"] as? String
                ?? bundle.infoDictionary?["CFBundleName"] as? String
        {
            return name
        }

        return bundleID
    }

    private func addExcluded(_ bundleID: String) {
        guard !settings.excludedBundleIDs.contains(bundleID) else {
            return
        }
        settings.excludedBundleIDs.append(bundleID)
    }

    private func removeExcluded(_ bundleID: String) {
        settings.excludedBundleIDs.removeAll { $0 == bundleID }
    }

    private func requestClearHistory(keepPinned: Bool) {
        NotificationCenter.default.post(
            name: .clearHistoryRequested,
            object: nil,
            userInfo: ["keepPinned": keepPinned]
        )
    }
}

#Preview {
    SettingsView(settings: AppSettings())
}
