import CoreBluetooth
import CoreLocation
import SwiftUI

struct LocationWithRssi: Identifiable {
    let id = UUID()
    var location: CLLocation
    var rssi: Int
}
struct BleDevice: Identifiable {
    var id: UUID
    var name: String
    var rssi: Int
    var advertisementData: [String: Any]
    var lastUpdated: Date
    var services: [CBService]
    var locations: [LocationWithRssi]
}

@MainActor
final class BLEScanner: NSObject, ObservableObject, @MainActor CBCentralManagerDelegate, @MainActor CBPeripheralDelegate {
    @Published var devices: [UUID: BleDevice] = [:]
    @Published var isScanning = false
    @Published var state: CBManagerState = .unknown
    var statusText: String {
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
    
    let locationManager: LocationManager
    private var central: CBCentralManager!
    private var peripherals: [UUID: CBPeripheral] = [:]

    override init() {
        self.locationManager = LocationManager()
        super.init()
        central = CBCentralManager(delegate: self, queue: nil)
        if locationManager.authorized != true {
            locationManager.request()
        }
    }

    func centralManagerDidUpdateState(_ central: CBCentralManager) {
        state = central.state
        if state != .poweredOn { isScanning = false }
    }

    func centralManager(_ central: CBCentralManager, didConnect peripheral: CBPeripheral) {
        guard peripheral.state == .connected else {
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

        let now = Date()
        if var device = devices[id] {
            // Throttle update to 1 second
            if abs(now.timeIntervalSince(device.lastUpdated)) > 1 {
                device.name = name
                device.services = services

                // RSSI must be updated before location updates
                if abs(device.rssi - newRSSI) >= 2 {
                    device.rssi = newRSSI
                }

                if let location = locationManager.location {
                    if let lastLocation = device.locations.last {
                        let distance = location.distance(from: lastLocation.location)
                        if distance >= 1 {  // threshold; adjust as needed
                            device.locations.append(LocationWithRssi(location: location, rssi: device.rssi))
                        }
                    } else {
                        device.locations.append(LocationWithRssi(location: location, rssi: device.rssi))
                    }
                } else {
                    print("no location manager location")
                }
                device.lastUpdated = now
                devices[id] = device
            }
        } else {
            if let location = locationManager.location {
                devices[id] = BleDevice(
                    id: id,
                    name: name,
                    rssi: newRSSI,
                    advertisementData: advertisementData,
                    lastUpdated: now,
                    services: services,
                    locations: [LocationWithRssi(location: location, rssi: newRSSI)]
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
        devices[peripheral.identifier]?.services = peripheral.services ?? []
    }

    // Scanner API
    func start() {
        guard central.state == .poweredOn else { return }
        devices.removeAll()
        isScanning = true
        central.scanForPeripherals(
            withServices: nil,
            options: [CBCentralManagerScanOptionAllowDuplicatesKey: true]
        )
    }

    func stop() {
        guard isScanning else { return }
        central.stopScan()
        isScanning = false
    }

    func connect(_ deviceId: UUID) {
        guard let peripheral = peripherals[deviceId] else {
            print("Could not find peripheral with ID \(deviceId)")
            return
        }
        guard peripheral.state != .connected || peripheral.state != .connecting else {
            print("Device already Connecting")
            return
        }
        central.connect(peripheral)
    }

}
