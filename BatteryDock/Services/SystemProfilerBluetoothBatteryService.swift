import Foundation
import IOKit

enum BluetoothBatteryError: LocalizedError {
    case profilerUnavailable
    case commandFailed(Int32, String)
    case invalidPayload

    var errorDescription: String? {
        switch self {
        case .profilerUnavailable:
            return "system_profiler bulunamadı."
        case .commandFailed(let status, let details):
            return "system_profiler hata kodu \(status): \(details)"
        case .invalidPayload:
            return "Bluetooth raporu okunamadı."
        }
    }
}

struct SystemProfilerBluetoothBatteryService: Sendable {
    private nonisolated static let profilerPath = "/usr/sbin/system_profiler"

    nonisolated init() {}

    nonisolated func connectedDevices() async throws -> [BluetoothBatteryDevice] {
        try await Task.detached(priority: .userInitiated) {
            try Self.connectedDevicesSync()
        }.value
    }

    private nonisolated static func connectedDevicesSync() throws -> [BluetoothBatteryDevice] {
        guard FileManager.default.isExecutableFile(atPath: profilerPath) else {
            throw BluetoothBatteryError.profilerUnavailable
        }

        let process = Process()
        let outputPipe = Pipe()
        let errorPipe = Pipe()

        process.executableURL = URL(fileURLWithPath: profilerPath)
        process.arguments = ["SPBluetoothDataType", "-json"]
        process.standardOutput = outputPipe
        process.standardError = errorPipe

        try process.run()
        process.waitUntilExit()

        let output = outputPipe.fileHandleForReading.readDataToEndOfFile()
        let errorOutput = errorPipe.fileHandleForReading.readDataToEndOfFile()

        guard process.terminationStatus == 0 else {
            let details = String(data: errorOutput, encoding: .utf8) ?? ""
            throw BluetoothBatteryError.commandFailed(process.terminationStatus, details)
        }

        let devices = try parseDevices(from: output)
        let fallbackPercentByAddress = ioRegistryBatteryPercentByAddress()
        let bosePercentByAddress = boseBMAPBatteryPercentByAddress(for: devices)

        guard !fallbackPercentByAddress.isEmpty || !bosePercentByAddress.isEmpty else {
            return devices
        }

        return devices.map { device in
            guard
                device.readings.isEmpty,
                let address = normalizedBluetoothAddress(device.address)
            else {
                return device
            }

            let readingID: String
            let percent: Int
            if let fallbackPercent = fallbackPercentByAddress[address] {
                readingID = "ioRegistryBatteryPercent"
                percent = fallbackPercent
            } else if let bosePercent = bosePercentByAddress[address] {
                readingID = "boseBMAPBatteryPercent"
                percent = bosePercent
            } else {
                return device
            }

            return BluetoothBatteryDevice(
                id: device.id,
                name: device.name,
                address: device.address,
                category: device.category,
                vendorID: device.vendorID,
                productID: device.productID,
                readings: [
                    BatteryReading(
                        id: readingID,
                        kind: .main,
                        label: "Pil",
                        percent: percent
                    )
                ]
            )
        }
    }

    private nonisolated static func parseDevices(from data: Data) throws -> [BluetoothBatteryDevice] {
        guard
            let root = try JSONSerialization.jsonObject(with: data) as? [String: Any],
            let controllers = root["SPBluetoothDataType"] as? [[String: Any]]
        else {
            throw BluetoothBatteryError.invalidPayload
        }

        return controllers.flatMap { controller -> [BluetoothBatteryDevice] in
            guard let connected = controller["device_connected"] as? [[String: Any]] else {
                return []
            }

            return connected.compactMap { entry in
                guard
                    let name = entry.keys.sorted().first,
                    let fields = entry[name] as? [String: Any]
                else {
                    return nil
                }

                let normalizedFields = fields.compactMapValues { value -> String? in
                    if let string = value as? String {
                        return string
                    }
                    if let number = value as? NSNumber {
                        return number.stringValue
                    }
                    return nil
                }

                let address = normalizedFields["device_address"]
                let id = address ?? name

                return BluetoothBatteryDevice(
                    id: id,
                    name: name,
                    address: address,
                    category: normalizedFields["device_minorType"],
                    vendorID: normalizedFields["device_vendorID"],
                    productID: normalizedFields["device_productID"],
                    readings: batteryReadings(from: normalizedFields)
                )
            }
        }
    }

    private nonisolated static func batteryReadings(from fields: [String: String]) -> [BatteryReading] {
        let knownKeys: [(key: String, kind: BatteryReading.Kind, label: String)] = [
            ("device_batteryLevelMain", .main, "Pil"),
            ("device_batteryLevelLeft", .left, "Sol"),
            ("device_batteryLevelRight", .right, "Sağ"),
            ("device_batteryLevelCase", .case, "Kutu")
        ]

        var readings = knownKeys.compactMap { item -> BatteryReading? in
            guard let rawValue = fields[item.key], let percent = parsePercent(rawValue) else {
                return nil
            }

            return BatteryReading(
                id: item.key,
                kind: item.kind,
                label: item.label,
                percent: percent
            )
        }

        let knownKeySet = Set(knownKeys.map(\.key))
        let extraReadings = fields.keys
            .filter { $0.hasPrefix("device_batteryLevel") && !knownKeySet.contains($0) }
            .sorted()
            .compactMap { key -> BatteryReading? in
                guard let rawValue = fields[key], let percent = parsePercent(rawValue) else {
                    return nil
                }

                let suffix = key.replacingOccurrences(of: "device_batteryLevel", with: "")
                let label = suffix.isEmpty ? "Pil" : suffix

                return BatteryReading(
                    id: key,
                    kind: .other,
                    label: label,
                    percent: percent
                )
            }

        readings.append(contentsOf: extraReadings)
        return readings
    }

    private nonisolated static func boseBMAPBatteryPercentByAddress(for devices: [BluetoothBatteryDevice]) -> [String: Int] {
        var batteriesByAddress: [String: Int] = [:]

        for device in devices where device.readings.isEmpty && isPotentialBoseBMAPDevice(device) {
            guard
                let address = device.address,
                let normalizedAddress = normalizedBluetoothAddress(address),
                let percent = BoseBMAPBatteryService.batteryPercent(
                    address: address,
                    productID: device.productID,
                    name: device.name,
                    category: device.category
                )
            else {
                continue
            }

            batteriesByAddress[normalizedAddress] = percent
        }

        return batteriesByAddress
    }

    private nonisolated static func isPotentialBoseBMAPDevice(_ device: BluetoothBatteryDevice) -> Bool {
        if let productID = parseHexID(device.productID), BoseBMAPBatteryService.isKnownBMAPProduct(productID) {
            return true
        }

        let name = device.name.lowercased()
        let category = (device.category ?? "").lowercased()
        let isAudioDevice = category.contains("headset")
            || category.contains("headphone")
            || category.contains("earbud")
            || category.contains("speaker")

        return name.contains("bose") && isAudioDevice
    }

    private nonisolated static func parsePercent(_ rawValue: String) -> Int? {
        let digits = rawValue.filter(\.isNumber)
        guard let percent = Int(digits), (0...100).contains(percent) else {
            return nil
        }
        return percent
    }

    private nonisolated static func parseHexID(_ rawValue: String?) -> Int? {
        guard let rawValue else {
            return nil
        }

        let trimmed = rawValue
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .replacingOccurrences(of: "0x", with: "")
            .replacingOccurrences(of: "0X", with: "")

        return Int(trimmed, radix: 16)
    }

    private nonisolated static func ioRegistryBatteryPercentByAddress() -> [String: Int] {
        guard let matching = IOServiceMatching("AppleDeviceManagementHIDEventService") else {
            return [:]
        }

        var iterator = io_iterator_t()
        guard IOServiceGetMatchingServices(kIOMainPortDefault, matching, &iterator) == KERN_SUCCESS else {
            return [:]
        }
        defer {
            IOObjectRelease(iterator)
        }

        var batteriesByAddress: [String: Int] = [:]

        while true {
            let service = IOIteratorNext(iterator)
            guard service != IO_OBJECT_NULL else {
                break
            }
            defer {
                IOObjectRelease(service)
            }

            guard
                let percent = registryInt(service, key: "BatteryPercent"),
                (0...100).contains(percent),
                isBluetoothRegistryService(service),
                let address = normalizedBluetoothAddress(
                    registryString(service, key: "DeviceAddress")
                        ?? registryString(service, key: "SerialNumber")
                )
            else {
                continue
            }

            batteriesByAddress[address] = percent
        }

        return batteriesByAddress
    }

    private nonisolated static func isBluetoothRegistryService(_ service: io_object_t) -> Bool {
        if let transport = registryString(service, key: "Transport")?.lowercased(),
           transport.contains("bluetooth") {
            return true
        }

        return registryBool(service, key: "BluetoothDevice") == true
    }

    private nonisolated static func registryString(_ service: io_object_t, key: String) -> String? {
        guard let value = registryValue(service, key: key) else {
            return nil
        }

        return value as? String
    }

    private nonisolated static func registryInt(_ service: io_object_t, key: String) -> Int? {
        guard let value = registryValue(service, key: key) else {
            return nil
        }

        if let number = value as? NSNumber {
            return number.intValue
        }

        if let string = value as? String {
            return Int(string)
        }

        return nil
    }

    private nonisolated static func registryBool(_ service: io_object_t, key: String) -> Bool? {
        guard let value = registryValue(service, key: key) else {
            return nil
        }

        if let number = value as? NSNumber {
            return number.boolValue
        }

        if let bool = value as? Bool {
            return bool
        }

        return nil
    }

    private nonisolated static func registryValue(_ service: io_object_t, key: String) -> Any? {
        IORegistryEntryCreateCFProperty(
            service,
            key as CFString,
            kCFAllocatorDefault,
            0
        )?.takeRetainedValue()
    }

    private nonisolated static func normalizedBluetoothAddress(_ rawValue: String?) -> String? {
        guard let rawValue else {
            return nil
        }

        let normalized = rawValue
            .filter(\.isHexDigit)
            .uppercased()

        guard normalized.count == 12 else {
            return nil
        }

        return normalized
    }
}
