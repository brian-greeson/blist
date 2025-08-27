//
//  DeviceDetailView.swift
//  blist
//
//  Created by Brian Greeson on 8/27/25.
//

import SwiftUI

struct DeviceDetailView: View {
    let device: BleDevice
    var body: some View {
        VStack {
            Text(device.name).font(.headline)
            Text(device.id.uuidString).font(.caption)
            Text("RSSI: \(device.rssi)")
            Text(device.lastUpdated, style: .relative)
        }
    }
}

#Preview {
    let device = BleDevice(id: UUID(), name: "Test Device", rssi: -65, lastUpdated: Date())
    DeviceDetailView(device: device)
}
