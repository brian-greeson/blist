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

        if rssi > -45 {
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
                    Text(device.name.capitalized).font(.subheadline)
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
    @State private var hideUnknowns: Bool = false
    @State private var showDeviceDetails: Bool = false
    @State private var selectedDevice: BleDevice?

    var body: some View {
        NavigationStack {
            
            if scanner.state != CBManagerState.poweredOn {
                Text(scanner.statusText)
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            }
            
            let sortedDevices = scanner.devices.sorted { $0.value.rssi > $1.value.rssi }
            let nearbyDevices = sortedDevices.filter { !favorites.contains($0.key) }
                .filter { hideUnknowns ? $0.value.name != "unknown" : true }
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
                                Button {
                                    selectedDevice = device
                                    showDeviceDetails = true
                                } label: {
                                    DeviceCard(id: id, device: device)
                                }
                                .buttonStyle(.plain)
                                .buttonStyle(.borderless)
                                Button {
                                    if let deviceIndex = favorites.firstIndex(of: id) {
                                        favorites.remove(at: deviceIndex)
                                    }
                                } label: {
                                    Image(systemName: "star.fill")
                                }
                                .buttonStyle(.borderless)
                            }
                        }
                    }
                }
                
                Section {
                    ForEach(nearbyDevices, id: \.key) { id, device in
                        HStack {
                            Button {
                                selectedDevice = device
                                showDeviceDetails = true
                            } label: {
                                DeviceCard(id: id, device: device)
                            }
                            .buttonStyle(.plain)
                            .buttonStyle(.borderless)
                            Button {
                                if !favorites.contains(id) {
                                    favorites.append(id)
                                }
                            } label: {
                                Image(systemName: "star")
                            }
                            .buttonStyle(.borderless)
                        }
                    }
                } header: {
                    HStack {
                        Button {
                            hideUnknowns.toggle()
                        } label: {
                            Text(hideUnknowns ? "Show all" : "Hide Unknown")
                                .font(.caption)
                        }
                        Spacer()
                        Text("Showing \(nearbyDevices.count) nearby devices")
                        
                    }
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
                        Text(scanner.isScanning ? "Stop Scan" : "Start Scan")
                            .foregroundStyle(scanner.isScanning ? .red : .primary)
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
                    }
                }
            }
        }
        .sheet(item: $selectedDevice){ device in
            
                DeviceDetailView(device: device)
         
        }
    
    }


}

#Preview {
    ContentView()
}
