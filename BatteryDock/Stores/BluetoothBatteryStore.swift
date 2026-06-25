import Combine
import Foundation

@MainActor
final class BluetoothBatteryStore: ObservableObject {
    @Published private(set) var devices: [BluetoothBatteryDevice] = []
    @Published private(set) var isRefreshing = false
    @Published private(set) var lastUpdated: Date?
    @Published private(set) var errorMessage: String?

    private let service: SystemProfilerBluetoothBatteryService
    private var refreshTask: Task<Void, Never>?

    init(service: SystemProfilerBluetoothBatteryService = SystemProfilerBluetoothBatteryService()) {
        self.service = service
    }

    deinit {
        refreshTask?.cancel()
    }

    func refresh() {
        guard !isRefreshing else {
            return
        }

        refreshTask?.cancel()
        isRefreshing = true
        errorMessage = nil

        refreshTask = Task { [service] in
            do {
                let loadedDevices = try await service.connectedDevices()
                guard !Task.isCancelled else {
                    return
                }

                devices = loadedDevices
                lastUpdated = Date()
            } catch {
                guard !Task.isCancelled else {
                    return
                }

                errorMessage = "Güncellenemedi"
            }

            isRefreshing = false
        }
    }
}
