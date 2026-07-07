import AppKit
import SwiftUI

struct SettingsView: View {
    @ObservedObject var settings: AppSettings
    @ObservedObject var eventPostingPermission: EventPostingPermission
    @State private var permissionRequestMessage: String?

    init(
        settings: AppSettings,
        eventPostingPermission: EventPostingPermission = .shared
    ) {
        self.settings = settings
        self.eventPostingPermission = eventPostingPermission
    }

    var body: some View {
        Form {
            trustSummarySection
            shortcutsSection
            pasteBehaviorSection
            privacySection
            historySection
            appearanceSection
        }
        .formStyle(.grouped)
        .padding(20)
        .frame(width: 620, height: 700)
        .onAppear {
            eventPostingPermission.refresh()
        }
    }

    // MARK: - 信任摘要

    private var trustSummarySection: some View {
        Section("信任与存储") {
            statusRow(
                title: "存储范围",
                value: "仅本机",
                systemImage: "internaldrive.fill",
                tint: .green
            )

            statusRow(
                title: "联网行为",
                value: settings.linkPreviewsEnabled ? "链接预览" : "不联网",
                systemImage: settings.linkPreviewsEnabled ? "globe" : "wifi.slash",
                tint: settings.linkPreviewsEnabled ? .orange : .green
            )

            statusRow(
                title: "历史保留",
                value: "\(settings.historyRetention.displayName) / \(settings.maxHistoryCount) 条",
                systemImage: "clock.arrow.circlepath",
                tint: .secondary
            )

            statusRow(
                title: "不记录 App",
                value: "\(settings.excludedBundleIDs.count) 个",
                systemImage: "eye.slash.fill",
                tint: .green
            )

            Text("剪贴板历史只保存在本机的数据库文件里；Bufferly 不做云同步，不把内容上传到任何服务器。链接预览关闭时，复制链接也不会联网获取标题或图标。")
                .font(.footnote)
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
                .font(.footnote)
                .foregroundStyle(.orange)
            }

            if let error = settings.hotKeyRegistrationError {
                Label(error, systemImage: "exclamationmark.triangle.fill")
                    .font(.footnote)
                    .foregroundStyle(.orange)
            }

            LabeledContent("面板内") {
                Text("←→ 选择 · 空格预览 · Return 粘贴 · ⌥Return 仅复制 · ⌘Return 纯文本 · ⌘P 固定 · ⌘⌫ 删除 · ⌘1/⌘2 切换分区")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.trailing)
            }
        }
    }

    /// 设置项 + 下方一行说明的统一排版。
    @ViewBuilder
    private func settingRow<Control: View>(_ caption: String, @ViewBuilder control: () -> Control) -> some View {
        VStack(alignment: .leading, spacing: 5) {
            control()
            Text(caption)
                .font(.footnote)
                .foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)
        }
    }

    // MARK: - 粘贴行为

    private var pasteBehaviorSection: some View {
        Section("粘贴行为") {
            settingRow("“只复制到剪贴板”只更新系统剪贴板；“复制后粘贴到上一应用”会回到刚才的 App 并模拟一次 ⌘V。") {
                Picker("按 Return 后", selection: $settings.autoPasteAfterSelection) {
                    Text("只复制到剪贴板").tag(false)
                    Text("复制后粘贴到上一应用").tag(true)
                }
                .pickerStyle(.menu)
            }

            settingRow("复制或粘贴完成后自动收起面板，回到你刚才的窗口。") {
                Toggle("完成后关闭面板", isOn: $settings.hideAfterPaste)
            }

            pasteBackStatusRow

            if settings.autoPasteAfterSelection && !eventPostingPermission.isGranted {
                Label("当前会先复制到剪贴板；授权后才会粘贴到上一应用。", systemImage: "info.circle")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            }

            if let permissionRequestMessage, !eventPostingPermission.isGranted {
                Label(permissionRequestMessage, systemImage: "arrow.up.forward.app")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            }

            HStack {
                Button {
                    requestPasteBackPermission()
                } label: {
                    Label("请求授权", systemImage: "hand.raised")
                }
                .disabled(eventPostingPermission.isGranted)

                Button {
                    refreshPasteBackPermission()
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

    private var pasteBackStatusRow: some View {
        VStack(alignment: .leading, spacing: 5) {
            LabeledContent("粘贴到上一应用权限") {
                Label(
                    pasteBackPermissionTitle,
                    systemImage: pasteBackPermissionSymbol
                )
                .foregroundStyle(pasteBackPermissionTint)
            }

            Text(pasteBackPermissionCaption)
                .font(.footnote)
                .foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)
        }
    }

    private var pasteBackPermissionTitle: String {
        if !settings.autoPasteAfterSelection {
            return "未启用"
        }

        return eventPostingPermission.isGranted ? "已允许" : "需要授权"
    }

    private var pasteBackPermissionCaption: String {
        if !settings.autoPasteAfterSelection {
            return "当前 Return 只复制到剪贴板，不需要辅助功能权限。"
        }

        if eventPostingPermission.isGranted {
            return "Return 会复制内容，并尝试回到刚才的 App 自动按 ⌘V。"
        }

        return "未授权时 Return 会退回为只复制；授权后才会粘贴到上一应用。"
    }

    private var pasteBackPermissionSymbol: String {
        if !settings.autoPasteAfterSelection {
            return "minus.circle"
        }

        return eventPostingPermission.isGranted ? "checkmark.circle.fill" : "exclamationmark.triangle.fill"
    }

    private var pasteBackPermissionTint: Color {
        if !settings.autoPasteAfterSelection {
            return .secondary
        }

        return eventPostingPermission.isGranted ? .green : .orange
    }

    // MARK: - 隐私

    private var privacySection: some View {
        Section("隐私") {
            settingRow("自动识别密码、验证码、密钥等敏感信息，不把原文存进历史。") {
                Toggle("敏感内容保护", isOn: $settings.sensitiveFiltering)
            }

            settingRow("识别到敏感信息时留一张提示卡片（不保存内容本身）；关闭后则完全不记录。") {
                Toggle("保留提示卡片（不保存内容）", isOn: $settings.storeSensitivePlaceholder)
                    .disabled(!settings.sensitiveFiltering)
            }

            settingRow("开启后会联网获取链接的标题与图标，显示在卡片上。默认关闭以保护隐私。") {
                Toggle("链接预览", isOn: $settings.linkPreviewsEnabled)
            }

            excludedAppsRow
        }
    }

    private func statusRow(
        title: String,
        value: String,
        systemImage: String,
        tint: Color
    ) -> some View {
        LabeledContent(title) {
            Label(value, systemImage: systemImage)
                .symbolRenderingMode(.hierarchical)
                .foregroundStyle(tint, .secondary)
        }
    }

    private var excludedAppsRow: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text("排除的 App")
                Spacer()
                Button("恢复建议") {
                    restoreRecommendedExcludedApps()
                }
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
                .font(.footnote)
                .foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)

            if settings.excludedBundleIDs.isEmpty {
                Text("当前没有排除任何 App。")
                    .font(.footnote)
                    .foregroundStyle(.tertiary)
            } else {
                ForEach(settings.excludedBundleIDs, id: \.self) { bundleID in
                    HStack {
                        Text(appName(for: bundleID))
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

    // MARK: - 历史保留

    private var historySection: some View {
        Section("历史保留") {
            settingRow("未固定内容会按这个时间自动过期；已固定内容不会因为时间过期被删除。") {
                Picker("保留时长", selection: $settings.historyRetention) {
                    ForEach(HistoryRetention.allCases) { retention in
                        Text(retention.displayName).tag(retention)
                    }
                }
                .pickerStyle(.menu)
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

            clearHistoryRow

            settingRow("你的剪贴板历史只保存在这个本地数据库文件里，不上传云端、不联网同步。") {
                LabeledContent("存储位置") {
                    VStack(alignment: .trailing, spacing: 6) {
                        Text(ClipStore.databasePath ?? "暂时无法访问")
                            .foregroundStyle(.secondary)
                            .lineLimit(2)
                            .multilineTextAlignment(.trailing)

                        Button {
                            revealDatabaseInFinder()
                        } label: {
                            Label("在 Finder 中显示", systemImage: "folder")
                        }
                        .disabled(ClipStore.databasePath == nil)
                    }
                }
            }
        }
    }

    // MARK: - 外观

    private var appearanceSection: some View {
        Section("外观与启动") {
            settingRow("登录 macOS 后自动启动 Bufferly 并常驻后台。") {
                Toggle("开机自动启动", isOn: $settings.launchAtLogin)
            }

            LabeledContent("界面外观") {
                Text("跟随系统 Light / Dark、Reduce Transparency 与 Reduce Motion。")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.trailing)
            }
        }
    }

    private var clearHistoryRow: some View {
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
                .font(.footnote)
                .foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)
        }
    }

    // MARK: - 排除 App 辅助

    private struct RunningApp {
        let name: String
        let bundleID: String
    }

    private static let knownAppNames: [String: String] = [
        "com.apple.keychainaccess": "Keychain Access",
        "com.apple.Passwords": "Passwords",
        "com.1password.1password": "1Password",
        "com.agilebits.onepassword7": "1Password 7",
        "com.bitwarden.desktop": "Bitwarden",
        "com.lastpass.LastPass": "LastPass",
        "com.dashlane.dashlanephonefinal": "Dashlane",
        "com.nordpass.NordPass": "NordPass",
        "me.proton.pass": "Proton Pass",
        "com.roboform.mac": "RoboForm"
    ]

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

        return Self.knownAppNames[bundleID] ?? bundleID
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

    private func restoreRecommendedExcludedApps() {
        var bundleIDs = settings.excludedBundleIDs
        for bundleID in AppSettings.recommendedExcludedBundleIDs where !bundleIDs.contains(bundleID) {
            bundleIDs.append(bundleID)
        }
        settings.excludedBundleIDs = bundleIDs
    }

    private func requestClearHistory(keepPinned: Bool) {
        NotificationCenter.default.post(
            name: .clearHistoryRequested,
            object: nil,
            userInfo: ["keepPinned": keepPinned]
        )
    }

    private func requestPasteBackPermission() {
        let granted = eventPostingPermission.requestAccess()
        eventPostingPermission.refresh()

        if granted || eventPostingPermission.isGranted {
            permissionRequestMessage = nil
            return
        }

        permissionRequestMessage = "如果没有弹窗，请在打开的系统设置中允许 Bufferly，授权后点刷新。"
        eventPostingPermission.openPrivacySettings()
    }

    private func refreshPasteBackPermission() {
        eventPostingPermission.refresh()
        if eventPostingPermission.isGranted {
            permissionRequestMessage = nil
        }
    }

    private func revealDatabaseInFinder() {
        guard let path = ClipStore.databasePath else { return }
        NSWorkspace.shared.activateFileViewerSelecting([URL(fileURLWithPath: path)])
    }
}

#Preview {
    SettingsView(settings: AppSettings())
}
