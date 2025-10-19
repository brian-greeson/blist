//
//  DeviceCard.swift
//  blist
//
//  Created by Brian Greeson on 8/27/25.
//

import SwiftUI

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
                        Text(device.name.capitalized).font(.headline)
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

#Preview {
    let adData: [String: Any] = ["kCBAdvDataLocalName": "Test Device", "kCBAdvDataIsConnectable": true]
    let device = BleDevice(id: UUID(), name: "Test Device", rssi: -65,advertisementData: adData,  lastUpdated: Date(), services: [], locations: [])
    DeviceCard(id: device.id, device: device)
}
