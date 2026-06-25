import SwiftUI

struct BatteryPopoverView: View {
    static let width: CGFloat = 340
    static let minHeight: CGFloat = 220
    static let maxHeight: CGFloat = 640

    @ObservedObject var store: BluetoothBatteryStore
    @ObservedObject var preferences: AppPreferences

    let onRefresh: () -> Void
    let onSettings: () -> Void
    let onQuit: () -> Void

    private var copy: AppCopy {
        AppCopy(language: preferences.language)
    }

    static func popoverSize(for devices: [BluetoothBatteryDevice]) -> CGSize {
        CGSize(width: width, height: popoverHeight(for: devices))
    }

    var body: some View {
        VStack(spacing: 0) {
            header
            Divider()
            content
            Divider()
            footer
        }
        .frame(width: Self.width, height: Self.popoverHeight(for: store.devices))
        .background(.regularMaterial)
    }

    private static func popoverHeight(for devices: [BluetoothBatteryDevice]) -> CGFloat {
        guard !devices.isEmpty else {
            return minHeight
        }

        let chromeHeight: CGFloat = 106
        let dividerHeight = CGFloat(max(0, devices.count - 1))
        let rowsHeight = devices.reduce(CGFloat.zero) { height, device in
            height + rowHeight(for: device)
        }

        return min(max(chromeHeight + dividerHeight + rowsHeight, minHeight), maxHeight)
    }

    private static func rowHeight(for device: BluetoothBatteryDevice) -> CGFloat {
        let titleHeight: CGFloat = 17
        let verticalPadding: CGFloat = 20
        let titleSpacing: CGFloat = 8

        if device.readings.isEmpty {
            return verticalPadding + titleHeight + titleSpacing + 16
        }

        let readingHeight: CGFloat = 16
        let readingSpacing: CGFloat = 6
        let readingsHeight = CGFloat(device.readings.count) * readingHeight
            + CGFloat(max(0, device.readings.count - 1)) * readingSpacing

        return verticalPadding + titleHeight + titleSpacing + readingsHeight
    }

    private var header: some View {
        HStack(spacing: 10) {
            Image(systemName: "minus.plus.batteryblock.fill")
                .symbolRenderingMode(.hierarchical)
                .font(.system(size: 18, weight: .semibold))

            VStack(alignment: .leading, spacing: 2) {
                Text("BatteryDock")
                    .font(.headline)
                Text(copy.connectedDeviceCount(store.devices.count))
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .monospacedDigit()
            }

            Spacer()

            Button(action: onRefresh) {
                Image(systemName: "arrow.clockwise")
            }
            .buttonStyle(.borderless)
            .disabled(store.isRefreshing)
            .help(copy.refresh)
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 12)
    }

    @ViewBuilder
    private var content: some View {
        if store.isRefreshing && store.devices.isEmpty {
            loadingView
        } else if store.devices.isEmpty {
            emptyOrErrorView
        } else {
            ScrollView {
                LazyVStack(spacing: 0) {
                    ForEach(store.devices) { device in
                        BatteryDeviceRow(device: device, copy: copy)

                        if device.id != store.devices.last?.id {
                            Divider()
                                .padding(.leading, 52)
                        }
                    }
                }
            }
        }
    }

    private var loadingView: some View {
        VStack(spacing: 12) {
            ProgressView()
                .controlSize(.small)
            Text(copy.refreshing)
                .font(.callout)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private var emptyOrErrorView: some View {
        VStack(spacing: 12) {
            Image(systemName: store.errorMessage == nil ? "dot.radiowaves.left.and.right" : "exclamationmark.triangle")
                .font(.system(size: 28, weight: .medium))
                .foregroundStyle(.secondary)

            Text(store.errorMessage == nil ? copy.connectedDevicesEmpty : copy.bluetoothUnavailable)
                .font(.callout)
                .foregroundStyle(.secondary)

            if store.errorMessage != nil {
                Button(copy.retry, action: onRefresh)
                    .controlSize(.small)
            }
        }
        .multilineTextAlignment(.center)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding()
    }

    private var footer: some View {
        HStack {
            Text(footerStatus)
                .font(.caption)
                .foregroundStyle(.secondary)
                .lineLimit(1)

            Spacer()

            Button(action: onSettings) {
                Image(systemName: "gearshape")
            }
            .buttonStyle(.borderless)
            .help(copy.settings)

            Button(action: onQuit) {
                Image(systemName: "power")
            }
            .buttonStyle(.borderless)
            .help(copy.quit)
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 9)
    }

    private var footerStatus: String {
        if store.isRefreshing {
            return "\(copy.refreshing) · \(preferences.shortcut.displayText)"
        }

        if let errorMessage = store.errorMessage, !store.devices.isEmpty {
            return "\(errorMessage) · \(preferences.shortcut.displayText)"
        }

        guard let lastUpdated = store.lastUpdated else {
            return "\(copy.shortcut): \(preferences.shortcut.displayText)"
        }

        return "\(copy.lastUpdatedPrefix): \(lastUpdated.formatted(date: .omitted, time: .shortened)) · \(preferences.shortcut.displayText)"
    }
}

private struct BatteryDeviceRow: View {
    let device: BluetoothBatteryDevice
    let copy: AppCopy

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: symbolName)
                .font(.system(size: 18, weight: .medium))
                .foregroundStyle(.secondary)
                .frame(width: 26, height: 26)

            VStack(alignment: .leading, spacing: 8) {
                Text(device.name)
                    .font(.callout.weight(.medium))
                    .lineLimit(1)
                    .frame(maxWidth: .infinity, alignment: .leading)

                if device.readings.isEmpty {
                    Text(copy.noBatteryData)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                } else {
                    VStack(spacing: 6) {
                        ForEach(device.readings) { reading in
                            BatteryReadingView(reading: reading, copy: copy)
                        }
                    }
                }
            }
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 10)
    }

    private var symbolName: String {
        let text = "\(device.category ?? "") \(device.name)".lowercased()

        if text.contains("airpods") || text.contains("headphone") || text.contains("headset") {
            return "headphones"
        }

        if text.contains("keyboard") {
            return "keyboard"
        }

        if text.contains("trackpad") {
            return "rectangle.and.hand.point.up.left"
        }

        if text.contains("mouse") {
            return "computermouse"
        }

        return "dot.radiowaves.left.and.right"
    }
}

private struct BatteryReadingView: View {
    let reading: BatteryReading
    let copy: AppCopy

    var body: some View {
        HStack(spacing: 8) {
            Text(copy.readingLabel(reading))
                .font(.caption)
                .foregroundStyle(.secondary)
                .frame(width: 34, alignment: .leading)

            BatteryMeter(percent: reading.percent)

            Text("\(reading.percent)%")
                .font(.caption.weight(.medium))
                .foregroundStyle(.primary)
                .monospacedDigit()
                .frame(width: 42, alignment: .trailing)
        }
    }
}

private struct BatteryMeter: View {
    let percent: Int

    var body: some View {
        GeometryReader { proxy in
            ZStack(alignment: .leading) {
                Capsule()
                    .fill(.secondary.opacity(0.18))

                if percent > 0 {
                    Capsule()
                        .fill(batteryColor(for: percent))
                        .frame(width: proxy.size.width * CGFloat(percent) / 100)
                }
            }
        }
        .frame(height: 7)
    }
}

private func batteryColor(for percent: Int) -> Color {
    switch percent {
    case 0...20:
        return .red
    case 21...50:
        return .orange
    default:
        return .green
    }
}
