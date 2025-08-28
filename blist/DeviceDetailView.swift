//
//  DeviceDetailView.swift
//  blist
//
//  Created by Brian Greeson on 8/27/25.
//

import SwiftUI

struct DeviceDetailView: View {
    @ObservedObject var scanner: BLEScanner
    let id: UUID

    var body: some View {
        if let device = scanner.devices[id] {

            VStack {
                DeviceCard(id: device.id, device: device).padding()
                VStack {
                    Text("Advertisement Data: \(device.advertisementData.count)").font(.headline)
                    ForEach(device.advertisementData.keys.sorted(), id: \.self) { key in
                        HStack {
                            Text(key)
                            Spacer()

                            Text("\(device.advertisementData[key] ?? "unknown")")
                        }.padding(.horizontal, 8)
                    }.padding(.bottom)
                    if device.services.isEmpty {
                        HStack{
                            Text("Loading Services").font(.headline)
                            ProgressView().padding()
                        }
                    } else {
                        Text("Services: \(device.services.count)").font(.headline)
                        ForEach(device.services.indices, id: \.self) { i in
                            Text("\(device.services[i])")
                        }
                    }
                }
                Spacer()

            }
        } else {
            Text("Error loading device")
        }
    }
}

#Preview {
    let adData: [String: Any] = ["kCBAdvDataLocalName": "Test Device", "kCBAdvDataIsConnectable": true]

    let device = BleDevice(
        id: UUID(),
        name: "Test Device",
        rssi: -65,
        advertisementData: adData,
        lastUpdated: Date(),
        services: []
    )
    DeviceDetailView(scanner: BLEScanner(), id: device.id)
}
