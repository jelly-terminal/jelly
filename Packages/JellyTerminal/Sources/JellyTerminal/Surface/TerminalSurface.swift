import AppKit
import JellyCore
import SwiftTerm

public final class TerminalSurface: TerminalView {
    public let paneID: PaneID
    public private(set) var title = ""
    public private(set) var currentDirectory: String?
    public private(set) var isRunning = false
    public private(set) var activity = TerminalActivity()

    public var onTitleChange: ((String) -> Void)?
    public var onDirectoryChange: ((String?) -> Void)?
    public var onGridSizeChange: ((Int, Int) -> Void)?
    public var onExit: ((Int32?) -> Void)?
    public var onContentRowsChange: ((Int) -> Void)?
    public private(set) var contentRows = 0

    private let appVersion: String
    private var appliedFont: NSFont?
    private lazy var events = SurfaceEvents(surface: self)
    private var notificationScanner = NotificationScanner()
    private var process: (any PaneProcess)?
    private var pendingInput: [UInt8] = []

    public init(paneID: PaneID = PaneID(), appVersion: String, settings: Settings, theme: Theme) {
        self.paneID = paneID
        self.appVersion = appVersion
        var options = TerminalOptions.default
        options.scrollback = settings.scrollback
        options.cursorStyle = Self.cursorStyle(settings.cursor)
        super.init(frame: CGRect(x: 0, y: 0, width: 640, height: 400), font: nil, options: options)
        terminalDelegate = events
        optionAsMetaKey = true
        try? setUseMetal(true)
        hideScroller()
        _ = apply(settings: settings, theme: theme)
    }

    public override func didAddSubview(_ subview: NSView) {
        super.didAddSubview(subview)
        if subview is NSScroller { subview.isHidden = true }
    }

    private func hideScroller() {
        for case let scroller as NSScroller in subviews {
            scroller.isHidden = true
        }
    }

    public required init?(coder: NSCoder) { fatalError() }

    public override func mouseDown(with event: NSEvent) {
        if window?.firstResponder !== self { window?.makeFirstResponder(self) }
        super.mouseDown(with: event)
    }

    public override func rightMouseDown(with event: NSEvent) {
        if window?.firstResponder !== self { window?.makeFirstResponder(self) }
        super.rightMouseDown(with: event)
    }

    public func recordInput() {
        activity.lastInput = .now
    }

    public override func bell(source: Terminal) {
        activity.alert(nil, at: .now)
        super.bell(source: source)
    }

    public var hasForegroundProcess: Bool {
        foregroundProcessGroup != nil
    }

    public var shellProcessID: pid_t? {
        guard isRunning, let pid = process?.shellPid, pid > 0 else { return nil }
        return pid
    }

    public var foregroundProcessGroup: pid_t? {
        guard isRunning, let pid = process?.shellPid else { return nil }
        return ForegroundProcess.group(ofShell: pid)
    }

    public func processIdentity(of pid: pid_t) -> ProcessIdentity? {
        ProcessArguments.identity(of: pid)
    }

    public var workingDirectory: String? {
        if isRunning, let pid = process?.shellPid, let live = ProcessDirectory.current(of: pid) { return live }
        return currentDirectory
    }

    public var gridSize: (cols: Int, rows: Int) {
        (terminal.cols, terminal.rows)
    }

    public func start(shell: ShellSettings, inheritedDirectory: String?, keepAlive: Bool, reattach: Bool) {
        let context = ShellLaunch.Context(inheritedDirectory: inheritedDirectory, appVersion: appVersion, paneID: paneID.rawValue.uuidString)
        let launch = ShellLaunch.resolve(shell, context: context)
        currentDirectory = launch.directory
        isRunning = true
        guard keepAlive || reattach else {
            connect(LocalPaneProcess(launch: launch, delegate: self))
            return
        }
        let request = MuxOpenRequest(
            pane: paneID.rawValue,
            launch: keepAlive ? launch : nil,
            size: MuxWindowSize(windowSize),
            scrollback: terminal.options.scrollback
        )
        DispatchQueue.global(qos: .userInitiated).async {
            let connection = MuxPaneProcess.connect(request, spawning: keepAlive)
            DispatchQueue.main.async { [weak self] in
                guard let self, self.isRunning, self.process == nil else {
                    connection.map(MuxPaneProcess.discard)
                    return
                }
                if let connection {
                    self.connect(MuxPaneProcess(connection: connection, delegate: self))
                } else {
                    self.connect(LocalPaneProcess(launch: launch, delegate: self))
                }
            }
        }
    }

    public var cellHeight: CGFloat {
        getOptimalFrameSize().height / CGFloat(max(terminal.rows, 1))
    }

    private func updateContentRows() {
        guard onContentRowsChange != nil else { return }
        let rows = measuredContentRows()
        guard rows != contentRows else { return }
        contentRows = rows
        onContentRowsChange?(rows)
    }

    private func measuredContentRows() -> Int {
        if terminal.isCurrentBufferAlternate { return terminal.rows }
        let lastFilled = (0..<terminal.rows).last { (terminal.getLine(row: $0)?.getTrimmedLength() ?? 0) > 0 } ?? -1
        let cursor = terminal.getCursorLocation()
        let cursorRow = isRunning && cursor.x > 0 ? cursor.y : -1
        return max(lastFilled, cursorRow) + 1
    }

    private func connect(_ process: any PaneProcess) {
        self.process = process
        process.resize(windowSize)
        guard !pendingInput.isEmpty else { return }
        process.send(pendingInput[...])
        pendingInput = []
    }

    @discardableResult
    public func apply(settings: Settings, theme: Theme) -> [Diagnostic] {
        let resolved = FontResolver.resolve(settings.font)
        if appliedFont != resolved.font {
            appliedFont = resolved.font
            font = resolved.font
        }

        installColors(theme.palette.map(Self.terminalColor))
        nativeForegroundColor = NSColor(theme.foreground)
        nativeBackgroundColor = NSColor(theme.background)
        backgroundOpacity = settings.window.backgroundOpacity
        caretColor = NSColor(theme.cursor)
        caretTextColor = NSColor(theme.cursorText)
        selectedTextBackgroundColor = NSColor(theme.selection)
        if let selectionText = theme.selectionText {
            selectedTextForegroundColor = NSColor(selectionText)
        }
        terminal.setCursorStyle(Self.cursorStyle(settings.cursor))
        if terminal.options.scrollback != settings.scrollback {
            terminal.changeHistorySize(settings.scrollback)
        }
        return resolved.diagnostics
    }

    public func stop() {
        guard isRunning else { return }
        isRunning = false
        process?.terminate()
    }

    public func copySelection() {
        copy(self)
    }

    public func pasteClipboard() {
        recordInput()
        paste(self)
    }

    public func sendText(_ text: String) {
        recordInput()
        send(txt: text)
    }

    public func clearScreen() {
        send(txt: "\u{0C}")
    }

    public func showFind() {
        let item = NSMenuItem()
        item.tag = NSTextFinder.Action.showFindInterface.rawValue
        performTextFinderAction(item)
    }

    public func insertPaths(_ urls: [URL]) {
        let quoted = urls.map { "'" + $0.path(percentEncoded: false).replacingOccurrences(of: "'", with: "'\\''") + "'" }
        send(txt: quoted.joined(separator: " ") + " ")
    }

    fileprivate func write(_ data: ArraySlice<UInt8>) {
        let data = QueryResponder.rewrite(data, version: appVersion)
        if let process {
            process.send(data)
        } else if isRunning {
            pendingInput += data
        }
    }

    fileprivate func gridSizeChanged(cols: Int, rows: Int) {
        process?.resize(windowSize)
        onGridSizeChange?(cols, rows)
    }

    fileprivate func titleChanged(_ title: String) {
        self.title = title
        onTitleChange?(title)
    }

    fileprivate func directoryChanged(_ directory: String?) {
        let path = directory.flatMap { URL(string: $0)?.path(percentEncoded: false) } ?? directory
        currentDirectory = path
        onDirectoryChange?(path)
    }

    private static func cursorStyle(_ cursor: CursorSettings) -> CursorStyle {
        switch (cursor.style, cursor.blink) {
        case (.block, true): .blinkBlock
        case (.block, false): .steadyBlock
        case (.bar, true): .blinkBar
        case (.bar, false): .steadyBar
        case (.underline, true): .blinkUnderline
        case (.underline, false): .steadyUnderline
        }
    }

    private static func terminalColor(_ color: ThemeColor) -> SwiftTerm.Color {
        SwiftTerm.Color(red8: UInt16(color.red), green8: UInt16(color.green), blue8: UInt16(color.blue))
    }
}

extension TerminalSurface: PaneProcessDelegate {
    var windowSize: winsize {
        let scale = window?.backingScaleFactor ?? NSScreen.main?.backingScaleFactor ?? 1
        let frame = getOptimalFrameSize()
        return winsize(
            ws_row: UInt16(clamping: terminal.rows),
            ws_col: UInt16(clamping: terminal.cols),
            ws_xpixel: UInt16(clamping: Int(frame.width * scale)),
            ws_ypixel: UInt16(clamping: Int(frame.height * scale))
        )
    }

    func paneProcess(didReceive data: ArraySlice<UInt8>) {
        let now = ContinuousClock.now
        activity.lastOutput = now
        for message in notificationScanner.scan(data) {
            activity.alert(message, at: now)
        }
        followMouseMode()
        feed(byteArray: data)
        followMouseMode()
        updateContentRows()
    }

    private func followMouseMode() {
        let reports = terminal.mouseMode != .off
        if allowMouseReporting != reports { allowMouseReporting = reports }
    }

    func paneProcessDidExit(_ exitCode: Int32?) {
        isRunning = false
        onExit?(exitCode)
    }
}

@MainActor
private final class SurfaceEvents: @preconcurrency TerminalViewDelegate {
    private weak var surface: TerminalSurface?

    init(surface: TerminalSurface) {
        self.surface = surface
    }

    func sizeChanged(source: TerminalView, newCols: Int, newRows: Int) {
        surface?.gridSizeChanged(cols: newCols, rows: newRows)
    }

    func setTerminalTitle(source: TerminalView, title: String) {
        surface?.titleChanged(title)
    }

    func hostCurrentDirectoryUpdate(source: TerminalView, directory: String?) {
        surface?.directoryChanged(directory)
    }

    func send(source: TerminalView, data: ArraySlice<UInt8>) {
        surface?.write(data)
    }

    func scrolled(source: TerminalView, position: Double) {}

    func rangeChanged(source: TerminalView, startY: Int, endY: Int) {}

    func requestOpenLink(source: TerminalView, link: String, params: [String: String]) {
        TerminalView.openDefaultLink(link)
    }

    func clipboardCopy(source: TerminalView, content: Data) {
        guard let text = String(bytes: content, encoding: .utf8) else { return }
        NSPasteboard.general.clearContents()
        NSPasteboard.general.writeObjects([text as NSString])
    }

    func clipboardRead(source: TerminalView) -> Data? {
        NSPasteboard.general.string(forType: .string)?.data(using: .utf8)
    }
}
