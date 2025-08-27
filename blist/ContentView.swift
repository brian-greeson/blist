import CoreBluetooth
import SwiftUI

//
//  ContentView.swift
//  blist
//
//  Created by Brian Greeson on 8/16/25.
//

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
    @State private var favorites: [UUID] = []
    var body: some View {
        NavigationStack() {
            Button(scanner.isScanning ? "Stop" : "Scan") {
                scanner.isScanning ? scanner.stop() : scanner.start()
            }
            .capsuleButton(isOn: scanner.isScanning)

            if scanner.state != CBManagerState.poweredOn {
                Text(statusText(scanner.state))
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            }

            let sortedDevices = scanner.devices.sorted { $0.value.rssi > $1.value.rssi }

            if favorites.isEmpty {
                Text("No favorites yet.")
                    .font(.body)
                    .foregroundStyle(.secondary)
            } else {
                let favoriteDevices = sortedDevices.filter { favorites.contains($0.key) }
                List(favoriteDevices, id: \.key) { id, device in
                    VStack {
                        Text(id.uuidString)
                            .font(.body)
                            .lineLimit(1)
                            .minimumScaleFactor(0.5)
                        HStack {
                            Text(device.name).font(.subheadline)
                            Spacer()
                            Image(systemName: "chart.bar.fill", variableValue: rssiValue(device.rssi))
                            Text("RSSI \(device.rssi)")
                                .monospacedDigit()
                                .foregroundStyle(.secondary)
                                .font(.caption)
                            Button{
                                if let deviceIndex = favorites.firstIndex(of: id){
                                    favorites.remove(at: deviceIndex)
                                }
                            }label: {
                                Image(systemName: "star.fill")
                            }
                           

                        }
                    }
                }
            }

            List(sortedDevices, id: \.key) { id, device in
                VStack {
                    Text(id.uuidString)
                        .font(.body)
                        .lineLimit(1)
                        .minimumScaleFactor(0.5)

                    HStack {

                        Text(device.name).font(.subheadline)
                        Spacer()
                        Image(systemName: "chart.bar.fill", variableValue: rssiValue(device.rssi))
                        Text("RSSI \(device.rssi)")
                            .monospacedDigit()
                            .foregroundStyle(.secondary)
                            .font(.caption)
                        Button {
                            if (!favorites.contains(id)){
                                favorites.append(id)
                            }
                        } label: {
                            Image(systemName: "star")
                        }

                    }

                }
            }
        }
        .padding()
    }
    func rssiValue(_ rssi: Int) -> Double {

        if rssi > -40{
            return 1.0
        } else if rssi > -60 {
            return 0.5
        } else if rssi > -70 {
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
