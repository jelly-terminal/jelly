import Carbon.HIToolbox
import JellyCore

final class GlobalHotKey {
    nonisolated private static let signature: OSType = 0x4A4C4C59

    private let action: () -> Void
    private var hotKeyRef: EventHotKeyRef?
    private var handlerRef: EventHandlerRef?

    init?(chord: KeyChord, action: @escaping () -> Void) {
        self.action = action
        guard let keyCode = chord.carbonKeyCode else { return nil }
        var spec = EventTypeSpec(eventClass: OSType(kEventClassKeyboard), eventKind: UInt32(kEventHotKeyPressed))
        let installed = InstallEventHandler(
            GetEventDispatcherTarget(),
            { _, event, userData in
                guard let event, let userData else { return OSStatus(eventNotHandledErr) }
                var id = EventHotKeyID()
                GetEventParameter(event, EventParamName(kEventParamDirectObject), EventParamType(typeEventHotKeyID), nil, MemoryLayout<EventHotKeyID>.size, nil, &id)
                guard id.signature == GlobalHotKey.signature else { return OSStatus(eventNotHandledErr) }
                MainActor.assumeIsolated {
                    Unmanaged<GlobalHotKey>.fromOpaque(userData).takeUnretainedValue().action()
                }
                return noErr
            },
            1,
            &spec,
            Unmanaged.passUnretained(self).toOpaque(),
            &handlerRef
        )
        guard installed == noErr else { return nil }
        let id = EventHotKeyID(signature: Self.signature, id: 1)
        let registered = RegisterEventHotKey(keyCode, chord.carbonModifiers, id, GetEventDispatcherTarget(), 0, &hotKeyRef)
        guard registered == noErr else {
            if let handlerRef { RemoveEventHandler(handlerRef) }
            handlerRef = nil
            return nil
        }
    }

    isolated deinit {
        if let hotKeyRef { UnregisterEventHotKey(hotKeyRef) }
        if let handlerRef { RemoveEventHandler(handlerRef) }
    }
}
