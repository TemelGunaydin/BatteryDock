import Foundation
import IOBluetooth

enum BoseBMAPBatteryService {
    nonisolated private static let getOperator: UInt8 = 0x01
    nonisolated private static let statusOperator: UInt8 = 0x03
    nonisolated fileprivate static let batteryBlock: UInt8 = 0x02
    nonisolated fileprivate static let batteryFunction: UInt8 = 0x02
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

        let channelIDs = channelCandidates(productID: productID, name: name, category: category)
        for channelID in channelIDs {
            if let percent = BoseBMAPRFCOMMReader(device: device, channelID: channelID).readBatteryPercent() {
                return percent
            }
        }

        return nil
    }

    nonisolated private static func channelCandidates(
        productID: String?,
        name: String,
        category: String?
    ) -> [BluetoothRFCOMMChannelID] {
        if let productID = parseHexID(productID), productID == 0x400C || productID == 0x4020 {
            return [8, 2]
        }

        return [2, 8]
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
            (0...100).contains(percent)
        else {
            return nil
        }

        return percent
    }
}
