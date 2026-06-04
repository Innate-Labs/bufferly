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
            Section("通用") {
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

            Section("数据") {
                LabeledContent("存储位置") {
                    Text(ClipStore.databasePath)
                        .foregroundStyle(.secondary)
                        .lineLimit(2)
                        .multilineTextAlignment(.trailing)
                }
            }
        }
        .formStyle(.grouped)
        .padding(20)
        .frame(width: 560, height: 460)
        .onAppear {
            eventPostingPermission.refresh()
        }
    }
}

#Preview {
    SettingsView(settings: AppSettings())
}
