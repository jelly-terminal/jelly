import Darwin
import Dispatch
import Foundation

final class FileWatcher {
    private let path: String
    private let onChange: () -> Void
    private var source: DispatchSourceFileSystemObject?
    private var pending: DispatchWorkItem?

    init(path: String, onChange: @escaping () -> Void) {
        self.path = path
        self.onChange = onChange
        arm()
    }

    isolated deinit {
        pending?.cancel()
        source?.cancel()
    }

    private func arm() {
        let descriptor = open(path, O_EVTONLY)
        guard descriptor >= 0 else { return }
        let source = DispatchSource.makeFileSystemObjectSource(
            fileDescriptor: descriptor,
            eventMask: [.write, .extend, .delete, .rename],
            queue: .main
        )
        source.setEventHandler { [weak self] in
            guard let self, let source = self.source else { return }
            let replaced = !source.data.isDisjoint(with: [.delete, .rename])
            self.schedule(rearm: replaced)
        }
        source.setCancelHandler { close(descriptor) }
        self.source = source
        source.resume()
    }

    private func schedule(rearm: Bool) {
        if rearm {
            source?.cancel()
            source = nil
        }
        pending?.cancel()
        let work = DispatchWorkItem { [weak self] in
            guard let self else { return }
            if self.source == nil { self.arm() }
            self.onChange()
        }
        pending = work
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.15, execute: work)
    }
}
