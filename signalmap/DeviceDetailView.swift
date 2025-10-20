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
    let debug = false
    var body: some View {
        if let device = scanner.devices[id] {

            VStack {
                DeviceCard(id: device.id, device: device).padding()
                DeviceMapView(device: device)
                if debug {
                    VStack {
                        Text("Advertisement Data: \(device.advertisementData.count)").font(.headline)
                        ForEach(device.advertisementData.keys.sorted(), id: \.self) { key in
                            HStack {
                                Text(key)
                                Spacer()

                                Text(verbatim: String(describing: device.advertisementData[key] ?? "unknown"))
                            }.padding(.horizontal, 8)
                        }.padding(.bottom)
                        if device.services.isEmpty {
                            HStack {
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

                HStack {
                    HStack {
                        Text("RssI: ")
                        HStack(spacing: 1) {
                            Rectangle()
                                .fill(Color.black)
                                .frame(width: 15, height: 15)
                                .cornerRadius(1)
                            Rectangle()
                                .fill(Color.green)
                                .frame(width: 15, height: 15)
                                .cornerRadius(1)
                            Rectangle()
                                .fill(Color.yellow)
                                .frame(width: 15, height: 15)
                                .cornerRadius(1)
                            Rectangle()
                                .fill(Color.red)
                                .frame(width: 15, height: 15)
                                .cornerRadius(1)
                        }
                    }
                    Spacer()
                    Button {
                        scanner.devices[id]?.locations = []

                    } label: {
                        Text("Clear HeatMap")
                    }
                }.padding(EdgeInsets(top: 5, leading: 10, bottom: 10, trailing: 10))
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
        services: [],
        locations: []
    )
    DeviceDetailView(scanner: BLEScanner(), id: device.id)
}
