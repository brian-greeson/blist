import CoreBluetooth
//
//  ContentView.swift
//  blist
//
//  Created by Brian Greeson on 8/16/25.
//
import SwiftUI
struct CapsuleButton: ViewModifier {
    var isOn: Bool

    func body(content: Content) -> some View {
        content
            .padding(.vertical, 10)
            .padding(.horizontal, 15)
            .background(isOn ? Color.red : Color.blue)
            .foregroundStyle(.white)
            .clipShape(Capsule())
    }
}
extension View {
    func capsuleButton(isOn: Bool) -> some View {
        self.modifier(CapsuleButton(isOn: isOn))
    }
}
struct ContentView: View {
    @StateObject private var scanner = BLEScanner()

    var body: some View {
        VStack(spacing: 12) {
            Button(scanner.isScanning ? "Stop" : "Scan") {
                scanner.isScanning ? scanner.stop() : scanner.start()
            }
            .capsuleButton(isOn: scanner.isScanning)
            
            if(scanner.state != CBManagerState.poweredOn) {
                Text(statusText(scanner.state))
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            }
            let sortedDevices =   scanner.devices.sorted { $0.value.rssi > $1.value.rssi}
            List(sortedDevices, id: \.key) {id, device in
                VStack{
                    Text(id.uuidString)
                        .font(.body)
                        .lineLimit(1)
                        .minimumScaleFactor(0.5)
                    
                    HStack {
                        
                        Text(device.name ).font(.subheadline)
                        Spacer()
                        Image(systemName: "chart.bar.fill", variableValue: rssiValue(device.rssi))
                        Text("RSSI \(device.rssi)")
                            .monospacedDigit()
                            .foregroundStyle(.secondary)
                            .font(.caption)
                    }
                }}
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
