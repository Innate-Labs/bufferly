import AppKit
import SwiftUI

struct QuickPanelView: View {
    @StateObject private var viewModel: QuickPanelViewModel
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @FocusState private var searchFocused: Bool
    @State private var keyMonitor: Any?

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
        // 外圆角 = 卡片圆角(14) + 卡片内边距(20)，与卡片同心。
        // 面板用实材质作底，让上面的 Liquid Glass 控件清晰浮起。
        .panelBackground(cornerRadius: 34)
        .onAppear {
            viewModel.startMonitoring()
            installKeyMonitor()
            focusSearch()
        }
        .onChange(of: viewModel.query) {
            viewModel.handleQueryChange()
        }
        // 面板每次重新显示都把焦点交还搜索框（DESIGN §14：呼出即聚焦）。
        .onReceive(NotificationCenter.default.publisher(for: .quickPanelDidShow)) { _ in
            focusSearch()
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

    // MARK: - 键盘

    /// 让搜索框聚焦。无边框面板里若没有任何 first responder，方向键 / Return 都不会进响应链。
    private func focusSearch() {
        DispatchQueue.main.async {
            searchFocused = true
        }
    }

    /// 安装本地 keyDown 监听，集中接管面板内的导航 / 动作键。
    ///
    /// 为什么不用 `onMoveCommand` / `keyboardShortcut`：无边框浮层面板里 SwiftUI 的
    /// 方向键命令依赖被聚焦视图的响应链，焦点在搜索框上时方向键又会被字段当作移动光标，
    /// 二者必有一失。本地监听在面板为 key 时直接拿到 keyDown，最可靠且不挑焦点。
    private func installKeyMonitor() {
        guard keyMonitor == nil else { return }
        keyMonitor = NSEvent.addLocalMonitorForEvents(matching: .keyDown) { event in
            handleKeyDown(event)
        }
    }

    private func handleKeyDown(_ event: NSEvent) -> NSEvent? {
        // 只接管浮动无边框面板自己的按键，避免干扰设置窗口等其它窗口。
        guard
            let window = event.window,
            window.styleMask.contains(.borderless),
            window.level == .floating
        else {
            return event
        }

        let mods = event.modifierFlags.intersection([.command, .option, .control, .shift])

        switch (event.keyCode, mods) {
        case (123, []), (126, []): // ← / ↑
            viewModel.selectPrevious()
            return nil
        case (124, []), (125, []): // → / ↓
            viewModel.selectNext()
            return nil
        case (36, []), (76, []): // Return / 小键盘 Enter
            activateSelection()
            return nil
        case (36, [.command]), (76, [.command]): // ⌘Return 粘贴
            activateSelection()
            return nil
        case (36, [.option]), (76, [.option]): // ⌥Return 仅复制后关闭
            copyOnlyAndClose()
            return nil
        case (51, [.command]): // ⌘⌫ 删除选中
            viewModel.deleteSelected()
            return nil
        case (35, [.command]): // ⌘P 固定 / 取消固定
            viewModel.togglePinSelected()
            return nil
        case (53, []): // Esc 关闭
            NotificationCenter.default.post(name: .quickPanelDidRequestClose, object: nil)
            return nil
        default:
            // 其余按键（打字、退格、其它组合）放行给搜索框 / 系统。
            return event
        }
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
