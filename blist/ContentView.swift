import CoreBluetooth
import SwiftUI
import SwiftData
//
//  ContentView.swift
//  blist
//
//  Created by Brian Greeson on 8/16/25.
//

struct ContentView: View {
    @StateObject private var scanner = BLEScanner()
    
    @State private var favorites: [UUID] = []
    @State private var hideUnknowns: Bool = false
    @State private var showDeviceDetails: Bool = false
    @State private var selectedDevice: BleDevice?
    
    @Query var favoriteDevices: [FavoriteDevice]

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
                Section {
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
                               removeFavorite(device)
                                } label: {
                                    Image(systemName: "star.fill")
                                }
                                .buttonStyle(.borderless)
                            }
                        }
                    }
                } header: {
                    HStack{
                        Text("Favorites")
                        Spacer()
                        Text("\(favoriteDevices.count) Favorites")
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
                                addFavorite(device)
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
            
            DeviceDetailView(scanner: scanner, id: device.id)
                .onAppear {
                print("appeared")
                    scanner.connect(device.id)
                }
            
        }
    }
    func addFavorite(_ device: BleDevice) {
        if !favorites.contains(device.id) {
            favorites.append(device.id)
       }
   }
    func removeFavorite(_ device: BleDevice) {
       
        if let deviceIndex = favorites.firstIndex(of: device.id) {
            favorites.remove(at: deviceIndex)
        }
}
}
        


#Preview {
    ContentView()
}
