import Carbon.HIToolbox
import Foundation

enum HotKeyRegistrationError: Error {
    case installFailed(OSStatus)
    case registerFailed(OSStatus)
}

private let hotKeyHandler: EventHandlerUPP = { _, _, userData in
    guard let userData else {
        return noErr
    }

    let manager = Unmanaged<HotKeyManager>.fromOpaque(userData).takeUnretainedValue()
    manager.handleHotKey()
    return noErr
}

final class HotKeyManager {
    private let shortcut: KeyboardShortcut
    private let action: @MainActor () -> Void

    private var eventHandlerRef: EventHandlerRef?
    private var hotKeyRef: EventHotKeyRef?

    init(shortcut: KeyboardShortcut, action: @escaping @MainActor () -> Void) {
        self.shortcut = shortcut
        self.action = action
    }

    deinit {
        unregister()
    }

    func register() throws {
        guard hotKeyRef == nil else {
            return
        }

        var eventType = EventTypeSpec(
            eventClass: OSType(kEventClassKeyboard),
            eventKind: UInt32(kEventHotKeyPressed)
        )

        let installStatus = InstallEventHandler(
            GetEventDispatcherTarget(),
            hotKeyHandler,
            1,
            &eventType,
            Unmanaged.passUnretained(self).toOpaque(),
            &eventHandlerRef
        )

        guard installStatus == noErr else {
            throw HotKeyRegistrationError.installFailed(installStatus)
        }

        let hotKeyID = EventHotKeyID(signature: 0x4244434B, id: 1) // BDCK
        let registerStatus = RegisterEventHotKey(
            shortcut.keyCode,
            shortcut.modifiers,
            hotKeyID,
            GetEventDispatcherTarget(),
            0,
            &hotKeyRef
        )

        guard registerStatus == noErr else {
            if let eventHandlerRef {
                RemoveEventHandler(eventHandlerRef)
                self.eventHandlerRef = nil
            }
            throw HotKeyRegistrationError.registerFailed(registerStatus)
        }
    }

    func unregister() {
        if let hotKeyRef {
            UnregisterEventHotKey(hotKeyRef)
            self.hotKeyRef = nil
        }

        if let eventHandlerRef {
            RemoveEventHandler(eventHandlerRef)
            self.eventHandlerRef = nil
        }
    }

    fileprivate func handleHotKey() {
        Task { @MainActor in
            action()
        }
    }
}
