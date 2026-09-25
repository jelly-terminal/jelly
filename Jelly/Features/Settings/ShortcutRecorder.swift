import AppKit
import JellyCore
import Observation

@Observable
final class ShortcutRecorder<Target: Hashable> {
    private(set) var target: Target?
    @ObservationIgnored private var monitor: Any?

    func start(_ target: Target, onRecord: @escaping (Target, KeyChord?) -> Void) {
        stop()
        self.target = target
        monitor = NSEvent.addLocalMonitorForEvents(matching: .keyDown) { [weak self] event in
            guard let self, let target = self.target else { return event }
            let modifiers = event.modifierFlags.intersection([.command, .option, .control, .shift])
            if modifiers.isEmpty, event.keyCode == 53 {
                self.stop()
            } else if modifiers.isEmpty, event.keyCode == 51 || event.keyCode == 117 {
                self.stop()
                onRecord(target, nil)
            } else if let chord = KeyChord(event: event), !chord.modifiers.isEmpty || Self.isFunctionKey(chord.key) {
                self.stop()
                onRecord(target, chord)
            } else {
                NSSound.beep()
            }
            return nil
        }
    }

    func stop() {
        if let monitor { NSEvent.removeMonitor(monitor) }
        monitor = nil
        target = nil
    }

    private static func isFunctionKey(_ key: String) -> Bool {
        key.count > 1 && key.hasPrefix("f") && Int(key.dropFirst()) != nil
    }
}
