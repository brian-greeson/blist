import CoreBluetooth
import SwiftUI

struct BleDevice: Identifiable {
    var id: UUID
    var name: String
    var rssi: Int
    var advertisementData: [String: Any]
    var lastUpdated: Date
    var services: [CBService]
}

final class BLEScanner: NSObject, ObservableObject, CBCentralManagerDelegate,CBPeripheralDelegate {
    @MainActor @Published var devices: [UUID: BleDevice] = [:]
    @MainActor @Published var isScanning = false
    @MainActor @Published var state: CBManagerState = .unknown
    @MainActor var statusText: String {
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
    private var peripherals: [UUID: CBPeripheral] = [:]

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
    
    func centralManager(_ central: CBCentralManager, didConnect peripheral: CBPeripheral) {
        print("central manager didConnect")
        guard ( peripheral.state == .connected) else {
            print("not connected")
            return
        }
        peripheral.delegate = self
        peripheral.discoverServices(nil)
    }
    
    func centralManager(
        _ central: CBCentralManager,
        didDiscover peripheral: CBPeripheral,
        advertisementData: [String: Any],
        rssi RSSI: NSNumber
    ) {
        // Parse advertised info
        let name =
            peripheral.name
            ?? (advertisementData[CBAdvertisementDataLocalNameKey] as? String)
            ?? "unknown"

        let id = peripheral.identifier
        let newRSSI = RSSI.intValue
        let services = peripheral.services ?? []

        // Save a reference to the peripheal
        if peripherals[id] == nil {
            peripherals[id] = peripheral
        }

        Task { @MainActor in
            let now = Date()
            if let old = devices[id] {
                // Throttle update to 1 second
                if abs(now.timeIntervalSince(old.lastUpdated)) > 1 {
                    // Only update if RSSI moved enough (e.g., ≥ 2 dB)
                    if abs(old.rssi - newRSSI) >= 2 {
                        devices[id] = BleDevice(
                            id: id,
                            name: old.name,
                            rssi: newRSSI,
                            advertisementData: advertisementData,
                            lastUpdated: now,
                            services: services
                        )
                    }
                }
            } else {
                devices[id] = BleDevice(
                    id: id,
                    name: name,
                    rssi: newRSSI,
                    advertisementData: advertisementData,
                    lastUpdated: now,
                    services: services
                )
            }
        }
    }
    
    func peripheral(
        _ peripheral: CBPeripheral,
        didDiscoverServices error: (any Error)?
    ) {
        if error != nil {
            print("Error discovering services: \(String(describing: error))")
            return
        }
        print(peripheral.name ?? "Unknown Peripheral")
        print("services: \(peripheral.services ?? [])")
        Task { @MainActor in
            devices[peripheral.identifier]?.services = peripheral.services ?? []
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

    @MainActor func connect(_ deviceId: UUID) {
        guard let peripheral = peripherals[deviceId] else {
            print("Could not find peripheral with ID \(deviceId)")
            return
        }
        guard peripheral.state != .connected || peripheral.state != .connecting else {
            print("Device already Connecting")
            return
        }
        central.connect(peripheral)
    
       // Move this to did connect callback -> peripheral.discoverServices(nil)
    }

}
