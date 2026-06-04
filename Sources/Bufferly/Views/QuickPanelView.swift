import SwiftUI

struct QuickPanelView: View {
    @StateObject private var viewModel: QuickPanelViewModel
    @FocusState private var searchFocused: Bool

    init(viewModel: QuickPanelViewModel = QuickPanelViewModel()) {
        _viewModel = StateObject(wrappedValue: viewModel)
    }

    var body: some View {
        VStack(spacing: 0) {
            topBar

            Divider()

            cardWall

            Divider()

            footer
        }
        .frame(maxWidth: .infinity)
        .frame(height: QuickPanelView.panelHeight)
        .background(.regularMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .strokeBorder(Color.primary.opacity(0.08), lineWidth: 1)
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
            case .left, .up:
                viewModel.selectPrevious()
            case .right, .down:
                viewModel.selectNext()
            default:
                break
            }
        }
        .onExitCommand {
            NotificationCenter.default.post(name: .quickPanelDidRequestClose, object: nil)
        }
    }

    static let panelHeight: CGFloat = 392

    // MARK: - Top bar

    private var topBar: some View {
        HStack(spacing: 12) {
            searchField
                .frame(maxWidth: 380)

            Spacer(minLength: 8)

            pinboardTabs

            closeButton
        }
        .padding(.horizontal, 16)
        .frame(height: 56)
    }

    private var searchField: some View {
        HStack(spacing: 8) {
            Image(systemName: "magnifyingglass")
                .font(.system(size: 14, weight: .medium))
                .foregroundStyle(.secondary)

            TextField("搜索剪贴板", text: $viewModel.query)
                .textFieldStyle(.plain)
                .font(.system(size: 15))
                .focused($searchFocused)
                .onSubmit(activateSelection)

            if !viewModel.query.isEmpty {
                Button {
                    viewModel.query = ""
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundStyle(.tertiary)
                }
                .buttonStyle(.plain)
                .accessibilityLabel("清除搜索")
            }
        }
        .padding(.horizontal, 12)
        .frame(height: 34)
        .background(Color.primary.opacity(0.06))
        .clipShape(Capsule())
    }

    private var pinboardTabs: some View {
        HStack(spacing: 4) {
            ForEach(QuickPanelViewModel.Board.allCases) { board in
                pinboardTab(board)
            }
        }
        .padding(3)
        .background(Color.primary.opacity(0.05))
        .clipShape(Capsule())
    }

    private func pinboardTab(_ board: QuickPanelViewModel.Board) -> some View {
        let isActive = viewModel.board == board

        return Button {
            viewModel.board = board
        } label: {
            HStack(spacing: 5) {
                Circle()
                    .fill(board.dotColor)
                    .frame(width: 6, height: 6)

                Text(board.rawValue)
                    .font(.system(size: 12, weight: .medium))
                    .foregroundStyle(isActive ? .primary : .secondary)
            }
            .padding(.horizontal, 10)
            .frame(height: 26)
            .background {
                if isActive {
                    Capsule().fill(Color(nsColor: .controlBackgroundColor))
                        .shadow(color: .black.opacity(0.08), radius: 2, y: 1)
                }
            }
        }
        .buttonStyle(.plain)
        .accessibilityAddTraits(isActive ? .isSelected : [])
    }

    private var closeButton: some View {
        Button {
            NotificationCenter.default.post(name: .quickPanelDidRequestClose, object: nil)
        } label: {
            Image(systemName: "xmark")
                .font(.system(size: 12, weight: .semibold))
                .foregroundStyle(.secondary)
                .frame(width: 26, height: 26)
                .background(Color.primary.opacity(0.05))
                .clipShape(Circle())
        }
        .buttonStyle(.plain)
        .accessibilityLabel("关闭面板")
    }

    // MARK: - Card wall

    @ViewBuilder
    private var cardWall: some View {
        if viewModel.filteredClips.isEmpty {
            emptyState
        } else {
            ScrollViewReader { proxy in
                ScrollView(.horizontal) {
                    LazyHStack(spacing: 14) {
                        ForEach(viewModel.filteredClips) { clip in
                            ClipCardView(
                                clip: clip,
                                isSelected: viewModel.selectedID == clip.id,
                                onSelect: { viewModel.selectedID = clip.id },
                                onActivate: {
                                    viewModel.selectedID = clip.id
                                    activateSelection()
                                },
                                onTogglePin: { viewModel.togglePin(clipID: clip.id) }
                            )
                            .id(clip.id)
                        }
                    }
                    .padding(.horizontal, 20)
                    .padding(.vertical, 18)
                }
                .scrollIndicators(.hidden)
                .onChange(of: viewModel.selectedID) {
                    guard let selectedID = viewModel.selectedID else { return }
                    withAnimation(.easeOut(duration: 0.16)) {
                        proxy.scrollTo(selectedID, anchor: .center)
                    }
                }
            }
            .frame(maxHeight: .infinity)
        }
    }

    private var emptyState: some View {
        VStack(spacing: 10) {
            Image(systemName: viewModel.board == .pinned ? "pin" : "clipboard")
                .font(.system(size: 30, weight: .regular))
                .foregroundStyle(.tertiary)

            Text(emptyMessage)
                .font(.system(size: 13, weight: .medium))
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private var emptyMessage: String {
        if !viewModel.query.isEmpty {
            return "没有匹配内容"
        }

        return viewModel.board == .pinned ? "还没有固定的片段" : "复制文本开始使用"
    }

    // MARK: - Footer

    private var footer: some View {
        HStack(spacing: 8) {
            Text("\(viewModel.filteredClips.count) 条记录")
                .foregroundStyle(.secondary)

            Circle()
                .fill(Color.secondary.opacity(0.35))
                .frame(width: 4, height: 4)

            Label("敏感过滤未启用", systemImage: "lock.open")
                .foregroundStyle(.secondary)

            Spacer()

            Text("←→")
                .keyboardHint()
            Text("选择")
                .foregroundStyle(.secondary)

            Text("Return")
                .keyboardHint()
            Text("粘贴")
                .foregroundStyle(.secondary)

            Button {
                viewModel.togglePinSelected()
            } label: {
                Text("⌘P 固定")
                    .foregroundStyle(.secondary)
            }
            .buttonStyle(.plain)
            .keyboardShortcut("p", modifiers: [.command])
            .disabled(viewModel.selectedClip == nil)

            Text("Esc")
                .keyboardHint()
            Text("关闭")
                .foregroundStyle(.secondary)
        }
        .font(.system(size: 12))
        .padding(.horizontal, 16)
        .frame(height: 36)
    }

    // MARK: - Actions

    private func activateSelection() {
        if viewModel.pasteSelected() {
            NotificationCenter.default.post(name: .quickPanelDidRequestPaste, object: nil)
        }
    }
}

#Preview {
    QuickPanelView()
        .frame(width: 980, height: QuickPanelView.panelHeight)
}
