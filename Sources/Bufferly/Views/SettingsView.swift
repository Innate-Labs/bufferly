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
            Section("General") {
                Toggle("Hide panel after paste", isOn: $settings.hideAfterPaste)
                Toggle("Paste into previous app after selection", isOn: $settings.autoPasteAfterSelection)

                Stepper(value: $settings.maxHistoryCount, in: 50...2_000, step: 50) {
                    HStack {
                        Text("Max history")
                        Spacer()
                        Text("\(settings.maxHistoryCount)")
                            .foregroundStyle(.secondary)
                    }
                }
            }

            Section("Permissions") {
                LabeledContent("Paste automation") {
                    Label(
                        eventPostingPermission.isGranted ? "Allowed" : "Needs access",
                        systemImage: eventPostingPermission.isGranted ? "checkmark.circle.fill" : "exclamationmark.triangle.fill"
                    )
                    .foregroundStyle(eventPostingPermission.isGranted ? .green : .orange)
                }

                HStack {
                    Button {
                        eventPostingPermission.requestAccess()
                    } label: {
                        Label("Request Access", systemImage: "hand.raised")
                    }
                    .disabled(eventPostingPermission.isGranted)

                    Button {
                        eventPostingPermission.refresh()
                    } label: {
                        Label("Refresh", systemImage: "arrow.clockwise")
                    }

                    Spacer()

                    Button {
                        eventPostingPermission.openPrivacySettings()
                    } label: {
                        Label("Open System Settings", systemImage: "gear")
                    }
                    .disabled(eventPostingPermission.isGranted)
                }
            }

            Section("Data") {
                LabeledContent("Storage") {
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
