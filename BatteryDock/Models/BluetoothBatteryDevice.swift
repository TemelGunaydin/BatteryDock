import Foundation

struct BluetoothBatteryDevice: Identifiable, Equatable, Sendable {
    let id: String
    let name: String
    let address: String?
    let category: String?
    let vendorID: String?
    let productID: String?
    let readings: [BatteryReading]

    var primaryPercent: Int? {
        readings.first(where: { $0.kind == .main })?.percent ?? readings.map(\.percent).min()
    }
}

struct BatteryReading: Identifiable, Equatable, Sendable {
    enum Kind: Int, Sendable {
        case main
        case left
        case right
        case `case`
        case other
    }

    let id: String
    let kind: Kind
    let label: String
    let percent: Int
}
