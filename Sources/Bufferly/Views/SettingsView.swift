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
            Toggle("开机自动启动", isOn: $settings.launchAtLogin)
            Toggle("粘贴后隐藏面板", isOn: $settings.hideAfterPaste)
            Toggle("选择后粘贴到上一应用", isOn: $settings.autoPasteAfterSelection)

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

    // MARK: - 快捷键

    private var shortcutsSection: some View {
        Section("快捷键") {
            Picker("呼出 / 隐藏 Bufferly", selection: $settings.hotKeyPreset) {
                ForEach(HotKeyPreset.allCases) { preset in
                    Text(preset.displayName).tag(preset)
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
            Toggle("敏感内容过滤", isOn: $settings.sensitiveFiltering)

            Toggle("保留脱敏占位（关则直接丢弃）", isOn: $settings.storeSensitivePlaceholder)
                .disabled(!settings.sensitiveFiltering)

            excludedAppsRow

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

            if settings.excludedBundleIDs.isEmpty {
                Text("剪贴板内容不会按来源 App 过滤")
                    .font(.caption)
                    .foregroundStyle(.secondary)
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
            LabeledContent("自动粘贴") {
                Label(
                    eventPostingPermission.isGranted ? "已允许" : "需要授权",
                    systemImage: eventPostingPermission.isGranted ? "checkmark.circle.fill" : "exclamationmark.triangle.fill"
                )
                .foregroundStyle(eventPostingPermission.isGranted ? .green : .orange)
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
            LabeledContent("存储位置") {
                Text(ClipStore.databasePath)
                    .foregroundStyle(.secondary)
                    .lineLimit(2)
                    .multilineTextAlignment(.trailing)
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
