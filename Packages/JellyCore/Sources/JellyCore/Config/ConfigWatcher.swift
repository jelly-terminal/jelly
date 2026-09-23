import Foundation

@MainActor
public final class ConfigWatcher {
    private let paths: ConfigPaths
    private let onChange: @MainActor () -> Void
    private var sources: [DispatchSourceFileSystemObject] = []
    private var debounce: Task<Void, Never>?

    public init(paths: ConfigPaths, onChange: @escaping @MainActor () -> Void) {
        self.paths = paths
        self.onChange = onChange
    }

    public func start() {
        rearm()
    }

    public func stop() {
        debounce?.cancel()
        sources.forEach { $0.cancel() }
        sources = []
    }

    private func rearm() {
        sources.forEach { $0.cancel() }
        sources = [paths.directory, paths.configFile, paths.themesDirectory].compactMap(watch)
    }

    private func watch(_ url: URL) -> DispatchSourceFileSystemObject? {
        let descriptor = open(url.path, O_EVTONLY)
        guard descriptor >= 0 else { return nil }
        let source = DispatchSource.makeFileSystemObjectSource(
            fileDescriptor: descriptor,
            eventMask: [.write, .extend, .delete, .rename],
            queue: .main
        )
        source.setEventHandler { [weak self] in
            MainActor.assumeIsolated { self?.changed() }
        }
        source.setCancelHandler { close(descriptor) }
        source.resume()
        return source
    }

    private func changed() {
        debounce?.cancel()
        debounce = Task { [weak self] in
            try? await Task.sleep(for: .milliseconds(100))
            guard !Task.isCancelled, let self else { return }
            self.rearm()
            self.onChange()
        }
    }
}
