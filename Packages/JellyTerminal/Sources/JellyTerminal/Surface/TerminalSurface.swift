import AppKit
import JellyCore
import SwiftTerm

public final class TerminalSurface: LocalProcessTerminalView {
    public let paneID: PaneID
    public private(set) var title = ""
    public private(set) var currentDirectory: String?
    public private(set) var isRunning = false
    public private(set) var activity = TerminalActivity()

    public var onTitleChange: ((String) -> Void)?
    public var onDirectoryChange: ((String?) -> Void)?
    public var onGridSizeChange: ((Int, Int) -> Void)?
    public var onExit: ((Int32?) -> Void)?

    private let appVersion: String
    private var appliedFont: NSFont?
    private lazy var events = ProcessEvents(surface: self)
    private var notificationScanner = NotificationScanner()

    public init(paneID: PaneID = PaneID(), appVersion: String, settings: Settings, theme: Theme) {
        self.paneID = paneID
        self.appVersion = appVersion
        var options = TerminalOptions.default
        options.scrollback = settings.scrollback
        options.cursorStyle = Self.cursorStyle(settings.cursor)
        super.init(frame: CGRect(x: 0, y: 0, width: 640, height: 400), font: nil, options: options)
        processDelegate = events
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

    public override func dataReceived(slice: ArraySlice<UInt8>) {
        let now = ContinuousClock.now
        activity.lastOutput = now
        for message in notificationScanner.scan(slice) {
            activity.alert(message, at: now)
        }
        super.dataReceived(slice: slice)
    }

    public override func bell(source: Terminal) {
        activity.alert(nil, at: .now)
        super.bell(source: source)
    }

    public var hasForegroundProcess: Bool {
        foregroundProcessGroup != nil
    }

    public var foregroundProcessGroup: pid_t? {
        guard isRunning, process.childfd >= 0 else { return nil }
        let group = tcgetpgrp(process.childfd)
        return group > 0 && group != process.shellPid ? group : nil
    }

    public func processIdentity(of pid: pid_t) -> ProcessIdentity? {
        ProcessArguments.identity(of: pid)
    }

    public var workingDirectory: String? {
        if isRunning, let live = ProcessDirectory.current(of: process.shellPid) { return live }
        return currentDirectory
    }

    public var gridSize: (cols: Int, rows: Int) {
        (terminal.cols, terminal.rows)
    }

    public func start(shell: ShellSettings, inheritedDirectory: String?) {
        let context = ShellLaunch.Context(inheritedDirectory: inheritedDirectory, appVersion: appVersion, paneID: paneID.rawValue.uuidString)
        let launch = ShellLaunch.resolve(shell, context: context)
        currentDirectory = launch.directory
        isRunning = true
        startProcess(
            executable: launch.executable,
            args: launch.args,
            environment: launch.environment,
            execName: launch.argv0,
            currentDirectory: launch.directory
        )
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
        terminate()
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

    public override func send(source: TerminalView, data: ArraySlice<UInt8>) {
        super.send(source: source, data: QueryResponder.rewrite(data, version: appVersion))
    }

    fileprivate func gridSizeChanged(cols: Int, rows: Int) {
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

    fileprivate func processExited(_ exitCode: Int32?) {
        isRunning = false
        onExit?(exitCode)
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

@MainActor
private final class ProcessEvents: @preconcurrency LocalProcessTerminalViewDelegate {
    private weak var surface: TerminalSurface?

    init(surface: TerminalSurface) {
        self.surface = surface
    }

    func sizeChanged(source: LocalProcessTerminalView, newCols: Int, newRows: Int) {
        surface?.gridSizeChanged(cols: newCols, rows: newRows)
    }

    func setTerminalTitle(source: LocalProcessTerminalView, title: String) {
        surface?.titleChanged(title)
    }

    func hostCurrentDirectoryUpdate(source: TerminalView, directory: String?) {
        surface?.directoryChanged(directory)
    }

    func processTerminated(source: TerminalView, exitCode: Int32?) {
        surface?.processExited(exitCode)
    }
}
