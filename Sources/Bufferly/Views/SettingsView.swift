import SwiftUI

struct SettingsView: View {
    @ObservedObject var settings: AppSettings

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
        .frame(width: 520, height: 360)
    }
}

#Preview {
    SettingsView(settings: AppSettings())
}
