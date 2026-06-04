import SwiftUI

struct QuickPanelView: View {
    @StateObject private var viewModel: QuickPanelViewModel
    @FocusState private var searchFocused: Bool

    init(viewModel: QuickPanelViewModel = QuickPanelViewModel()) {
        _viewModel = StateObject(wrappedValue: viewModel)
    }

    var body: some View {
        VStack(spacing: 0) {
            searchBar

            Divider()

            clipsList

            Divider()

            footer
        }
        .frame(width: 720, height: 520)
        .background(.regularMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .stroke(Color.primary.opacity(0.08), lineWidth: 1)
        }
        .onAppear {
            viewModel.startMonitoring()
            searchFocused = true
        }
        .onChange(of: viewModel.query) {
            viewModel.handleQueryChange()
        }
        .onMoveCommand { direction in
            switch direction {
            case .up:
                viewModel.selectPrevious()
            case .down:
                viewModel.selectNext()
            default:
                break
            }
        }
        .onExitCommand {
            NSApp.keyWindow?.close()
        }
    }

    private var searchBar: some View {
        HStack(spacing: 10) {
            Image(systemName: "magnifyingglass")
                .font(.system(size: 15, weight: .medium))
                .foregroundStyle(.secondary)

            TextField("Search clips", text: $viewModel.query)
                .textFieldStyle(.plain)
                .font(.system(size: 18, weight: .regular))
                .focused($searchFocused)
                .onSubmit {
                    viewModel.pasteSelected()
                }

            if !viewModel.query.isEmpty {
                Button {
                    viewModel.query = ""
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundStyle(.tertiary)
                }
                .buttonStyle(.plain)
                .accessibilityLabel("Clear search")
            }
        }
        .padding(.horizontal, 18)
        .frame(height: 58)
    }

    private var clipsList: some View {
        ScrollView {
            LazyVStack(alignment: .leading, spacing: 12) {
                if viewModel.filteredClips.isEmpty {
                    emptyState
                } else {
                    if !viewModel.pinnedClips.isEmpty {
                        ClipSectionView(
                            title: "Pinned",
                            clips: viewModel.pinnedClips,
                            selectedID: $viewModel.selectedID,
                            onTogglePin: viewModel.togglePin
                        )
                    }

                    ClipSectionView(
                        title: "Recent",
                        clips: viewModel.recentClips,
                        selectedID: $viewModel.selectedID,
                        onTogglePin: viewModel.togglePin
                    )
                }
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 12)
        }
        .scrollIndicators(.hidden)
    }

    private var emptyState: some View {
        VStack(spacing: 8) {
            Image(systemName: "clipboard")
                .font(.system(size: 28, weight: .regular))
                .foregroundStyle(.tertiary)

            Text(viewModel.query.isEmpty ? "Copy text to start" : "No matching clips")
                .font(.system(size: 13, weight: .medium))
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
        .frame(height: 320)
    }

    private var footer: some View {
        HStack(spacing: 8) {
            Text("\(viewModel.filteredClips.count) clips")
                .foregroundStyle(.secondary)

            Circle()
                .fill(Color.secondary.opacity(0.35))
                .frame(width: 4, height: 4)

            Label("Sensitive filter on", systemImage: "lock")
                .foregroundStyle(.secondary)

            Spacer()

            Text("Return")
                .keyboardHint()
            Text("Copy")
                .foregroundStyle(.secondary)

            Button {
                viewModel.togglePinSelected()
            } label: {
                Text("Pin")
                    .foregroundStyle(.secondary)
            }
            .buttonStyle(.plain)
            .keyboardShortcut("p", modifiers: [.command])
            .disabled(viewModel.selectedClip == nil)

            Text("Esc")
                .keyboardHint()
            Text("Close")
                .foregroundStyle(.secondary)
        }
        .font(.system(size: 12))
        .padding(.horizontal, 14)
        .frame(height: 36)
    }
}

#Preview {
    QuickPanelView()
        .frame(width: 720, height: 520)
}
