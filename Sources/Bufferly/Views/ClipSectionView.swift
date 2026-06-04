import SwiftUI

struct ClipSectionView: View {
    let title: String
    let clips: [ClipItem]
    @Binding var selectedID: ClipItem.ID?
    let onTogglePin: (ClipItem.ID) -> Void

    var body: some View {
        if clips.isEmpty {
            EmptyView()
        } else {
            VStack(alignment: .leading, spacing: 6) {
                Text(title)
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(.secondary)
                    .padding(.horizontal, 8)

                VStack(spacing: 2) {
                    ForEach(clips) { clip in
                        ClipRowView(
                            clip: clip,
                            isSelected: selectedID == clip.id,
                            onTogglePin: {
                                onTogglePin(clip.id)
                            }
                        )
                        .contentShape(Rectangle())
                        .onTapGesture {
                            selectedID = clip.id
                        }
                    }
                }
            }
        }
    }
}
