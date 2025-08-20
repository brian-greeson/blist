import SwiftUI
import CoreBluetooth

struct BleDevice {
var name: String
var rssi: Int
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

    func centralManager(_ central: CBCentralManager,
                        didDiscover peripheral: CBPeripheral,
                        advertisementData: [String : Any],
                        rssi RSSI: NSNumber) {
        let name = peripheral.name
            ?? (advertisementData[CBAdvertisementDataLocalNameKey] as? String)
            ?? "Unknown"
        
        let identifier = peripheral.identifier
        print(peripheral)

        Task { @MainActor in
            devices[identifier] = BleDevice(name: name, rssi: RSSI.intValue)
        
        }
    }

    // public API you call from the UI
    @MainActor func start() {
        guard central.state == .poweredOn else { return }
        devices.removeAll()
        isScanning = true
        central.scanForPeripherals(withServices: nil,
                                   options: [CBCentralManagerScanOptionAllowDuplicatesKey: false])
    }

    @MainActor func stop() {
        guard isScanning else { return }
        central.stopScan()
        isScanning = false
    }
}
