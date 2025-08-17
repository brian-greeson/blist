import CoreBluetooth
//
//  ContentView.swift
//  blist
//
//  Created by Brian Greeson on 8/16/25.
//
import SwiftUI

struct ContentView: View {
    @StateObject private var scanner = BLEScanner()

    var body: some View {
        VStack(spacing: 12) {
            Button(scanner.isScanning ? "Stop" : "Scan") {
                scanner.isScanning ? scanner.stop() : scanner.start()
            }
            .buttonStyle(.borderedProminent)

            Text(statusText(scanner.state))
                .font(.footnote)
                .foregroundStyle(.secondary)

            List(scanner.devices.indices, id: \.self) { i in
                let item = scanner.devices[i]
                HStack {

                    Text(item.name)
                    Spacer()
                    Image(systemName: "chart.bar.fill", variableValue: rssiValue(item.rssi))
                    Text("RSSI \(item.rssi)")
                        .monospacedDigit()
                        .foregroundStyle(.secondary)
                }
            }
        }
        .padding()
    }
    func rssiValue(_ rssi: Int) -> Double {

        if rssi > -55 {
            return 1.0
        } else if rssi > -55 {
            return 0.5
        } else if rssi > -65 {
            return 0.25
        } else {
            return 0.0
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
