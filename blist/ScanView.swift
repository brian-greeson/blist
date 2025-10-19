import CoreBluetooth
import StoreKit
import SwiftData
import SwiftUI

//
//  ScanView.swift
//  blist
//
//  Created by Brian Greeson on 10/12/25.
//

struct ScanView: View {
    @Environment(\.modelContext) var modelContext
    @State private var hideUnknowns: Bool = false
    @State private var showDeviceDetails: Bool = false

    @Binding var selectedDevice: BleDevice?
    @ObservedObject var scanner: BLEScanner
    @Query var favoriteDevices: [FavoriteDevice]
    var body: some View {
        NavigationStack {

            if scanner.state != CBManagerState.poweredOn {
                Text(scanner.statusText)
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            }
            let favorites = Set(favoriteDevices.map(\.id))
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
                                    let newDevice = FavoriteDevice(id: device.id, name: device.name)
                                    removeFavorite(newDevice)
                                } label: {
                                    Image(systemName: "star.fill")
                                }
                                .buttonStyle(.borderless)
                            }
                        }
                    }
                } header: {
                    HStack {
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
                                let newDevice = FavoriteDevice(id: device.id, name: device.name)
                                addFavorite(newDevice)
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
        }
        .sheet(item: $selectedDevice) { device in

            DeviceDetailView(scanner: scanner, id: device.id)
                .onAppear {
                    print("appeared")
                    scanner.connect(device.id)
                }

        }
    }

    func addFavorite(_ device: FavoriteDevice) {
        if !favoriteDevices.contains(where: { $0.self.id == device.id }) {
            modelContext.insert(device)
            do {
                try modelContext.save()
            } catch {
                assertionFailure("Failed to save favorite: \(error)")
            }
        }
    }

    func removeFavorite(_ device: FavoriteDevice) {
        if let matchIndex = favoriteDevices.firstIndex(where: { $0.self.id == device.id }) {
            print("deleting \(device)")
            modelContext.delete(favoriteDevices[matchIndex])
            do {
                try modelContext.save()
            } catch {
                assertionFailure("Failed to save after delete: \(error)")
            }
        }
    }
}

#Preview {
    @Previewable @State var previewSelected: BleDevice? = nil
    ScanView(selectedDevice: $previewSelected, scanner: BLEScanner())
}
