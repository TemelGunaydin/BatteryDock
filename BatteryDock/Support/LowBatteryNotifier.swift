import Foundation
import UserNotifications

final class LowBatteryNotifier: NSObject, UNUserNotificationCenterDelegate {
    private let center = UNUserNotificationCenter.current()
    private var notifiedKeys = Set<String>()

    override init() {
        super.init()
        center.delegate = self
    }

    func requestAuthorizationIfNeeded() {
        center.getNotificationSettings { [center] settings in
            guard settings.authorizationStatus == .notDetermined else {
                return
            }

            center.requestAuthorization(options: [.alert, .sound]) { _, error in
                if let error {
                    NSLog("BatteryDock notification authorization failed: \(error)")
                }
            }
        }
    }

    func evaluate(devices: [BluetoothBatteryDevice], threshold: Int, isEnabled: Bool, language: AppLanguage) {
        guard isEnabled else {
            notifiedKeys.removeAll()
            return
        }

        let copy = AppCopy(language: language)
        var currentLowKeys = Set<String>()

        for device in devices {
            for reading in device.readings where reading.percent <= threshold {
                let key = "\(device.id)-\(reading.id)"
                currentLowKeys.insert(key)

                guard !notifiedKeys.contains(key) else {
                    continue
                }

                notifiedKeys.insert(key)
                sendNotification(
                    title: "BatteryDock",
                    body: "\(device.name) · \(copy.readingLabel(reading)) \(reading.percent)%"
                )
            }
        }

        notifiedKeys = notifiedKeys.intersection(currentLowKeys)
    }

    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        willPresent notification: UNNotification,
        withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void
    ) {
        completionHandler([.banner, .sound])
    }

    private func sendNotification(title: String, body: String) {
        center.getNotificationSettings { [center] settings in
            guard settings.authorizationStatus == .authorized || settings.authorizationStatus == .provisional else {
                return
            }

            let content = UNMutableNotificationContent()
            content.title = title
            content.body = body
            content.sound = .default

            let request = UNNotificationRequest(
                identifier: "BatteryDock.lowBattery.\(UUID().uuidString)",
                content: content,
                trigger: nil
            )

            center.add(request) { error in
                if let error {
                    NSLog("BatteryDock notification scheduling failed: \(error)")
                }
            }
        }
    }
}
