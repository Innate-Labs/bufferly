import AppKit
import SwiftUI

struct QuickPanelView: View {
    @StateObject private var viewModel: QuickPanelViewModel
    @ObservedObject private var appSettings: AppSettings
    @ObservedObject private var eventPostingPermission: EventPostingPermission
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @FocusState private var searchFocused: Bool
    @State private var keyMonitor: Any?
    @State private var showPreview = false
    @State private var showOnboarding = false
    @State private var statusBanner: StatusBanner?
    @State private var statusDismissTask: Task<Void, Never>?

    init(
        viewModel: QuickPanelViewModel = QuickPanelViewModel(),
        appSettings: AppSettings = .shared,
        eventPostingPermission: EventPostingPermission = .shared
    ) {
        _viewModel = StateObject(wrappedValue: viewModel)
        self.appSettings = appSettings
        self.eventPostingPermission = eventPostingPermission
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
        .overlay(alignment: .bottom) {
            if let statusBanner, !showPreview, !showOnboarding {
                statusBannerView(statusBanner)
                    .padding(.bottom, 18)
                    .transition(statusTransition)
            }
        }
        .animation(reduceMotion ? nil : .easeOut(duration: 0.16), value: statusBanner)
        .overlay {
            if showPreview, viewModel.selectedClip != nil {
                previewOverlay
            }
        }
        .overlay {
            if showOnboarding {
                onboardingOverlay
            }
        }
        .onAppear {
            viewModel.startMonitoring()
            installKeyMonitor()
            focusSearch()
            showOnboarding = !AppSettings.shared.hasCompletedOnboarding
        }
        .onDisappear {
            statusDismissTask?.cancel()
            statusDismissTask = nil
        }
        .onChange(of: viewModel.query) {
            viewModel.handleQueryChange()
        }
        // 面板每次重新显示：补抓一次剪贴板（让最新一条立刻在），并把焦点交还搜索框。
        .onReceive(NotificationCenter.default.publisher(for: .quickPanelDidShow)) { _ in
            eventPostingPermission.refresh()
            viewModel.prepareForPanelShow()
            viewModel.captureLatestNow()
            showPreview = false
            focusSearch()
        }
        .onReceive(NotificationCenter.default.publisher(for: .quickPanelDidRequestStatus)) { notification in
            handleStatusNotification(notification)
        }
    }

    static let panelHeight: CGFloat = 370

    // MARK: - Top bar

    private var topBar: some View {
        HStack(spacing: 12) {
            searchField

            Spacer(minLength: 8)

            returnModePill

            PinboardTabs(selection: $viewModel.board)
        }
        // 四周统一 20：搜索上方到面板顶、左右边距、搜索行到卡片(由卡片墙 20 提供)全部一致。
        // 不再用固定高度，顶栏高度 = 20 顶部内边距 + 内容自然高度。
        .padding(.horizontal, 20)
        .padding(.top, 20)
    }

    /// 常驻玻璃搜索框（macOS 26 工具栏药丸样式）。
    private var searchField: some View {
        HStack(spacing: 8) {
            Image(systemName: "magnifyingglass")
                .foregroundStyle(.secondary)

            TextField("搜索剪贴板", text: $viewModel.query)
                .textFieldStyle(.plain)
                .focused($searchFocused)
                .onSubmit { activateSelection() }

            if !viewModel.query.isEmpty {
                Text("\(viewModel.filteredClips.count)")
                    .font(.caption2.monospacedDigit())
                    .foregroundStyle(.secondary)
                    .padding(.horizontal, 6)
                    .frame(height: 18)
                    .background(Color.secondary.opacity(0.12), in: Capsule())
                    .accessibilityLabel("匹配 \(viewModel.filteredClips.count) 条")

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
        // interactive 玻璃：交互时有真实光感 / lensing 响应（macOS 26 Tahoe）。
        .glassEffect(.regular.interactive(), in: Capsule())
    }

    private var returnModePill: some View {
        let state = returnActionState

        return HStack(spacing: 6) {
            Text("Return")
                .font(.caption2.monospaced().weight(.medium))
                .padding(.horizontal, 5)
                .frame(height: 18)
                .background(Color.primary.opacity(0.07), in: RoundedRectangle(cornerRadius: 4, style: .continuous))

            Image(systemName: state.symbolName)
                .font(.caption2.weight(.semibold))
                .foregroundStyle(state.tint)

            Text(state.title)
                .font(.caption.weight(.medium))
                .foregroundStyle(.secondary)

            if let note = state.note {
                Text(note)
                    .font(.caption2.weight(.medium))
                    .foregroundStyle(state.tint)
            }
        }
        .padding(.horizontal, 9)
        .frame(height: 28)
        .background(Color.primary.opacity(0.045), in: Capsule())
        .overlay {
            Capsule()
                .strokeBorder(state.tint.opacity(0.18), lineWidth: 1)
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Return 当前行为：\(state.accessibilityText)")
    }

    private var returnActionState: ReturnActionState {
        if !appSettings.autoPasteAfterSelection {
            return ReturnActionState(
                title: "只复制",
                note: nil,
                symbolName: "doc.on.clipboard",
                tint: .secondary,
                accessibilityText: "只复制到剪贴板"
            )
        }

        if eventPostingPermission.isGranted {
            return ReturnActionState(
                title: "贴回上一应用",
                note: nil,
                symbolName: "arrowshape.turn.up.left.fill",
                tint: .green,
                accessibilityText: "复制并贴回上一应用"
            )
        }

        return ReturnActionState(
            title: "只复制",
            note: "需授权",
            symbolName: "exclamationmark.triangle.fill",
            tint: .orange,
            accessibilityText: "贴回上一应用未授权，目前只复制到剪贴板"
        )
    }

    // MARK: - Card wall

    @ViewBuilder
    private var cardWall: some View {
        if viewModel.filteredClips.isEmpty {
            emptyState
        } else {
            ScrollViewReader { proxy in
                ScrollView(.horizontal) {
                    LazyHStack(spacing: 16) {
                        ForEach(viewModel.filteredClips) { clip in
                            ClipCardView(
                                clip: clip,
                                searchQuery: viewModel.query,
                                onSelect: { viewModel.select(clipID: clip.id) },
                                onActivate: {
                                    viewModel.select(clipID: clip.id)
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
                // Tahoe 滚动边缘柔化：左右边缘的卡片淡入面板圆角，不硬裁切。
                .scrollEdgeEffectStyle(.soft, for: .horizontal)
                .onChange(of: viewModel.scrollTarget) {
                    guard let target = viewModel.scrollTarget else { return }
                    proxy.scrollTo(target, anchor: .center)
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
        Button(returnActionState.title) {
            viewModel.select(clipID: clip.id, revealFocus: false)
            activateSelection()
        }
        .disabled(clip.isSensitive)

        Button("复制") {
            viewModel.select(clipID: clip.id, revealFocus: false)
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

    // MARK: - 覆盖层

    private var statusTransition: AnyTransition {
        reduceMotion ? .opacity : .opacity.combined(with: .move(edge: .bottom))
    }

    private func statusBannerView(_ banner: StatusBanner) -> some View {
        HStack(spacing: 10) {
            ZStack {
                Circle()
                    .fill(banner.kind.tint.opacity(0.12))
                    .frame(width: 22, height: 22)

                Image(systemName: banner.kind.symbolName)
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(banner.kind.tint)
            }

            Text(banner.message)
                .font(.caption.weight(.medium))
                .foregroundStyle(.primary)
                .lineLimit(1)

            Spacer(minLength: 0)
        }
        .padding(.leading, 8)
        .padding(.trailing, 12)
        .frame(width: 300, height: 38)
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 11, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 11, style: .continuous)
                .strokeBorder(Color.primary.opacity(0.08), lineWidth: 1)
        }
        .overlay(alignment: .leading) {
            RoundedRectangle(cornerRadius: 2, style: .continuous)
                .fill(banner.kind.tint.opacity(0.65))
                .frame(width: 3, height: 20)
                .padding(.leading, 1)
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel(banner.message)
    }

    private func handleStatusNotification(_ notification: Notification) {
        guard let message = notification.userInfo?[QuickPanelStatusPayload.messageKey] as? String else {
            return
        }

        let kindRawValue = notification.userInfo?[QuickPanelStatusPayload.kindKey] as? String
        let kind = kindRawValue.flatMap(QuickPanelStatusKind.init(rawValue:)) ?? .info
        showStatus(message, kind: kind)
    }

    private func showStatus(_ message: String, kind: QuickPanelStatusKind) {
        statusBanner = StatusBanner(message: message, kind: kind)
        statusDismissTask?.cancel()
        statusDismissTask = Task { @MainActor in
            try? await Task.sleep(nanoseconds: 1_600_000_000)
            guard !Task.isCancelled else { return }
            statusBanner = nil
        }
    }

    /// 首次使用引导：一次性，看过即不再出现。
    private var onboardingOverlay: some View {
        ZStack {
            Rectangle()
                .fill(.black.opacity(0.28))
                .ignoresSafeArea()
                .onTapGesture { dismissOnboarding() }

            VStack(spacing: 14) {
                Image(systemName: "doc.on.clipboard.fill")
                    .font(.system(size: 34))
                    .foregroundStyle(.tint)

                Text("欢迎使用 Bufferly")
                    .font(.title3)
                    .fontWeight(.semibold)

                VStack(alignment: .leading, spacing: 8) {
                    onboardingLine("⌥ Space", "在任意 App 呼出 / 隐藏面板")
                    onboardingLine("← →", "浏览 · Return 按当前模式执行 · 空格预览")
                    onboardingLine("⌘P / ⌘⌫", "固定 / 删除选中")
                }
                .font(.callout)

                Text("若选择「贴回上一应用」，需在设置里授权辅助功能。")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)

                Button("开始使用") { dismissOnboarding() }
                    .buttonStyle(.borderedProminent)
                    .controlSize(.large)
            }
            .padding(28)
            .frame(maxWidth: 380)
            .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 22, style: .continuous))
            .padding(24)
        }
    }

    private func onboardingLine(_ key: String, _ desc: String) -> some View {
        HStack(spacing: 10) {
            Text(key)
                .font(.callout.monospaced())
                .fontWeight(.medium)
                .frame(width: 78, alignment: .leading)
            Text(desc)
                .foregroundStyle(.secondary)
            Spacer(minLength: 0)
        }
    }

    /// 空格 Quick Look：把选中条目的完整内容 / 大图弹出来看，贴前确认。
    @ViewBuilder
    private var previewOverlay: some View {
        if let clip = viewModel.selectedClip {
            ZStack {
                Rectangle()
                    .fill(.black.opacity(0.32))
                    .ignoresSafeArea()
                    .onTapGesture { showPreview = false }

                VStack(alignment: .leading, spacing: 10) {
                    HStack(spacing: 8) {
                        Image(systemName: clip.kind.symbolName)
                            .foregroundStyle(clip.kind.accent)
                        Text(clip.kind.rawValue)
                            .fontWeight(.semibold)
                        Text(clip.source)
                            .foregroundStyle(.secondary)
                        Spacer()
                        Text("空格 / Esc 关闭 · Return \(returnActionState.title)")
                            .font(.caption)
                            .foregroundStyle(.tertiary)
                    }
                    .font(.callout)

                    Divider()

                    previewBody(for: clip)
                }
                .padding(18)
                .frame(maxWidth: 560, maxHeight: 300)
                .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 18, style: .continuous))
                .padding(20)
            }
        }
    }

    @ViewBuilder
    private func previewBody(for clip: ClipItem) -> some View {
        let mono = clip.kind == .code || clip.kind == .json || clip.kind == .command

        if clip.isSensitive {
            Text("敏感内容已隐藏")
                .foregroundStyle(.secondary)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
        } else if
            clip.kind == .image,
            let filename = clip.attachmentFilename,
            let data = ClipBlobStore.read(filename: filename),
            let image = NSImage(data: data)
        {
            Image(nsImage: image)
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
        } else {
            ScrollView {
                Text(clip.content)
                    .font(mono ? .system(.callout, design: .monospaced) : .callout)
                    .textSelection(.enabled)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
            .frame(maxHeight: .infinity)
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

        // 引导覆盖层期间：Return / Esc / 空格关闭引导，其它键一律吞掉避免误操作。
        if showOnboarding {
            switch (event.keyCode, mods) {
            case (36, []), (76, []), (53, []), (49, []):
                dismissOnboarding()
                return nil
            default:
                return nil
            }
        }

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
        case (36, [.command]), (76, [.command]): // ⌘Return 纯文本粘贴
            activateSelection(mode: .plainText)
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
        case (49, []): // 空格：搜索为空时切换 Quick Look 预览，否则放行给搜索框打空格
            if viewModel.query.isEmpty {
                showPreview.toggle()
                return nil
            }
            return event
        case (53, []): // Esc：预览→关预览 → 有搜索词→清搜索 → 否则关面板
            if showPreview {
                showPreview = false
                return nil
            }
            if !viewModel.query.isEmpty {
                viewModel.query = ""
                return nil
            }
            NotificationCenter.default.post(name: .quickPanelDidRequestClose, object: nil)
            return nil
        default:
            // 其余按键（打字、退格、其它组合）放行给搜索框 / 系统。
            return event
        }
    }

    private func dismissOnboarding() {
        showOnboarding = false
        AppSettings.shared.hasCompletedOnboarding = true
    }

    private func activateSelection(mode: QuickPanelViewModel.PasteMode = .original) {
        if viewModel.pasteSelected(mode: mode) {
            NotificationCenter.default.post(name: .quickPanelDidRequestPaste, object: nil)
        } else {
            showStatus(pasteFailureMessage, kind: .warning)
        }
    }

    /// 仅复制到剪贴板、不自动粘贴，然后关闭面板。
    private func copyOnlyAndClose() {
        if viewModel.pasteSelected() {
            NotificationCenter.default.post(name: .quickPanelDidRequestClose, object: nil)
        } else {
            showStatus(pasteFailureMessage, kind: .warning)
        }
    }

    private var pasteFailureMessage: String {
        guard let selectedClip = viewModel.selectedClip else {
            return "没有可复制内容"
        }

        if selectedClip.isSensitive {
            return "敏感内容不会写入剪贴板"
        }

        return "无法写入剪贴板"
    }
}

private struct StatusBanner: Equatable {
    let id = UUID()
    let message: String
    let kind: QuickPanelStatusKind
}

private struct ReturnActionState {
    let title: String
    let note: String?
    let symbolName: String
    let tint: Color
    let accessibilityText: String
}

private extension QuickPanelStatusKind {
    var symbolName: String {
        switch self {
        case .success:
            return "checkmark.circle.fill"
        case .warning:
            return "exclamationmark.triangle.fill"
        case .info:
            return "info.circle.fill"
        }
    }

    var tint: Color {
        switch self {
        case .success:
            return .green
        case .warning:
            return .orange
        case .info:
            return .blue
        }
    }
}

#Preview {
    QuickPanelView()
        .frame(width: 980, height: QuickPanelView.panelHeight)
}
