import Darwin

struct MuxWindowSize: Codable, Equatable, Sendable {
    var cols: UInt16
    var rows: UInt16
    var width: UInt16
    var height: UInt16

    init(cols: UInt16, rows: UInt16, width: UInt16, height: UInt16) {
        self.cols = cols
        self.rows = rows
        self.width = width
        self.height = height
    }

    init(_ size: winsize) {
        self.init(cols: size.ws_col, rows: size.ws_row, width: size.ws_xpixel, height: size.ws_ypixel)
    }

    var winsize: winsize {
        Darwin.winsize(ws_row: max(rows, 1), ws_col: max(cols, 1), ws_xpixel: width, ws_ypixel: height)
    }
}
