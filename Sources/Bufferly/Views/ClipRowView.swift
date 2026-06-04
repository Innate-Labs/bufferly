import SwiftUI

struct ClipRowView: View {
    let clip: ClipItem
    let isSelected: Bool
    let onTogglePin: () -> Void

    var body: some View {
        HStack(alignment: .center, spacing: 12) {
            typeBadge

            VStack(alignment: .leading, spacing: 3) {
                HStack(spacing: 6) {
                    Text(clip.title)
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundStyle(.primary)
                        .lineLimit(1)

                    if clip.isPinned {
                        Image(systemName: "pin.fill")
                            .font(.system(size: 10, weight: .semibold))
                            .foregroundStyle(.secondary)
                    }
                }

                Text(clip.preview)
                    .font(clip.kind == .command || clip.kind == .code || clip.kind == .json ? .system(size: 12, design: .monospaced) : .system(size: 12))
                    .foregroundStyle(clip.isSensitive ? Color.secondary : Color.primary.opacity(0.72))
                    .lineLimit(2)
            }

            Spacer(minLength: 12)

            VStack(alignment: .trailing, spacing: 5) {
                HStack(spacing: 6) {
                    Text(clip.relativeTime)
                        .font(.system(size: 12))
                        .foregroundStyle(.secondary)

                    Button {
                        onTogglePin()
                    } label: {
                        Image(systemName: clip.isPinned ? "pin.fill" : "pin")
                            .font(.system(size: 11, weight: .semibold))
                            .foregroundStyle(clip.isPinned ? .secondary : .tertiary)
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel(clip.isPinned ? "Unpin clip" : "Pin clip")
                }

                Text(clip.source)
                    .font(.system(size: 11))
                    .foregroundStyle(.tertiary)
                    .lineLimit(1)
            }
            .frame(width: 84, alignment: .trailing)
        }
        .padding(.horizontal, 8)
        .frame(minHeight: 54)
        .background(rowBackground)
        .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
        .accessibilityElement(children: .combine)
        .accessibilityLabel(accessibilityText)
    }

    private var typeBadge: some View {
        HStack(spacing: 4) {
            Image(systemName: clip.kind.symbolName)
                .font(.system(size: 11, weight: .semibold))

            Text(clip.kind.rawValue)
                .font(.system(size: 10, weight: .semibold))
        }
        .foregroundStyle(clip.kind.tint)
        .frame(width: 66, height: 24)
        .background(Color.primary.opacity(0.055))
        .clipShape(RoundedRectangle(cornerRadius: 6, style: .continuous))
    }

    @ViewBuilder
    private var rowBackground: some View {
        if isSelected {
            RoundedRectangle(cornerRadius: 8, style: .continuous)
                .fill(Color.accentColor.opacity(0.16))
        } else {
            RoundedRectangle(cornerRadius: 8, style: .continuous)
                .fill(Color.primary.opacity(0.001))
        }
    }

    private var accessibilityText: String {
        "\(clip.kind.rawValue), \(clip.title), \(clip.preview), copied \(clip.relativeTime) from \(clip.source)"
    }
}
