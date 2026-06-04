import SwiftUI

struct QuickPanelView: View {
    @StateObject private var viewModel: QuickPanelViewModel
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @FocusState private var searchFocused: Bool

    init(viewModel: QuickPanelViewModel = QuickPanelViewModel()) {
        _viewModel = StateObject(wrappedValue: viewModel)
    }

    var body: some View {
        VStack(spacing: 0) {
            topBar

            cardWall
        }
        .frame(maxWidth: .infinity)
        .frame(height: QuickPanelView.panelHeight)
        .background(hiddenShortcuts)
        // 外圆角 = 卡片圆角(14) + 卡片内边距(20)，与卡片同心。
        // 面板用实材质作底，让上面的 Liquid Glass 控件清晰浮起。
        .panelBackground(cornerRadius: 34)
        .onAppear {
            viewModel.startMonitoring()
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

            Spacer(minLength: 8)

            pinboardPicker
        }
        // 内边距与卡片墙(20)对齐：外圆角(34) = 控件圆角 + 边距，让顶部控件与外圆同心，
        // 右上角分段控件因此避开 34pt 圆弧，不再「顶到圆角」。
        .padding(.horizontal, 20)
        .padding(.top, 6)
        .frame(height: 56)
    }

    /// 常驻玻璃搜索框（macOS 26 工具栏药丸样式）。
    private var searchField: some View {
        HStack(spacing: 8) {
            Image(systemName: "magnifyingglass")
                .foregroundStyle(.secondary)

            TextField("搜索剪贴板", text: $viewModel.query)
                .textFieldStyle(.plain)
                .focused($searchFocused)
                .onSubmit(activateSelection)

            if !viewModel.query.isEmpty {
                Button {
                    viewModel.query = ""
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .symbolRenderingMode(.hierarchical)
                        .foregroundStyle(.secondary)
                }
                .buttonStyle(.plain)
                .accessibilityLabel("清除搜索")
            }
        }
        // 原生工具栏搜索字号（body），不是标题级；避免文字撑满药丸。
        .font(.body)
        .padding(.horizontal, 14)
        .frame(maxWidth: 320)
        .frame(height: 32)
        .glassEffect(in: Capsule())
    }

    /// 原生分段控件（macOS 26 自动套用 Liquid Glass）。
    private var pinboardPicker: some View {
        Picker("Pinboard", selection: $viewModel.board) {
            ForEach(QuickPanelViewModel.Board.allCases) { board in
                Text(board.rawValue).tag(board)
            }
        }
        .pickerStyle(.segmented)
        .labelsHidden()
        // 用 large 控件尺寸配齐搜索药丸高度，让顶部两个控件读成同一排。
        .controlSize(.large)
        .fixedSize()
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
                    .animation(reduceMotion ? nil : .easeOut(duration: 0.18), value: viewModel.filteredClips.map(\.id))
                }
                .scrollIndicators(.hidden)
                .onChange(of: viewModel.scrollTarget) {
                    guard let target = viewModel.scrollTarget else { return }
                    withAnimation(reduceMotion ? nil : .easeOut(duration: 0.1)) {
                        proxy.scrollTo(target, anchor: .center)
                    }
                }
            }
            .frame(maxHeight: .infinity)
        }
    }

    private var emptyState: some View {
        VStack(spacing: 10) {
            Image(systemName: viewModel.board == .pinned ? "pin" : "doc.on.clipboard")
                .font(.largeTitle)
                .symbolRenderingMode(.hierarchical)
                .foregroundStyle(.tertiary)

            Text(emptyMessage)
                .font(.callout)
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
