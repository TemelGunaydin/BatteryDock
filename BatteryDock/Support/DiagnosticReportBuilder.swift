import Foundation

enum DiagnosticReportBuilder {
    static func build(
        devices: [BluetoothBatteryDevice],
        lastUpdated: Date?,
        errorMessage: String?,
        preferences: AppPreferences
    ) -> String {
        var lines: [String] = [
            "BatteryDock Diagnostics",
            "App Version: \(bundleVersion)",
            "macOS: \(ProcessInfo.processInfo.operatingSystemVersionString)",
            "Generated: \(Date().ISO8601Format())",
            "Last Updated: \(lastUpdated?.ISO8601Format() ?? "nil")",
            "Error: \(errorMessage ?? "nil")",
            "Language: \(preferences.language.rawValue)",
            "Refresh Interval: \(preferences.refreshInterval.rawValue)",
            "Menu Bar Mode: \(preferences.menuBarDisplayMode.rawValue)",
            "Low Battery Notifications: \(preferences.lowBatteryNotificationsEnabled)",
            "Low Battery Threshold: \(preferences.lowBatteryThreshold)",
            "Shortcut: \(preferences.shortcut.displayText)",
            "Devices: \(devices.count)"
        ]

        for device in devices {
            lines.append("- \(device.name)")
            lines.append("  Category: \(device.category ?? "nil")")
            lines.append("  Address Suffix: \(addressSuffix(device.address))")
            if device.readings.isEmpty {
                lines.append("  Battery: unavailable")
            } else {
                for reading in device.readings {
                    lines.append("  \(reading.id): \(reading.percent)%")
                }
            }
        }

        return lines.joined(separator: "\n")
    }

    private static var bundleVersion: String {
        let info = Bundle.main.infoDictionary
        let version = info?["CFBundleShortVersionString"] as? String ?? "unknown"
        let build = info?["CFBundleVersion"] as? String ?? "unknown"
        return "\(version) (\(build))"
    }

    private static func addressSuffix(_ address: String?) -> String {
        guard let address else {
            return "nil"
        }

        let normalized = address.filter(\.isHexDigit)
        guard normalized.count >= 4 else {
            return "masked"
        }

        return "****\(normalized.suffix(4))"
    }
}
