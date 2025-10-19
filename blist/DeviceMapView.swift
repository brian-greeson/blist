//
//  DeviceMapView.swift
//  blist
//
//  Created by Brian Greeson on 10/19/25.
//

import MapKit
import SwiftUI

struct DeviceMapView: View {
    let device: BleDevice

    var body: some View {
        HStack {
            if device.locations.count > 0 {
               
                Map {
                    ForEach( device.locations, id: \.location.timestamp ){location in
                        
                        Marker("\(location.rssi)", coordinate: location.location.coordinate)
                    }
                    
                    MapPolyline(coordinates: device.locations.map { $0.location.coordinate}).stroke(.blue, lineWidth: 3)
                    
                }.mapStyle(.hybrid())
                    .onChange(of: device.locations.count) { oldValue, newValue in
                        print(device.locations.map { "\($0.location.coordinate.latitude),\($0.location.coordinate.longitude)" })
                    }
            } else {
                Text("Location Disabled")
            }
        }
       
    }
}

#Preview {
    let adData: [String: Any] = ["kCBAdvDataLocalName": "Test Device", "kCBAdvDataIsConnectable": true]
   
    let locations = [
        LocationWithRssi(location: CLLocation(latitude: 40.16542788868557, longitude: -105.11478137193205), rssi: 65)
    ]
    //, 40.16542737193466,-105.11486883117522, 40.16542715301923,-105.11484493024145
    let device = BleDevice(
        id: UUID(),
        name: "Test Device",
        rssi: -65,
        advertisementData: adData,
        lastUpdated: Date(),
        services: [],
        locations: []
    )
    DeviceMapView(device: device)
}
