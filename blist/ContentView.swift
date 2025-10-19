import CoreBluetooth
import StoreKit
import SwiftData
import SwiftUI

//
//  ContentView.swift
//  blist
//
//  Created by Brian Greeson on 8/16/25.
//
enum AppView: String, CaseIterable, Codable {
    case scanView, mapView, detailView
}
struct ContentView: View {
    @StateObject private var scanner = BLEScanner()
    @StateObject private var locationManger = LocationManager()
    //    @State private var favorites: [UUID] = []
    //    @State private var hideUnknowns: Bool = false
    //    @State private var showDeviceDetails: Bool = false
    @State private var currentView: AppView = .mapView
    @State private var selectedDevice: BleDevice?
    
    var body: some View {
        
        NavigationStack {
            Group{
                switch currentView {
                case .scanView:
                    ScanView(selectedDevice: $selectedDevice, scanner: scanner)
                case .mapView:
                    MapView(locationManager: locationManger)
                default:
                    ScanView(selectedDevice: $selectedDevice, scanner: scanner)
                }
            }.toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button {
                        switch currentView {
                        case .scanView:
                            currentView = .mapView
                        case .mapView:
                            currentView = .scanView
                        default:
                            currentView = .scanView
                        }
                    } label: {
                        switch currentView {
                        case .scanView:
                            Image(systemName: "map")
                      
                        case .mapView:
                            Image(systemName: "list.triangle")
                        
                        default:
                            Image(systemName: "map")
                        }
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
        }.onAppear{
            locationManger.request()
            
        }
    }
}

#Preview {
    ContentView()
}
