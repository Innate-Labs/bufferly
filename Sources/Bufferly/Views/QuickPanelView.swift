import AppKit
import SwiftUI

struct QuickPanelView: View {
    @StateObject private var viewModel: QuickPanelViewModel
    @ObservedObject private var appSettings: AppSettings
    @ObservedObject private var eventPostingPermission: EventPostingPermission
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Environment(\.accessibilityReduceTransparency) private var reduceTransparency
    @FocusState private var searchFocused: Bool
    @State private var keyMonitor: Any?
    @State private var scrollWheelMonitor: Any?
    @State private var showPreview = false
    @State private var showOnboarding = false
    @State private var statusBanner: StatusBanner?
    @State private var statusDismissTask: Task<Void, Never>?
    /// 卡片墙滚动控制与几何信息（偏移 / 视口 / 内容宽），用于可见性判断和滚轮映射。
    @State private var wallPosition = ScrollPosition()
    @State private var wallGeometry = WallGeometry()
    /// 键盘落卡瞬时脉冲：只发给目标卡，token 变化触发一次上移后自动复原。
    @State private var keyboardPulse: KeyboardPulse?

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

            footerBar
        }
        .frame(maxWidth: .infinity)
        .frame(height: QuickPanelView.panelHeight)
        // 外圆角 = 卡片圆角(14) + 卡片内边距(20)，与卡片同心。
        // 外层板子只使用低透明底色，前景卡片保持实底保证内容可读。
        .panelBackground(cornerRadius: 34)
        .overlay(alignment: .bottom) {
            if let statusBanner, !showPreview, !showOnboarding {
                statusBannerView(statusBanner)
                    .padding(.bottom, 18)
                    .transition(statusTransition)
            }
        }
        .animation(reduceMotion ? nil : Motion.toast, value: statusBanner)
        .overlay {
            if showPreview, viewModel.selectedClip != nil {
                previewOverlay
                    .transition(.opacity)
            }
        }
        .overlay {
            if showOnboarding {
                onboardingOverlay
                    .transition(.opacity)
            }
        }
        .animation(reduceMotion ? nil : Motion.overlay, value: showPreview)
        .animation(reduceMotion ? nil : Motion.overlay, value: showOnboarding)
        .onAppear {
            viewModel.startMonitoring()
            installKeyMonitor()
            installScrollWheelMonitor()
            focusSearch()
            showOnboarding = !AppSettings.shared.hasCompletedOnboarding
        }
        .onDisappear {
            if let keyMonitor {
                NSEvent.removeMonitor(keyMonitor)
                self.keyMonitor = nil
            }
            if let scrollWheelMonitor {
                NSEvent.removeMonitor(scrollWheelMonitor)
                self.scrollWheelMonitor = nil
            }
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

    // 392 = 顶栏 + 卡片墙 + footer（DESIGN §4.1 建议高度）。
    static let panelHeight: CGFloat = 392

    // MARK: - Top bar

    private var topBar: some View {
        HStack(spacing: 12) {
            searchField

            Spacer(minLength: 8)

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
        .background {
            if reduceTransparency {
                Capsule()
                    .fill(Color(nsColor: .controlBackgroundColor))
            }
        }
        .glassEffect(reduceTransparency ? .identity : .regular.interactive(), in: Capsule())
    }

    private var returnActionTitle: String {
        guard appSettings.autoPasteAfterSelection, eventPostingPermission.isGranted else {
            return "只复制"
        }

        return "粘贴到上一应用"
    }

    // MARK: - Card wall

    private static let cardSpacing: CGFloat = 16
    private static let wallPadding: CGFloat = 20

    @ViewBuilder
    private var cardWall: some View {
        if viewModel.filteredClips.isEmpty {
            emptyState
        } else {
            ScrollView(.horizontal) {
                LazyHStack(spacing: Self.cardSpacing) {
                    ForEach(viewModel.filteredClips) { clip in
                        ClipCardView(
                            clip: clip,
                            searchQuery: viewModel.query,
                            keyboardPulseToken: keyboardPulse?.clipID == clip.id ? keyboardPulse?.token : nil,
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
                        // 只做退场（删除 / 取消固定）的轻微 fade + 缩小；入场保持直入，不做飞入。
                        .transition(
                            reduceMotion
                                ? .identity
                                : .asymmetric(
                                    insertion: .identity,
                                    removal: .opacity.combined(with: .scale(scale: 0.98))
                                )
                        )
                    }
                }
                .padding(.horizontal, Self.wallPadding)
                .padding(.vertical, 20)
                .animation(reduceMotion ? nil : Motion.listChange, value: viewModel.filteredClips.map(\.id))
            }
            .scrollIndicators(.hidden)
            // Tahoe 滚动边缘柔化：左右边缘的卡片淡入面板圆角，不硬裁切。
            .scrollEdgeEffectStyle(.soft, for: .horizontal)
            .scrollPosition($wallPosition)
            .onScrollGeometryChange(for: WallGeometry.self) { geometry in
                WallGeometry(
                    offsetX: geometry.contentOffset.x,
                    viewportWidth: geometry.containerSize.width,
                    contentWidth: geometry.contentSize.width
                )
            } action: { _, geometry in
                wallGeometry = geometry
            }
            .onChange(of: viewModel.scrollRequest) {
                guard let request = viewModel.scrollRequest else { return }
                handleScrollRequest(request)
            }
            .frame(maxHeight: .infinity)
        }
    }

    // MARK: - 卡片墙滚动

    private func handleScrollRequest(_ request: QuickPanelViewModel.ScrollRequest) {
        switch request.kind {
        case .resetToFront:
            // 程序性复位（呼出 / 搜索 / 新条目）：直接就位，不播开场滚动。
            wallPosition.scrollTo(edge: .leading)
        case .reveal(let clipID):
            revealCard(clipID)
        }
    }

    /// 键盘导航落卡：目标卡完全可见时只播脉冲、画面不动；
    /// 不可见时滚到最近一侧边缘（DESIGN §8：~160ms ease-out）。
    private func revealCard(_ clipID: ClipItem.ID) {
        keyboardPulse = KeyboardPulse(clipID: clipID)

        guard
            let index = viewModel.filteredClips.firstIndex(where: { $0.id == clipID }),
            wallGeometry.viewportWidth > 0
        else {
            return
        }

        let cardStride = ClipCardView.width + Self.cardSpacing
        let cardMinX = Self.wallPadding + CGFloat(index) * cardStride
        let cardMaxX = cardMinX + ClipCardView.width
        let visibleMinX = wallGeometry.offsetX
        let visibleMaxX = wallGeometry.offsetX + wallGeometry.viewportWidth

        if cardMinX >= visibleMinX, cardMaxX <= visibleMaxX {
            return
        }

        let maxOffset = max(0, wallGeometry.contentWidth - wallGeometry.viewportWidth)
        let rawTarget = cardMinX < visibleMinX
            ? cardMinX - Self.wallPadding
            : cardMaxX + Self.wallPadding - wallGeometry.viewportWidth
        let targetX = min(max(0, rawTarget), maxOffset)

        if reduceMotion {
            wallPosition.scrollTo(x: targetX)
        } else {
            withAnimation(Motion.scroll) {
                wallPosition.scrollTo(x: targetX)
            }
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

        return viewModel.board == .pinned ? "还没有固定的内容" : "复制的文字、图片、文件会出现在这里"
    }

    // MARK: - Footer

    /// 常驻辅助条（DESIGN §4.7）：结果数量 + 核心按键提示，兜住引导看完就忘的用户。
    private var footerBar: some View {
        HStack(spacing: 12) {
            Text("\(viewModel.filteredClips.count) 条")
                .foregroundStyle(.secondary)
                .monospacedDigit()

            Spacer(minLength: 8)

            Text("← → 选择 · 回车\(footerReturnHint) · 空格预览 · ⌘P 固定")
                .foregroundStyle(.tertiary)
                .lineLimit(1)
        }
        .font(.caption)
        .padding(.horizontal, 20)
        .padding(.bottom, 12)
    }

    private var footerReturnHint: String {
        appSettings.autoPasteAfterSelection && eventPostingPermission.isGranted ? "粘贴" : "复制"
    }

    // MARK: - Actions

    /// 卡片右键动作列表，保持为高频操作，不放开发者转换类动作。
    @ViewBuilder
    private func clipActions(for clip: ClipItem) -> some View {
        Button(returnActionTitle) {
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
        let shape = RoundedRectangle(cornerRadius: 14, style: .continuous)

        return HStack(spacing: 10) {
            ZStack {
                Circle()
                    .fill(banner.kind.tint.opacity(0.14))
                    .frame(width: 24, height: 24)

                Image(systemName: banner.kind.symbolName)
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(banner.kind.tint)
            }

            Text(banner.message)
                .font(.caption.weight(.medium))
                .foregroundStyle(.primary)
                .lineLimit(2)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(.leading, 9)
        .padding(.trailing, 13)
        // 宽度随内容自适应，长消息（授权类警告）最多两行，不再被固定宽度截断。
        .frame(minHeight: 42)
        .frame(maxWidth: 420)
        .background {
            if reduceTransparency {
                shape
                    .fill(Color(nsColor: .windowBackgroundColor))
            } else {
                shape
                    .fill(Color(nsColor: .windowBackgroundColor).opacity(0.16))
                    .glassEffect(.regular, in: shape)
            }
        }
        .shadow(color: .black.opacity(0.12), radius: 8, x: 0, y: 3)
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
                    onboardingLine(appSettings.hotKeyPreset.symbols, "在任意 App 呼出 / 隐藏这个面板")
                    onboardingLine("← →", "左右浏览 · 按空格放大预览")
                    onboardingLine("回车", "把选中内容复制到剪贴板")
                    onboardingLine("⌘P / ⌘⌫", "固定常用内容 / 删除选中")
                }
                .font(.callout)

                Text("呼出快捷键是 \(appSettings.hotKeyPreset.displayName)。想按回车后自动粘贴回刚才的 App，可以在设置里开启。")
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
            // 浮层本体在 scrim 淡入之上叠加 0.98 → 1 的轻微缩放（DESIGN §8 面板出现动效）。
            .transition(.opacity.combined(with: .scale(scale: 0.98)))
        }
    }

    private func onboardingLine(_ key: String, _ desc: String) -> some View {
        HStack(spacing: 10) {
            Text(key)
                .font(.callout.monospaced())
                .fontWeight(.medium)
                .frame(width: 90, alignment: .leading)
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
                    .fill(.black.opacity(0.24))
                    .ignoresSafeArea()
                    .onTapGesture { showPreview = false }

                previewPanel(for: clip)
                    .padding(20)
                    .transition(.opacity.combined(with: .scale(scale: 0.98)))
            }
        }
    }

    private func previewPanel(for clip: ClipItem) -> some View {
        let shellShape = RoundedRectangle(cornerRadius: 22, style: .continuous)

        return VStack(alignment: .leading, spacing: 12) {
            previewHeader(for: clip)
            previewContentSurface(for: clip)
        }
        .padding(14)
        .frame(maxWidth: 560, maxHeight: 306)
        .background {
            if reduceTransparency {
                shellShape
                    .fill(Color(nsColor: .windowBackgroundColor))
            } else {
                shellShape
                    .fill(Color(nsColor: .windowBackgroundColor).opacity(0.14))
                    .glassEffect(.regular, in: shellShape)
            }
        }
        .shadow(color: .black.opacity(0.16), radius: 16, x: 0, y: 6)
    }

    private func previewHeader(for clip: ClipItem) -> some View {
        HStack(spacing: 8) {
            TablerIconView(name: clip.kind.tablerIconName, fallbackSystemName: clip.kind.symbolName)
                .foregroundStyle(clip.kind.accent)
                .frame(width: 15, height: 15)

            Text(clip.kind.displayName)
                .fontWeight(.semibold)

            Text(clip.source)
                .foregroundStyle(.secondary)

            Spacer()

            Text("空格 / Esc 关闭 · Return \(returnActionTitle)")
                .font(.caption)
                .foregroundStyle(.tertiary)
        }
        .font(.callout)
        .padding(.horizontal, 4)
    }

    private func previewContentSurface(for clip: ClipItem) -> some View {
        let contentShape = RoundedRectangle(cornerRadius: 12, style: .continuous)

        return previewBody(for: clip)
            .padding(12)
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
            .background {
                contentShape
                    .fill(Color(nsColor: .textBackgroundColor).opacity(0.94))
            }
    }

    @ViewBuilder
    private func previewBody(for clip: ClipItem) -> some View {
        let mono = clip.kind == .code || clip.kind == .json || clip.kind == .command

        if clip.isSensitive {
            VStack(spacing: 6) {
                Text("敏感内容已隐藏")
                    .foregroundStyle(.secondary)

                Text("为保护隐私没有保存原文，需要时请回到原来的 App 重新复制。")
                    .font(.caption)
                    .foregroundStyle(.tertiary)
            }
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

    /// 安装本地 scrollWheel 监听：把「纵向为主」的滚轮 / 触控板滚动映射为卡片墙横向滚动
    /// （Paste 惯例，Magic Mouse / 滚轮鼠标才能逛卡片墙）；横向手势保持原生行为。
    private func installScrollWheelMonitor() {
        guard scrollWheelMonitor == nil else { return }
        scrollWheelMonitor = NSEvent.addLocalMonitorForEvents(matching: .scrollWheel) { event in
            handleScrollWheel(event)
        }
    }

    private func handleScrollWheel(_ event: NSEvent) -> NSEvent? {
        // 只接管浮动无边框面板自己的滚动；预览 / 引导覆盖层期间放行（预览里有纵向滚动区）。
        guard
            let window = event.window,
            window.styleMask.contains(.borderless),
            window.level == .floating,
            !showPreview, !showOnboarding,
            !viewModel.filteredClips.isEmpty
        else {
            return event
        }

        let deltaX = event.scrollingDeltaX
        let deltaY = event.scrollingDeltaY

        guard abs(deltaY) > abs(deltaX) else {
            return event
        }

        // 非精确滚动（传统滚轮）按行计数，放大到舒适的步进。
        let factor: CGFloat = event.hasPreciseScrollingDeltas ? 1 : 24
        let maxOffset = max(0, wallGeometry.contentWidth - wallGeometry.viewportWidth)
        let targetX = min(max(0, wallGeometry.offsetX - deltaY * factor), maxOffset)
        wallPosition.scrollTo(x: targetX)
        return nil
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

        // 引导覆盖层期间：Return / Esc / 空格关闭引导；直接打字则关掉引导并把
        // 按键透传给搜索框（第一反应就是搜索的用户不该被卡住）；其余组合键吞掉。
        if showOnboarding {
            switch (event.keyCode, mods) {
            case (36, []), (76, []), (53, []), (49, []):
                dismissOnboarding()
                return nil
            default:
                if
                    mods.subtracting(.shift).isEmpty,
                    let character = event.charactersIgnoringModifiers?.first,
                    character.isLetter || character.isNumber || character.isPunctuation || character.isSymbol
                {
                    dismissOnboarding()
                    return event
                }
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
        case (18, [.command]): // ⌘1 剪贴板分区
            switchBoard(.clipboard)
            return nil
        case (19, [.command]): // ⌘2 已固定分区
            switchBoard(.pinned)
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

    /// 键盘切换分区（⌘1/⌘2），与点击分段标签共用同一滑动动效。
    private func switchBoard(_ board: QuickPanelViewModel.Board) {
        guard viewModel.board != board else { return }

        if reduceMotion {
            viewModel.board = board
        } else {
            withAnimation(Motion.tabSlide) {
                viewModel.board = board
            }
        }
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
            return "没有保存原文，请回到原来的 App 重新复制"
        }

        return "无法写入剪贴板"
    }
}

private struct StatusBanner: Equatable {
    let id = UUID()
    let message: String
    let kind: QuickPanelStatusKind
}

/// 卡片墙滚动几何：内容偏移 + 视口宽 + 内容总宽。
private struct WallGeometry: Equatable {
    var offsetX: CGFloat = 0
    var viewportWidth: CGFloat = 0
    var contentWidth: CGFloat = 0
}

/// 键盘落卡脉冲：token 每次都变，保证同一张卡连续触发也能重播。
private struct KeyboardPulse: Equatable {
    let clipID: ClipItem.ID
    let token = UUID()
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
