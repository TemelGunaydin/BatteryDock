import AppKit
import Combine
import SwiftUI

@MainActor
final class StatusBarController: NSObject, NSPopoverDelegate {
    private let store = BluetoothBatteryStore()
    private let preferences = AppPreferences()
    private let lowBatteryNotifier = LowBatteryNotifier()
    private let statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.squareLength)
    private let statusSymbolName = "minus.plus.batteryblock.fill"
    private let popover = NSPopover()
    private let settingsPopover = NSPopover()
    private var hotKeyManager: HotKeyManager?
    private var refreshTimer: Timer?
    private var cancellables = Set<AnyCancellable>()

    override init() {
        super.init()
        configureStatusItem()
        configurePopover()
        configureSettingsPopover()
        observeStore()
        observePreferences()
        store.refresh()
    }

    private func configureStatusItem() {
        guard let button = statusItem.button else {
            return
        }

        button.imagePosition = .imageOnly
        button.toolTip = "BatteryDock"
        button.target = self
        button.action = #selector(togglePopoverFromStatusItem)
        setStatusImage(named: statusSymbolName)
    }

    private func configurePopover() {
        popover.behavior = .transient
        popover.animates = true
        let hostingController = NSHostingController(
            rootView: BatteryPopoverView(
                store: store,
                preferences: preferences,
                onRefresh: { [store] in
                    store.refresh()
                },
                onSettings: { [weak self] in
                    self?.showSettingsPopover()
                },
                onQuit: {
                    NSApplication.shared.terminate(nil)
                }
            )
        )

        let contentSize = BatteryPopoverView.popoverSize(for: store.devices)
        hostingController.preferredContentSize = contentSize
        popover.contentSize = contentSize
        popover.contentViewController = hostingController
    }

    private func configureSettingsPopover() {
        settingsPopover.behavior = .transient
        settingsPopover.animates = true
        settingsPopover.contentSize = NSSize(width: 390, height: 560)
        settingsPopover.contentViewController = NSHostingController(
            rootView: AppSettingsView(
                preferences: preferences,
                onCopyDiagnostic: { [weak self] in
                    self?.copyDiagnostic()
                },
                onBack: { [weak self] in
                    self?.returnToMainPopover()
                }
            )
        )
    }

    private func observeStore() {
        store.$devices
            .combineLatest(store.$errorMessage)
            .sink { [weak self] devices, errorMessage in
                self?.updateStatusItem(devices: devices, errorMessage: errorMessage)
                self?.updatePopoverSize(devices: devices)
                self?.evaluateLowBattery(devices: devices)
            }
            .store(in: &cancellables)
    }

    private func observePreferences() {
        preferences.$shortcut
            .removeDuplicates()
            .sink { [weak self] shortcut in
                self?.registerHotKey(shortcut)
            }
            .store(in: &cancellables)

        preferences.$refreshInterval
            .removeDuplicates()
            .sink { [weak self] interval in
                self?.configureRefreshTimer(interval: interval)
            }
            .store(in: &cancellables)

        preferences.$lowBatteryNotificationsEnabled
            .removeDuplicates()
            .sink { [weak self] isEnabled in
                guard let self else {
                    return
                }

                if isEnabled {
                    self.lowBatteryNotifier.requestAuthorizationIfNeeded()
                }
                self.evaluateLowBattery(devices: self.store.devices)
            }
            .store(in: &cancellables)

        preferences.$lowBatteryThreshold
            .removeDuplicates()
            .sink { [weak self] _ in
                guard let self else {
                    return
                }

                self.updateStatusItem(devices: self.store.devices, errorMessage: self.store.errorMessage)
                self.evaluateLowBattery(devices: self.store.devices)
            }
            .store(in: &cancellables)

        preferences.$menuBarDisplayMode
            .combineLatest(preferences.$language)
            .sink { [weak self] _, _ in
                guard let self else {
                    return
                }

                self.updateStatusItem(devices: self.store.devices, errorMessage: self.store.errorMessage)
            }
            .store(in: &cancellables)
    }

    @objc private func togglePopoverFromStatusItem() {
        togglePopover()
    }

    private func togglePopover() {
        if popover.isShown {
            popover.performClose(nil)
            return
        }

        showPopover()
    }

    private func showPopover() {
        guard let button = statusItem.button else {
            return
        }

        store.refresh()
        updatePopoverSize(devices: store.devices)
        popover.show(relativeTo: button.bounds, of: button, preferredEdge: .minY)
        NSApp.activate(ignoringOtherApps: true)
    }

    private func showSettingsPopover() {
        guard let button = statusItem.button else {
            return
        }

        preferences.refreshLaunchAtLoginStatus()

        if popover.isShown {
            popover.performClose(nil)
        }

        if settingsPopover.isShown {
            settingsPopover.performClose(nil)
            return
        }

        settingsPopover.show(relativeTo: button.bounds, of: button, preferredEdge: .minY)
        NSApp.activate(ignoringOtherApps: true)
    }

    private func returnToMainPopover() {
        settingsPopover.performClose(nil)
        showPopover()
    }

    private func updatePopoverSize(devices: [BluetoothBatteryDevice]) {
        let contentSize = BatteryPopoverView.popoverSize(for: devices)
        popover.contentSize = contentSize
        popover.contentViewController?.preferredContentSize = contentSize
    }

    private func configureRefreshTimer(interval: RefreshInterval) {
        refreshTimer?.invalidate()
        refreshTimer = nil

        guard let seconds = interval.seconds else {
            return
        }

        refreshTimer = Timer.scheduledTimer(withTimeInterval: seconds, repeats: true) { [weak self] _ in
            guard let controller = self else {
                return
            }

            Task { @MainActor in
                controller.store.refresh()
            }
        }
    }

    private func evaluateLowBattery(devices: [BluetoothBatteryDevice]) {
        lowBatteryNotifier.evaluate(
            devices: devices,
            threshold: preferences.lowBatteryThreshold,
            isEnabled: preferences.lowBatteryNotificationsEnabled,
            language: preferences.language
        )
    }

    private func registerHotKey(_ shortcut: KeyboardShortcut) {
        hotKeyManager?.unregister()
        hotKeyManager = nil

        let manager = HotKeyManager(shortcut: shortcut) { [weak self] in
            self?.togglePopover()
        }

        do {
            try manager.register()
            hotKeyManager = manager
        } catch {
            NSLog("BatteryDock hot key registration failed: \(error)")
        }
    }

    private func copyDiagnostic() {
        let report = DiagnosticReportBuilder.build(
            devices: store.devices,
            lastUpdated: store.lastUpdated,
            errorMessage: store.errorMessage,
            preferences: preferences
        )

        NSPasteboard.general.clearContents()
        NSPasteboard.general.setString(report, forType: .string)
        preferences.markDiagnosticCopied()
    }

    private func setStatusImage(named systemName: String, title: String? = nil) {
        guard let button = statusItem.button else {
            return
        }

        statusItem.length = title == nil ? NSStatusItem.squareLength : NSStatusItem.variableLength
        button.imagePosition = title == nil ? .imageOnly : .imageLeft
        button.title = title ?? ""

        let configuration = NSImage.SymbolConfiguration(pointSize: 16, weight: .medium)
        let image = NSImage(systemSymbolName: systemName, accessibilityDescription: "BatteryDock")?
            .withSymbolConfiguration(configuration)

        if let image {
            image.isTemplate = true
            button.image = image
        } else {
            button.image = nil
            button.title = title ?? "BD"
        }
    }

    private func updateStatusItem(devices: [BluetoothBatteryDevice], errorMessage: String?) {
        if errorMessage != nil && devices.isEmpty {
            setStatusImage(named: "exclamationmark.triangle")
            return
        }

        guard let lowestBattery = lowestBattery(in: devices) else {
            setStatusImage(named: statusSymbolName)
            return
        }

        let title = menuBarTitle(for: lowestBattery)
        setStatusImage(named: statusSymbolName, title: title)
    }

    private func lowestBattery(in devices: [BluetoothBatteryDevice]) -> (device: BluetoothBatteryDevice, percent: Int)? {
        devices
            .compactMap { device -> (BluetoothBatteryDevice, Int)? in
                guard let percent = device.primaryPercent else {
                    return nil
                }
                return (device, percent)
            }
            .min { lhs, rhs in
                lhs.1 < rhs.1
            }
    }

    private func menuBarTitle(for battery: (device: BluetoothBatteryDevice, percent: Int)) -> String? {
        switch preferences.menuBarDisplayMode {
        case .iconOnly:
            return nil
        case .lowestPercent:
            return "\(battery.percent)%"
        case .criticalDevice:
            guard battery.percent <= preferences.lowBatteryThreshold else {
                return nil
            }

            return "\(shortStatusName(battery.device.name)) \(battery.percent)%"
        }
    }

    private func shortStatusName(_ name: String) -> String {
        let trimmed = name.trimmingCharacters(in: .whitespacesAndNewlines)
        guard trimmed.count > 12 else {
            return trimmed
        }

        return "\(trimmed.prefix(11))…"
    }
}
