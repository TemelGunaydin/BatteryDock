import Foundation
import IOBluetooth

enum BoseBMAPBatteryService {
    nonisolated private static let getOperator: UInt8 = 0x01
    nonisolated private static let statusOperator: UInt8 = 0x03
    nonisolated fileprivate static let batteryBlock: UInt8 = 0x02
    nonisolated fileprivate static let batteryFunction: UInt8 = 0x02
    nonisolated private static let failureCooldown: TimeInterval = 120
    nonisolated private static let cacheTTL: TimeInterval = 300
    nonisolated private static let cacheLock = NSLock()
    nonisolated(unsafe) private static var cachedBatteryByAddress: [String: CachedBattery] = [:]
    nonisolated(unsafe) private static var lastFailureByAddress: [String: Date] = [:]

    nonisolated fileprivate static let batteryCommand: [UInt8] = [
        batteryBlock,
        batteryFunction,
        getOperator,
        0x00
    ]

    nonisolated private static let bmapProductIDs: Set<Int> = [
        0x400C, // QuietComfort 35
        0x4020, // QuietComfort 35 II
        0x4024, // Noise Cancelling Headphones 700
        0x4039, // QuietComfort 45
        0x4062, // QuietComfort Ultra Earbuds (2nd Gen)
        0x4064, // QuietComfort Earbuds II
        0x4066, // QuietComfort Ultra Headphones
        0x4068, // Ultra Open Earbuds
        0x4072, // QuietComfort Ultra Earbuds
        0x4075, // QuietComfort Headphones
        0x4082  // QuietComfort Ultra Headphones (2nd Gen)
    ]

    nonisolated static func isKnownBMAPProduct(_ productID: Int) -> Bool {
        bmapProductIDs.contains(productID)
    }

    nonisolated static func batteryPercent(
        address: String,
        productID: String?,
        name: String,
        category: String?
    ) -> Int? {
        guard let device = IOBluetoothDevice(addressString: address) else {
            return nil
        }

        if let cachedPercent = cachedBatteryPercent(address: address) {
            return cachedPercent
        }

        guard shouldAttemptBatteryRead(address: address) else {
            return nil
        }

        let channelIDs = channelCandidates(productID: productID, name: name, category: category, device: device)
        for channelID in channelIDs {
            if let percent = BoseBMAPRFCOMMReader(device: device, channelID: channelID).readBatteryPercent() {
                cacheBatteryPercent(percent, address: address)
                return percent
            }
        }

        markBatteryReadFailure(address: address)
        return nil
    }

    nonisolated private static func channelCandidates(
        productID: String?,
        name: String,
        category: String?,
        device: IOBluetoothDevice
    ) -> [BluetoothRFCOMMChannelID] {
        if let productID = parseHexID(productID), productID == 0x400C || productID == 0x4020 {
            return ([8] + BoseBMAPSDPChannelResolver(device: device).channelCandidates() + [2]).uniqued()
        } else {
            return ([2] + BoseBMAPSDPChannelResolver(device: device).channelCandidates() + [8]).uniqued()
        }
    }

    nonisolated private static func parseHexID(_ rawValue: String?) -> Int? {
        guard let rawValue else {
            return nil
        }

        let trimmed = rawValue
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .replacingOccurrences(of: "0x", with: "")
            .replacingOccurrences(of: "0X", with: "")

        return Int(trimmed, radix: 16)
    }

    nonisolated private static func cachedBatteryPercent(address: String) -> Int? {
        let now = Date()

        cacheLock.lock()
        defer { cacheLock.unlock() }

        guard let cached = cachedBatteryByAddress[address] else {
            return nil
        }

        if now.timeIntervalSince(cached.date) <= cacheTTL {
            return cached.percent
        }

        cachedBatteryByAddress[address] = nil
        return nil
    }

    nonisolated private static func shouldAttemptBatteryRead(address: String) -> Bool {
        let now = Date()

        cacheLock.lock()
        defer { cacheLock.unlock() }

        guard let lastFailure = lastFailureByAddress[address] else {
            return true
        }

        return now.timeIntervalSince(lastFailure) > failureCooldown
    }

    nonisolated private static func cacheBatteryPercent(_ percent: Int, address: String) {
        cacheLock.lock()
        cachedBatteryByAddress[address] = CachedBattery(percent: percent, date: Date())
        lastFailureByAddress[address] = nil
        cacheLock.unlock()
    }

    nonisolated private static func markBatteryReadFailure(address: String) {
        cacheLock.lock()
        lastFailureByAddress[address] = Date()
        cacheLock.unlock()
    }
}

private struct CachedBattery {
    let percent: Int
    let date: Date
}

private extension Array where Element: Hashable {
    nonisolated func uniqued() -> [Element] {
        var seen: Set<Element> = []
        var result: [Element] = []

        for element in self where seen.insert(element).inserted {
            result.append(element)
        }

        return result
    }
}

private final class BoseBMAPRFCOMMReader: NSObject, IOBluetoothRFCOMMChannelDelegate {
    nonisolated(unsafe) private let device: IOBluetoothDevice
    private let channelID: BluetoothRFCOMMChannelID
    private let responseLock = NSLock()
    nonisolated(unsafe) private var responseBuffer = Data()

    nonisolated init(device: IOBluetoothDevice, channelID: BluetoothRFCOMMChannelID) {
        self.device = device
        self.channelID = channelID
        super.init()
    }

    nonisolated func readBatteryPercent() -> Int? {
        var channel: IOBluetoothRFCOMMChannel?
        let openResult = device.openRFCOMMChannelSync(&channel, withChannelID: channelID, delegate: self)
        guard openResult == kIOReturnSuccess, let channel else {
            return nil
        }
        defer {
            channel.close()
        }

        var command = BoseBMAPBatteryService.batteryCommand
        guard channel.writeSync(&command, length: UInt16(command.count)) == kIOReturnSuccess else {
            return nil
        }

        guard let response = waitForBatteryResponse(timeout: 2.0) else {
            return nil
        }

        return parseBatteryPercent(from: response)
    }

    nonisolated func rfcommChannelData(
        _ rfcommChannel: IOBluetoothRFCOMMChannel!,
        data dataPointer: UnsafeMutableRawPointer!,
        length dataLength: Int
    ) {
        guard let dataPointer, dataLength > 0 else {
            return
        }

        responseLock.lock()
        responseBuffer.append(dataPointer.assumingMemoryBound(to: UInt8.self), count: dataLength)
        responseLock.unlock()
    }

    nonisolated private func waitForBatteryResponse(timeout: TimeInterval) -> Data? {
        let deadline = Date().addingTimeInterval(timeout)

        while Date() < deadline {
            if let response = currentBatteryResponse() {
                return response
            }

            RunLoop.current.run(mode: .default, before: Date().addingTimeInterval(0.05))
        }

        return currentBatteryResponse()
    }

    nonisolated private func currentBatteryResponse() -> Data? {
        responseLock.lock()
        let buffer = responseBuffer
        responseLock.unlock()

        return firstBatteryResponse(in: buffer)
    }

    nonisolated private func firstBatteryResponse(in data: Data) -> Data? {
        let bytes = [UInt8](data)
        var offset = 0

        while offset + 4 <= bytes.count {
            let block = bytes[offset]
            let function = bytes[offset + 1]
            let op = bytes[offset + 2] & 0x0F
            let length = Int(bytes[offset + 3])
            let end = offset + 4 + length

            guard end <= bytes.count else {
                return nil
            }

            if block == 0x02, function == 0x02, op == 0x03 {
                return Data(bytes[offset..<end])
            }

            offset = end
        }

        return nil
    }

    nonisolated private func parseBatteryPercent(from response: Data) -> Int? {
        let bytes = [UInt8](response)
        guard bytes.count >= 5 else {
            return nil
        }

        let block = bytes[0]
        let function = bytes[1]
        let op = bytes[2] & 0x0F
        let payloadLength = Int(bytes[3])
        let percent = Int(bytes[4])

        guard
            block == 0x02,
            function == 0x02,
            op == 0x03,
            payloadLength > 0,
            (1...100).contains(percent)
        else {
            return nil
        }

        return percent
    }
}

private final class BoseBMAPSDPChannelResolver: NSObject {
    nonisolated(unsafe) private let device: IOBluetoothDevice
    nonisolated(unsafe) private var queryCompleted = false
    nonisolated(unsafe) private var resolvedChannels: [BluetoothRFCOMMChannelID] = []
    private let stateLock = NSLock()

    nonisolated init(device: IOBluetoothDevice) {
        self.device = device
        super.init()
    }

    nonisolated func channelCandidates(timeout: TimeInterval = 2.0) -> [BluetoothRFCOMMChannelID] {
        guard device.performSDPQuery(self) == kIOReturnSuccess else {
            return []
        }

        let deadline = Date().addingTimeInterval(timeout)
        while Date() < deadline {
            stateLock.lock()
            let isComplete = queryCompleted
            stateLock.unlock()

            if isComplete {
                break
            }

            RunLoop.current.run(mode: .default, before: Date().addingTimeInterval(0.05))
        }

        stateLock.lock()
        let channels = resolvedChannels
        stateLock.unlock()

        return channels
    }

    nonisolated func sdpQueryComplete(_ device: IOBluetoothDevice!, status: IOReturn) {
        var channels: [BluetoothRFCOMMChannelID] = []

        if status == kIOReturnSuccess, let device {
            channels.append(contentsOf: channelsForUUID(bmapUUID, device: device))
            channels.append(contentsOf: channelsForUUID(serialPortProfileUUID, device: device))
        }

        stateLock.lock()
        resolvedChannels = channels.uniqued()
        queryCompleted = true
        stateLock.unlock()
    }

    nonisolated private func channelsForUUID(
        _ uuid: IOBluetoothSDPUUID?,
        device: IOBluetoothDevice
    ) -> [BluetoothRFCOMMChannelID] {
        guard let uuid else {
            return []
        }

        if let service = device.getServiceRecord(for: uuid),
           let channelID = rfcommChannelID(for: service) {
            return [channelID]
        }

        let matchingServices = (device.services as? [IOBluetoothSDPServiceRecord] ?? [])
            .filter { service in
                service.attributes.description.lowercased().contains(uuid.description.lowercased())
            }

        return matchingServices.compactMap(rfcommChannelID)
    }

    nonisolated private func rfcommChannelID(for service: IOBluetoothSDPServiceRecord) -> BluetoothRFCOMMChannelID? {
        var channelID = BluetoothRFCOMMChannelID(0)
        guard service.getRFCOMMChannelID(&channelID) == kIOReturnSuccess else {
            return nil
        }

        return channelID
    }

    nonisolated private var bmapUUID: IOBluetoothSDPUUID? {
        let bytes: [UInt8] = [
            0x00, 0x00, 0x00, 0x00,
            0xde, 0xca, 0xfa, 0xde,
            0xde, 0xca, 0xde, 0xaf,
            0xde, 0xca, 0xca, 0xff
        ]

        return bytes.withUnsafeBytes { pointer in
            guard let baseAddress = pointer.baseAddress else {
                return nil
            }

            return IOBluetoothSDPUUID(bytes: baseAddress, length: bytes.count)
        }
    }

    nonisolated private var serialPortProfileUUID: IOBluetoothSDPUUID? {
        IOBluetoothSDPUUID(uuid16: 0x1101)
    }
}
