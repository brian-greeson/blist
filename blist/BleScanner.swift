import CoreBluetooth
import SwiftUI

struct BleDevice {
    var name: String
    var rssi: Int
    var lastUpdated: Date
}

final class BLEScanner: NSObject, ObservableObject, CBCentralManagerDelegate {
    @MainActor @Published var devices: [UUID: BleDevice] = [:]
    @MainActor @Published var isScanning = false
    @MainActor @Published var state: CBManagerState = .unknown

    private var central: CBCentralManager!

    override init() {
        super.init()
        central = CBCentralManager(delegate: self, queue: nil)
    }

    func centralManagerDidUpdateState(_ central: CBCentralManager) {
        Task { @MainActor in
            state = central.state
            if state != .poweredOn { isScanning = false }
        }
    }

    func centralManager(
        _ central: CBCentralManager,
        didDiscover peripheral: CBPeripheral,
        advertisementData: [String: Any],
        rssi RSSI: NSNumber
    ) {
        let name =
            peripheral.name
            ?? (advertisementData[CBAdvertisementDataLocalNameKey] as? String)
            ?? "Unknown"

        let id = peripheral.identifier
        let newRSSI = RSSI.intValue

        Task { @MainActor in
            let now = Date()
            if let old = devices[id] {
                // Throttle update to 1 second
                if (abs(now.timeIntervalSince(old.lastUpdated)) > 1) {
                    // Only update if RSSI moved enough (e.g., ≥ 2 dB)
                    if abs(old.rssi - newRSSI) >= 2 {
                        devices[id] = BleDevice(name: old.name, rssi: newRSSI, lastUpdated: now)
                    }
                }
            } else {
                devices[id] = BleDevice(name: name, rssi: newRSSI, lastUpdated: now)
            }
        }
    }

    // public API you call from the UI
    @MainActor func start() {
        guard central.state == .poweredOn else { return }
        devices.removeAll()
        isScanning = true
        central.scanForPeripherals(
            withServices: nil,
            options: [CBCentralManagerScanOptionAllowDuplicatesKey: true]
        )
    }

    @MainActor func stop() {
        guard isScanning else { return }
        central.stopScan()
        isScanning = false
    }
}
