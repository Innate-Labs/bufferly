import SwiftUI

struct QuickPanelView: View {
    @StateObject private var viewModel: QuickPanelViewModel
    @FocusState private var searchFocused: Bool
    @Namespace private var pinboardNamespace

    init(viewModel: QuickPanelViewModel = QuickPanelViewModel()) {
        _viewModel = StateObject(wrappedValue: viewModel)
    }

    var body: some View {
        VStack(spacing: 0) {
            topBar

            Divider()

            cardWall
        }
        .frame(maxWidth: .infinity)
        .frame(height: QuickPanelView.panelHeight)
        .background(hiddenShortcuts)
        .background(.ultraThinMaterial)
        // 外圆角 = 卡片圆角(14) + 卡片内边距(20)，与卡片同心。
        .clipShape(RoundedRectangle(cornerRadius: 34, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 34, style: .continuous)
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

    static let panelHeight: CGFloat = 370

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
            RemixIcon(name: "RemixSearch", size: 15)
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
                    RemixIcon(name: "RemixClearFill", size: 15)
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
            withAnimation(.spring(response: 0.32, dampingFraction: 0.78)) {
                viewModel.board = board
            }
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
                    Capsule()
                        .fill(Color(nsColor: .controlBackgroundColor))
                        .shadow(color: .black.opacity(0.08), radius: 2, y: 1)
                        .matchedGeometryEffect(id: "pinboardActive", in: pinboardNamespace)
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
            RemixIcon(name: "RemixClose", size: 13)
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
                            .contextMenu {
                                clipActions(for: clip)
                            }
                        }
                    }
                    .padding(.horizontal, 20)
                    .padding(.vertical, 20)
                    .animation(.easeOut(duration: 0.18), value: viewModel.filteredClips.map(\.id))
                }
                .scrollIndicators(.hidden)
                .onChange(of: viewModel.scrollTarget) {
                    guard let target = viewModel.scrollTarget else { return }
                    withAnimation(.easeOut(duration: 0.1)) {
                        proxy.scrollTo(target, anchor: .center)
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

    // MARK: - Actions

    /// 卡片右键 / ⌘K 共用的动作列表。
    @ViewBuilder
    private func clipActions(for clip: ClipItem) -> some View {
        Button("粘贴") {
            viewModel.selectedID = clip.id
            activateSelection()
        }
        .disabled(clip.isSensitive)

        Button("复制") {
            viewModel.selectedID = clip.id
            copyOnlyAndClose()
        }
        .disabled(clip.isSensitive)

        Button(clip.isPinned ? "取消固定" : "固定") {
            viewModel.togglePin(clipID: clip.id)
        }

        if clip.kind == .json {
            Divider()
            Button("格式化 JSON") {
                viewModel.applyTransform(ClipTransform.formatJSON, to: clip.id)
            }
            Button("压缩 JSON") {
                viewModel.applyTransform(ClipTransform.minifyJSON, to: clip.id)
            }
        }

        if clip.kind == .url {
            Divider()
            Button("清理 URL（去 tracking 参数）") {
                viewModel.applyTransform(ClipTransform.cleanURL, to: clip.id)
            }
        }

        Divider()
        Button("删除", role: .destructive) {
            viewModel.delete(clipID: clip.id)
        }
    }

    /// 隐藏的键盘快捷键宿主：⌥↵ 仅复制、⌘↵ 纯文本粘贴、⌘⌫ 删除。
    private var hiddenShortcuts: some View {
        ZStack {
            Button("", action: copyOnlyAndClose)
                .keyboardShortcut(.return, modifiers: .option)

            Button("", action: activateSelection)
                .keyboardShortcut(.return, modifiers: .command)

            Button("", action: viewModel.deleteSelected)
                .keyboardShortcut(.delete, modifiers: .command)

            Button("", action: viewModel.togglePinSelected)
                .keyboardShortcut("p", modifiers: .command)
        }
        .opacity(0)
        .frame(width: 0, height: 0)
        .accessibilityHidden(true)
        .disabled(viewModel.selectedClip == nil)
    }

    private func activateSelection() {
        if viewModel.pasteSelected() {
            NotificationCenter.default.post(name: .quickPanelDidRequestPaste, object: nil)
        }
    }

    /// 仅复制到剪贴板、不自动粘贴，然后关闭面板。
    private func copyOnlyAndClose() {
        if viewModel.pasteSelected() {
            NotificationCenter.default.post(name: .quickPanelDidRequestClose, object: nil)
        }
    }
}

#Preview {
    QuickPanelView()
        .frame(width: 980, height: QuickPanelView.panelHeight)
}
