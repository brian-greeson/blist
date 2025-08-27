import CoreBluetooth
import SwiftUI

struct BleDevice: Identifiable {
    var id: UUID
    var name: String
    var rssi: Int
    var lastUpdated: Date
}

final class BLEScanner: NSObject, ObservableObject, CBCentralManagerDelegate {
    @MainActor @Published var devices: [UUID: BleDevice] = [:]
    @MainActor @Published var isScanning = false
    @MainActor @Published var state: CBManagerState = .unknown
    @MainActor var statusText: String  {
        switch state {
        case .unknown: return "Bluetooth state: unknown"
        case .resetting: return "Bluetooth state: resetting"
        case .unsupported: return "Bluetooth unsupported on this device"
        case .unauthorized: return "Bluetooth unauthorized"
        case .poweredOff: return "Bluetooth is off"
        case .poweredOn: return "Bluetooth is on"
        @unknown default: return "Bluetooth state: ?"
        }
    }
    
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
            ?? "unknown"

        let id = peripheral.identifier
        let newRSSI = RSSI.intValue

        Task { @MainActor in
            let now = Date()
            if let old = devices[id] {
                // Throttle update to 1 second
                if (abs(now.timeIntervalSince(old.lastUpdated)) > 1) {
                    // Only update if RSSI moved enough (e.g., ≥ 2 dB)
                    if abs(old.rssi - newRSSI) >= 2 {
                        devices[id] = BleDevice(id: id, name: old.name, rssi: newRSSI, lastUpdated: now)
                    }
                }
            } else {
                devices[id] = BleDevice(id: id, name: name, rssi: newRSSI, lastUpdated: now)
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
