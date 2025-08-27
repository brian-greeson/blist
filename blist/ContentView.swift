import CoreBluetooth
import SwiftUI

//
//  ContentView.swift
//  blist
//
//  Created by Brian Greeson on 8/16/25.
//

struct DeviceCard: View {
    let id: UUID
    let device: BleDevice

    private func rssiValue(_ rssi: Int) -> Double {

        if rssi > -40 {
            return 1.0
        } else if rssi > -60 {
            return 0.5
        } else if rssi > -70 {
            return 0.25
        } else {
            return 0.0
        }
    }

    var body: some View {
        HStack {
            VStack {
                HStack {
                    Text(device.name).font(.subheadline)
                    Spacer()
                    Image(systemName: "chart.bar.fill", variableValue: rssiValue(device.rssi))
                    Text("RSSI \(device.rssi)")
                        .monospacedDigit()
                        .foregroundStyle(.secondary)
                        .font(.caption)
                }
                Text(id.uuidString)
                    .font(.body)
                    .lineLimit(1)
                    .minimumScaleFactor(0.5)
            }
        }
    }
}

struct ContentView: View {
    @StateObject private var scanner = BLEScanner()
    @State private var favorites: [UUID] = []

    var body: some View {
        NavigationStack {

            if scanner.state != CBManagerState.poweredOn {
                Text(statusText(scanner.state))
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            }

            let sortedDevices = scanner.devices.sorted { $0.value.rssi > $1.value.rssi }
            let nearbyDevices = sortedDevices.filter { !favorites.contains($0.key) }
            let favoriteDevices = sortedDevices.filter { favorites.contains($0.key) }

            List {
                Section("Favorites") {
                    if favorites.isEmpty {
                        Text("No favorites yet.")
                            .font(.body)
                            .foregroundStyle(.secondary)
                    } else {
                        ForEach(favoriteDevices, id: \.key) { id, device in
                            HStack {
                                DeviceCard(id: id, device: device)
                                Button {
                                    if let deviceIndex = favorites.firstIndex(of: id) {
                                        favorites.remove(at: deviceIndex)
                                    }
                                } label: {
                                    Image(systemName: "star.fill")
                                }
                            }
                        }
                    }
                }

                Section {
                    ForEach(nearbyDevices, id: \.key) { id, device in
                        HStack {
                            DeviceCard(id: id, device: device)
                            Button {
                                if !favorites.contains(id) {
                                    favorites.append(id)
                                }
                            } label: {
                                Image(systemName: "star")
                            }
                        }
                    }
                } header: {

                    Text("Showing \(nearbyDevices.count) nearby devices")
                }
            }
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button {
                    } label: {
                        Image(systemName: "map")
                    }
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        scanner.isScanning ? scanner.stop() : scanner.start()
                    } label: {
                        Image(
                            systemName: scanner.isScanning
                                ? "antenna.radiowaves.left.and.right" : "antenna.radiowaves.left.and.right.slash"
                        )
                        .foregroundStyle(scanner.isScanning ? .red : .primary)
                        .symbolEffect(
                            .variableColor.iterative.hideInactiveLayers.nonReversing,
                            options: .repeat(.continuous),
                            isActive: scanner.isScanning
                        )
                        Text(scanner.isScanning ? "Stop Scan" : "Start Scan")
                            .foregroundStyle(scanner.isScanning ? .red : .primary)
                    }
                }
            }
        }
    }

    private func statusText(_ s: CBManagerState) -> String {
        switch s {
        case .unknown: return "Bluetooth state: unknown"
        case .resetting: return "Bluetooth state: resetting"
        case .unsupported: return "Bluetooth unsupported on this device"
        case .unauthorized: return "Bluetooth unauthorized"
        case .poweredOff: return "Bluetooth is off"
        case .poweredOn: return "Bluetooth is on"
        @unknown default: return "Bluetooth state: ?"
        }
    }
}

#Preview {
    ContentView()
}
