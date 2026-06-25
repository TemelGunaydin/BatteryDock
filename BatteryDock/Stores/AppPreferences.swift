import Combine
import Foundation
import ServiceManagement

enum MenuBarDisplayMode: String, CaseIterable, Identifiable {
    case iconOnly
    case lowestPercent
    case criticalDevice

    var id: String { rawValue }
}

enum RefreshInterval: Int, CaseIterable, Identifiable {
    case manual = 0
    case thirtySeconds = 30
    case oneMinute = 60
    case fiveMinutes = 300

    var id: Int { rawValue }

    var seconds: TimeInterval? {
        rawValue == 0 ? nil : TimeInterval(rawValue)
    }
}

enum AppLanguage: String, CaseIterable, Identifiable {
    case turkish
    case english
    case german
    case spanish
    case french
    case italian
    case portuguese
    case japanese
    case korean
    case chineseSimplified

    var id: String { rawValue }
}

@MainActor
final class AppPreferences: ObservableObject {
    @Published var shortcut: KeyboardShortcut {
        didSet { saveShortcut() }
    }

    @Published private(set) var launchAtLoginEnabled: Bool

    @Published var lowBatteryNotificationsEnabled: Bool {
        didSet { defaults.set(lowBatteryNotificationsEnabled, forKey: Keys.lowBatteryNotificationsEnabled) }
    }

    @Published var lowBatteryThreshold: Int {
        didSet { defaults.set(lowBatteryThreshold, forKey: Keys.lowBatteryThreshold) }
    }

    @Published var menuBarDisplayMode: MenuBarDisplayMode {
        didSet { defaults.set(menuBarDisplayMode.rawValue, forKey: Keys.menuBarDisplayMode) }
    }

    @Published var refreshInterval: RefreshInterval {
        didSet { defaults.set(refreshInterval.rawValue, forKey: Keys.refreshInterval) }
    }

    @Published var language: AppLanguage {
        didSet { defaults.set(language.rawValue, forKey: Keys.language) }
    }

    @Published var statusMessage: String?

    private enum Keys {
        static let shortcutKeyCode = "shortcut.keyCode"
        static let shortcutModifiers = "shortcut.modifiers"
        static let lowBatteryNotificationsEnabled = "lowBatteryNotificationsEnabled"
        static let lowBatteryThreshold = "lowBatteryThreshold"
        static let menuBarDisplayMode = "menuBarDisplayMode"
        static let refreshInterval = "refreshInterval"
        static let language = "language"
    }

    private let defaults: UserDefaults

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
        shortcut = Self.loadShortcut(defaults: defaults)
        launchAtLoginEnabled = SMAppService.mainApp.status == .enabled
        lowBatteryNotificationsEnabled = defaults.bool(forKey: Keys.lowBatteryNotificationsEnabled)

        let savedThreshold = defaults.integer(forKey: Keys.lowBatteryThreshold)
        lowBatteryThreshold = [10, 20, 30].contains(savedThreshold) ? savedThreshold : 20

        if let rawMenuMode = defaults.string(forKey: Keys.menuBarDisplayMode),
           let mode = MenuBarDisplayMode(rawValue: rawMenuMode) {
            menuBarDisplayMode = mode
        } else {
            menuBarDisplayMode = .iconOnly
        }

        let rawInterval = defaults.object(forKey: Keys.refreshInterval) as? Int ?? RefreshInterval.oneMinute.rawValue
        refreshInterval = RefreshInterval(rawValue: rawInterval) ?? .oneMinute

        if let rawLanguage = defaults.string(forKey: Keys.language),
           let savedLanguage = AppLanguage(rawValue: rawLanguage) {
            language = savedLanguage
        } else {
            language = .turkish
        }
    }

    func setShortcut(_ shortcut: KeyboardShortcut) {
        guard shortcut.isRegisterableGlobalHotKey else {
            return
        }

        self.shortcut = shortcut
    }

    func setLaunchAtLoginEnabled(_ isEnabled: Bool) {
        do {
            if isEnabled {
                try SMAppService.mainApp.register()
            } else {
                try SMAppService.mainApp.unregister()
            }

            launchAtLoginEnabled = SMAppService.mainApp.status == .enabled
            statusMessage = nil
        } catch {
            launchAtLoginEnabled = SMAppService.mainApp.status == .enabled
            statusMessage = AppCopy(language: language).loginItemFailed
            NSLog("BatteryDock launch at login update failed: \(error)")
        }
    }

    func refreshLaunchAtLoginStatus() {
        launchAtLoginEnabled = SMAppService.mainApp.status == .enabled
    }

    func resetDefaults() {
        setShortcut(.defaultValue)
        lowBatteryNotificationsEnabled = false
        lowBatteryThreshold = 20
        menuBarDisplayMode = .iconOnly
        refreshInterval = .oneMinute
        language = .turkish
        statusMessage = nil
    }

    func markDiagnosticCopied() {
        statusMessage = AppCopy(language: language).diagnosticCopied
    }

    private func saveShortcut() {
        defaults.set(shortcut.keyCode, forKey: Keys.shortcutKeyCode)
        defaults.set(shortcut.modifiers, forKey: Keys.shortcutModifiers)
    }

    private static func loadShortcut(defaults: UserDefaults) -> KeyboardShortcut {
        let keyCode = defaults.object(forKey: Keys.shortcutKeyCode) as? NSNumber
        let modifiers = defaults.object(forKey: Keys.shortcutModifiers) as? NSNumber

        guard let keyCode, let modifiers else {
            return .defaultValue
        }

        let shortcut = KeyboardShortcut(
            keyCode: keyCode.uint32Value,
            modifiers: modifiers.uint32Value
        )

        return shortcut.isRegisterableGlobalHotKey ? shortcut : .defaultValue
    }
}
